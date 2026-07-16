[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedHead)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/RepoHealthManifestCoordinator.psm1') -Force

$passed = 0
function Assert-True { param([bool]$Condition,[string]$Message) if(-not $Condition){throw $Message};$script:passed++ }
function Assert-Fails { param([scriptblock]$Action,[string]$Message) $failed=$false;try{& $Action}catch{$failed=$true};Assert-True $failed $Message }

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$head = (git -C $repo rev-parse HEAD).Trim()
Assert-True ($head -eq $ExpectedHead) 'exact-head audit binding'

$header = [pscustomobject][ordered]@{
    goal_schema='repo-health-goal-header.v1';goal_id='readonly-audit';parent_goal_id='readonly-parent';run_id='readonly-run';wave_id='W0';step_id='PUBLISH_GENERIC_COORDINATOR';phase_id='EXACT_HEAD_AUDIT';role='Supervisor'
    working_directory=$repo;repository_id='dev_governance_files';repository_path=$repo;github_repository='JerrySkywalker/dev_governance_files';stable_branch='main';expected_input_sha=$ExpectedHead;expected_output_sha_or_empty=$ExpectedHead
    allowed_write_surfaces=@('none');prohibited_write_surfaces=@('all-writes');goal_file_path='in-memory-only';goal_sha256=('a'*64)
}
$envelope = [pscustomobject](New-RepoHealthProcessEnvelope -GoalHeader $header -Outcome PASS -ObservedSha $ExpectedHead -AuditedSha $ExpectedHead -RemoteCandidateSha $ExpectedHead -PrHeadSha $ExpectedHead -PrBaseBranch main -SanitizedSummary 'readonly_exact_head_audit_pass')
Assert-True (Test-RepoHealthProcessEnvelope -Envelope $envelope).valid 'strict pure Supervisor envelope'
$extra=[pscustomobject]@{};foreach($property in $envelope.PSObject.Properties){$extra|Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value};$extra|Add-Member -NotePropertyName harmless_extra -NotePropertyValue 'one'
Assert-True (-not (Test-RepoHealthProcessEnvelope -Envelope $extra).valid) 'strict extra field rejection'
Assert-RepoHealthBoundEnvelope -Envelope $envelope -Header $header -ObservedHead $ExpectedHead
Assert-True $true 'exact Goal to envelope identity binding'
$implementerHeader=[pscustomobject]$header;$implementerHeader.role='Implementer'
$implementer=[pscustomobject](New-RepoHealthProcessEnvelope -GoalHeader $implementerHeader -Outcome PASS -ObservedSha $ExpectedHead -ProductRepositoryWrite $true -GitMutation $true -SanitizedSummary 'candidate_sha_ready')
Assert-RepoHealthPostImplementerSha -ImplementerEnvelope $implementer -ObservedCandidateSha $ExpectedHead
Assert-True $true 'post-Implementer SHA binding'
Assert-Fails { Assert-RepoHealthPostImplementerSha -ImplementerEnvelope $implementer -ObservedCandidateSha ('b'*40) } 'post-Implementer SHA mismatch'
Assert-RepoHealthBranchStability -LocalCandidateSha $ExpectedHead -RemoteCandidateSha $ExpectedHead -PrHeadSha $ExpectedHead -SupervisorAuditedSha $ExpectedHead -ExpectedMergeHeadSha $ExpectedHead -PrBaseBranch main -StableBranch main
Assert-True $true 'branch stability proof'
Assert-Fails { Assert-RepoHealthBranchStability -LocalCandidateSha $ExpectedHead -RemoteCandidateSha ('c'*40) -PrHeadSha $ExpectedHead -SupervisorAuditedSha $ExpectedHead -ExpectedMergeHeadSha $ExpectedHead -PrBaseBranch main -StableBranch main } 'branch move rejection'
Assert-Fails { Assert-RepoHealthLaunchArguments -Arguments @('--yolo') } 'forbidden yolo rejection'

$moduleSource = Get-Content -LiteralPath (Join-Path $repo 'tools/repo-health/RepoHealthManifestCoordinator.psm1') -Raw
foreach($required in @('Test-RepoHealthExactPropertySet','duplicate_semantic_field','Assert-RepoHealthRunStepRequest','Assert-RepoHealthPostImplementerSha','Assert-RepoHealthBranchStability','Read-only role changed Git state')) { Assert-True ($moduleSource.Contains($required)) ('required coordinator guard '+$required) }
foreach($file in @((Join-Path $repo 'tools/repo-health/RepoHealthManifestCoordinator.psm1'),(Join-Path $repo 'tools/repo-health/Invoke-RepoHealthManifestCoordinator.ps1'))) { $tokens=$null;$errors=$null;[System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)|Out-Null;Assert-True ($errors.Count -eq 0) ('PowerShell AST '+[IO.Path]::GetFileName($file)) }
foreach($file in Get-ChildItem -LiteralPath (Join-Path $repo 'tools/repo-health/schemas') -Filter '*.json') { Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null;Assert-True $true ('JSON parse '+$file.Name) }
git -C $repo diff --check ($ExpectedHead + '^..' + $ExpectedHead)
if($LASTEXITCODE -ne 0){throw 'exact-head diff check failed'}
Write-Output ('PASS repo-health read-only exact-head audit tests=' + $passed)
