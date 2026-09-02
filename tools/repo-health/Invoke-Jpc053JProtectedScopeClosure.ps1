[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Observe','Close')]
    [string]$Mode,
    [string]$AuthorizationPath = ''
)

Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'Jpc054DProtectedScopeClosure.psm1') -Force

Invoke-Jpc053JProtectedScopeClosure -Mode $Mode -AuthorizationPath $AuthorizationPath | ConvertTo-Json -Depth 12
