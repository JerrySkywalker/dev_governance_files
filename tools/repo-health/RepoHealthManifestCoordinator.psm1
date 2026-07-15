Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'RepoHealthCoordinator.psm1') -Force

$script:RepoHealthRoleProfiles = [ordered]@{
    Architect = 'jerry-architect'
    Implementer = 'jerry-implementer'
    Supervisor = 'jerry-supervisor'
    Auditor = 'jerry-auditor'
    Mechanical = 'jerry-mechanical'
}

function Get-RepoHealthManifestPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
        [string]$LogRoot = 'V:\src\codex-run-logs\repo-health'
    )

    Assert-RepoHealthSafeIdentifier -Value $RunId -Field 'run_id'
    [pscustomobject]@{
        RunRoot = Join-Path (Join-Path $InventoryRoot 'runs') $RunId
        StatePath = Join-Path (Join-Path (Join-Path $InventoryRoot 'runs') $RunId) 'manifest-state.json'
        EnvelopeRoot = Join-Path (Join-Path (Join-Path $InventoryRoot 'runs') $RunId) 'envelopes'
        LogRoot = Join-Path $LogRoot $RunId
    }
}

function Get-RepoHealthRoleProfile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role)
    return $script:RepoHealthRoleProfiles[$Role]
}

function Test-RepoHealthRoutingContract {
    [CmdletBinding()]
    param([string]$RoutingPath = (Join-Path $HOME '.codex\profile-routing.meta.json'))

    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $RoutingPath)) {
        $reasons.Add('routing_metadata_missing')
        return [pscustomobject]@{ valid = $false; reasons = @($reasons) }
    }
    $routing = Get-Content -LiteralPath $RoutingPath -Raw | ConvertFrom-Json
    if ([string]$routing.routing_version -ne 'codex-routing-v2') { $reasons.Add('routing_version') }
    foreach ($role in $script:RepoHealthRoleProfiles.Keys) {
        $key = $role.ToLowerInvariant()
        $entry = $routing.roles.$key
        if ($null -eq $entry -or [string]$entry.profile -ne $script:RepoHealthRoleProfiles[$role]) {
            $reasons.Add(('profile_' + $key))
            continue
        }
        $expectedSandbox = if ($role -eq 'Implementer') { 'danger-full-access' } else { 'read-only' }
        if ([string]$entry.sandbox_mode -ne $expectedSandbox -or [string]$entry.approval_policy -ne 'never') {
            $reasons.Add(('permission_' + $key))
        }
    }
    return [pscustomobject]@{ valid = ($reasons.Count -eq 0); reasons = @($reasons) }
}

function Test-RepoHealthRunManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ManifestPath)

    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        return [pscustomobject]@{ valid = $false; manifest = $null; reasons = @('manifest_missing') }
    }
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    foreach ($property in @('run_id','deadline_utc','goal_files','execution_mode','execution_surface','detached_runner_enabled','interactive_resume_required','single_product_writer','wave7_authorized')) {
        if ($null -eq $manifest.PSObject.Properties[$property]) { $reasons.Add(('missing_' + $property)) }
    }
    if ($reasons.Count -eq 0) {
        if ([string]$manifest.execution_mode -ne 'process-isolated') { $reasons.Add('execution_mode') }
        if ([string]$manifest.execution_surface -ne 'interactive-tui') { $reasons.Add('execution_surface') }
        if ([bool]$manifest.detached_runner_enabled -or -not [bool]$manifest.interactive_resume_required) { $reasons.Add('interactive_tui_contract') }
        if (-not [bool]$manifest.single_product_writer) { $reasons.Add('single_product_writer') }
        if ([bool]$manifest.wave7_authorized) { $reasons.Add('wave7_not_disabled') }
        $goals = @($manifest.goal_files | Where-Object { $_.name -ne '99-run-index.md' })
        if ($goals.Count -ne 7) { $reasons.Add('goal_count') }
        foreach ($goal in $goals) {
            if (-not (Test-Path -LiteralPath $goal.path)) { $reasons.Add(('goal_missing_' + $goal.name)); continue }
            $hash = (Get-FileHash -LiteralPath $goal.path -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($hash -ne [string]$goal.sha256) { $reasons.Add(('goal_hash_' + $goal.name)) }
        }
    }
    return [pscustomobject]@{ valid = ($reasons.Count -eq 0); manifest = $manifest; reasons = @($reasons) }
}

function Get-RepoHealthNewRepositoryDeadline {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ManifestPath)
    $goalPath = Join-Path (Split-Path -Parent $ManifestPath) '00-bootstrap-generic-coordinator.md'
    if (-not (Test-Path -LiteralPath $goalPath)) { throw 'Bootstrap goal is missing.' }
    $goal = Get-Content -LiteralPath $goalPath -Raw
    $match = [regex]::Match($goal, 'Do not start a new repository after:\s*`([^`]+)`')
    if (-not $match.Success) { throw 'Bootstrap new-repository deadline is missing.' }
    return ([datetimeoffset]::Parse($match.Groups[1].Value)).ToString('o')
}

function Test-RepoHealthPriorReceipt {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ReceiptPath)

    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $ReceiptPath)) {
        return [pscustomobject]@{ valid = $false; reasons = @('prior_receipt_missing') }
    }
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json
    if ([string]$receipt.checkpoint -ne 'W1_S01_COMPLETE') { $reasons.Add('w1_s01_not_complete') }
    if ([bool]$receipt.w1s02_started) { $reasons.Add('w1_s02_already_started') }
    if ($null -eq $receipt.contract -or -not [bool]$receipt.contract.repo_healthy) { $reasons.Add('prior_receipt_unhealthy') }
    return [pscustomobject]@{ valid = ($reasons.Count -eq 0); reasons = @($reasons) }
}

function New-RepoHealthManifestState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][string]$AdmittedGovernanceHead,
        [string]$NewRepositoryDeadlineUtc = ''
    )

    Assert-RepoHealthSafeIdentifier -Value $RunId -Field 'run_id'
    if ($AdmittedGovernanceHead -notmatch '^[0-9a-f]{40}$') { throw 'admitted_governance_head must be a SHA-1.' }
    [pscustomobject]@{
        schema = 'repo-health-manifest-state.v1'
        run_id = $RunId
        current_wave = 'W0'
        current_step = 'COORDINATOR_VALIDATION'
        current_repository = 'dev_governance_files'
        admitted_governance_head = $AdmittedGovernanceHead
        run_status = 'PLANNED'
        active_writer = $null
        active_children = @()
        completed_milestones = @('M0_FOUNDATION_READY')
        pending_steps = @('W1-S02','W1-S03','W1-S04','W2','W3','W4','W5','W6')
        completed_steps = @('W1-S01')
        blockers = @()
        stop_requested = $false
        deadline_utc = [string]$Manifest.deadline_utc
        new_repository_deadline_utc = $NewRepositoryDeadlineUtc
        revision = 1
        updated_utc = [DateTime]::UtcNow.ToString('o')
    }
}

function Read-RepoHealthManifestState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RunId, [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health')
    $paths = Get-RepoHealthManifestPaths -RunId $RunId -InventoryRoot $InventoryRoot
    return Read-RepoHealthJson -Path $paths.StatePath
}

function Save-RepoHealthManifestState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$State, [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health')
    if ([string]$State.schema -ne 'repo-health-manifest-state.v1') { throw 'Unsupported manifest state schema.' }
    $paths = Get-RepoHealthManifestPaths -RunId ([string]$State.run_id) -InventoryRoot $InventoryRoot
    $State.revision = [int]$State.revision + 1
    $State.updated_utc = [DateTime]::UtcNow.ToString('o')
    return Write-RepoHealthJsonAtomic -Path $paths.StatePath -Value $State
}

function Test-RepoHealthManifestDeadline {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$State, [datetimeoffset]$Now = [datetimeoffset]::UtcNow)
    $deadline = [datetimeoffset]::Parse([string]$State.deadline_utc)
    if (-not [string]::IsNullOrWhiteSpace([string]$State.new_repository_deadline_utc)) {
        $newRepositoryDeadline = [datetimeoffset]::Parse([string]$State.new_repository_deadline_utc)
        if ($newRepositoryDeadline -lt $deadline) { $deadline = $newRepositoryDeadline }
    }
    $remaining = [math]::Floor(($deadline - $Now).TotalMinutes)
    return [pscustomobject]@{ start_allowed = ($remaining -ge 45 -and -not [bool]$State.stop_requested); remaining_minutes = $remaining; deadline_utc = $deadline.UtcDateTime.ToString('o') }
}

function Get-RepoHealthGithubActionsClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('PASS','FAILURE','QUOTA_EXHAUSTED')][string]$WorkflowResult,
        [Parameter(Mandatory)][int]$ExecutedStepCount,
        [bool]$QuotaProven = $false,
        [bool]$LocalExactHeadEquivalent = $false,
        [bool]$ExactMainRetest = $false,
        [bool]$SecretPackageChecks = $false,
        [bool]$SupervisorApproved = $false
    )
    if ($WorkflowResult -eq 'PASS') {
        return [pscustomobject]@{ classification = 'GITHUB_CI_PASS'; github_ci_pass_claimed = $true; accepted_proof = 'GITHUB_ACTIONS' }
    }
    if ($WorkflowResult -eq 'QUOTA_EXHAUSTED' -and $ExecutedStepCount -eq 0 -and $QuotaProven -and $LocalExactHeadEquivalent -and $ExactMainRetest -and $SecretPackageChecks -and $SupervisorApproved) {
        return [pscustomobject]@{ classification = 'WAIVED_EXTERNAL_QUOTA_EXHAUSTED'; github_ci_pass_claimed = $false; accepted_proof = 'LOCAL_EXACT_HEAD_EQUIVALENCE' }
    }
    return [pscustomobject]@{ classification = 'GITHUB_CI_NOT_WAIVED'; github_ci_pass_claimed = $false; accepted_proof = 'NONE' }
}

function New-RepoHealthProcessEnvelope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Wave,
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$AdmittedHead,
        [Parameter(Mandatory)][string]$Outcome,
        [bool]$ProductRepositoryWrite = $false,
        [bool]$GitMutation = $false,
        [Parameter(Mandatory)][string]$SanitizedSummary,
        [string]$BlockerFingerprint = ''
    )
    [pscustomobject]@{
        schema = 'repo-health-process-envelope.v2'
        run_id = $RunId
        wave = $Wave
        step = $Step
        role = $Role
        scope = $Scope
        admitted_head = $AdmittedHead
        outcome = $Outcome
        product_repository_write = $ProductRepositoryWrite
        git_mutation = $GitMutation
        sanitized_summary = $SanitizedSummary
        blocker_fingerprint = $BlockerFingerprint
        secrets_visible = $false
        private_connection_metadata_count = 0
    }
}

function Test-RepoHealthProcessEnvelope {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Envelope)

    $reasons = New-Object System.Collections.Generic.List[string]
    foreach ($property in @('schema','run_id','wave','step','role','scope','admitted_head','outcome','product_repository_write','git_mutation','sanitized_summary','blocker_fingerprint','secrets_visible','private_connection_metadata_count')) {
        if ($null -eq $Envelope.PSObject.Properties[$property]) { $reasons.Add(('missing_' + $property)) }
    }
    if ($reasons.Count -eq 0) {
        if ([string]$Envelope.schema -ne 'repo-health-process-envelope.v2') { $reasons.Add('schema') }
        foreach ($field in @('run_id','wave','step','role','scope')) { try { Assert-RepoHealthSafeIdentifier -Value ([string]$Envelope.$field) -Field $field } catch { $reasons.Add(('unsafe_' + $field)) } }
        if ([string]$Envelope.admitted_head -notmatch '^[0-9a-f]{40}$') { $reasons.Add('admitted_head') }
        $allowed = switch ([string]$Envelope.role) {
            'Supervisor' { @('PASS','CHANGES_REQUIRED','BLOCKED_EXTERNAL','HUMAN_ESCALATION_REQUIRED') }
            default { @('PASS','HOLD','BLOCKED') }
        }
        if ([string]$Envelope.outcome -notin $allowed) { $reasons.Add('outcome') }
        if (-not (Test-RepoHealthSafeSummary -Value ([string]$Envelope.sanitized_summary))) { $reasons.Add('sanitized_summary') }
        if ([bool]$Envelope.secrets_visible) { $reasons.Add('secrets_visible') }
        if ([int]$Envelope.private_connection_metadata_count -ne 0) { $reasons.Add('private_connection_metadata') }
        if ([string]$Envelope.role -ne 'Implementer' -and ([bool]$Envelope.product_repository_write -or [bool]$Envelope.git_mutation)) { $reasons.Add('readonly_mutation') }
        if ([string]$Envelope.blocker_fingerprint -and [string]$Envelope.blocker_fingerprint -notmatch '^[0-9a-f]{64}$') { $reasons.Add('blocker_fingerprint') }
    }
    return [pscustomobject]@{ valid = ($reasons.Count -eq 0); reasons = @($reasons) }
}

function Assert-RepoHealthLaunchRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [Parameter(Mandatory)][string]$Profile,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$GoalText
    )
    if ($Profile -ne (Get-RepoHealthRoleProfile -Role $Role)) { throw 'Role profile mismatch.' }
    if (-not (Test-Path -LiteralPath $WorkingDirectory)) { throw 'Working directory is missing.' }
    if ([string]::IsNullOrWhiteSpace($GoalText)) { throw 'Exact goal delivery is required.' }
}

function Assert-RepoHealthLaunchArguments {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments)
    foreach ($argument in $Arguments) {
        if ($argument -in @('--yolo','--sandbox','--config','--dangerously-bypass-approvals-and-sandbox','--dangerously-bypass-hook-trust')) {
            throw 'Forbidden process launch override.'
        }
    }
}

function Resolve-RepoHealthCodexHost {
    [CmdletBinding()]
    param()
    $command = Get-Command codex -ErrorAction Stop
    if ($command.CommandType -eq 'Application') {
        return [pscustomobject]@{ file_name = $command.Source; prefix_arguments = @() }
    }
    if ($command.CommandType -eq 'ExternalScript') {
        return [pscustomobject]@{ file_name = (Join-Path $PSHOME 'pwsh.exe'); prefix_arguments = @('-NoProfile','-File',$command.Source) }
    }
    throw 'Codex command is not an external executable or script.'
}

function Enter-RepoHealthWriterLease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$SessionId,
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )
    $global = Enter-RepoHealthLock -Repository 'product-writer' -SessionId $SessionId -StateRoot $StateRoot
    try {
        $repositoryLock = Enter-RepoHealthLock -Repository $Repository -SessionId $SessionId -StateRoot $StateRoot
        return [pscustomobject]@{ Global = $global; Repository = $repositoryLock }
    }
    catch {
        Exit-RepoHealthLock -Lock $global
        throw
    }
}

function Exit-RepoHealthWriterLease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Lease)
    try { Exit-RepoHealthLock -Lock $Lease.Repository } finally { Exit-RepoHealthLock -Lock $Lease.Global }
}

function Write-RepoHealthProcessLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][int]$ExitCode,
        [Parameter(Mandatory)][int]$StdOutCharacters,
        [Parameter(Mandatory)][int]$StdErrCharacters,
        [Parameter(Mandatory)][string]$Outcome,
        [Parameter(Mandatory)][string]$Profile,
        [Parameter(Mandatory)][int]$ChildProcessId
    )
    Write-RepoHealthJsonAtomic -Path $Path -Value ([pscustomobject]@{
        schema = 'repo-health-process-log.v1'; role = $Role; exit_code = $ExitCode
        stdout_characters = $StdOutCharacters; stderr_characters = $StdErrCharacters
        outcome = $Outcome; launch_profile = $Profile; child_process_id = $ChildProcessId
        secrets_visible = $false; private_connection_metadata_count = 0
    }) | Out-Null
}

function Invoke-RepoHealthRoleProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Wave,
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$AdmittedHead,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$GoalText,
        [int]$TimeoutSeconds = 1800,
        [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
        [string]$LogRoot = 'V:\src\codex-run-logs\repo-health'
    )
    $profile = Get-RepoHealthRoleProfile -Role $Role
    Assert-RepoHealthLaunchRequest -Role $Role -Profile $profile -WorkingDirectory $WorkingDirectory -GoalText $GoalText
    $paths = Get-RepoHealthManifestPaths -RunId $RunId -InventoryRoot $InventoryRoot -LogRoot $LogRoot
    [System.IO.Directory]::CreateDirectory($paths.EnvelopeRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($paths.LogRoot) | Out-Null
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $tempResult = Join-Path ([System.IO.Path]::GetTempPath()) ('repo-health-' + $RunId + '-' + $stamp + '.result.json')
    $host = Resolve-RepoHealthCodexHost
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $host.file_name
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $arguments = @($host.prefix_arguments) + @('exec','--profile',$profile,'-C',$WorkingDirectory,'--output-last-message',$tempResult,'-')
    Assert-RepoHealthLaunchArguments -Arguments $arguments
    foreach ($argument in $arguments) { $psi.ArgumentList.Add([string]$argument) }
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.StandardInput.Write($GoalText)
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        $outcome = 'BLOCKED'
        $result = New-RepoHealthProcessEnvelope -Role $Role -RunId $RunId -Wave $Wave -Step $Step -Scope $Scope -AdmittedHead $AdmittedHead -Outcome $outcome -SanitizedSummary 'child_timeout'
    }
    elseif (-not (Test-Path -LiteralPath $tempResult)) {
        $outcome = 'BLOCKED'
        $result = New-RepoHealthProcessEnvelope -Role $Role -RunId $RunId -Wave $Wave -Step $Step -Scope $Scope -AdmittedHead $AdmittedHead -Outcome $outcome -SanitizedSummary 'child_no_result'
    }
    else {
        try { $result = Get-Content -LiteralPath $tempResult -Raw | ConvertFrom-Json } catch { $result = New-RepoHealthProcessEnvelope -Role $Role -RunId $RunId -Wave $Wave -Step $Step -Scope $Scope -AdmittedHead $AdmittedHead -Outcome 'BLOCKED' -SanitizedSummary 'child_invalid_json' }
        $outcome = [string]$result.outcome
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $validation = Test-RepoHealthProcessEnvelope -Envelope $result
    if (-not $validation.valid) { throw ('Invalid process envelope: ' + ($validation.reasons -join ',')) }
    if ([string]$result.role -ne $Role -or [string]$result.run_id -ne $RunId -or [string]$result.wave -ne $Wave -or [string]$result.step -ne $Step -or [string]$result.scope -ne $Scope -or [string]$result.admitted_head -ne $AdmittedHead) {
        throw 'Process envelope is not bound to the launched role and phase identity.'
    }
    $name = ('{0}-{1}-{2}-{3}.json' -f $Wave,$Step,$Role,$stamp)
    $envelopePath = Join-Path $paths.EnvelopeRoot $name
    Write-RepoHealthJsonAtomic -Path $envelopePath -Value $result | Out-Null
    Write-RepoHealthProcessLog -Path (Join-Path $paths.LogRoot ($name + '.log.json')) -Role $Role -ExitCode $process.ExitCode -StdOutCharacters $stdout.Length -StdErrCharacters $stderr.Length -Outcome $outcome -Profile $profile -ChildProcessId $process.Id
    if (Test-Path -LiteralPath $tempResult) { Remove-Item -LiteralPath $tempResult -Force }
    return [pscustomobject]@{ envelope = $result; envelope_path = $envelopePath; exit_code = $process.ExitCode }
}

function Request-RepoHealthManifestStop {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$State)
    $State.stop_requested = $true
    $State.run_status = 'SAFE_PAUSE_REQUESTED'
    return $State
}

function New-RepoHealthPhaseGoal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor')][string]$Role,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Wave,
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$AdmittedHead,
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][string]$ExactGoal,
        [string]$PriorSummary = ''
    )
    $allowedOutcomes = if ($Role -eq 'Supervisor') { 'PASS, CHANGES_REQUIRED, BLOCKED_EXTERNAL, HUMAN_ESCALATION_REQUIRED' } else { 'PASS, HOLD, BLOCKED' }
    $writeInstruction = if ($Role -eq 'Implementer') { 'You are the sole authorized writer only for the declared scope during this phase.' } else { 'You are read-only and must not modify source, Git, PRs, branches, worktrees, or external systems.' }
    $phaseConstraint = if ($Phase -eq 'IMPLEMENT_VERIFY') { 'Do not merge or delete branches in this phase; validate the proposed change and return control for independent review.' } elseif ($Phase -eq 'MERGE_CLEANUP') { 'Merge only after the prior Supervisor PASS, use a normal merge path, and perform only approved cleanup with ownership proof.' } else { 'Follow the declared phase boundary exactly.' }
    $prior = if ([string]::IsNullOrWhiteSpace($PriorSummary)) { 'none' } else { $PriorSummary }
    return @"
You are the $Role phase in an interactive process-isolated repository-health run.
Phase=$Phase; Run=$RunId; Wave=$Wave; Step=$Step; Scope=$Scope; AdmittedHead=$AdmittedHead.
$writeInstruction
$phaseConstraint
Do not access secrets, signing material, browser profiles, physical devices, MFA, production systems, or runner scripts. Do not force-push, use bypass flags, or make an out-of-scope mutation.
Prior safe summary=$prior.

Return exactly one compact JSON object with this shape:
{"schema":"repo-health-process-envelope.v2","run_id":"$RunId","wave":"$Wave","step":"$Step","role":"$Role","scope":"$Scope","admitted_head":"$AdmittedHead","outcome":"one of $allowedOutcomes","product_repository_write":false,"git_mutation":false,"sanitized_summary":"safe_identifier_or_safe_summary","blocker_fingerprint":"","secrets_visible":false,"private_connection_metadata_count":0}
Set product_repository_write and git_mutation to true only when you are the Implementer and actually performed those authorized mutations.

--- EXACT GOAL BEGIN ---
$ExactGoal
--- EXACT GOAL END ---
"@
}

function Invoke-RepoHealthManifestStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Wave,
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$GoalPath,
        [switch]$ProductWrite,
        [int]$MaxCorrections = 1,
        [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
        [string]$LogRoot = 'V:\src\codex-run-logs\repo-health',
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )
    Assert-RepoHealthSafeIdentifier -Value $Repository -Field 'repository'
    if ($Wave -match '^W7') { throw 'Wave 7 is not authorized for this manifest.' }
    if (-not (Test-Path -LiteralPath $RepositoryPath) -or -not (Test-Path -LiteralPath $GoalPath)) { throw 'Repository path or exact goal is missing.' }
    $state = Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
    if ($null -eq $state) { throw 'Manifest state is missing; run Plan first.' }
    if (@($state.pending_steps).Count -eq 0 -or [string]$state.pending_steps[0] -ne $Step) { throw 'Manifest dependency order rejects this step.' }
    $deadline = Test-RepoHealthManifestDeadline -State $state
    if (-not $deadline.start_allowed) {
        $state.run_status = 'OVERNIGHT_RUN_PAUSED_SAFE'
        Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
        return [pscustomobject]@{ outcome = 'OVERNIGHT_RUN_PAUSED_SAFE'; next_step = $state.current_step; remaining_minutes = $deadline.remaining_minutes }
    }
    $exactGoal = Get-Content -LiteralPath $GoalPath -Raw
    $admittedHead = (git -C $RepositoryPath rev-parse HEAD).Trim()
    if ($admittedHead -notmatch '^[0-9a-f]{40}$') { throw 'Unable to establish admitted repository head.' }
    $state.run_status = 'RUNNING'
    $state.current_wave = $Wave
    $state.current_step = $Step
    $state.current_repository = $Repository
    Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null

    $architectGoal = New-RepoHealthPhaseGoal -Role Architect -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -Phase CHIEF_PLAN -ExactGoal $exactGoal
    $architect = Invoke-RepoHealthRoleProcess -Role Architect -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $architectGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
    if ([string]$architect.envelope.outcome -ne 'PASS') {
        $state.run_status = 'HOLD'
        Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
        return [pscustomobject]@{ outcome = 'HOLD'; phase = 'CHIEF_PLAN'; envelope_path = $architect.envelope_path }
    }

    if ($ProductWrite) {
        $lease = Enter-RepoHealthWriterLease -Repository $Repository -SessionId ($RunId + '-' + $Step) -StateRoot $StateRoot
        try {
            $state.active_writer = $Repository
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            $implementerGoal = New-RepoHealthPhaseGoal -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -Phase IMPLEMENT_VERIFY -ExactGoal $exactGoal -PriorSummary ([string]$architect.envelope.sanitized_summary)
            $implementer = Invoke-RepoHealthRoleProcess -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $implementerGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
        }
        finally {
            $state.active_writer = $null
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            Exit-RepoHealthWriterLease -Lease $lease
        }
        if ([string]$implementer.envelope.outcome -ne 'PASS') {
            $state.run_status = 'HOLD'
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            return [pscustomobject]@{ outcome = 'HOLD'; phase = 'IMPLEMENT_VERIFY'; envelope_path = $implementer.envelope_path }
        }
    }

    $supervisorGoal = New-RepoHealthPhaseGoal -Role Supervisor -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -Phase SUPERVISOR_AUDIT -ExactGoal $exactGoal -PriorSummary ([string]$architect.envelope.sanitized_summary)
    $supervisor = Invoke-RepoHealthRoleProcess -Role Supervisor -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $supervisorGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
    $correction = 0
    while ($ProductWrite -and [string]$supervisor.envelope.outcome -eq 'CHANGES_REQUIRED' -and $correction -lt $MaxCorrections) {
        $correction++
        $lease = Enter-RepoHealthWriterLease -Repository $Repository -SessionId ($RunId + '-' + $Step + '-c' + $correction) -StateRoot $StateRoot
        try {
            $state.active_writer = $Repository
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            $correctionGoal = New-RepoHealthPhaseGoal -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -Phase CORRECTION -ExactGoal $exactGoal -PriorSummary ([string]$supervisor.envelope.sanitized_summary)
            $correctionResult = Invoke-RepoHealthRoleProcess -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $correctionGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
        }
        finally {
            $state.active_writer = $null
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            Exit-RepoHealthWriterLease -Lease $lease
        }
        if ([string]$correctionResult.envelope.outcome -ne 'PASS') { break }
        $supervisor = Invoke-RepoHealthRoleProcess -Role Supervisor -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $supervisorGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
    }
    if ([string]$supervisor.envelope.outcome -ne 'PASS') {
        $state.run_status = if ([string]$supervisor.envelope.outcome -eq 'HUMAN_ESCALATION_REQUIRED') { 'HUMAN_ESCALATION_REQUIRED' } else { 'HOLD' }
        Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
        return [pscustomobject]@{ outcome = $state.run_status; phase = 'SUPERVISOR_AUDIT'; envelope_path = $supervisor.envelope_path }
    }
    if ($ProductWrite) {
        $lease = Enter-RepoHealthWriterLease -Repository $Repository -SessionId ($RunId + '-' + $Step + '-merge') -StateRoot $StateRoot
        try {
            $state.active_writer = $Repository
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            $mergeGoal = New-RepoHealthPhaseGoal -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -Phase MERGE_CLEANUP -ExactGoal $exactGoal -PriorSummary ([string]$supervisor.envelope.sanitized_summary)
            $merge = Invoke-RepoHealthRoleProcess -Role Implementer -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $admittedHead -WorkingDirectory $RepositoryPath -GoalText $mergeGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
        }
        finally {
            $state.active_writer = $null
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            Exit-RepoHealthWriterLease -Lease $lease
        }
        if ([string]$merge.envelope.outcome -ne 'PASS') {
            $state.run_status = 'HOLD'
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            return [pscustomobject]@{ outcome = 'HOLD'; phase = 'MERGE_CLEANUP'; envelope_path = $merge.envelope_path }
        }
        $exactStableHead = (git -C $RepositoryPath rev-parse HEAD).Trim()
        if ($exactStableHead -notmatch '^[0-9a-f]{40}$') { throw 'Unable to establish exact stable head.' }
        $finalGoal = New-RepoHealthPhaseGoal -Role Supervisor -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $exactStableHead -Phase EXACT_STABLE_AUDIT -ExactGoal $exactGoal -PriorSummary ([string]$merge.envelope.sanitized_summary)
        $finalSupervisor = Invoke-RepoHealthRoleProcess -Role Supervisor -RunId $RunId -Wave $Wave -Step $Step -Scope $Repository -AdmittedHead $exactStableHead -WorkingDirectory $RepositoryPath -GoalText $finalGoal -InventoryRoot $InventoryRoot -LogRoot $LogRoot
        if ([string]$finalSupervisor.envelope.outcome -ne 'PASS') {
            $state.run_status = if ([string]$finalSupervisor.envelope.outcome -eq 'HUMAN_ESCALATION_REQUIRED') { 'HUMAN_ESCALATION_REQUIRED' } else { 'HOLD' }
            Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
            return [pscustomobject]@{ outcome = $state.run_status; phase = 'EXACT_STABLE_AUDIT'; envelope_path = $finalSupervisor.envelope_path }
        }
    }
    $state.completed_steps = @($state.completed_steps) + $Step
    $state.pending_steps = @($state.pending_steps | Where-Object { $_ -ne $Step })
    $state.run_status = if (@($state.pending_steps).Count -eq 0) { 'M6_REPOSITORY_HEALTH_TRAIN_COMPLETE' } else { 'STEP_COMPLETE' }
    Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
    return [pscustomobject]@{ outcome = 'PASS'; phase = 'SUPERVISOR_AUDIT'; corrections = $correction; next_step = @($state.pending_steps | Select-Object -First 1) }
}

Export-ModuleMember -Function @(
    'Assert-RepoHealthLaunchArguments','Assert-RepoHealthLaunchRequest','Enter-RepoHealthWriterLease','Exit-RepoHealthWriterLease',
    'Get-RepoHealthGithubActionsClassification','Get-RepoHealthManifestPaths','Get-RepoHealthNewRepositoryDeadline','Get-RepoHealthRoleProfile','Invoke-RepoHealthRoleProcess',
    'Invoke-RepoHealthManifestStep','New-RepoHealthManifestState','New-RepoHealthPhaseGoal','New-RepoHealthProcessEnvelope','Read-RepoHealthManifestState',
    'Request-RepoHealthManifestStop','Resolve-RepoHealthCodexHost','Save-RepoHealthManifestState',
    'Test-RepoHealthManifestDeadline','Test-RepoHealthPriorReceipt','Test-RepoHealthProcessEnvelope',
    'Test-RepoHealthRoutingContract','Test-RepoHealthRunManifest','Write-RepoHealthProcessLog'
)
