[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Observe','Prepare')][string]$Mode,
    [Parameter(Mandatory)][string]$TaskRoot,
    [Parameter(Mandatory)][string]$LeasePath,
    [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
    [Parameter(Mandatory)][string]$PreparationManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'ProtectedA5LegacyCompatibility.psm1') -Force

if($Mode -ceq 'Observe'){
    Test-ProtectedA5LegacyCompatibilityAdmission -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath | ConvertTo-Json -Depth 12
}
else{
    Invoke-ProtectedA5LegacyCompatibilityPreparation -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath | ConvertTo-Json -Depth 12
}
