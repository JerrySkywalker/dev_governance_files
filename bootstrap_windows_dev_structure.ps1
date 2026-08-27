# Canonical staged bootstrap for a Jerry Windows development workstation.
# It creates and verifies directory topology only; package installation and
# dotfiles/profile wiring intentionally remain outside this entrypoint.

[CmdletBinding()]
param(
    [ValidateSet('C', 'V', 'All')]
    [string]$Stage = 'All',
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

$allActions = [System.Collections.Generic.List[object]]::new()
$volume = $null

if ($Stage -in @('C', 'All')) {
    Write-Host "[STAGE A/B] Creating and verifying stable C:\Dev topology at $CDevRoot"
    $cActions = @(New-WindowsDevCDevStructure -CDevRoot $CDevRoot)
    foreach ($action in $cActions) {
        $allActions.Add($action)
        Write-Host "[$($action.Action)] $($action.Path)"
    }
}

$cReport = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot)[0]
if (-not $cReport.IsValid) {
    throw "C:\Dev topology is incomplete. Stage V and package installation are refused. Missing: $($cReport.MissingRelativePaths -join ', ')"
}
Write-Host '[PASS] STAGE_B_C_DEV_PARENTS=VALID'

if ($Stage -in @('V', 'All')) {
    Write-Host "[STAGE C] Verifying mounted Dev Drive $VWorkRoot before any V: directory action"
    $volume = Assert-WindowsDevWorkingVolume -VWorkRoot $VWorkRoot
    Write-Host "[PASS] STAGE_C_V_WORKING_VOLUME=VALID ($($volume.FileSystem), $($volume.DriveType))"

    Write-Host "[STAGE D] Creating and verifying V: working topology at $VWorkRoot"
    $vActions = @(New-WindowsDevVWorkStructure -VWorkRoot $VWorkRoot -IncludePythonCaches:$IncludePythonCaches)
    foreach ($action in $vActions) {
        $allActions.Add($action)
        Write-Host "[$($action.Action)] $($action.Path)"
    }

    $reports = @(Test-WindowsDevDirectoryTopology -CDevRoot $CDevRoot -VWorkRoot $VWorkRoot -IncludeVWork -IncludePythonCaches:$IncludePythonCaches)
    $invalidReports = @($reports | Where-Object { -not $_.IsValid })
    if ($invalidReports.Count -gt 0) {
        $missing = @($invalidReports | ForEach-Object { $_.MissingRelativePaths })
        throw "Directory topology verification failed: $($missing -join ', ')"
    }
    Write-Host '[PASS] STAGE_D_V_WORKING_SKELETON=VALID'
}

Write-Host '[BOUNDARY] STAGE_E_PACKAGE_INSTALLATION=NOT_RUN'
Write-Host '[BOUNDARY] STAGE_F_DOTFILES_PROFILE_WIRING=NOT_RUN'
Write-Host '[BOUNDARY] STAGE_G_APPLICATION_SEMANTIC_MIGRATIONS=NOT_RUN'
Write-Host '[NEXT] After the required directory topology is valid, package installation may be performed by its separately authorized workflow.'

if ($PassThru) {
    [pscustomobject]@{
        Stage = $Stage
        CDevTopologyValid = [bool]$cReport.IsValid
        VWorkingVolume = $volume
        IncludePythonCaches = [bool]$IncludePythonCaches
        DirectoryActions = @($allActions)
        DirectoryBootstrapInstallsSoftware = $false
    }
}
