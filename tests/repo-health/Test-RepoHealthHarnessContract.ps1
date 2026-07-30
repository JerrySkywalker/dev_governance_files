[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$configPath = Join-Path $root 'config/repo-health-harness-v1.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

Assert ($config.model_id -eq 'JERRY_HARNESS_MODEL_V1') 'Unexpected model ID.'
Assert ($config.baseline_id -eq 'JERRY_AUTONOMY_CI_PARAMS_V1') 'Unexpected baseline ID.'
Assert ($config.parameter_family_count -eq 16) 'Parameter family count must be 16.'
Assert ($config.parameter_families.Count -eq 16) 'Parameter family registry must contain 16 entries.'
Assert ($config.profiles.PSObject.Properties.Count -eq 6) 'Profile count must be 6.'
Assert ($config.axes.P -contains 'P_INIT') 'P_INIT is required.'
Assert ($config.axes.L.Count -eq 6) 'L0-L5 must all exist.'
Assert ($config.global_invariants.same_head_same_signature_rerun_lifetime -eq 1) 'Frozen rerun limit changed.'
Assert ($config.global_invariants.duplicate_canonical_full_gate_count -eq 0) 'Duplicate full Gate must remain zero.'
Assert ($config.global_invariants.authority_never_expands_automatically) 'Automatic authority expansion must be disabled.'
Assert ($config.global_invariants.budget_domains_never_borrow) 'Budget borrowing must be disabled.'

$domains = @($config.budget_domains)
$domainIndex = @{}
for ($i = 0; $i -lt $domains.Count; $i++) { $domainIndex[$domains[$i]] = $i }

foreach ($profileProperty in $config.profiles.PSObject.Properties) {
    $profile = $profileProperty.Value
    Assert ($profile.initial_progress_state -eq 'P_INIT') "$($profileProperty.Name) must start at P_INIT."
    Assert ($profile.budget_matrix.Count -eq $domains.Count) "$($profileProperty.Name) budget matrix length mismatch."
    for ($i = 0; $i -lt $domains.Count; $i++) {
        $budget = @($profile.budget_matrix[$i])
        Assert ($budget.Count -eq 3) "$($profileProperty.Name)/$($domains[$i]) budget tuple invalid."
        Assert ($budget[2] -ge $budget[0]) "$($profileProperty.Name)/$($domains[$i]) lifetime below window."
    }
}

$preflight = $config.profiles.PROTECTED_PREFLIGHT_V2.budget_matrix
foreach ($domain in @('prepare', 'apply', 'acceptance', 'rollback', 'finalize', 'closeout')) {
    Assert (@($preflight[$domainIndex[$domain]])[2] -eq 0) "Protected preflight must prohibit $domain."
}

$transaction = $config.profiles.PROTECTED_TRANSACTION_V2
Assert (@($transaction.budget_matrix[$domainIndex['apply']])[0] -eq 1) 'Apply window is frozen at 1.'
Assert (@($transaction.budget_matrix[$domainIndex['finalize']])[0] -eq 1) 'Finalize window is frozen at 1.'
Assert ($transaction.transaction_invariants.failed_or_unverified_rollback_hard_stop) 'Rollback hard stop is required.'

& (Join-Path $root 'scripts/repo-health/Build-RepoHealthHarnessReference.ps1') -Check
'HARNESS_CONTRACT=PASS'
