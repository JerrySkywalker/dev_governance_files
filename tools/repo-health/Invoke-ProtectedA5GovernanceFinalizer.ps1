[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Observe','Finalize')][string]$Mode,
    [Parameter(Mandatory)][string]$TaskRoot,
    [Parameter(Mandatory)][string]$LeasePath,
    [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
    [string]$AuthorizationPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ProtectedA5GovernanceFinalizer.psm1') -Force

if ($Mode -ceq 'Observe') {
    Test-ProtectedA5GovernanceFinalizationAdmission `
        -TaskRoot $TaskRoot `
        -LeasePath $LeasePath `
        -ExpectedLeaseSha256 $ExpectedLeaseSha256 `
        -AuthorizationPath $AuthorizationPath |
        ConvertTo-Json -Depth 12
}
else {
    Invoke-ProtectedA5GovernanceFinalization `
        -TaskRoot $TaskRoot `
        -LeasePath $LeasePath `
        -ExpectedLeaseSha256 $ExpectedLeaseSha256 `
        -AuthorizationPath $AuthorizationPath |
        ConvertTo-Json -Depth 12
}
