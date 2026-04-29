# 创建 V:\ 目录结构（Dev Drive / 工作层 / 高 IO 层）
# 可重复执行；已存在目录会被跳过。
# 默认目标盘符为 V:；如需修改，请调整 $base 变量。
# 说明：V:\ 只承载活跃项目、构建、缓存、数据和临时内容；
#       MCP 服务端本体不放在 V:\，而统一放在 C:\Dev\mcp。
#       具体项目的 Codex MCP 配置应放在对应仓库的 .codex\config.toml 中。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$base = 'V:\'

if (-not (Test-Path -LiteralPath $base)) {
    throw "目标盘符 $base 不存在。请先挂载 Dev Drive，再运行此脚本。"
}

$relativeDirs = @(
    'src',
    'build',
    'cache',
    'cache\pub',
    'cache\gradle',
    'cache\vcpkg-downloads',
    'cache\vcpkg-bincache',
    'cache\pip',
    'cache\conda-pkgs',
    'cache\temp',
    'datasets',
    'datasets\hgv',
    'datasets\stk-exports',
    'datasets\monte-carlo',
    'scratch'
)

Write-Host "[INFO] 正在创建 Dev Drive 工作目录结构：$base"

foreach ($relativeDir in $relativeDirs) {
    $dir = Join-Path -Path $base -ChildPath $relativeDir

    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "[CREATE] $dir"
    }
    else {
        Write-Host "[SKIP]   $dir"
    }
}

Write-Host "`n[OK] V: 工作目录结构创建完成。"
Write-Host "[NOTE] 建议将项目源码放入 V:\src，将缓存放入 V:\cache，将构建输出放入 V:\build。"
Write-Host "[NOTE] 若某项目需要 MATLAB MCP，请在该项目仓库内创建：.codex\config.toml。"
Write-Host "[NOTE] MCP 服务端本体建议统一放在：C:\Dev\mcp，而不是 V:\。"