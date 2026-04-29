# 创建 C:\Dev 目录结构（稳定层 / 治理层 / NTFS）
# 可重复执行；已存在目录会被跳过。
# 说明：MCP 相关服务端、Agentic Toolkit 与配置模板统一放在 C:\Dev\mcp；
#       具体项目是否启用某个 MCP Server，则由项目仓库内的 .codex\config.toml 控制。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$base = 'C:\Dev'

$relativeDirs = @(
    '.',

    # 手动管理的工具链本体
    'toolchains',
    'toolchains\flutter',
    'toolchains\vcpkg',
    'toolchains\qt',
    'toolchains\qt-legacy',
    'toolchains\android-sdk',
    'toolchains\miniconda3',

    # MCP / Agent 集成层：服务端、Toolkit、模板、日志
    'mcp',
    'mcp\servers',
    'mcp\servers\matlab-mcp-core-server',
    'mcp\servers\matlab-mcp-core-server\bin',
    'mcp\servers\matlab-mcp-core-server\releases',
    'mcp\toolkits',
    'mcp\toolkits\matlab-agentic-toolkit',
    'mcp\configs',
    'mcp\configs\codex',
    'mcp\configs\codex\templates',
    'mcp\docs',
    'mcp\logs',

    # 共享资源与公共资产
    'resources',
    'resources\stk',
    'resources\stk\satellites',
    'resources\stk\terrain',
    'resources\stk\imagery',
    'resources\stk\templates',
    'resources\common-data',

    # 机器级脚本、文档、虚拟磁盘、备份和历史兼容区
    'scripts',
    'docs',
    'volumes',
    'backups',
    'legacy',
    'legacy\src',
    'legacy\build',
    'legacy\resources'
)

function Join-DevPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    if ($RelativePath -eq '.') {
        return $BasePath
    }

    return Join-Path -Path $BasePath -ChildPath $RelativePath
}

Write-Host "[INFO] 正在创建 C 盘治理目录结构：$base"

foreach ($relativeDir in $relativeDirs) {
    $dir = Join-DevPath -BasePath $base -RelativePath $relativeDir

    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "[CREATE] $dir"
    }
    else {
        Write-Host "[SKIP]   $dir"
    }
}

Write-Host "`n[OK] C:\Dev 目录结构创建完成。"
Write-Host "[NOTE] Dev Drive 的 VHDX 文件建议放到：C:\Dev\volumes\dev-main.vhdx"
Write-Host "[NOTE] MATLAB MCP Core Server 建议放到：C:\Dev\mcp\servers\matlab-mcp-core-server\bin\matlab-mcp-core-server.exe"
Write-Host "[NOTE] MATLAB Agentic Toolkit 建议放到：C:\Dev\mcp\toolkits\matlab-agentic-toolkit"
Write-Host "[NOTE] Codex 的 MATLAB MCP 不建议写入全局 ~/.codex/config.toml；建议在具体项目的 .codex\config.toml 中启用。"