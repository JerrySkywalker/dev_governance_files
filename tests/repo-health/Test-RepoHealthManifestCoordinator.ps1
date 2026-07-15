[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/RepoHealthManifestCoordinator.psm1') -Force

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

$root = 'V:\src\dev_governance_files'
$runId = 'synthetic-run-20260716'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('repo-health-manifest-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $manifestPath = 'V:\src\goals\repo-health\w1-w6-20260716-042454\run-manifest.json'
    $manifestResult = Test-RepoHealthRunManifest -ManifestPath $manifestPath
    Assert-True $manifestResult.valid 'manifest hashes and execution policy'
    Assert-True (Test-RepoHealthRoutingContract -RoutingPath 'C:\Users\jerry\.codex\profile-routing.meta.json').valid 'routing role permissions'
    Assert-True (Test-RepoHealthPriorReceipt -ReceiptPath 'V:\src\integration-inventory\repo-health\w1-s01-completion-checkpoint.json').valid 'prior receipt gate'

    $newRepositoryDeadline = Get-RepoHealthNewRepositoryDeadline -ManifestPath $manifestPath
    Assert-True ($newRepositoryDeadline -eq '2026-07-16T06:24:55.0164783+00:00') 'bootstrap new repository deadline'
    $state = New-RepoHealthManifestState -RunId $runId -Manifest $manifestResult.manifest -AdmittedGovernanceHead ('a' * 40) -NewRepositoryDeadlineUtc $newRepositoryDeadline
    Assert-True ((Test-RepoHealthManifestDeadline -State $state -Now ([datetimeoffset]::Parse('2026-07-16T05:30:00Z'))).start_allowed) 'deadline start allowed'
    Assert-True (-not (Test-RepoHealthManifestDeadline -State $state -Now ([datetimeoffset]::Parse('2026-07-16T06:10:00Z'))).start_allowed) 'deadline start rejected'
    $waiver = Get-RepoHealthGithubActionsClassification -WorkflowResult QUOTA_EXHAUSTED -ExecutedStepCount 0 -QuotaProven $true -LocalExactHeadEquivalent $true -ExactMainRetest $true -SecretPackageChecks $true -SupervisorApproved $true
    Assert-True ($waiver.classification -eq 'WAIVED_EXTERNAL_QUOTA_EXHAUSTED' -and -not $waiver.github_ci_pass_claimed) 'quota zero step waiver'
    $notWaived = Get-RepoHealthGithubActionsClassification -WorkflowResult QUOTA_EXHAUSTED -ExecutedStepCount 1 -QuotaProven $true -LocalExactHeadEquivalent $true -ExactMainRetest $true -SecretPackageChecks $true -SupervisorApproved $true
    Assert-True ($notWaived.classification -eq 'GITHUB_CI_NOT_WAIVED') 'quota actual test failure rejection'
    Save-RepoHealthManifestState -State $state -InventoryRoot $testRoot | Out-Null
    Assert-True ((Read-RepoHealthManifestState -RunId $runId -InventoryRoot $testRoot).run_id -eq $runId) 'manifest durable resume'
    Assert-True ($state.pending_steps[0] -eq 'W1-S02' -and $state.completed_steps[0] -eq 'W1-S01') 'manifest deterministic ordering'
    Assert-Fails { Invoke-RepoHealthManifestStep -RunId $runId -Wave W1 -Step W1-S03 -Repository synthetic -RepositoryPath $root -GoalPath $manifestPath -InventoryRoot $testRoot } 'manifest dependency order rejection'
    Request-RepoHealthManifestStop -State $state | Out-Null
    Assert-True ([bool]$state.stop_requested -and [string]$state.run_status -eq 'SAFE_PAUSE_REQUESTED') 'safe stop request'

    $architect = New-RepoHealthProcessEnvelope -Role Architect -RunId $runId -Wave W0 -Step PLAN -Scope governance -AdmittedHead ('b' * 40) -Outcome PASS -SanitizedSummary 'architect_plan_ready'
    Assert-True (Test-RepoHealthProcessEnvelope -Envelope $architect).valid 'architect envelope'
    $supervisor = New-RepoHealthProcessEnvelope -Role Supervisor -RunId $runId -Wave W0 -Step AUDIT -Scope governance -AdmittedHead ('c' * 40) -Outcome PASS -SanitizedSummary 'supervisor_audit_ready'
    Assert-True (Test-RepoHealthProcessEnvelope -Envelope $supervisor).valid 'supervisor outcome envelope'
    $supervisor.git_mutation = $true
    Assert-True (-not (Test-RepoHealthProcessEnvelope -Envelope $supervisor).valid) 'supervisor mutation rejection'
    Assert-Fails { Assert-RepoHealthLaunchRequest -Role Architect -Profile jerry-implementer -WorkingDirectory $root -GoalText 'safe_goal' } 'role profile mismatch rejection'
    Assert-Fails { Assert-RepoHealthLaunchArguments -Arguments @('--yolo') } 'forbidden override rejection'
    Assert-RepoHealthLaunchRequest -Role Architect -Profile jerry-architect -WorkingDirectory $root -GoalText 'safe_goal'
    Assert-Fails { Invoke-RepoHealthManifestStep -RunId $runId -Wave W7A -Step W7A-S01 -Repository synthetic -RepositoryPath $root -GoalPath $manifestPath -InventoryRoot $testRoot } 'wave seven rejection'
    Assert-True ((Resolve-RepoHealthCodexHost).file_name.Length -gt 0) 'fresh process host resolution'

    $stateRoot = Join-Path $testRoot 'state'
    $lease = Enter-RepoHealthWriterLease -Repository repoone -SessionId writerone -StateRoot $stateRoot
    try {
        Assert-Fails { Enter-RepoHealthWriterLease -Repository repotwo -SessionId writertwo -StateRoot $stateRoot } 'global writer lease exclusion'
    }
    finally { Exit-RepoHealthWriterLease -Lease $lease }

    $logPath = Join-Path $testRoot 'bounded-log.json'
    Write-RepoHealthProcessLog -Path $logPath -Role Architect -ExitCode 0 -StdOutCharacters 10 -StdErrCharacters 0 -Outcome PASS -Profile jerry-architect -ChildProcessId 123
    $log = Get-Content -LiteralPath $logPath -Raw | ConvertFrom-Json
    Assert-True ($log.secrets_visible -eq $false -and $log.private_connection_metadata_count -eq 0 -and $log.launch_profile -eq 'jerry-architect') 'bounded safe log'

    $dry = & (Join-Path $root 'tools/repo-health/Invoke-RepoHealthManifestCoordinator.ps1') -Mode DryRun -RunId $runId -ManifestPath $manifestPath
    Assert-True (-not (($dry | ConvertFrom-Json).product_writing_session_started)) 'manifest dry run write guard'

    foreach ($file in Get-ChildItem -Path (Join-Path $root 'tools/repo-health'),(Join-Path $root 'tests/repo-health') -Recurse -File | Where-Object { $_.Extension -in @('.ps1','.psm1') }) {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors) | Out-Null
        Assert-True ($errors.Count -eq 0) ('PowerShell AST ' + $file.Name)
    }
}
finally {
    $resolved = (Resolve-Path -LiteralPath $testRoot).Path
    if (-not $resolved.StartsWith([System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()), [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Synthetic fixture cleanup escaped temp root.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}

Write-Output ('PASS repo-health manifest tests=' + $passed)
