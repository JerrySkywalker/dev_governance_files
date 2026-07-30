[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$configPath = Join-Path $root 'config/repo-health-harness-v1.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

if ($config.model_id -ne 'JERRY_HARNESS_MODEL_V1') { throw 'Unexpected model ID.' }
if ($config.baseline_id -ne 'JERRY_AUTONOMY_CI_PARAMS_V1') { throw 'Unexpected baseline ID.' }
if ([int]$config.parameter_family_count -ne 16) { throw 'Parameter family count must be 16.' }
if (@($config.parameter_families).Count -ne 16) { throw 'Parameter family registry must contain 16 entries.' }
if (@($config.profiles.PSObject.Properties).Count -ne 6) { throw 'Profile count must be 6.' }
if ('P_INIT' -notin @($config.axes.P)) { throw 'P_INIT is required.' }
if (@($config.axes.L).Count -ne 6) { throw 'L0-L5 must all exist.' }
if ([int]$config.global_invariants.same_head_same_signature_rerun_lifetime -ne 1) { throw 'Frozen rerun limit changed.' }
if ([int]$config.global_invariants.duplicate_canonical_full_gate_count -ne 0) { throw 'Duplicate full Gate must remain zero.' }
if (-not [bool]$config.global_invariants.authority_never_expands_automatically) { throw 'Automatic authority expansion must be disabled.' }
if (-not [bool]$config.global_invariants.budget_domains_never_borrow) { throw 'Budget borrowing must be disabled.' }

$domains = @($config.budget_domains)
$domainIndex = @{}
for ($i = 0; $i -lt $domains.Count; $i++) { $domainIndex[$domains[$i]] = $i }

foreach ($profileProperty in $config.profiles.PSObject.Properties) {
    $profileName = $profileProperty.Name
    $profile = $profileProperty.Value
    if ($profile.initial_progress_state -ne 'P_INIT') { throw "$profileName must start at P_INIT." }
    if (@($profile.budget_matrix).Count -ne $domains.Count) { throw "$profileName budget matrix length mismatch." }
    for ($i = 0; $i -lt $domains.Count; $i++) {
        $budget = @($profile.budget_matrix[$i])
        if ($budget.Count -ne 3) { throw "$profileName/$($domains[$i]) budget tuple invalid." }
        if ([int]$budget[2] -lt [int]$budget[0]) { throw "$profileName/$($domains[$i]) lifetime below window." }
    }
}

$preflight = $config.profiles.PROTECTED_PREFLIGHT_V2.budget_matrix
foreach ($domain in @('prepare', 'apply', 'acceptance', 'rollback', 'finalize', 'closeout')) {
    $budget = @($preflight[$domainIndex[$domain]])
    if ([int]$budget[2] -ne 0) { throw "Protected preflight must prohibit $domain." }
}

$transaction = $config.profiles.PROTECTED_TRANSACTION_V2
$applyBudget = @($transaction.budget_matrix[$domainIndex['apply']])
$finalizeBudget = @($transaction.budget_matrix[$domainIndex['finalize']])
if ([int]$applyBudget[0] -ne 1) { throw 'Apply window is frozen at 1.' }
if ([int]$finalizeBudget[0] -ne 1) { throw 'Finalize window is frozen at 1.' }
if (-not [bool]$transaction.transaction_invariants.failed_or_unverified_rollback_hard_stop) { throw 'Rollback hard stop is required.' }

& (Join-Path $root 'scripts/repo-health/Build-RepoHealthHarnessReference.ps1') -Check
'HARNESS_CONTRACT=PASS'
