[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$agents = Join-Path $root 'AGENTS.md'
$manifestPath = Join-Path $root '.agent\context-manifest-v1.json'
Assert (Test-Path $agents) 'Root AGENTS.md missing'
Assert ((Get-Item $agents).Length -le 12288) 'Root AGENTS.md exceeds 12 KiB'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
Assert ($manifest.manifest_id -eq 'JERRY_AGENT_CONTEXT_V1') 'Unexpected context manifest ID'

$routes = @($manifest.routes)
$retro = $routes | Where-Object glob -eq 'docs/jerry-series/retrospectives/**'
Assert ($retro.context_class -eq 'HISTORICAL_REFERENCE') 'Retrospectives must be historical'
Assert (-not $retro.normative) 'Retrospectives must be non-normative'
Assert ($retro.execution -eq 'prohibited') 'Retrospective execution must be prohibited'

$plans = $routes | Where-Object glob -eq 'docs/jerry-series/plans/**'
Assert ($plans.context_class -eq 'ARCHIVE_EXPLICIT_ONLY') 'Plans must be explicit-only by default'

$harness = $routes | Where-Object glob -eq 'docs/jerry-series/harness/**'
Assert ($harness.context_class -eq 'ACTIVE_NORMATIVE') 'Harness must be active normative'
Assert ($harness.entrypoint -eq 'docs/jerry-series/harness/README.md') 'Harness entrypoint mismatch'

foreach ($path in @(
    'docs\jerry-series\harness\AGENTS.md',
    'docs\jerry-series\playbooks\AGENTS.md',
    'docs\jerry-series\decisions\AGENTS.md',
    'docs\jerry-series\retrospectives\AGENTS.md',
    'docs\jerry-series\plans\AGENTS.md'
)) {
    Assert (Test-Path (Join-Path $root $path)) "Missing nested Agent instruction: $path"
}

& (Join-Path $root 'scripts\repo-health\Build-AgentContextAdapters.ps1') -Check
"AGENT_CONTEXT_CONTRACT=PASS"
