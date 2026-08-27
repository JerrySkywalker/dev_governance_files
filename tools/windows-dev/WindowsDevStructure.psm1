Set-StrictMode -Version Latest

$script:WindowsDevStructureRepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:WindowsDevStructureManifestPath = Join-Path $script:WindowsDevStructureRepositoryRoot 'config/windows-dev-directory-manifest-v1.json'

function Assert-WindowsDevRelativeDirectoryPath {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$FieldName
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "$FieldName must not be empty."
    }

    if ($RelativePath -eq '.') {
        return
    }

    if ([System.IO.Path]::IsPathRooted($RelativePath) -or
        $RelativePath -match '(^|[\\/])\.\.([\\/]|$)' -or
        $RelativePath -match '(^|[\\/])\.([\\/]|$)') {
        throw "$FieldName must be a safe relative directory path: $RelativePath"
    }
}

function Get-WindowsDevDirectoryEntries {
    param(
        [Parameter(Mandatory = $true)][object]$Manifest,
        [Parameter(Mandatory = $true)][string[]]$CollectionNames
    )

    $entries = [System.Collections.Generic.List[object]]::new()
    $paths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($collectionName in $CollectionNames) {
        $property = $Manifest.PSObject.Properties[$collectionName]
        if ($null -eq $property) {
            throw "Directory manifest is missing $collectionName."
        }

        foreach ($entry in @($property.Value)) {
            if ($null -eq $entry.PSObject.Properties['relative_path'] -or
                $null -eq $entry.PSObject.Properties['purpose']) {
                throw "Directory manifest entry in $collectionName is incomplete."
            }

            $relativePath = [string]$entry.relative_path
            Assert-WindowsDevRelativeDirectoryPath -RelativePath $relativePath -FieldName "$collectionName.relative_path"
            if (-not $paths.Add($relativePath)) {
                throw "Directory manifest duplicates a governed path: $relativePath"
            }

            $entries.Add([pscustomobject]@{
                RelativePath = $relativePath
                Purpose = [string]$entry.purpose
            })
        }
    }

    return @($entries)
}

function Get-WindowsDevDirectoryManifest {
    [CmdletBinding()]
    param(
        [string]$ManifestPath = $script:WindowsDevStructureManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Windows development directory manifest is missing: $ManifestPath"
    }

    try {
        $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    }
    catch {
        throw "Windows development directory manifest is invalid JSON: $ManifestPath. $($_.Exception.Message)"
    }

    if ([int]$manifest.schema_version -ne 1) {
        throw 'Unsupported Windows development directory manifest schema version.'
    }
    if ([string]$manifest.manifest_id -ne 'JERRY_WINDOWS_DEV_DIRECTORY_MANIFEST_V1') {
        throw 'Unexpected Windows development directory manifest ID.'
    }
    if ([string]$manifest.roots.c_dev -ne 'C:\Dev' -or [string]$manifest.roots.v_work -ne 'V:\') {
        throw 'Windows development directory manifest roots do not match the canonical C: and V: roots.'
    }
    if ([bool]$manifest.invariants.directory_bootstrap_installs_software -or
        -not [bool]$manifest.invariants.v_python_caches_opt_in_only -or
        [bool]$manifest.invariants.vhdx_creation_or_replacement -or
        [bool]$manifest.invariants.production_or_device_mutation) {
        throw 'Windows development directory manifest safety invariants are invalid.'
    }

    $null = Get-WindowsDevDirectoryEntries -Manifest $manifest -CollectionNames @('c_dev_directories')
    $null = Get-WindowsDevDirectoryEntries -Manifest $manifest -CollectionNames @('v_work_directories', 'v_optional_python_cache_directories')
    return $manifest
}

function Resolve-WindowsDevDirectoryPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    Assert-WindowsDevRelativeDirectoryPath -RelativePath $RelativePath -FieldName 'relative_path'
    if ($RelativePath -eq '.') {
        return $BasePath
    }

    return Join-Path -Path $BasePath -ChildPath $RelativePath
}

function New-WindowsDevDirectoryEntries {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][object[]]$Entries
    )

    foreach ($entry in $Entries) {
        $path = Resolve-WindowsDevDirectoryPath -BasePath $BasePath -RelativePath ([string]$entry.RelativePath)
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force
            if (-not $item.PSIsContainer) {
                throw "Governed directory path exists but is not a directory: $path"
            }
            [pscustomobject]@{
                Path = $path
                RelativePath = [string]$entry.RelativePath
                Purpose = [string]$entry.Purpose
                Action = 'EXISTING'
            }
            continue
        }

        New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
        [pscustomobject]@{
            Path = $path
            RelativePath = [string]$entry.RelativePath
            Purpose = [string]$entry.Purpose
            Action = 'CREATED'
        }
    }
}

function New-WindowsDevCDevStructure {
    [CmdletBinding()]
    param(
        [string]$CDevRoot
    )

    $manifest = Get-WindowsDevDirectoryManifest
    if ([string]::IsNullOrWhiteSpace($CDevRoot)) {
        $CDevRoot = [string]$manifest.roots.c_dev
    }

    $entries = Get-WindowsDevDirectoryEntries -Manifest $manifest -CollectionNames @('c_dev_directories')
    New-WindowsDevDirectoryEntries -BasePath $CDevRoot -Entries $entries
}

function Assert-WindowsDevWorkingVolume {
    [CmdletBinding()]
    param(
        [string]$VWorkRoot
    )

    $manifest = Get-WindowsDevDirectoryManifest
    if ([string]::IsNullOrWhiteSpace($VWorkRoot)) {
        $VWorkRoot = [string]$manifest.roots.v_work
    }

    if ($VWorkRoot -notmatch '^[A-Za-z]:\\?$') {
        throw "V working root must be a mounted drive root such as V:\\; received: $VWorkRoot"
    }

    $driveLetter = $VWorkRoot.Substring(0, 1).ToUpperInvariant()
    $normalizedRoot = "$driveLetter`:\"
    if (-not (Test-Path -LiteralPath $normalizedRoot -PathType Container)) {
        throw "Dev Drive $normalizedRoot is not mounted. No directory, VHDX, or volume action was taken."
    }

    $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
    if ($null -eq $volume) {
        throw "Mounted drive $normalizedRoot could not be inspected as a volume; refusing to create the V: working skeleton."
    }
    if ([string]$volume.DriveType -ne 'Fixed') {
        throw "Mounted drive $normalizedRoot has unsupported drive type '$($volume.DriveType)'; expected Fixed."
    }
    if ([string]$volume.FileSystem -ne 'ReFS') {
        throw "Mounted drive $normalizedRoot has filesystem '$($volume.FileSystem)'; expected ReFS for the Dev Drive working layer."
    }

    return [pscustomobject]@{
        DriveRoot = $normalizedRoot
        DriveType = [string]$volume.DriveType
        FileSystem = [string]$volume.FileSystem
        Suitable = $true
    }
}

function New-WindowsDevVWorkStructure {
    [CmdletBinding()]
    param(
        [string]$VWorkRoot,
        [switch]$IncludePythonCaches
    )

    $manifest = Get-WindowsDevDirectoryManifest
    if ([string]::IsNullOrWhiteSpace($VWorkRoot)) {
        $VWorkRoot = [string]$manifest.roots.v_work
    }
    if (-not (Test-Path -LiteralPath $VWorkRoot -PathType Container)) {
        throw "V working root is absent: $VWorkRoot. No directory, VHDX, or volume action was taken."
    }

    $collections = @('v_work_directories')
    if ($IncludePythonCaches) {
        $collections += 'v_optional_python_cache_directories'
    }
    $entries = Get-WindowsDevDirectoryEntries -Manifest $manifest -CollectionNames $collections
    New-WindowsDevDirectoryEntries -BasePath $VWorkRoot -Entries $entries
}

function Test-WindowsDevDirectoryTopology {
    [CmdletBinding()]
    param(
        [string]$CDevRoot,
        [string]$VWorkRoot,
        [switch]$IncludeVWork,
        [switch]$IncludePythonCaches
    )

    $manifest = Get-WindowsDevDirectoryManifest
    if ([string]::IsNullOrWhiteSpace($CDevRoot)) {
        $CDevRoot = [string]$manifest.roots.c_dev
    }
    if ([string]::IsNullOrWhiteSpace($VWorkRoot)) {
        $VWorkRoot = [string]$manifest.roots.v_work
    }

    $topologies = [System.Collections.Generic.List[object]]::new()
    $topologies.Add([pscustomobject]@{
        Name = 'C_DEV'
        BasePath = $CDevRoot
        Collections = @('c_dev_directories')
    })
    if ($IncludeVWork) {
        $collections = @('v_work_directories')
        if ($IncludePythonCaches) {
            $collections += 'v_optional_python_cache_directories'
        }
        $topologies.Add([pscustomobject]@{
            Name = 'V_WORK'
            BasePath = $VWorkRoot
            Collections = $collections
        })
    }

    foreach ($topology in $topologies) {
        $entries = Get-WindowsDevDirectoryEntries -Manifest $manifest -CollectionNames $topology.Collections
        $missing = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $entries) {
            $path = Resolve-WindowsDevDirectoryPath -BasePath $topology.BasePath -RelativePath $entry.RelativePath
            if (-not (Test-Path -LiteralPath $path -PathType Container)) {
                $missing.Add($entry.RelativePath)
            }
        }

        [pscustomobject]@{
            Name = $topology.Name
            BasePath = $topology.BasePath
            ExpectedDirectoryCount = $entries.Count
            MissingRelativePaths = @($missing)
            IsValid = ($missing.Count -eq 0)
        }
    }
}

Export-ModuleMember -Function @(
    'Get-WindowsDevDirectoryManifest',
    'New-WindowsDevCDevStructure',
    'Assert-WindowsDevWorkingVolume',
    'New-WindowsDevVWorkStructure',
    'Test-WindowsDevDirectoryTopology'
)
