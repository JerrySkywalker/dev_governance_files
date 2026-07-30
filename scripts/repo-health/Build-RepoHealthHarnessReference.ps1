[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Write
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$configPath = Join-Path $root 'config\repo-health-harness-v1.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

$domainIndex = @{}
for ($i = 0; $i -lt $config.budget_domains.Count; $i++) {
    $domainIndex[$config.budget_domains[$i]] = $i
}

$rows = foreach ($property in $config.profiles.PSObject.Properties) {
    $name = $property.Name
    $p = $property.Value
    $source = @($p.budget_matrix[$domainIndex['semantic_correction']])
    $apply = @($p.budget_matrix[$domainIndex['apply']])
    $finalize = @($p.budget_matrix[$domainIndex['finalize']])
    "| $name | $($p.allowed_authority_classes -join ',') | $($p.elasticity_grade) | $($p.allowed_layers -join ',') | $($source[0])/$($source[2]) | $($apply[0])/$($apply[2]) | $($finalize[0])/$($finalize[2]) |"
}

$content = @(
    '<!-- GENERATED FROM config/repo-health-harness-v1.json; DO NOT EDIT -->'
    '# Harness Profile Summary'
    ''
    '| Profile | Authority | Elasticity | Layers | Source correction | Apply | Finalize |'
    '| --- | --- | --- | --- | ---: | ---: | ---: |'
    $rows
    ''
    '`window/lifetime`; exact ledgers remain in the JSON source.'
    ''
) -join [Environment]::NewLine

$path = Join-Path $root 'docs\jerry-series\harness\generated\profile-summary.md'
if ($Write) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    Set-Content -LiteralPath $path -Value $content -NoNewline -Encoding utf8
}

if (-not (Test-Path -LiteralPath $path)) { throw "Missing generated Harness reference" }
$actual = Get-Content -Raw -LiteralPath $path
$normalize = { param($Text) (($Text -replace "`r`n", "`n").TrimEnd() + "`n") }
if ((& $normalize $actual) -ne (& $normalize $content)) {
    throw "Harness generated reference drift"
}

"HARNESS_REFERENCE=PASS"
