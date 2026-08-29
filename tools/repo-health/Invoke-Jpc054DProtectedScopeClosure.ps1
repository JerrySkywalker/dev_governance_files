[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Verify','Close')][string]$Mode,
    [string]$AuthorizationPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Jpc054DProtectedScopeClosure.psm1') -Force

Invoke-Jpc054DProtectedScopeClosure -Mode $Mode -AuthorizationPath $AuthorizationPath | ConvertTo-Json -Depth 12
