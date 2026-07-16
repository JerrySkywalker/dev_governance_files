Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'RepoHealthCoordinator.Types.ps1')

function ConvertTo-RepoHealthJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Value
    )

    return ($Value | ConvertTo-Json -Depth 32)
}

function Get-RepoHealthSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Assert-RepoHealthSafeIdentifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Value,
        [Parameter(Mandatory)]
        [string]$Field
    )

    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw "$Field must be a safe identifier."
    }
}

function Test-RepoHealthSafeSummary {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    $unsafe = '(?i)(token|password|secret|credential|authorization|connection\s*string|ssh://|-----BEGIN|[A-Za-z]:\\Users\\)'
    return $Value -notmatch $unsafe
}

function Get-RepoHealthPaths {
    [CmdletBinding()]
    param(
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state',
        [string]$GoalRoot = 'V:\src\goals\repo-health',
        [string]$LogRoot = 'V:\src\codex-run-logs\repo-health'
    )

    return [pscustomobject]@{
        StateRoot = $StateRoot
        GoalRoot = $GoalRoot
        LogRoot = $LogRoot
        LockRoot = (Join-Path $StateRoot 'locks')
    }
}

function Write-RepoHealthJsonAtomic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [object]$Value
    )

    $parent = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    $temporary = Join-Path $parent ('.' + [System.IO.Path]::GetFileName($Path) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8.GetBytes((ConvertTo-RepoHealthJson -Value $Value))
    $stream = New-Object System.IO.FileStream($temporary, ([System.IO.FileMode]::Create), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::None), 4096, ([System.IO.FileOptions]::WriteThrough))
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    if (Test-Path -LiteralPath $Path) {
        $backup = Join-Path $parent ('.' + [System.IO.Path]::GetFileName($Path) + '.previous.bak')
        [System.IO.File]::Replace($temporary, $Path, $backup)
    }
    else {
        [System.IO.File]::Move($temporary, $Path)
    }

    return $Path
}

function Read-RepoHealthJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function New-RepoHealthState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,
        [string]$SessionId = '',
        [string]$CurrentState = 'DISCOVER'
    )

    Assert-RepoHealthSafeIdentifier -Value $Repository -Field 'repository'
    if ($CurrentState -notin (Get-RepoHealthStateNames)) {
        throw 'current_state is not a supported coordinator state.'
    }

    return [pscustomobject]@{
        schema = 'repo-health-coordinator-state.v1'
        repository = $Repository
        current_state = $CurrentState
        writer_session_id = $SessionId
        automatic_session_launch_supported = $false
        blockers = @()
        milestone_status = @()
        revision = 1
        updated_utc = [DateTime]::UtcNow.ToString('o')
    }
}

function Get-RepoHealthStatePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )

    Assert-RepoHealthSafeIdentifier -Value $Repository -Field 'repository'
    return (Join-Path $StateRoot ($Repository + '.state.json'))
}

function Read-RepoHealthState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )

    return (Read-RepoHealthJson -Path (Get-RepoHealthStatePath -Repository $Repository -StateRoot $StateRoot))
}

function Save-RepoHealthState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$State,
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )

    if ($State.schema -ne 'repo-health-coordinator-state.v1') {
        throw 'State schema is not supported.'
    }
    $State.revision = [int]$State.revision + 1
    $State.updated_utc = [DateTime]::UtcNow.ToString('o')
    return (Write-RepoHealthJsonAtomic -Path (Get-RepoHealthStatePath -Repository $State.repository -StateRoot $StateRoot) -Value $State)
}

function Enter-RepoHealthLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,
        [Parameter(Mandatory)]
        [string]$SessionId,
        [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
    )

    Assert-RepoHealthSafeIdentifier -Value $Repository -Field 'repository'
    Assert-RepoHealthSafeIdentifier -Value $SessionId -Field 'session_id'
    $lockRoot = Join-Path $StateRoot 'locks'
    [System.IO.Directory]::CreateDirectory($lockRoot) | Out-Null
    $lockPath = Join-Path $lockRoot ($Repository + '.lock')
    try {
        $handle = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    }
    catch [System.IO.IOException] {
        throw "Repository lock collision for $Repository."
    }

    $lockPayload = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-RepoHealthJson -Value ([pscustomobject]@{
        schema = 'repository-lock.v1'
        repository = $Repository
        session_id = $SessionId
        acquired_utc = [DateTime]::UtcNow.ToString('o')
    })))
    $handle.Write($lockPayload, 0, $lockPayload.Length)
    $handle.Flush()
    return [pscustomobject]@{ Path = $lockPath; Handle = $handle; Repository = $Repository; SessionId = $SessionId }
}

function Exit-RepoHealthLock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Lock
    )

    $Lock.Handle.Dispose()
    if (Test-Path -LiteralPath $Lock.Path) {
        Remove-Item -LiteralPath $Lock.Path -Force
    }
}

function Assert-RepoHealthWriterAdmission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$State,
        [Parameter(Mandatory)]
        [string]$SessionId,
        [Parameter(Mandatory)]
        [ValidateSet('Implementer', 'Supervisor')]
        [string]$Role,
        [bool]$ProductRepositoryWrite = $false,
        [bool]$GitMutation = $false
    )

    Assert-RepoHealthSafeIdentifier -Value $SessionId -Field 'session_id'
    if ($Role -eq 'Supervisor' -and ($ProductRepositoryWrite -or $GitMutation)) {
        throw 'Supervisor admission rejects product repository writes and Git mutation.'
    }
    if ($Role -eq 'Implementer' -and $State.writer_session_id -and $State.writer_session_id -ne $SessionId) {
        throw 'One-writer admission rejected a second writer session.'
    }
    if ($Role -eq 'Implementer') {
        $State.writer_session_id = $SessionId
    }
    return $State
}

function Test-RepoHealthResultEnvelope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Envelope
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    foreach ($property in @('schema', 'role', 'repository', 'outcome', 'product_repository_write', 'git_mutation', 'sanitized_summary')) {
        if ($null -eq $Envelope.PSObject.Properties[$property]) {
            $reasons.Add("missing_$property")
        }
    }
    if ($reasons.Count -eq 0) {
        if ($Envelope.schema -ne 'repo-health-result-envelope.v1') { $reasons.Add('unsupported_schema') }
        if ($Envelope.role -notin @('Implementer', 'Supervisor')) { $reasons.Add('invalid_role') }
        try { Assert-RepoHealthSafeIdentifier -Value ([string]$Envelope.repository) -Field 'repository' } catch { $reasons.Add('unsafe_repository') }
        if ($Envelope.outcome -notin @('PASS', 'BLOCKED', 'HOLD')) { $reasons.Add('invalid_outcome') }
        if (-not (Test-RepoHealthSafeSummary -Value ([string]$Envelope.sanitized_summary))) { $reasons.Add('unsafe_summary') }
        if ($Envelope.role -eq 'Supervisor' -and ([bool]$Envelope.product_repository_write -or [bool]$Envelope.git_mutation)) {
            $reasons.Add('supervisor_mutation')
        }
    }

    return [pscustomobject]@{ valid = ($reasons.Count -eq 0); reasons = @($reasons) }
}

function Assert-RepoHealthResultEnvelope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Envelope,
        [Parameter(Mandatory)]
        [object]$State,
        [Parameter(Mandatory)]
        [string]$SessionId
    )

    $result = Test-RepoHealthResultEnvelope -Envelope $Envelope
    if (-not $result.valid) {
        throw ('Invalid result envelope: ' + ($result.reasons -join ','))
    }
    return (Assert-RepoHealthWriterAdmission -State $State -SessionId $SessionId -Role $Envelope.role -ProductRepositoryWrite ([bool]$Envelope.product_repository_write) -GitMutation ([bool]$Envelope.git_mutation))
}

function Get-RepoHealthBlockerFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Blocker
    )

    foreach ($property in @('repository_or_scope', 'phase', 'finite_classification', 'failing_contract', 'normalized_exit_code', 'source_head_sha_when_applicable', 'safe_path_digest_when_applicable')) {
        if ($null -eq $Blocker.PSObject.Properties[$property]) {
            throw "Blocker fingerprint input is missing $property."
        }
    }
    Assert-RepoHealthSafeIdentifier -Value ([string]$Blocker.repository_or_scope) -Field 'repository_or_scope'
    if ([string]$Blocker.phase -notin (Get-RepoHealthStateNames)) { throw 'phase is not a coordinator state.' }
    Assert-RepoHealthSafeIdentifier -Value ([string]$Blocker.finite_classification) -Field 'finite_classification'
    Assert-RepoHealthSafeIdentifier -Value ([string]$Blocker.failing_contract) -Field 'failing_contract'
    if ([int]$Blocker.normalized_exit_code -lt 0 -or [int]$Blocker.normalized_exit_code -gt 255) { throw 'normalized_exit_code must be between 0 and 255.' }
    if ($Blocker.source_head_sha_when_applicable -and [string]$Blocker.source_head_sha_when_applicable -notmatch '^[0-9a-f]{40}$') { throw 'source_head_sha_when_applicable must be a SHA-1 or empty.' }
    if ($Blocker.safe_path_digest_when_applicable -and [string]$Blocker.safe_path_digest_when_applicable -notmatch '^[0-9a-f]{64}$') { throw 'safe_path_digest_when_applicable must be a SHA-256 digest or empty.' }

    $canonical = [ordered]@{
        repository_or_scope = [string]$Blocker.repository_or_scope
        phase = [string]$Blocker.phase
        finite_classification = [string]$Blocker.finite_classification
        failing_contract = [string]$Blocker.failing_contract
        normalized_exit_code = [int]$Blocker.normalized_exit_code
        source_head_sha_when_applicable = [string]$Blocker.source_head_sha_when_applicable
        safe_path_digest_when_applicable = [string]$Blocker.safe_path_digest_when_applicable
    }
    return [pscustomobject]@{
        schema = 'repo-health-blocker-fingerprint.v1'
        fields = [pscustomobject]$canonical
        fingerprint = (Get-RepoHealthSha256 -Text (ConvertTo-RepoHealthJson -Value $canonical))
    }
}

function Register-RepoHealthBlocker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$State,
        [Parameter(Mandatory)]
        [object]$Blocker
    )

    $fingerprint = Get-RepoHealthBlockerFingerprint -Blocker $Blocker
    $matching = @($State.blockers | Where-Object { $_.fingerprint -eq $fingerprint.fingerprint })
    $count = $matching.Count + 1
    $highRisk = [string]$Blocker.finite_classification -in (Get-RepoHealthHighRiskClasses)
    $State.blockers = @($State.blockers) + [pscustomobject]@{
        fingerprint = $fingerprint.fingerprint
        count = $count
        finite_classification = [string]$Blocker.finite_classification
        recorded_utc = [DateTime]::UtcNow.ToString('o')
    }
    if ($highRisk -or $count -ge 3) {
        $State.current_state = 'HUMAN_REQUIRED'
        $action = 'HUMAN_REQUIRED'
    }
    elseif ($count -eq 2) {
        $State.current_state = 'BLOCKED_ROUND_2'
        $action = 'ARCHITECT_PLUS_ADVERSARIAL_AUDIT'
    }
    else {
        $State.current_state = 'BLOCKED_ROUND_1'
        $action = 'ARCHITECT_FIRST_ANALYSIS'
    }
    return [pscustomobject]@{ state = $State; fingerprint = $fingerprint; occurrence_count = $count; next_action = $action }
}

function Get-NextRepoHealthState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('DISCOVER', 'CLASSIFY_BRANCHES', 'PLAN_CONVERGENCE', 'IMPLEMENT', 'VERIFY_LOCAL', 'VERIFY_CI', 'SUPERVISOR_AUDIT', 'MERGE_MAIN', 'MERGE_DEV', 'ARCHIVE', 'DELETE_BRANCH', 'WORKTREE_CLEANUP', 'REPO_HEALTHY', 'BLOCKED_ROUND_1', 'BLOCKED_ROUND_2', 'HUMAN_REQUIRED')]
        [string]$CurrentState,
        [bool]$RequiresDevIntegration = $false,
        [bool]$RequiresArchive = $false
    )

    $next = @{
        DISCOVER = 'CLASSIFY_BRANCHES'
        CLASSIFY_BRANCHES = 'PLAN_CONVERGENCE'
        PLAN_CONVERGENCE = 'IMPLEMENT'
        IMPLEMENT = 'VERIFY_LOCAL'
        VERIFY_LOCAL = 'VERIFY_CI'
        VERIFY_CI = 'SUPERVISOR_AUDIT'
        SUPERVISOR_AUDIT = 'MERGE_MAIN'
        MERGE_MAIN = 'WORKTREE_CLEANUP'
        MERGE_DEV = 'WORKTREE_CLEANUP'
        ARCHIVE = 'DELETE_BRANCH'
        DELETE_BRANCH = 'WORKTREE_CLEANUP'
        WORKTREE_CLEANUP = 'REPO_HEALTHY'
        REPO_HEALTHY = 'REPO_HEALTHY'
        BLOCKED_ROUND_1 = 'PLAN_CONVERGENCE'
        BLOCKED_ROUND_2 = 'PLAN_CONVERGENCE'
        HUMAN_REQUIRED = 'HUMAN_REQUIRED'
    }
    if ($CurrentState -eq 'SUPERVISOR_AUDIT' -and $RequiresDevIntegration) { return 'MERGE_DEV' }
    if ($CurrentState -eq 'SUPERVISOR_AUDIT' -and $RequiresArchive) { return 'ARCHIVE' }
    return $next[$CurrentState]
}

function Test-RepoHealthMilestoneDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Milestone,
        [AllowEmptyCollection()]
        [object[]]$Dependencies = @(),
        [AllowEmptyCollection()]
        [object[]]$CompletedMilestones = @()
    )

    Assert-RepoHealthSafeIdentifier -Value $Milestone -Field 'milestone'
    $missing = @($Dependencies | Where-Object { $_ -notin $CompletedMilestones })
    return [pscustomobject]@{ milestone = $Milestone; ready = ($missing.Count -eq 0); missing_dependencies = $missing }
}

function Test-RepoHealthAdmission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,
        [Parameter(Mandatory)]
        [object]$BranchInventory,
        [Parameter(Mandatory)]
        [object]$EvidenceInventory
    )

    $agentsPath = Join-Path $RepositoryRoot 'AGENTS.md'
    $requiredHeadings = @('Branch Model', 'Branch Target Rules', 'Short-Lived Branch Lifecycle', 'Single-Writer Rule', 'Agent Allocation', 'Blocker Handling', 'Repository-Specific Preservation Rules')
    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $agentsPath)) {
        $reasons.Add('agents_md_missing')
    }
    else {
        $agents = Get-Content -LiteralPath $agentsPath -Raw
        foreach ($heading in $requiredHeadings) {
            if ($agents -notmatch [regex]::Escape($heading)) { $reasons.Add(('agents_md_missing_' + $heading.Replace(' ', '_').ToLowerInvariant())) }
        }
    }
    if ([string]$BranchInventory.main -ne 'healthy') { $reasons.Add('main_not_healthy') }
    if ([string]$BranchInventory.dev -notin @('healthy', 'absent')) { $reasons.Add('dev_not_healthy_or_absent') }
    if ([int]$BranchInventory.unclassified_non_main_dev -ne 0) { $reasons.Add('unclassified_branches') }

    function Get-AdmissionEvidenceBoolean {
        param([Parameter(Mandatory)][string]$Name, [bool]$Default = $false)
        $property = $EvidenceInventory.PSObject.Properties[$Name]
        if ($null -eq $property) { return $Default }
        return [bool]$property.Value
    }
    function Get-AdmissionEvidenceInteger {
        param([Parameter(Mandatory)][string]$Name, [int]$Default = 0)
        $property = $EvidenceInventory.PSObject.Properties[$Name]
        if ($null -eq $property) { return $Default }
        return [int]$property.Value
    }

    $evidenceStates = New-Object System.Collections.Generic.List[string]
    $trackedClean = Get-AdmissionEvidenceBoolean -Name 'tracked_clean'
    $approvedPreservedEvidenceCount = Get-AdmissionEvidenceInteger -Name 'approved_preserved_evidence_count'
    $unknownDirtCount = Get-AdmissionEvidenceInteger -Name 'unknown_dirt_count'
    $preservationLedgerVerified = Get-AdmissionEvidenceBoolean -Name 'preservation_ledger_verified'
    $preservedEvidenceBoundaryVerified = Get-AdmissionEvidenceBoolean -Name 'preserved_evidence_boundary_verified'
    $reviewerMustNotAccessOriginalWorktreeEvidence = Get-AdmissionEvidenceBoolean -Name 'reviewer_must_not_access_original_worktree_evidence'
    $snapshotRequired = $reviewerMustNotAccessOriginalWorktreeEvidence -or (Get-AdmissionEvidenceBoolean -Name 'snapshot_required')
    $trackedSnapshotIsolated = Get-AdmissionEvidenceBoolean -Name 'tracked_snapshot_isolated'
    $snapshotSourceShaBound = Get-AdmissionEvidenceBoolean -Name 'snapshot_source_sha_bound'
    $snapshotTreeDigestVerified = Get-AdmissionEvidenceBoolean -Name 'snapshot_tree_digest_verified'

    if ($trackedClean) { $evidenceStates.Add('TRACKED_CLEAN') }
    else { $reasons.Add('tracked_not_clean') }

    if ($approvedPreservedEvidenceCount -gt 0) {
        $evidenceStates.Add('APPROVED_PRESERVED_EVIDENCE')
        if (-not $preservationLedgerVerified) { $reasons.Add('approved_preserved_evidence_ledger_unverified') }
        if (-not $preservedEvidenceBoundaryVerified) { $reasons.Add('approved_preserved_evidence_boundary_unverified') }
    }

    if ($unknownDirtCount -gt 0) {
        $evidenceStates.Add('UNKNOWN_DIRT')
        $reasons.Add('unknown_dirt_present')
    }

    if ($snapshotRequired) {
        $evidenceStates.Add('SNAPSHOT_REQUIRED')
        if (-not $trackedSnapshotIsolated) { $reasons.Add('tracked_snapshot_isolation_required') }
        if (-not $snapshotSourceShaBound) { $reasons.Add('tracked_snapshot_source_sha_unbound') }
        if (-not $snapshotTreeDigestVerified) { $reasons.Add('tracked_snapshot_tree_digest_unverified') }
    }

    return [pscustomobject]@{
        admitted = ($reasons.Count -eq 0)
        reasons = @($reasons | Select-Object -Unique)
        evidence_states = @($evidenceStates | Select-Object -Unique)
        evidence = [pscustomobject]@{
            tracked_clean = $trackedClean
            approved_preserved_evidence_count = $approvedPreservedEvidenceCount
            unknown_dirt_count = $unknownDirtCount
            snapshot_required = $snapshotRequired
            tracked_snapshot_isolated = $trackedSnapshotIsolated
            snapshot_source_sha_bound = $snapshotSourceShaBound
            snapshot_tree_digest_verified = $snapshotTreeDigestVerified
        }
    }
}

function New-RepoHealthGoalContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Implementer', 'Supervisor')]
        [string]$Role,
        [Parameter(Mandatory)]
        [string]$Repository,
        [Parameter(Mandatory)]
        [string]$State
    )

    Assert-RepoHealthSafeIdentifier -Value $Repository -Field 'repository'
    if ($State -notin (Get-RepoHealthStateNames)) { throw 'State is not supported.' }
    $common = @"
repository=$Repository
state=$State
agents.max_threads=8
agents.max_depth=1
features.multi_agent_v2.max_concurrent_threads_per_session=8
"@
    if ($Role -eq 'Implementer') {
        return $common + @"
role=Implementer
one_writer_root=true
direct_read_only_subagents=7
agents_md_admission_required=true
branch_policy_admission_required=true
repository_specific_preservation_rules_required=true
"@
    }
    return $common + @"
role=Supervisor
product_repository_read_only=true
git_mutation_prohibited=true
architect_first_blocker_analysis=true
next_goal_generation_only=true
"@
}

function Write-RepoHealthGoalQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Implementer', 'Supervisor')]
        [string]$Role,
        [Parameter(Mandatory)]
        [string]$Repository,
        [Parameter(Mandatory)]
        [string]$State,
        [string]$GoalRoot = 'V:\src\goals\repo-health'
    )

    [System.IO.Directory]::CreateDirectory($GoalRoot) | Out-Null
    $name = ('{0}-{1}-{2}.goal.md' -f $Repository, $State.ToLowerInvariant(), $Role.ToLowerInvariant())
    $path = Join-Path $GoalRoot $name
    $content = New-RepoHealthGoalContent -Role $Role -Repository $Repository -State $State
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
    return $path
}

function Get-RepoHealthGoalQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Items
    )

    return @($Items | Sort-Object @{Expression = 'milestone_order'; Ascending = $true}, @{Expression = 'wave_step'; Ascending = $true}, @{Expression = 'repository'; Ascending = $true}, @{Expression = 'role'; Ascending = $true})
}

function Get-RepoHealthLaunchCapability {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        automatic_session_launch_supported = $false
        mode = 'queue-file-manual-attach'
        documented_adapter = 'codex-exec-help-inspected'
        product_writing_session_started = $false
    }
}

function New-RepoHealthSafeReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$State
    )

    return [pscustomobject]@{
        schema = 'repo-health-safe-report.v1'
        repository = [string]$State.repository
        current_state = [string]$State.current_state
        revision = [int]$State.revision
        automatic_session_launch_supported = [bool]$State.automatic_session_launch_supported
        blocker_count = @($State.blockers).Count
        secrets_visible = $false
        output_private_connection_metadata = 0
    }
}

Export-ModuleMember -Function @(
    'Assert-RepoHealthResultEnvelope',
    'Assert-RepoHealthSafeIdentifier',
    'Assert-RepoHealthWriterAdmission',
    'ConvertTo-RepoHealthJson',
    'Enter-RepoHealthLock',
    'Exit-RepoHealthLock',
    'Get-NextRepoHealthState',
    'Get-RepoHealthBlockerFingerprint',
    'Get-RepoHealthHighRiskClasses',
    'Get-RepoHealthPaths',
    'Get-RepoHealthGoalQueue',
    'Get-RepoHealthLaunchCapability',
    'Get-RepoHealthSha256',
    'Get-RepoHealthStateNames',
    'Get-RepoHealthStatePath',
    'New-RepoHealthGoalContent',
    'New-RepoHealthSafeReport',
    'New-RepoHealthState',
    'Read-RepoHealthJson',
    'Read-RepoHealthState',
    'Register-RepoHealthBlocker',
    'Save-RepoHealthState',
    'Test-RepoHealthAdmission',
    'Test-RepoHealthMilestoneDependencies',
    'Test-RepoHealthResultEnvelope',
    'Test-RepoHealthSafeSummary',
    'Write-RepoHealthGoalQueue',
    'Write-RepoHealthJsonAtomic'
)
