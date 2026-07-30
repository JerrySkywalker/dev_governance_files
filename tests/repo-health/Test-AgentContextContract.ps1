[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path

$agents = Join-Path $root 'AGENTS.md'
$manifestPath = Join-Path $root '.agent/context-manifest-v1.json'
if (-not (Test-Path -LiteralPath $agents)) { throw 'Root AGENTS.md missing.' }
if ((Get-Item -LiteralPath $agents).Length -gt 12288) { throw 'Root AGENTS.md exceeds 12 KiB.' }
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.manifest_id -ne 'JERRY_AGENT_CONTEXT_V1') { throw 'Unexpected context manifest ID.' }

$routes = @($manifest.routes)
$retrospectives = @($routes | Where-Object glob -eq 'docs/jerry-series/retrospectives/**')
if ($retrospectives.Count -ne 1) { throw 'Exactly one Retrospective route is required.' }
if ($retrospectives[0].context_class -ne 'HISTORICAL_REFERENCE') { throw 'Retrospectives must be historical.' }
if ([bool]$retrospectives[0].normative) { throw 'Retrospectives must be non-normative.' }
if ($retrospectives[0].execution -ne 'prohibited') { throw 'Retrospective execution must be prohibited.' }

$plans = @($routes | Where-Object glob -eq 'docs/jerry-series/plans/**')
if ($plans.Count -ne 1) { throw 'Exactly one Plans route is required.' }
if ($plans[0].context_class -ne 'ARCHIVE_EXPLICIT_ONLY') { throw 'Plans must be explicit-only by default.' }

$harness = @($routes | Where-Object glob -eq 'docs/jerry-series/harness/**')
if ($harness.Count -ne 1) { throw 'Exactly one Harness route is required.' }
if ($harness[0].context_class -ne 'ACTIVE_NORMATIVE') { throw 'Harness must be active normative.' }
if ($harness[0].entrypoint -ne 'docs/jerry-series/harness/README.md') { throw 'Harness entrypoint mismatch.' }

foreach ($path in @(
    'docs/jerry-series/harness/AGENTS.md',
    'docs/jerry-series/playbooks/AGENTS.md',
    'docs/jerry-series/decisions/AGENTS.md',
    'docs/jerry-series/retrospectives/AGENTS.md',
    'docs/jerry-series/plans/AGENTS.md'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path))) {
        throw "Missing nested Agent instruction: $path"
    }
}

& (Join-Path $root 'scripts/repo-health/Build-AgentContextAdapters.ps1') -Check
'AGENT_CONTEXT_CONTRACT=PASS'
