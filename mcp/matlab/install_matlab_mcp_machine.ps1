#Requires -Version 5.1
<#
.SYNOPSIS
  Install MATLAB MCP Core Server into the machine-level MCP governance directory.

.DESCRIPTION
  This script downloads MATLAB MCP Core Server for Windows and installs it under C:\Dev\mcp.
  It can optionally clone/update MATLAB Agentic Toolkit.

  IMPORTANT:
  This script does NOT write to the global Codex config:
      %USERPROFILE%\.codex\config.toml

  The agreed workflow is project-level Codex MCP configuration:
      <project>\.codex\config.toml

.PARAMETER McpRoot
  Machine-level MCP root. Default: C:\Dev\mcp

.PARAMETER MatlabRoot
  MATLAB installation root. Do not include \bin. Default: C:\Program Files\MATLAB\R2025b

.PARAMETER SkipToolkit
  Skip cloning/updating MATLAB Agentic Toolkit.

.PARAMETER Force
  Force re-download and reinstall of MATLAB MCP Core Server.

.EXAMPLE
  .\install_matlab_mcp_machine.ps1

.EXAMPLE
  .\install_matlab_mcp_machine.ps1 -MatlabRoot "C:\Program Files\MATLAB\R2025b" -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$McpRoot = "C:\Dev\mcp",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$MatlabRoot = "C:\Program Files\MATLAB\R2025b",

    [Parameter()]
    [switch]$SkipToolkit,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Text)
    Write-Host ""
    Write-Host "==== $Text ====" -ForegroundColor Cyan
}

function New-DirectoryIfMissing {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATE] $Path"
    }
    else {
        Write-Host "[SKIP]   $Path"
    }
}

function ConvertTo-TomlBasicString {
    param([Parameter(Mandatory = $true)][string]$Text)

    $escaped = $Text.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
}

function Test-Executable {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Test-Path -LiteralPath $Path -PathType Leaf)
}

Write-Section "Create MCP governance directories"

$serverRoot = Join-Path $McpRoot "servers\matlab-mcp-core-server"
$serverBinDir = Join-Path $serverRoot "bin"
$serverReleaseDir = Join-Path $serverRoot "releases"
$toolkitsDir = Join-Path $McpRoot "toolkits"
$toolkitDir = Join-Path $toolkitsDir "matlab-agentic-toolkit"
$configTemplateDir = Join-Path $McpRoot "configs\codex\templates"
$docsDir = Join-Path $McpRoot "docs"
$logsDir = Join-Path $McpRoot "logs"

@(
    $McpRoot,
    (Join-Path $McpRoot "servers"),
    $serverRoot,
    $serverBinDir,
    $serverReleaseDir,
    $toolkitsDir,
    $configTemplateDir,
    $docsDir,
    $logsDir
) | ForEach-Object { New-DirectoryIfMissing -Path $_ }

Write-Section "Check MATLAB root"

if (Test-Path -LiteralPath $MatlabRoot) {
    Write-Host "[OK] MATLAB root exists: $MatlabRoot"
}
else {
    Write-Warning "MATLAB root does not exist: $MatlabRoot"
    Write-Warning "The install can continue, but project templates will contain this path. Fix it if needed."
}

Write-Section "Download MATLAB MCP Core Server"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$targetExe = Join-Path $serverBinDir "matlab-mcp-core-server.exe"

if ((Test-Executable -Path $targetExe) -and (-not $Force)) {
    Write-Host "[SKIP] MATLAB MCP Core Server already exists: $targetExe"
    Write-Host "       Use -Force to re-download."
}
else {
    $releaseApi = "https://api.github.com/repos/matlab/matlab-mcp-core-server/releases/latest"
    $headers = @{
        "User-Agent" = "dev-dev-governance-matlab-mcp-installer"
        "Accept"     = "application/vnd.github+json"
    }

    Write-Host "[INFO] Query latest release: $releaseApi"
    $release = Invoke-RestMethod -Uri $releaseApi -Headers $headers

    $asset = $release.assets |
        Where-Object { $_.name -match "win64" -and $_.name -match "\.exe$" } |
        Select-Object -First 1

    if (-not $asset) {
        throw "Cannot find a Windows win64 .exe asset in the latest MATLAB MCP Core Server release."
    }

    $tagName = $release.tag_name
    $downloadPath = Join-Path $serverReleaseDir ("matlab-mcp-core-server-{0}-win64.exe" -f $tagName)

    Write-Host "[INFO] Latest release: $tagName"
    Write-Host "[INFO] Download asset: $($asset.name)"
    Write-Host "[INFO] Save to: $downloadPath"

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath -Headers $headers

    Copy-Item -Path $downloadPath -Destination $targetExe -Force
    Unblock-File -Path $targetExe -ErrorAction SilentlyContinue

    Write-Host "[OK] Installed MATLAB MCP Core Server:"
    Write-Host "     $targetExe"
}

Write-Section "Optionally clone or update MATLAB Agentic Toolkit"

if ($SkipToolkit) {
    Write-Host "[SKIP] SkipToolkit was specified."
}
else {
    $git = Get-Command git -ErrorAction SilentlyContinue

    if (-not $git) {
        Write-Warning "git was not found. Skip MATLAB Agentic Toolkit clone/update."
        Write-Warning "Install Git for Windows if you want the toolkit managed here."
    }
    elseif (Test-Path -LiteralPath (Join-Path $toolkitDir ".git")) {
        Write-Host "[INFO] Update existing MATLAB Agentic Toolkit:"
        Write-Host "       $toolkitDir"
        & git -C $toolkitDir pull
    }
    elseif (Test-Path -LiteralPath $toolkitDir) {
        Write-Warning "Toolkit directory exists but is not a git repository: $toolkitDir"
        Write-Warning "Please inspect it manually."
    }
    else {
        Write-Host "[INFO] Clone MATLAB Agentic Toolkit:"
        Write-Host "       $toolkitDir"
        & git clone "https://github.com/matlab/matlab-agentic-toolkit.git" $toolkitDir
    }
}

Write-Section "Generate Codex project-level config template"

$templatePath = Join-Path $configTemplateDir "matlab-project.config.toml"

$tomlCommand = ConvertTo-TomlBasicString -Text $targetExe
$tomlMatlabRoot = ConvertTo-TomlBasicString -Text ("--matlab-root={0}" -f $MatlabRoot)

$template = @"
# MATLAB MCP project-level Codex template.
# Copy this file to:
#   <project>\.codex\config.toml
#
# Do NOT put this block into:
#   %USERPROFILE%\.codex\config.toml
#
# Adjust --matlab-root if your MATLAB is installed elsewhere.

[mcp_servers.matlab]
command = $tomlCommand
args = [
  $tomlMatlabRoot,
  "--matlab-display-mode=nodesktop",
  "--matlab-session-mode=new",
  "--initialize-matlab-on-startup=false",
  "--disable-telemetry=true"
]
startup_timeout_sec = 60
tool_timeout_sec = 600
enabled_tools = [
  "detect_matlab_toolboxes",
  "check_matlab_code",
  "evaluate_matlab_code",
  "run_matlab_file",
  "run_matlab_test_file"
]
"@

Set-Content -Path $templatePath -Value $template -Encoding UTF8
Write-Host "[OK] Template generated:"
Write-Host "     $templatePath"

Write-Section "Check global Codex config"

$globalCodexConfig = Join-Path $env:USERPROFILE ".codex\config.toml"

if (Test-Path -LiteralPath $globalCodexConfig) {
    $globalText = Get-Content -Path $globalCodexConfig -Raw -ErrorAction Stop

    if ($globalText -match "(?m)^\s*\[mcp_servers\.matlab\]\s*$") {
        Write-Warning "Global Codex config contains [mcp_servers.matlab]."
        Write-Warning "Recommended action: remove that block manually and use project-level .codex\config.toml instead."
        Write-Warning "Global config: $globalCodexConfig"
    }
    else {
        Write-Host "[OK] No global [mcp_servers.matlab] block detected."
    }
}
else {
    Write-Host "[OK] Global Codex config does not exist yet:"
    Write-Host "     $globalCodexConfig"
}

Write-Section "Summary"

Write-Host "[MCP root]       $McpRoot"
Write-Host "[Server exe]     $targetExe"
Write-Host "[Template]       $templatePath"
Write-Host "[MATLAB root]    $MatlabRoot"
Write-Host ""
Write-Host "Next step:"
Write-Host "  Copy mcp\matlab\setup_project_matlab_mcp.ps1 into a project root, then run it there."
Write-Host "  It will create project-level .codex\config.toml and docs\MATLAB_MCP_PROJECT.md."
