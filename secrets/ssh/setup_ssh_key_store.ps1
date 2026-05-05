# 初始化 Windows 本机 SSH 私钥保管区
# 默认路径：C:\Dev\secrets\ssh
#
# 用法示例：
#   pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1
#   pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1 -SourceKey "C:\Dev\ssh_key\beijing.pem"
#   pwsh -File .\secrets\ssh\setup_ssh_key_store.ps1 -SourceKey "C:\Dev\ssh_key\beijing.pem" -KeyName "beijing.pem"

param(
    [string]$TargetDir = "C:\Dev\secrets\ssh",
    [string]$SourceKey = "",
    [string]$KeyName = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Grant-PrivateAcl {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$IsDirectory
    )

    $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    icacls $Path /inheritance:r | Out-Null
    icacls $Path /remove:g "BUILTIN\Users" "Authenticated Users" "Everyone" 2>$null | Out-Null
    icacls $Path /remove:g "*S-1-5-32-545" 2>$null | Out-Null

    if ($IsDirectory) {
        icacls $Path /grant:r "$($me):(OI)(CI)(F)" | Out-Null
        icacls $Path /grant:r "SYSTEM:(OI)(CI)(F)" | Out-Null
        icacls $Path /grant:r "Administrators:(OI)(CI)(F)" | Out-Null
    }
    else {
        icacls $Path /grant:r "$($me):(R)" | Out-Null
        icacls $Path /grant:r "SYSTEM:(F)" | Out-Null
        icacls $Path /grant:r "Administrators:(F)" | Out-Null
    }
}

Write-Host "[INFO] SSH key store: $TargetDir"

if (-not (Test-Path -LiteralPath $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
    Write-Host "[CREATE] $TargetDir"
}
else {
    Write-Host "[SKIP]   $TargetDir"
}

Grant-PrivateAcl -Path $TargetDir -IsDirectory

if ($SourceKey -ne "") {
    if (-not (Test-Path -LiteralPath $SourceKey)) {
        throw "Source key does not exist: $SourceKey"
    }

    if ($KeyName -eq "") {
        $KeyName = Split-Path -Path $SourceKey -Leaf
    }

    $targetKey = Join-Path -Path $TargetDir -ChildPath $KeyName

    Move-Item -LiteralPath $SourceKey -Destination $targetKey -Force
    Grant-PrivateAcl -Path $targetKey

    Write-Host "[MOVED]  $SourceKey -> $targetKey"
    Write-Host "[NOTE]   Add this to %USERPROFILE%\.ssh\config:"
    Write-Host "         IdentityFile $($targetKey.Replace('\','/'))"
}

Write-Host "`n[OK] SSH key store initialized."
Write-Host "[CHECK] Run: icacls `"$TargetDir`""
