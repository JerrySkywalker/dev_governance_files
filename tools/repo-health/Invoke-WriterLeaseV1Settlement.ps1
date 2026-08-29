[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Observe','Settle')][string]$Mode,
    [Parameter(Mandatory)][string]$TaskRoot,
    [Parameter(Mandatory)][string]$LeasePath,
    [ValidatePattern('^[0-9a-f]{64}$')][string]$ExpectedLeaseSha256 = '',
    [string]$AuthorizationPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'WriterLeaseV1Settlement.psm1') -Force

switch ($Mode) {
    'Observe' {
        Test-WriterLeaseV1SettlementAdmission -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 | ConvertTo-Json -Depth 8
    }
    'Settle' {
        if ([string]::IsNullOrWhiteSpace($ExpectedLeaseSha256) -or [string]::IsNullOrWhiteSpace($AuthorizationPath)) {
            throw 'Settle requires ExpectedLeaseSha256 and AuthorizationPath.'
        }
        Invoke-WriterLeaseV1InterimSettlement -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath | ConvertTo-Json -Depth 8
    }
}
