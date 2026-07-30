[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Write
)

$ErrorActionPreference = 'Stop'
if ($Check -and $Write) { throw 'Choose either -Check or -Write, not both.' }
if (-not $Check -and -not $Write) { $Check = $true }

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$manifestPath = Join-Path $root '.agent/context-manifest-v1.json'
$null = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

$expected = [ordered]@{
    'CLAUDE.md' = @'
<!-- GENERATED FROM AGENTS.md AND .agent/context-manifest-v1.json -->
Read `AGENTS.md` first. Use `.agent/context-manifest-v1.json` for context routing.
Do not recursively load historical directories. Retrospectives and old Plans are
non-normative and their code blocks are non-executable. For Harness work, start
at `docs/jerry-series/harness/README.md`.
'@
    '.github/copilot-instructions.md' = @'
<!-- GENERATED FROM AGENTS.md AND .agent/context-manifest-v1.json -->
This repository separates active normative Harness sources, conditional
Playbooks, and historical evidence. Read `AGENTS.md` and route through
`.agent/context-manifest-v1.json`. Do not infer current defaults from
Retrospectives or old Plans. For Harness work, start at
`docs/jerry-series/harness/README.md`; numeric values come only from
`config/repo-health-harness-v1.json`.
'@
    '.aiderignore' = @'
# GENERATED FROM .agent/context-manifest-v1.json
docs/jerry-series/retrospectives/**
docs/jerry-series/plans/**
**/generated/**
# Explicitly add a historical file for a history/calibration task when required.
'@
}

$drift = @()
foreach ($entry in $expected.GetEnumerator()) {
    $path = Join-Path $root $entry.Key
    $wanted = ($entry.Value.TrimEnd() + [Environment]::NewLine)
    if ($Write) {
        $parent = Split-Path -Parent $path
        if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        Set-Content -LiteralPath $path -Value $wanted -NoNewline -Encoding utf8
    }
    if (-not (Test-Path -LiteralPath $path)) {
        $drift += "missing:$($entry.Key)"
        continue
    }
    $actual = Get-Content -Raw -LiteralPath $path
    $normalize = { param($Text) (($Text -replace "`r`n", "`n").TrimEnd() + "`n") }
    if ((& $normalize $actual) -ne (& $normalize $wanted)) {
        $drift += "drift:$($entry.Key)"
    }
}

if ($drift.Count -gt 0) {
    throw "Agent adapter drift: $($drift -join ', ')"
}

'AGENT_CONTEXT_ADAPTERS=PASS'
