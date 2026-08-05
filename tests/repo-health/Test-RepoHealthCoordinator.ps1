[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/RepoHealthCoordinator.psm1') -Force

$passed = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}
function Assert-Fails {
    param([scriptblock]$Action, [string]$Message)
    $failed = $false
    try { & $Action } catch { $failed = $true }
    Assert-True -Condition $failed -Message $Message
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('repo-health-synthetic-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $plan = Get-Content -LiteralPath 'V:\src\dev_governance_files\config\repo-health-master-wave-plan.json' -Raw | ConvertFrom-Json
    Assert-True ($plan.plan_id -eq 'repo-health-master-wave-plan') 'master-plan parse'
    Assert-True ($plan.waves.Count -eq 15 -and $plan.waves[0].steps.Count -eq 4 -and $plan.deferred_wave.wave_id -eq 'P') 'master-plan wave coverage'
    Assert-True ($plan.version -eq '2.0' -and $plan.status -eq 'COMPLETE' -and $plan.effective_amendment_id -eq 'REPO-HEALTH-FINAL-CLOSEOUT-001') 'master-plan terminal closeout amendment'
    Assert-True ($plan.active_branch_policy.version -eq '2.0' -and $plan.active_branch_policy.path -eq 'policy/main-dev-policy-v2.json') 'master-plan active branch policy'
    $closeout = $plan.program_closeout
    Assert-True ($closeout.scope -eq 'REPOSITORY_HEALTH_ONLY' -and $closeout.repository_health_program_status -eq 'COMPLETE' -and $closeout.final_health_closeout_audit -eq 'PASS') 'repository-health terminal closeout facts'
    Assert-True (-not $closeout.canonical_repository_health_debt_remaining -and $closeout.post_w7_repository_convergence -eq 'COMPLETE' -and $closeout.unknown_classification_count -eq 0) 'repository-health debt and classification closeout'
    Assert-True ($closeout.old_w8_w9_execution_status -eq 'SUPERSEDED_UNEXECUTED' -and $closeout.historical_definitions_preserved -and $closeout.product_work_not_claimed_complete) 'historical W8 W9 truth preserved'
    Assert-True ($closeout.post_health_foundation_tracks.Count -eq 3 -and $closeout.post_health_product_tracks.Count -eq 3 -and -not $closeout.post_health_tracks_authorized_by_this_goal) 'post-health tracks registered without authorization'
    Assert-True ($closeout.active_repository_health_blockers.Count -eq 0 -and $closeout.resolution_ledger.Count -eq 4) 'obsolete active blockers have finite effective dispositions'
    $amendment = @($plan.amendments | Where-Object { $_.amendment_id -eq 'W7V-R03-PHASE-A-CLOSEOUT-AND-COMPRESSED-WAVE7-TRAIN' })[0]
    Assert-True ($amendment.phase_a_complete -and $amendment.g1_complete -and $amendment.dashboard_exact_main -eq '88b9b8e41b992887f832c5c31e230f373700ab5c') 'Wave 7 Phase A closeout'
    Assert-True ($amendment.phase_b_status -eq 'DEFERRED_BY_OWNER' -and $amendment.phase_c_status -eq 'DEFERRED_BY_OWNER' -and -not $amendment.m_pre_w7b_dashboard_hardening_complete) 'Dashboard Phase B and C deferral'
    $wave7b = @($plan.waves | Where-Object { $_.wave_id -eq 'W7B' })[0]
    Assert-True (($wave7b.entry_gates -join '|') -eq 'W7V_OVERALL_STATUS=COMPLETE|M_DASH_AUTH_AUTOMATION_READY=true|W7B_OWNER_AUTHORIZATION=true|W7B_STARTED=false') 'Wave 7B exact admission gates'
    Assert-True (-not $wave7b.w7b_owner_authorization -and -not $wave7b.w7b_started -and -not $wave7b.execution_started) 'Wave 7B remains not started'
    $runBundle = @($plan.run_bundles | Where-Object { $_.run_id -eq 'W7-COMPRESSED-001' })[0]
    Assert-True (($runBundle.waves -join '|') -eq 'W7B|W7C|W7D|W7E' -and $runBundle.default_product_outcome -eq 'NO_PRODUCT_DELTA_REQUIRED') 'compressed Wave 7 run bundle'
    Assert-True ($runBundle.stop_after_wave -eq 'W7E' -and $runBundle.retrospective_required_before_w8_or_w9 -and -not $runBundle.w8_authorized -and -not $runBundle.w9_authorized) 'compressed Wave 7 stop boundary'
    $postW7 = $plan.post_w7_canary_parity
    Assert-True ($postW7.run_id -eq 'POST-W7-CANARY-PARITY-001' -and $postW7.position.after_wave -eq 'W7E' -and $postW7.position.before_wave -eq 'W8') 'post-W7 Canary parity position'
    Assert-True ($postW7.wave7_historical_status -eq 'COMPLETE' -and $postW7.w7_acceptance_history_immutable -and $postW7.owner_intent_conformance_gap -eq 'DISCOVERED_POST_ACCEPTANCE') 'post-W7 immutable historical closure'
    Assert-True ($postW7.w8_entry_gate -eq 'BLOCKED_BY_DASHBOARD_UI_HARDENING' -and -not $postW7.w9_started -and -not $postW7.w8_started) 'post-W7 Wave 8 and Wave 9 gate'
    $uiHardening = $plan.post_w7_dashboard_ui_hardening
    Assert-True ($uiHardening.run_id -eq 'POST-W7-DASHBOARD-UI-HARDENING-001' -and $uiHardening.current_parity_technical_status -eq 'PASS' -and $uiHardening.current_parity_owner_ux_decision -eq 'REJECTED') 'post-W7 dashboard UI hardening identity'
    Assert-True ($uiHardening.ui_hardening_required -and -not $uiHardening.production_mutation -and $uiHardening.w8_entry_gate -eq 'BLOCKED_BY_DASHBOARD_UI_HARDENING') 'post-W7 dashboard UI hardening boundary'
    Assert-True ($uiHardening.phase_b_status -eq 'AUTHORIZED' -and $uiHardening.phase_c1_status -eq 'AUTHORIZED_CANARY_PREVIEW_ONLY' -and $uiHardening.phase_c2_status -eq 'NOT_AUTHORIZED_PRODUCTION') 'post-W7 deferred phases are narrowly activated'
    $wave1 = @($plan.waves | Where-Object { $_.wave_id -eq 'W1' })[0]
    $wave2 = @($plan.waves | Where-Object { $_.wave_id -eq 'W2' })[0]
    Assert-True ($wave1.status -eq 'COMPLETED' -and $wave1.milestone_status -eq 'ACHIEVED' -and $wave2.status -eq 'PLANNED' -and $wave2.not_started) 'Wave 1 completion does not start Wave 2'

    $policyV2 = Get-Content -LiteralPath 'V:\src\dev_governance_files\policy\main-dev-policy-v2.json' -Raw | ConvertFrom-Json
    Assert-True ($policyV2.schema -eq 'repo-health-main-dev-policy.v2' -and $policyV2.status -eq 'ACTIVE' -and $policyV2.supersedes.path -eq 'config/branch-lifecycle-policy.json') 'main-dev policy v2 amendment parse'
    Assert-True ($policyV2.admission.status_values -contains 'UNKNOWN_DIRT' -and $policyV2.admission.status_values -contains 'SNAPSHOT_REQUIRED') 'main-dev policy admission states'

    $registry = Get-Content -LiteralPath 'V:\src\dev_governance_files\config\repository-registry.json' -Raw | ConvertFrom-Json
    $registryIds = @($registry.repositories.repository_id)
    Assert-True ($registry.version -eq '1.1' -and $registry.repositories.Count -eq 22 -and (@($registryIds | Select-Object -Unique).Count -eq 22)) 'repository-registry closeout parse'
    Assert-True (-not ($registryIds -contains 'UNKNOWN')) 'registry finite ids'
    Assert-True (@($registry.repositories | Where-Object { $_.roster_membership -eq 'CANONICAL_REGISTRY' }).Count -eq 17) 'registry canonical membership count'
    Assert-True (@($registry.repositories | Where-Object { $_.roster_membership -eq 'POST_HEALTH_TRACK_ADMITTED' }).Count -eq 5) 'registry post-health membership count'
    $allowedCloseoutStates = @('HEALTH_PROGRAM_COMPLETE','POST_HEALTH_FOUNDATION_TRACK','POST_HEALTH_PRODUCT_TRACK','HISTORICAL_ONLY','EXTERNAL_NOT_OWNED')
    Assert-True (@($registry.repositories | Where-Object { $_.current_state -notin $allowedCloseoutStates }).Count -eq 0) 'registry closeout classifications are finite'
    Assert-True (@($registry.repositories | Where-Object { [string]$_.default_branch_sha -notmatch '^[0-9a-f]{40}$' }).Count -eq 0) 'registry exact default branch SHAs'
    $classificationTotal = 0
    foreach ($value in $registry.closeout_binding.classification_counts.PSObject.Properties.Value) { $classificationTotal += [int]$value }
    Assert-True ($classificationTotal -eq 22 -and $registry.closeout_binding.unknown_classification_count -eq 0 -and $registry.closeout_binding.unclassified_unique_branch_count -eq 0) 'registry classification coverage'
    Assert-True ($registry.retained_work_ledger.held_evidence_ref_count -eq 1 -and $registry.retained_work_ledger.active_pr_head_count -eq 4 -and $registry.retained_work_ledger.unknown_count -eq 0) 'registry retained work ledger'

    $graph = Get-Content -LiteralPath 'V:\src\dev_governance_files\config\dependency-graph.json' -Raw | ConvertFrom-Json
    foreach ($edge in $graph.edges) {
        Assert-True ($graph.nodes -contains $edge.from -and $graph.nodes -contains $edge.to) 'dependency-graph node reference'
        Assert-True ($edge.status -in @('EVIDENCED','TOPOLOGY_REVIEW_REQUIRED')) 'dependency-graph finite edge status'
    }

    foreach ($schema in Get-ChildItem -LiteralPath 'V:\src\dev_governance_files\tools\repo-health\schemas' -Filter '*.json') {
        $schemaText = Get-Content -LiteralPath $schema.FullName -Raw
        if ($null -ne (Get-Command Test-Json -ErrorAction SilentlyContinue)) {
            Assert-True (Test-Json -Json $schemaText) ('schema parse ' + $schema.Name)
        }
        else {
            ConvertFrom-Json -InputObject $schemaText | Out-Null
            Assert-True $true ('schema parse ' + $schema.Name)
        }
    }

    $syntheticRepo = Join-Path $testRoot 'synthetic-repo'
    New-Item -ItemType Directory -Path $syntheticRepo -Force | Out-Null
    git init -q $syntheticRepo
    git -C $syntheticRepo config user.email 'repo-health-test@example.invalid'
    git -C $syntheticRepo config user.name 'repo-health-test'
    Set-Content -LiteralPath (Join-Path $syntheticRepo 'fixture.txt') -Value 'fixture'
    git -C $syntheticRepo add -- fixture.txt
    git -C $syntheticRepo commit -q -m fixture
    git -C $syntheticRepo branch dev
    $cleanWorktree = Join-Path $testRoot 'clean-worktree'
    git -C $syntheticRepo worktree add -q -b fixture-clean $cleanWorktree
    $cleanStatus = @(git -C $cleanWorktree status --porcelain)
    Assert-True ($cleanStatus.Count -eq 0) 'clean synthetic worktree'
    $dirtyWorktree = Join-Path $testRoot 'dirty-worktree'
    git -C $syntheticRepo worktree add -q -b fixture-dirty $dirtyWorktree
    Set-Content -LiteralPath (Join-Path $dirtyWorktree 'dirty.txt') -Value 'dirty'
    $dirtyStatus = @(git -C $dirtyWorktree status --porcelain)
    Assert-True ($dirtyStatus.Count -gt 0) 'dirty synthetic worktree'

    $admissionRoot = Join-Path $testRoot 'admission'
    New-Item -ItemType Directory -Path $admissionRoot -Force | Out-Null
    @('Branch Model','Branch Target Rules','Short-Lived Branch Lifecycle','Single-Writer Rule','Agent Allocation','Blocker Handling','Repository-Specific Preservation Rules') | Set-Content -LiteralPath (Join-Path $admissionRoot 'AGENTS.md')
    $cleanEvidence = [pscustomobject]@{tracked_clean=$true;approved_preserved_evidence_count=0;unknown_dirt_count=0;preservation_ledger_verified=$false;preserved_evidence_boundary_verified=$false;reviewer_must_not_access_original_worktree_evidence=$false;snapshot_required=$false;tracked_snapshot_isolated=$false;snapshot_source_sha_bound=$false;snapshot_tree_digest_verified=$false}
    $admission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0}) -EvidenceInventory $cleanEvidence
    Assert-True ($admission.admitted -and $admission.evidence_states -contains 'TRACKED_CLEAN') 'AGENTS branch and tracked-clean admission'
    $approvedEvidence = [pscustomobject]@{tracked_clean=$true;approved_preserved_evidence_count=1;unknown_dirt_count=0;preservation_ledger_verified=$true;preserved_evidence_boundary_verified=$true;reviewer_must_not_access_original_worktree_evidence=$false;snapshot_required=$false;tracked_snapshot_isolated=$false;snapshot_source_sha_bound=$false;snapshot_tree_digest_verified=$false}
    $approvedAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0}) -EvidenceInventory $approvedEvidence
    Assert-True ($approvedAdmission.admitted -and $approvedAdmission.evidence_states -contains 'APPROVED_PRESERVED_EVIDENCE') 'approved preserved evidence is distinct from dirt'
    $unknownEvidence = [pscustomobject]@{tracked_clean=$true;approved_preserved_evidence_count=0;unknown_dirt_count=1;preservation_ledger_verified=$false;preserved_evidence_boundary_verified=$false;reviewer_must_not_access_original_worktree_evidence=$false;snapshot_required=$false;tracked_snapshot_isolated=$false;snapshot_source_sha_bound=$false;snapshot_tree_digest_verified=$false}
    $unknownAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0}) -EvidenceInventory $unknownEvidence
    Assert-True (-not $unknownAdmission.admitted -and $unknownAdmission.evidence_states -contains 'UNKNOWN_DIRT' -and $unknownAdmission.reasons -contains 'unknown_dirt_present') 'unknown dirt blocks admission'
    $unisolatedSnapshotEvidence = [pscustomobject]@{tracked_clean=$true;approved_preserved_evidence_count=1;unknown_dirt_count=0;preservation_ledger_verified=$true;preserved_evidence_boundary_verified=$true;reviewer_must_not_access_original_worktree_evidence=$true;snapshot_required=$false;tracked_snapshot_isolated=$false;snapshot_source_sha_bound=$false;snapshot_tree_digest_verified=$false}
    $unisolatedSnapshotAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0}) -EvidenceInventory $unisolatedSnapshotEvidence
    Assert-True (-not $unisolatedSnapshotAdmission.admitted -and $unisolatedSnapshotAdmission.evidence_states -contains 'SNAPSHOT_REQUIRED') 'reviewer restriction requires tracked-snapshot isolation'
    $isolatedSnapshotEvidence = [pscustomobject]@{tracked_clean=$true;approved_preserved_evidence_count=1;unknown_dirt_count=0;preservation_ledger_verified=$true;preserved_evidence_boundary_verified=$true;reviewer_must_not_access_original_worktree_evidence=$true;snapshot_required=$true;tracked_snapshot_isolated=$true;snapshot_source_sha_bound=$true;snapshot_tree_digest_verified=$true}
    $isolatedSnapshotAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0}) -EvidenceInventory $isolatedSnapshotEvidence
    Assert-True ($isolatedSnapshotAdmission.admitted -and $isolatedSnapshotAdmission.evidence_states -contains 'SNAPSHOT_REQUIRED') 'bound tracked snapshot satisfies reviewer restriction'
    $badAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='red';unclassified_non_main_dev=1}) -EvidenceInventory $cleanEvidence
    Assert-True (-not $badAdmission.admitted) 'branch convergence admission rejection'

    $stateRoot = Join-Path $testRoot 'state'
    $state = New-RepoHealthState -Repository synthetic
    Save-RepoHealthState -State $state -StateRoot $stateRoot | Out-Null
    $readState = Read-RepoHealthState -Repository synthetic -StateRoot $stateRoot
    Assert-True ($readState.repository -eq 'synthetic') 'durable state resume'
    $reportOne = New-RepoHealthSafeReport -State $readState | ConvertTo-Json -Compress
    $reportTwo = New-RepoHealthSafeReport -State $readState | ConvertTo-Json -Compress
    Assert-True ($reportOne -ceq $reportTwo) 'idempotent Status'
    $statePath = Get-RepoHealthStatePath -Repository synthetic -StateRoot $stateRoot
    $oldBytes = [System.IO.File]::ReadAllBytes($statePath)
    $stray = Join-Path $stateRoot '.synthetic.state.json.next.fixture'
    [System.IO.File]::WriteAllText($stray, 'interrupted')
    Assert-True ((Read-RepoHealthState -Repository synthetic -StateRoot $stateRoot).repository -eq 'synthetic') 'crash recovery ignores interrupted replacement'
    Write-RepoHealthJsonAtomic -Path $statePath -Value $readState | Out-Null
    Assert-True ((Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).schema -eq 'repo-health-coordinator-state.v1') 'atomic state replacement'
    Assert-True ($oldBytes.Length -gt 0) 'atomic state old snapshot'

    $lock1 = Enter-RepoHealthLock -Repository synthetic -SessionId writer1 -StateRoot $stateRoot
    try {
        Assert-Fails { Enter-RepoHealthLock -Repository synthetic -SessionId writer2 -StateRoot $stateRoot } 'repository-lock exclusivity'
    }
    finally { Exit-RepoHealthLock -Lock $lock1 }

    $writerState = New-RepoHealthState -Repository synthetic
    Assert-RepoHealthWriterAdmission -State $writerState -SessionId writer1 -Role Implementer | Out-Null
    Assert-Fails { Assert-RepoHealthWriterAdmission -State $writerState -SessionId writer2 -Role Implementer } 'one-writer enforcement'
    Assert-Fails { Assert-RepoHealthWriterAdmission -State $writerState -SessionId supervisor1 -Role Supervisor -ProductRepositoryWrite $true } 'supervisor-read-only enforcement'

    $envelope = [pscustomobject]@{schema='repo-health-result-envelope.v1';role='Supervisor';repository='synthetic';outcome='PASS';product_repository_write=$false;git_mutation=$false;sanitized_summary='read-only audit passed'}
    Assert-True (Test-RepoHealthResultEnvelope -Envelope $envelope).valid 'sanitized supervisor envelope'
    Assert-True (-not (Test-RepoHealthSafeSummary -Value ('to' + 'ken=value'))) 'safe output contract'

    $blocker = [pscustomobject]@{repository_or_scope='synthetic';phase='VERIFY_LOCAL';finite_classification='TEST_FAILURE';failing_contract='LOCAL_TEST';normalized_exit_code=1;source_head_sha_when_applicable='';safe_path_digest_when_applicable=''}
    $round1 = Register-RepoHealthBlocker -State (New-RepoHealthState -Repository synthetic) -Blocker $blocker
    $round2 = Register-RepoHealthBlocker -State $round1.state -Blocker $blocker
    $round3 = Register-RepoHealthBlocker -State $round2.state -Blocker $blocker
    Assert-True ($round1.next_action -eq 'ARCHITECT_FIRST_ANALYSIS' -and $round2.next_action -eq 'ARCHITECT_PLUS_ADVERSARIAL_AUDIT' -and $round3.next_action -eq 'HUMAN_REQUIRED') 'same-blocker three-strike escalation'
    $risk = $blocker.psobject.Copy()
    $risk.finite_classification = 'REAL_SECRET'
    Assert-True ((Register-RepoHealthBlocker -State (New-RepoHealthState -Repository synthetic) -Blocker $risk).state.current_state -eq 'HUMAN_REQUIRED') 'immediate-risk escalation'

    $queue = Get-RepoHealthGoalQueue -Items @(
        [pscustomobject]@{milestone_order=2;wave_step='W2-S01';repository='zeta';role='Supervisor'},
        [pscustomobject]@{milestone_order=1;wave_step='W1-S01';repository='beta';role='Implementer'},
        [pscustomobject]@{milestone_order=1;wave_step='W1-S01';repository='alpha';role='Implementer'})
    Assert-True ($queue[0].repository -eq 'alpha' -and $queue[2].repository -eq 'zeta') 'Goal queue ordering'
    Assert-True (-not (Test-RepoHealthMilestoneDependencies -Milestone M2 -Dependencies @('M1') -CompletedMilestones @()).ready) 'milestone dependency blocking'
    Assert-True ((Test-RepoHealthMilestoneDependencies -Milestone M2 -Dependencies @('M1') -CompletedMilestones @('M1')).ready) 'milestone dependency pass'
    Assert-True ((Test-RepoHealthMilestoneDependencies -Milestone M0).ready) 'milestone no-dependency pass'

    $launch = Get-RepoHealthLaunchCapability
    Assert-True (-not $launch.automatic_session_launch_supported -and $launch.mode -eq 'queue-file-manual-attach') 'manual attach adapter fallback'
    $dry = & 'V:\src\dev_governance_files\tools\repo-health\Invoke-RepoHealthCoordinator.ps1' -Mode DryRun -Repository synthetic
    Assert-True (($dry | ConvertFrom-Json).product_writing_session_started -eq $false) 'DryRun product write guard'

    $manifestCoordinatorSource = Get-Content -LiteralPath 'V:\src\dev_governance_files\tools\repo-health\RepoHealthManifestCoordinator.psm1' -Raw
    Assert-True ($manifestCoordinatorSource -notmatch 'TimeoutSeconds' -and $manifestCoordinatorSource -notmatch '\.Kill\(') 'native role lifecycle has no automatic hard timeout or kill path'

    $coordinatorFiles = Get-ChildItem -Path 'V:\src\dev_governance_files\tools\repo-health','V:\src\dev_governance_files\tests\repo-health' -Recurse -File | Where-Object { $_.Extension -in @('.ps1','.psm1') }
    foreach ($file in $coordinatorFiles) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
        Assert-True ($errors.Count -eq 0) ('PowerShell AST ' + $file.Name)
    }
}
finally {
    $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
    if (-not $resolvedTestRoot.StartsWith([System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()), [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Synthetic fixture cleanup escaped temp root.' }
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
}

Write-Output ('PASS repo-health synthetic tests=' + $passed)
