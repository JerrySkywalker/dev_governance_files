# Compatibility entrypoint retained for C-only Python, uv, and Conda preparation.
# It now creates the complete canonical C:\Dev skeleton so every parent exists
# before any separately authorized package installation starts.

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

Write-Host "[INFO] Compatibility entrypoint: verifying complete C:\Dev prerequisites at $CDevRoot"
$actions = @(New-WindowsDevCDevStructure -CDevRoot $CDevRoot)
foreach ($action in $actions) {
    Write-Host "[$($action.Action)] $($action.Path)"
}

$report = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot)[0]
if (-not $report.IsValid) {
    throw "C:\Dev topology verification failed: $($report.MissingRelativePaths -join ', ')"
}

Write-Host '[PASS] C_DEV_UV_CONDA_PREREQUISITES=VALID'
Write-Host '[BOUNDARY] No uv, Miniconda, Python, Conda, pip, Codex, or profile action was run.'

if ($PassThru) {
    $actions
}
