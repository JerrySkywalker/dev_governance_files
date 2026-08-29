[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/RepoHealthManifestCoordinator.psm1') -Force

$passed=0
function Assert-True { param([bool]$Condition,[string]$Message) if(-not $Condition){throw $Message};$script:passed++ }
function Assert-Fails { param([scriptblock]$Action,[string]$Message)$failed=$false;try{& $Action}catch{$failed=$true};Assert-True $failed $Message }

$prohibitions='stage0 publication;A4;A5;production mutation;protected transaction;rollback execution;device mutation;owner-only production boundary'
$header=[pscustomobject]@{allowed_write_surfaces=@('src/**','tests/**','docs/**');prohibited_write_surfaces=@('all-other-repositories')}
$development=[pscustomobject]@{header=$header;body=("SCOPE_CLASSIFICATION=DEVELOPMENT_TRAIN`nDEVELOPMENT_OWNERSHIP=source code;tests;CI;Git PR;docs;release preparation;release build qualification;immutable artifact custody`nPROHIBITED_PROTECTED_SURFACES=$prohibitions`nSource-only implementation.`n")}
$classification=Test-RepoHealthDevelopmentProductionScope -Goal $development
Assert-True ($classification.allowed -and $classification.classification -eq 'DEVELOPMENT_TRAIN') 'ordinary development scope remains writer-admissible'

$mixed=[pscustomobject]@{header=$header;body=($development.body + 'conditional later A5 protected transaction after release' + "`n")}
$mixedClassification=Test-RepoHealthDevelopmentProductionScope -Goal $mixed
Assert-True (-not $mixedClassification.allowed -and $mixedClassification.classification -eq 'MIXED_DEVELOPMENT_PRODUCTION_SCOPE') 'conditional later A5 is permanently mixed scope'
Assert-Fails { Assert-RepoHealthDevelopmentWriterScope -Goal $mixed | Out-Null } 'mixed scope rejects before writer acquisition'

$surfaceBypassHeader=[pscustomobject]@{allowed_write_surfaces=@('src/**','production');prohibited_write_surfaces=@('all-other-repositories')}
$surfaceBypass=[pscustomobject]@{header=$surfaceBypassHeader;body=$development.body}
$surfaceBypassClassification=Test-RepoHealthDevelopmentProductionScope -Goal $surfaceBypass
Assert-True (-not $surfaceBypassClassification.allowed -and $surfaceBypassClassification.classification -eq 'MIXED_DEVELOPMENT_PRODUCTION_SCOPE') 'bare production allow-list entry cannot bypass mixed-scope rejection'

$protected=[pscustomobject]@{header=$header;body='SCOPE_CLASSIFICATION=PROTECTED_TRANSACTION' + "`n"}
Assert-True ((Test-RepoHealthDevelopmentProductionScope -Goal $protected).classification -eq 'PROTECTED_SCOPE_REQUIRES_SEPARATE_TRANSACTION_COORDINATOR') 'protected transaction requires a separate coordinator'
Write-Output ('PASS development-production scope tests=' + $passed)
