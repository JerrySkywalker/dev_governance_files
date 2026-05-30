[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$RenderScript = Join-Path $RepoRoot "server-ops\bin\render-windows-bootstrap.py"
$TemplatePath = Join-Path $RepoRoot "server-ops\edge-hermes\templates\windows-bootstrap.ps1.tmpl"
$GeneratedDir = Join-Path $RepoRoot "server-ops\edge-hermes\generated\tests"
$GeneratedPath = Join-Path $GeneratedDir "laptop-zenbookduo-windows-bootstrap.ps1"

function Assert-Contains {
  param(
    [string]$Content,
    [string]$Needle,
    [string]$Label
  )
  if (-not $Content.Contains($Needle)) {
    throw "Missing required marker: $Label"
  }
}

function Assert-NotContains {
  param(
    [string]$Content,
    [string]$Needle,
    [string]$Label
  )
  if ($Content.Contains($Needle)) {
    throw "Forbidden marker present: $Label"
  }
}

if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
  throw "Template not found: $TemplatePath"
}

New-Item -ItemType Directory -Force -Path $GeneratedDir | Out-Null
python $RenderScript laptop-zenbookduo --output $GeneratedPath

if (-not (Test-Path -LiteralPath $GeneratedPath -PathType Leaf)) {
  throw "Generated bootstrap not found: $GeneratedPath"
}

$Rendered = Get-Content -LiteralPath $GeneratedPath -Raw

Assert-NotContains $Rendered "C:\Dev\tools\bin\python.exe" "legacy fake global Python path"

$RequiredMarkers = @(
  "HermesCmd",
  "HermesPython",
  "RunnerPath",
  "LauncherVbs",
  "WatchdogPath",
  "WatchdogVbs",
  "wscript.exe",
  "WindowsPowerShell\v1.0\powershell.exe",
  "--noproxy",
  "-Audit",
  "-Plan",
  "-Apply",
  "-Repair"
)

foreach ($marker in $RequiredMarkers) {
  Assert-Contains $Rendered $marker $marker
}

[scriptblock]::Create($Rendered) | Out-Null

$SecretPatterns = @(
  "sk-[A-Za-z0-9_-]{20,}",
  "FAKE_EDGE_API_KEY_[0-9A-Fa-f]{32,}",
  "[A-Fa-f0-9]{64}"
)

foreach ($pattern in $SecretPatterns) {
  if ($Rendered -match $pattern) {
    throw "Possible embedded secret matched pattern: $pattern"
  }
}

Write-Host "Edge bootstrap generator tests passed: $GeneratedPath"
