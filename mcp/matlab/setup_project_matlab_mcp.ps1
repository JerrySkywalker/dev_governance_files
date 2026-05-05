#Requires -Version 5.1
<#
.SYNOPSIS
  Create project-level Codex configuration for MATLAB MCP.

.DESCRIPTION
  Copy this script into a MATLAB project root and run it there.
  It creates:
      .codex\config.toml
      docs\MATLAB_MCP_PROJECT.md

  It does NOT modify the global Codex config:
      %USERPROFILE%\.codex\config.toml

.PARAMETER ProjectRoot
  Project root. Default: current directory.

.PARAMETER McpExe
  MATLAB MCP Core Server executable path.

.PARAMETER MatlabRoot
  MATLAB installation root. Do not include \bin.

.PARAMETER SessionMode
  MATLAB session mode. new or existing. Default: new.

.PARAMETER DisplayMode
  MATLAB display mode. nodesktop or desktop. Default: nodesktop.

.PARAMETER InitializeMatlabOnStartup
  If set, MATLAB initializes as soon as the MCP server starts.
  Default is false; MATLAB starts only when the first tool is called.

.PARAMETER NoInitialWorkingFolder
  If set, do not add --initial-working-folder=<ProjectRoot>.

.PARAMETER OverwriteMatlabSection
  If .codex\config.toml already contains [mcp_servers.matlab], replace that section.

.PARAMETER CreateAgentsFile
  If set, create a conservative AGENTS.md if one does not already exist.

.EXAMPLE
  .\setup_project_matlab_mcp.ps1

.EXAMPLE
  .\setup_project_matlab_mcp.ps1 -ProjectRoot "C:\Dev\src\hgv-custody-tpipe" -OverwriteMatlabSection

.EXAMPLE
  .\setup_project_matlab_mcp.ps1 -SessionMode existing -DisplayMode desktop
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Get-Location).Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$McpExe = "C:\Dev\mcp\servers\matlab-mcp-core-server\bin\matlab-mcp-core-server.exe",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$MatlabRoot = "C:\Program Files\MATLAB\R2025b",

    [Parameter()]
    [ValidateSet("new", "existing")]
    [string]$SessionMode = "new",

    [Parameter()]
    [ValidateSet("nodesktop", "desktop")]
    [string]$DisplayMode = "nodesktop",

    [Parameter()]
    [switch]$InitializeMatlabOnStartup,

    [Parameter()]
    [switch]$NoInitialWorkingFolder,

    [Parameter()]
    [switch]$OverwriteMatlabSection,

    [Parameter()]
    [switch]$CreateAgentsFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Text)
    Write-Host ""
    Write-Host "==== $Text ====" -ForegroundColor Cyan
}

function ConvertTo-TomlBasicString {
    param([Parameter(Mandatory = $true)][string]$Text)

    $escaped = $Text.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
}

function Backup-File {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$Path.bak.$timestamp"
        Copy-Item -Path $Path -Destination $backupPath -Force
        Write-Host "[BACKUP] $backupPath"
    }
}

function Remove-MatlabMcpSection {
    param([Parameter(Mandatory = $true)][string]$Content)

    $pattern = '(?ms)^\s*\[mcp_servers\.matlab\]\s*.*?(?=^\s*\[|\z)'
    return [regex]::Replace($Content, $pattern, '').Trim()
}

Write-Section "Resolve project paths"

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$codexDir = Join-Path $ProjectRoot ".codex"
$docsDir = Join-Path $ProjectRoot "docs"
$configPath = Join-Path $codexDir "config.toml"
$projectDocPath = Join-Path $docsDir "MATLAB_MCP_PROJECT.md"

Write-Host "[PROJECT] $ProjectRoot"
Write-Host "[CODEX]   $codexDir"
Write-Host "[CONFIG]  $configPath"
Write-Host "[DOC]     $projectDocPath"

Write-Section "Validate prerequisites"

if (-not (Test-Path -LiteralPath $McpExe -PathType Leaf)) {
    throw "MATLAB MCP Core Server executable not found: $McpExe. Run install_matlab_mcp_machine.ps1 first."
}

if (-not (Test-Path -LiteralPath $MatlabRoot -PathType Container)) {
    throw "MATLAB root not found: $MatlabRoot. Pass -MatlabRoot with the correct MATLAB installation path."
}

Write-Host "[OK] MCP executable exists: $McpExe"
Write-Host "[OK] MATLAB root exists: $MatlabRoot"

Write-Section "Create project directories"

New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
New-Item -ItemType Directory -Force -Path $docsDir | Out-Null

Write-Section "Build MATLAB MCP config"

$initOnStartup = if ($InitializeMatlabOnStartup) { "true" } else { "false" }

$argItems = New-Object System.Collections.Generic.List[string]
$argItems.Add("--matlab-root=$MatlabRoot")
$argItems.Add("--matlab-display-mode=$DisplayMode")
$argItems.Add("--matlab-session-mode=$SessionMode")
$argItems.Add("--initialize-matlab-on-startup=$initOnStartup")
$argItems.Add("--disable-telemetry=true")

if (-not $NoInitialWorkingFolder) {
    $argItems.Add("--initial-working-folder=$ProjectRoot")
}

$tomlArgLines = $argItems | ForEach-Object { "  " + (ConvertTo-TomlBasicString -Text $_) }
$tomlArgBlock = $tomlArgLines -join ",`r`n"

$matlabSectionLines = @(
    '[mcp_servers.matlab]',
    ('command = ' + (ConvertTo-TomlBasicString -Text $McpExe)),
    'args = [',
    $tomlArgBlock,
    ']',
    'startup_timeout_sec = 60',
    'tool_timeout_sec = 600',
    'enabled_tools = [',
    '  "detect_matlab_toolboxes",',
    '  "check_matlab_code",',
    '  "evaluate_matlab_code",',
    '  "run_matlab_file",',
    '  "run_matlab_test_file"',
    ']'
)
$matlabSection = ($matlabSectionLines -join "`r`n").Trim()

$currentConfig = ""
if (Test-Path -LiteralPath $configPath) {
    $currentConfig = Get-Content -Path $configPath -Raw
}

$hasMatlabSection = $currentConfig -match "(?m)^\s*\[mcp_servers\.matlab\]\s*$"

if ($hasMatlabSection -and (-not $OverwriteMatlabSection)) {
    throw "Existing [mcp_servers.matlab] found in $configPath. Re-run with -OverwriteMatlabSection to replace it."
}

if (Test-Path -LiteralPath $configPath) {
    Backup-File -Path $configPath
}

if ($hasMatlabSection) {
    $currentConfig = Remove-MatlabMcpSection -Content $currentConfig
}

if ([string]::IsNullOrWhiteSpace($currentConfig)) {
    $newConfig = $matlabSection + "`r`n"
}
else {
    $newConfig = $currentConfig.TrimEnd() + "`r`n`r`n" + $matlabSection + "`r`n"
}

Set-Content -Path $configPath -Value $newConfig -Encoding UTF8
Write-Host "[OK] Wrote project Codex config:"
Write-Host "     $configPath"

Write-Section "Generate project Markdown"

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$hasInitialWorkingFolder = (-not $NoInitialWorkingFolder).ToString()

$projectDocLines = @(
    '# MATLAB MCP 项目级配置说明',
    '',
    ('生成时间：' + $generatedAt),
    '',
    '## 1. 项目路径',
    '',
    '```text',
    $ProjectRoot,
    '```',
    '',
    '## 2. 当前 MATLAB MCP 配置',
    '',
    'MATLAB MCP Core Server：',
    '',
    '```text',
    $McpExe,
    '```',
    '',
    'MATLAB 安装目录：',
    '',
    '```text',
    $MatlabRoot,
    '```',
    '',
    'MATLAB session mode：',
    '',
    '```text',
    $SessionMode,
    '```',
    '',
    'MATLAB display mode：',
    '',
    '```text',
    $DisplayMode,
    '```',
    '',
    '是否在 MCP Server 启动时立即初始化 MATLAB：',
    '',
    '```text',
    $initOnStartup,
    '```',
    '',
    '是否设置 MATLAB 初始工作目录：',
    '',
    '```text',
    $hasInitialWorkingFolder,
    '```',
    '',
    '项目级 Codex 配置文件：',
    '',
    '```text',
    (Join-Path $ProjectRoot '.codex\config.toml'),
    '```',
    '',
    '## 3. 使用方法',
    '',
    '进入项目目录：',
    '',
    '```powershell',
    ('cd "' + $ProjectRoot + '"'),
    'codex',
    '```',
    '',
    '如果 Codex 提示是否信任该项目，请选择信任。',
    '',
    '进入 Codex 后执行：',
    '',
    '```text',
    '/mcp',
    '```',
    '',
    '确认 matlab server 已出现。',
    '',
    '然后可以输入：',
    '',
    '```text',
    '请检测 MATLAB 版本和已安装工具箱。',
    '```',
    '',
    '## 4. 推荐第一次任务',
    '',
    '```text',
    '请使用 MATLAB MCP 对当前工程做只读环境检查，不要修改任何文件。',
    '',
    '要求：',
    '1. 检测 MATLAB 版本和工具箱；',
    '2. 检查当前工作目录；',
    "3. 尝试执行 startup('force', true)；",
    '4. 使用 check_matlab_code 检查 startup.m；',
    '5. 不运行任何大型实验；',
    '6. 汇报 MATLAB 是否可用、路径链是否正常、下一步建议。',
    '```',
    '',
    '## 5. 注意事项',
    '',
    '1. 本项目使用项目级 .codex/config.toml，不依赖全局 Codex MCP 配置。',
    '2. 不建议把 MATLAB MCP 写入 %USERPROFILE%\.codex\config.toml。',
    '3. 长耗时仿真实验应先由 Codex 生成命令，再由用户确认是否执行。',
    '4. 如果需要连接已经打开的 MATLAB，请改用 --matlab-session-mode=existing，并在 MATLAB 中运行 shareMATLABSession()。',
    '5. 如果项目移动了位置，请重新运行本脚本，以刷新 --initial-working-folder。',
    '',
    '## 6. 当前生成的 MCP 片段',
    '',
    '```toml'
) + ($matlabSection -split "`r?`n") + @(
    '```'
)

$projectDoc = $projectDocLines -join "`r`n"
Set-Content -Path $projectDocPath -Value $projectDoc -Encoding UTF8
Write-Host "[OK] Wrote project Markdown:"
Write-Host "     $projectDocPath"

if ($CreateAgentsFile) {
    Write-Section "Create optional AGENTS.md"

    $agentsPath = Join-Path $ProjectRoot "AGENTS.md"

    if (Test-Path -LiteralPath $agentsPath) {
        Write-Host "[SKIP] AGENTS.md already exists:"
        Write-Host "       $agentsPath"
    }
    else {
        $agentsLines = @(
            '# AGENTS.md',
            '',
            '本工程是 MATLAB 代码工程。默认目标是整理、复现和维护，不允许随意改变核心数学模型、实验口径和图表口径。',
            '',
            '## 基本原则',
            '',
            '1. 默认使用中文回复。',
            '2. 修改前必须先说明计划。',
            '3. 除非明确要求，不得删除 outputs、mats、figs、logs 中的历史结果。',
            '4. 不得一次性大规模重构；每次修改应控制在一个明确主题内。',
            '5. 对数值算法、参数网格、指标定义、图表口径的修改必须单独说明。',
            '6. 优先保留可复现性，而不是追求目录“好看”。',
            '7. 长耗时实验默认不要直接运行，应先说明风险和命令。',
            '8. 使用 MATLAB MCP 时，优先执行只读检查和 smoke test。'
        )
        $agents = $agentsLines -join "`r`n"
        Set-Content -Path $agentsPath -Value $agents -Encoding UTF8
        Write-Host "[OK] Wrote AGENTS.md:"
        Write-Host "     $agentsPath"
    }
}

Write-Section "Summary"

Write-Host "[OK] Project-level MATLAB MCP configuration is ready."
Write-Host ""
Write-Host "Next commands:"
Write-Host "  cd `"$ProjectRoot`""
Write-Host "  codex"
Write-Host ""
Write-Host "Inside Codex:"
Write-Host "  /mcp"
Write-Host "  请检测 MATLAB 版本和已安装工具箱。"
