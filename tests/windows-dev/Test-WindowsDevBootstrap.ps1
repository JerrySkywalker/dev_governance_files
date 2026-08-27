[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw "ASSERTION_FAILED: $Message"
    }
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $threw = $false
    try {
        & $Action
    }
    catch {
        $threw = $true
    }
    Assert-True -Condition $threw -Message $Message
}

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$modulePath = Join-Path $root 'tools/windows-dev/WindowsDevStructure.psm1'
Import-Module $modulePath -Force

$parseTargets = @(
    'create_c_dev_structure.ps1',
    'create_c_python_conda_structure.ps1',
    'create_v_devdrive_structure.ps1',
    'bootstrap_windows_dev_structure.ps1',
    'tools/windows-dev/WindowsDevStructure.psm1'
)
foreach ($relativeTarget in $parseTargets) {
    $target = Join-Path $root $relativeTarget
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($target, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-True -Condition ($errors.Count -eq 0) -Message "PowerShell parser rejected $relativeTarget"
}

$manifest = Get-WindowsDevDirectoryManifest
Assert-True -Condition ($manifest.manifest_id -eq 'JERRY_WINDOWS_DEV_DIRECTORY_MANIFEST_V1') -Message 'canonical directory manifest ID'
Assert-True -Condition (-not [bool]$manifest.invariants.directory_bootstrap_installs_software) -Message 'directory bootstrap must not install software'
Assert-True -Condition ([bool]$manifest.invariants.v_python_caches_opt_in_only) -Message 'V Python caches must stay opt-in'
Assert-True -Condition (-not [bool]$manifest.invariants.vhdx_creation_or_replacement) -Message 'bootstrap must not create or replace VHDX files'

$cPaths = @($manifest.c_dev_directories | ForEach-Object { [string]$_.relative_path })
$requiredCPaths = @(
    'tools', 'tools\bin', 'tools\uv-tools', 'tools\uv-python',
    'toolchains', 'toolchains\miniconda3', 'envs', 'envs\conda',
    'cache', 'cache\uv', 'cache\pip', 'cache\conda-pkgs',
    'backups', 'backups\conda', 'mcp', 'resources', 'scripts', 'docs',
    'volumes', 'legacy', 'secrets'
)
foreach ($path in $requiredCPaths) {
    Assert-True -Condition ($path -in $cPaths) -Message "manifest lacks required C directory $path"
}
Assert-True -Condition (($cPaths | Select-Object -Unique).Count -eq $cPaths.Count) -Message 'C manifest paths must be unique'

$vPaths = @($manifest.v_work_directories | ForEach-Object { [string]$_.relative_path })
foreach ($path in @('src', 'build', 'cache', 'datasets', 'scratch')) {
    Assert-True -Condition ($path -in $vPaths) -Message "manifest lacks required V directory $path"
}
$optionalVPaths = @($manifest.v_optional_python_cache_directories | ForEach-Object { [string]$_.relative_path })
Assert-True -Condition (($optionalVPaths -join '|') -eq 'cache\pip|cache\conda-pkgs') -Message 'V Python cache paths must be the two explicit opt-in paths'

$bootstrapSources = @(
    'create_c_dev_structure.ps1',
    'create_c_python_conda_structure.ps1',
    'create_v_devdrive_structure.ps1',
    'bootstrap_windows_dev_structure.ps1',
    'tools/windows-dev/WindowsDevStructure.psm1'
) | ForEach-Object { Get-Content -Raw -LiteralPath (Join-Path $root $_) }
$bootstrapText = $bootstrapSources -join "`n"
$installCommandPattern = '(?im)^\s*(?:&\s*)?(?:winget|choco|scoop|uv|conda|python|pip)\b.*\b(?:install|create|init)\b'
Assert-True -Condition ($bootstrapText -notmatch $installCommandPattern) -Message 'directory bootstrap source must not invoke installation commands'
foreach ($forbiddenVolumeCommand in @('New-VHD', 'Mount-VHD', 'Dismount-VHD', 'Initialize-Disk', 'Format-Volume', 'New-Volume')) {
    Assert-True -Condition ($bootstrapText -notmatch "(?i)\\b$forbiddenVolumeCommand\\b") -Message "directory bootstrap must not invoke $forbiddenVolumeCommand"
}

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('devgov-windows-bootstrap-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryRoot -ErrorAction Stop | Out-Null
try {
    $cDevRoot = Join-Path $temporaryRoot 'C-Dev'
    $firstC = @(New-WindowsDevCDevStructure -CDevRoot $cDevRoot)
    Assert-True -Condition ($firstC.Count -eq $cPaths.Count) -Message 'first C creation must process every manifest entry'
    Assert-True -Condition ((@($firstC | Where-Object Action -eq 'CREATED')).Count -gt 0) -Message 'first C creation must create directories'

    $cReport = @(Test-WindowsDevDirectoryTopology -CDevRoot $cDevRoot)[0]
    Assert-True -Condition $cReport.IsValid -Message 'created C topology must verify'

    $secondC = @(New-WindowsDevCDevStructure -CDevRoot $cDevRoot)
    Assert-True -Condition ((@($secondC | Where-Object Action -ne 'EXISTING')).Count -eq 0) -Message 'C creation must be idempotent'

    $compatibilityCRoot = Join-Path $temporaryRoot 'Compatibility-C-Dev'
    $compatibilityC = & (Join-Path $root 'create_c_dev_structure.ps1') -CDevRoot $compatibilityCRoot -PassThru 6>$null
    Assert-True -Condition (@($compatibilityC).Count -eq $cPaths.Count) -Message 'C compatibility entrypoint must consume the canonical manifest'
    $compatibilityPython = & (Join-Path $root 'create_c_python_conda_structure.ps1') -CDevRoot $compatibilityCRoot -PassThru 6>$null
    Assert-True -Condition ((@($compatibilityPython | Where-Object Action -ne 'EXISTING')).Count -eq 0) -Message 'Python compatibility entrypoint must remain idempotent'

    $vWorkRoot = Join-Path $temporaryRoot 'V-Work'
    New-Item -ItemType Directory -Path $vWorkRoot -ErrorAction Stop | Out-Null
    $firstV = @(New-WindowsDevVWorkStructure -VWorkRoot $vWorkRoot)
    Assert-True -Condition ($firstV.Count -eq $vPaths.Count) -Message 'default V creation must exclude opt-in Python caches'

    $reportsWithoutPythonCaches = @(Test-WindowsDevDirectoryTopology -CDevRoot $cDevRoot -VWorkRoot $vWorkRoot -IncludeVWork)
    Assert-True -Condition ((@($reportsWithoutPythonCaches | Where-Object { -not $_.IsValid })).Count -eq 0) -Message 'default V topology must verify without Python caches'

    $reportsBeforeOptIn = @(Test-WindowsDevDirectoryTopology -CDevRoot $cDevRoot -VWorkRoot $vWorkRoot -IncludeVWork -IncludePythonCaches)
    Assert-True -Condition ((@($reportsBeforeOptIn | Where-Object { -not $_.IsValid })).Count -eq 1) -Message 'opt-in V Python cache verification must detect absent opt-in paths'

    $optInV = @(New-WindowsDevVWorkStructure -VWorkRoot $vWorkRoot -IncludePythonCaches)
    Assert-True -Condition ((@($optInV | Where-Object Action -eq 'CREATED')).Count -eq $optionalVPaths.Count) -Message 'explicit opt-in must create only the optional Python cache paths'
    $reportsWithPythonCaches = @(Test-WindowsDevDirectoryTopology -CDevRoot $cDevRoot -VWorkRoot $vWorkRoot -IncludeVWork -IncludePythonCaches)
    Assert-True -Condition ((@($reportsWithPythonCaches | Where-Object { -not $_.IsValid })).Count -eq 0) -Message 'V topology with opt-in Python caches must verify'

    $secondV = @(New-WindowsDevVWorkStructure -VWorkRoot $vWorkRoot -IncludePythonCaches)
    Assert-True -Condition ((@($secondV | Where-Object Action -ne 'EXISTING')).Count -eq 0) -Message 'V creation must be idempotent'

    $orchestratedC = Join-Path $temporaryRoot 'Orchestrated-C-Dev'
    $orchestration = & (Join-Path $root 'bootstrap_windows_dev_structure.ps1') -Stage C -CDevRoot $orchestratedC -PassThru 6>$null
    Assert-True -Condition $orchestration.CDevTopologyValid -Message 'canonical orchestrator C stage must verify its topology'
    Assert-True -Condition (-not $orchestration.DirectoryBootstrapInstallsSoftware) -Message 'canonical orchestrator must report no package installation'

    $missingDrive = $null
    foreach ($letterCode in 68..90) {
        $candidate = "{0}:\" -f [char]$letterCode
        if (-not (Test-Path -LiteralPath $candidate)) {
            $missingDrive = $candidate
            break
        }
    }
    Assert-True -Condition ($null -ne $missingDrive) -Message 'a missing drive is required for the V absence safety test'
    Assert-Throws -Action { Assert-WindowsDevWorkingVolume -VWorkRoot $missingDrive | Out-Null } -Message 'absent V working volume must be refused'
    Assert-Throws -Action { & (Join-Path $root 'create_v_devdrive_structure.ps1') -CDevRoot $cDevRoot -VWorkRoot $missingDrive 6>$null } -Message 'V compatibility entrypoint must refuse an absent V volume'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

'WINDOWS_DEV_BOOTSTRAP_TEST=PASS'
