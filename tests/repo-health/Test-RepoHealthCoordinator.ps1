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
    Assert-True ($plan.waves.Count -eq 14 -and $plan.waves[0].steps.Count -eq 4 -and $plan.deferred_wave.wave_id -eq 'P') 'master-plan wave coverage'

    $registry = Get-Content -LiteralPath 'V:\src\dev_governance_files\config\repository-registry.json' -Raw | ConvertFrom-Json
    $registryIds = @($registry.repositories.repository_id)
    Assert-True ($registry.repositories.Count -eq 17 -and (@($registryIds | Select-Object -Unique).Count -eq 17)) 'repository-registry parse'
    Assert-True (-not ($registryIds -contains 'UNKNOWN')) 'registry finite ids'

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
    $admission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='absent';unclassified_non_main_dev=0})
    Assert-True $admission.admitted 'AGENTS and branch admission'
    $badAdmission = Test-RepoHealthAdmission -RepositoryRoot $admissionRoot -BranchInventory ([pscustomobject]@{main='healthy';dev='red';unclassified_non_main_dev=1})
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
