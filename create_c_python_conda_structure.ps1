# 创建 C-only Python / Conda 目录结构
# 可重复执行；已存在目录会被跳过。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$base = 'C:\Dev'

$relativeDirs = @(
    'toolchains',
    'toolchains\miniconda3',
    'envs',
    'envs\conda',
    'cache',
    'cache\pip',
    'cache\conda-pkgs',
    'backups',
    'backups\conda'
)

function Join-DevPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    return Join-Path -Path $BasePath -ChildPath $RelativePath
}

Write-Host "[INFO] 正在创建 C-only Python / Conda 目录结构：$base"

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

Write-Host "`n[OK] C-only Python / Conda 目录结构创建完成。"
Write-Host "[NOTE] Miniconda 本体：C:\Dev\toolchains\miniconda3"
Write-Host "[NOTE] conda envs：C:\Dev\envs\conda"
Write-Host "[NOTE] conda 包缓存：C:\Dev\cache\conda-pkgs"
Write-Host "[NOTE] pip 缓存：C:\Dev\cache\pip"
