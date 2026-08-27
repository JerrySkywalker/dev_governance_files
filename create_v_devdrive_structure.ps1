# Compatibility entrypoint for the canonical V: Dev Drive working skeleton.
# It requires the complete C:\Dev topology first and never creates or replaces a VHDX.

[CmdletBinding()]
param(
    [string]$CDevRoot,
    [string]$VWorkRoot,
    [switch]$IncludePythonCaches,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'tools/windows-dev/WindowsDevStructure.psm1') -Force
$manifest = Get-WindowsDevDirectoryManifest
if ([string]::IsNullOrWhiteSpace($CDevRoot)) {
    $CDevRoot = [string]$manifest.roots.c_dev
}
if ([string]::IsNullOrWhiteSpace($VWorkRoot)) {
    $VWorkRoot = [string]$manifest.roots.v_work
}

$cReport = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot)[0]
if (-not $cReport.IsValid) {
    throw "C:\Dev topology is incomplete. Run create_c_dev_structure.ps1 first. Missing: $($cReport.MissingRelativePaths -join ', ')"
}

$volume = Assert-WindowsDevWorkingVolume -VWorkRoot $VWorkRoot
Write-Host "[INFO] Verified Dev Drive $($volume.DriveRoot) ($($volume.FileSystem), $($volume.DriveType))"
$actions = @(New-WindowsDevVWorkStructure -VWorkRoot $VWorkRoot -IncludePythonCaches:$IncludePythonCaches)
foreach ($action in $actions) {
    Write-Host "[$($action.Action)] $($action.Path)"
}

$reports = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot -VWorkRoot $VWorkRoot -IncludeVWork -IncludePythonCaches:$IncludePythonCaches)
$invalidReports = @($reports | Where-Object { -not $_.IsValid })
if ($invalidReports.Count -gt 0) {
    $missing = @($invalidReports | ForEach-Object { $_.MissingRelativePaths })
    throw "Working topology verification failed: $($missing -join ', ')"
}

Write-Host '[PASS] V_WORK_TOPOLOGY=VALID'
Write-Host "[BOUNDARY] V_PYTHON_CACHES_OPT_IN_ONLY=$([bool]$IncludePythonCaches)"
Write-Host '[BOUNDARY] VHDX_CREATION_OR_REPLACEMENT=false'

if ($PassThru) {
    $actions
}
