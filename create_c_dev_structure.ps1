# Compatibility entrypoint for the canonical C:\Dev stable-governance skeleton.
# Directory topology only: this script never installs software or changes profiles.

[CmdletBinding()]
param(
    [string]$CDevRoot,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'tools/windows-dev/WindowsDevStructure.psm1') -Force
$manifest = Get-WindowsDevDirectoryManifest
if ([string]::IsNullOrWhiteSpace($CDevRoot)) {
    $CDevRoot = [string]$manifest.roots.c_dev
}

Write-Host "[INFO] Creating or verifying canonical C:\Dev topology: $CDevRoot"
$actions = @(New-WindowsDevCDevStructure -CDevRoot $CDevRoot)
foreach ($action in $actions) {
    Write-Host "[$($action.Action)] $($action.Path)"
}

$report = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot)[0]
if (-not $report.IsValid) {
    throw "C:\Dev topology verification failed: $($report.MissingRelativePaths -join ', ')"
}

Write-Host '[PASS] C_DEV_TOPOLOGY=VALID'
Write-Host '[NEXT] Package or tool installation remains a separate, later lifecycle stage.'
Write-Host '[BOUNDARY] DIRECTORY_BOOTSTRAP_INSTALLS_SOFTWARE=false'

if ($PassThru) {
    $actions
}
