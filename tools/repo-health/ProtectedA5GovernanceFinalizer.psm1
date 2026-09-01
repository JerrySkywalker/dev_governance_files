Set-StrictMode -Version Latest

$script:Pa5LeaseFields = [ordered]@{
    schema = 'String'; goal = 'String'; holder = 'String'; holder_session = 'String'; state = 'String'
    acquired_utc = 'String'; created_utc = 'String'; hard_stop_utc = 'String'; single_intentional_writer = 'Boolean'
    scope = 'StringArray'; goal_ref = 'String'; budget_state_ref = 'String'
}
$script:Pa5GoalFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; profile = 'String'; authority_class = 'String'
    elasticity_grade = 'String'; initial_progress_state = 'String'; current_layer = 'String'; max_admitted_layer = 'String'
    next_proof_vector = 'String'; allowed_repositories = 'StringArray'; allowed_paths = 'StringArray'; allowed_services = 'StringArray'
    protected_boundaries = 'StringArray'; owner_only_boundaries = 'StringArray'; budget_overrides = 'Object'
    budget_state_ref = 'String'; last_accepted_checkpoint = 'String'; context_modules = 'StringArray'; stop_conditions = 'StringArray'
    created_utc = 'String'
}
$script:Pa5BudgetFields = [ordered]@{ schema = 'String'; goal = 'String'; run_id = 'String'; created_utc = 'String'; domains = 'Object' }
$script:Pa5AuthorizationFields = [ordered]@{
    schema = 'String'; authorization_id = 'String'; authorization_scope = 'String'; authorized_by = 'String'
    authorized_utc = 'String'; expires_utc = 'String'; task_root_relative_lease_path = 'String'; expected_lease_sha256 = 'String'
    expected_goal = 'String'; expected_run_id = 'String'; expected_goal_metadata_sha256 = 'String'; expected_budget_metadata_sha256 = 'String'
    transaction_id = 'String'; finalization_evidence_path = 'String'; expected_finalization_evidence_sha256 = 'String'
    reconciliation_receipt_path = 'String'; expected_reconciliation_receipt_sha256 = 'String'
    independent_verifier_receipt_path = 'String'; expected_independent_verifier_receipt_sha256 = 'String'
    expected_terminal_result = 'String'; expected_terminal_failure_code = 'String'
}
$script:Pa5EvidenceFields = [ordered]@{
    schema = 'String'; evidence_id = 'String'; created_utc = 'String'; expected_lease_sha256 = 'String'
    goal = 'String'; run_id = 'String'; goal_metadata_sha256 = 'String'; budget_metadata_sha256 = 'String'
    transaction_id = 'String'; transaction_terminal = 'Boolean'; terminal_result = 'String'; terminal_failure_code = 'String'
    reconciliation_status = 'String'; final_supervisor_status = 'String'; fresh_transaction_evidence = 'Boolean'
    live_prestate_status = 'String'; configuration_mutation_status = 'String'; rollback_packet_status = 'String'
    rollback_status = 'String'; no_unresolved_protected_mutation = 'Boolean'
    no_contradictory_later_transaction_evidence = 'Boolean'; no_fabricated_historical_receipt = 'Boolean'
    unresolved_rollback = 'Boolean'; conflicting_evidence = 'Boolean'; accepted_target_status = 'String'
    final_protected_verification_status = 'String'; reconciliation_receipt_path = 'String'
    reconciliation_receipt_sha256 = 'String'; independent_verifier_receipt_path = 'String'
    independent_verifier_receipt_sha256 = 'String'
}
$script:Pa5ReceiptFields = [ordered]@{
    schema = 'String'; finalization_id = 'String'; finalization_status = 'String'; finalized_utc = 'String'
    transaction_id = 'String'; terminal_result = 'String'; terminal_failure_code = 'String'; goal = 'String'; run_id = 'String'
    source_relative_path = 'String'; historical_relative_path = 'String'; original_lease_schema = 'String'
    original_lease_sha256 = 'String'; goal_metadata_sha256 = 'String'; budget_metadata_sha256 = 'String'
    authorization_sha256 = 'String'; finalization_evidence_sha256 = 'String'; reconciliation_receipt_sha256 = 'String'
    independent_verifier_receipt_sha256 = 'String'; production_transaction_mutated = 'Boolean'
}

function Throw-Pa5Rejected {
    param([Parameter(Mandatory)][string]$Code)
    throw ('FINALIZATION_REJECTED_' + $Code)
}

function Get-Pa5BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Get-Pa5PathComparison {
    if ($IsWindows) { return [System.StringComparison]::OrdinalIgnoreCase }
    return [System.StringComparison]::Ordinal
}

function Get-Pa5FullPath {
    param([Parameter(Mandatory)][string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) }
    catch { Throw-Pa5Rejected 'INVALID_PATH' }
}

function Test-Pa5PathWithin {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Candidate)
    $comparison = Get-Pa5PathComparison
    $fullRoot = (Get-Pa5FullPath -Path $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullCandidate = Get-Pa5FullPath -Path $Candidate
    if ($fullCandidate.Equals($fullRoot, $comparison)) { return $true }
    return $fullCandidate.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, $comparison)
}

function Assert-Pa5NoReparseExistingAncestors {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Get-Pa5FullPath -Path $Path
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) { Throw-Pa5Rejected 'INVALID_PATH' }
    $current = $root
    $separators = [char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $tail = $fullPath.Substring($root.Length).Split($separators, [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $tail) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { break }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-Pa5Rejected 'REPARSE_PATH' }
    }
    return $fullPath
}

function Assert-Pa5Directory {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Pa5NoReparseExistingAncestors -Path $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) { Throw-Pa5Rejected 'DIRECTORY_REQUIRED' }
    return $fullPath
}

function Assert-Pa5RegularFile {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Pa5NoReparseExistingAncestors -Path $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { Throw-Pa5Rejected 'REGULAR_FILE_REQUIRED' }
    $item = Get-Item -LiteralPath $fullPath -Force
    if (-not ($item -is [System.IO.FileInfo])) { Throw-Pa5Rejected 'REGULAR_FILE_REQUIRED' }
    return $fullPath
}

function Assert-Pa5SafeIdentifier {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,191}$') { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function Assert-Pa5Sha256 {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ($Value -cnotmatch '^[0-9a-f]{64}$') { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function ConvertTo-Pa5Utc {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact($Value, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant())
    }
    return $parsed.ToUniversalTime()
}

function Get-Pa5StrictJsonRoot {
    param(
        [Parameter(Mandatory)][byte[]]$Bytes,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Expected,
        [Parameter(Mandatory)][string]$FailureCode
    )
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 131072) { Throw-Pa5Rejected $FailureCode }
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes) }
    catch { Throw-Pa5Rejected $FailureCode }
    try { $document = [System.Text.Json.JsonDocument]::Parse($text) }
    catch { Throw-Pa5Rejected $FailureCode }
    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) { Throw-Pa5Rejected $FailureCode }
        $expectedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($name in $Expected.Keys) { $expectedNames.Add([string]$name) | Out-Null }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $properties = @{}
        foreach ($property in $root.EnumerateObject()) {
            if (-not $seen.Add($property.Name) -or -not $expectedNames.Contains($property.Name)) { Throw-Pa5Rejected $FailureCode }
            $properties[$property.Name] = $property.Value
        }
        if ($properties.Count -ne $Expected.Count) { Throw-Pa5Rejected $FailureCode }
        foreach ($entry in $Expected.GetEnumerator()) {
            if (-not $properties.ContainsKey($entry.Key)) { Throw-Pa5Rejected $FailureCode }
            $kind = $properties[$entry.Key].ValueKind.ToString()
            if ($entry.Value -eq 'StringArray') {
                if ($kind -ne 'Array') { Throw-Pa5Rejected $FailureCode }
                foreach ($element in $properties[$entry.Key].EnumerateArray()) {
                    if ($element.ValueKind -ne [System.Text.Json.JsonValueKind]::String) { Throw-Pa5Rejected $FailureCode }
                }
            }
            elseif ($entry.Value -eq 'Boolean') {
                if ($kind -notin @('True','False')) { Throw-Pa5Rejected $FailureCode }
            }
            elseif ($kind -ne $entry.Value) { Throw-Pa5Rejected $FailureCode }
        }
        return [pscustomobject]@{ Document = $document; Properties = $properties }
    }
    catch {
        $document.Dispose()
        throw
    }
}

function Get-Pa5StringArray {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Element)
    return @($Element.EnumerateArray() | ForEach-Object { $_.GetString() })
}

function Read-Pa5Lease {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $checked = Get-Pa5StrictJsonRoot -Bytes $Bytes -Expected $script:Pa5LeaseFields -FailureCode 'MALFORMED_LEASE'
    try {
        $p = $checked.Properties
        $lease = [pscustomobject]@{
            schema=$p.schema.GetString(); goal=$p.goal.GetString(); holder=$p.holder.GetString(); holder_session=$p.holder_session.GetString()
            state=$p.state.GetString(); acquired_utc=$p.acquired_utc.GetString(); created_utc=$p.created_utc.GetString()
            hard_stop_utc=$p.hard_stop_utc.GetString(); single_intentional_writer=$p.single_intentional_writer.GetBoolean()
            scope=Get-Pa5StringArray -Element $p.scope; goal_ref=$p.goal_ref.GetString(); budget_state_ref=$p.budget_state_ref.GetString()
        }
    }
    finally { $checked.Document.Dispose() }
    if ($lease.schema -cne 'jpc.taskroot-writer-lease.v1') { Throw-Pa5Rejected 'UNSUPPORTED_LEASE_SCHEMA' }
    foreach ($pair in @(@{v=$lease.goal;n='goal'},@{v=$lease.holder_session;n='holder_session'})) { Assert-Pa5SafeIdentifier -Value $pair.v -Field $pair.n }
    if ([string]::IsNullOrWhiteSpace($lease.holder) -or $lease.holder.Length -gt 191 -or $lease.holder -match '[\x00-\x1f]') { Throw-Pa5Rejected 'MALFORMED_HOLDER' }
    if ($lease.state -cne 'active' -or -not $lease.single_intentional_writer) { Throw-Pa5Rejected 'MALFORMED_LEASE' }
    if ($lease.scope.Count -eq 0 -or $lease.scope.Count -gt 32 -or @($lease.scope | Where-Object { [string]::IsNullOrWhiteSpace($_) -or $_.Length -gt 191 }).Count -ne 0) { Throw-Pa5Rejected 'MALFORMED_SCOPE' }
    $created = ConvertTo-Pa5Utc -Value $lease.created_utc -Field 'created_utc'
    $acquired = ConvertTo-Pa5Utc -Value $lease.acquired_utc -Field 'acquired_utc'
    $hardStop = ConvertTo-Pa5Utc -Value $lease.hard_stop_utc -Field 'hard_stop_utc'
    if ($created -gt $acquired -or $acquired -gt $hardStop) { Throw-Pa5Rejected 'MALFORMED_LEASE' }
    return $lease
}

function Read-Pa5Goal {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes((Assert-Pa5RegularFile -Path $Path))
    $checked = Get-Pa5StrictJsonRoot -Bytes $bytes -Expected $script:Pa5GoalFields -FailureCode 'MALFORMED_GOAL_METADATA'
    try {
        $p = $checked.Properties
        $goal = [pscustomobject]@{}
        foreach ($name in @('schema','goal','run_id','profile','authority_class','elasticity_grade','initial_progress_state','current_layer','max_admitted_layer','next_proof_vector','budget_state_ref','last_accepted_checkpoint','created_utc')) { $goal | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString() }
        foreach ($name in @('allowed_repositories','allowed_paths','allowed_services','protected_boundaries','owner_only_boundaries','context_modules','stop_conditions')) { $goal | Add-Member -NotePropertyName $name -NotePropertyValue @(Get-Pa5StringArray -Element $p[$name]) }
    }
    finally { $checked.Document.Dispose() }
    if ($goal.schema -cne 'jpc.frozen-goal.v1') { Throw-Pa5Rejected 'MALFORMED_GOAL_METADATA' }
    foreach ($pair in @(@{v=$goal.goal;n='goal'},@{v=$goal.run_id;n='run_id'})) { Assert-Pa5SafeIdentifier -Value $pair.v -Field $pair.n }
    ConvertTo-Pa5Utc -Value $goal.created_utc -Field 'goal_created_utc' | Out-Null
    return [pscustomobject]@{ value=$goal; sha256=(Get-Pa5BytesSha256 -Bytes $bytes); path=(Get-Pa5FullPath -Path $Path) }
}

function Read-Pa5Budget {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes((Assert-Pa5RegularFile -Path $Path))
    $checked = Get-Pa5StrictJsonRoot -Bytes $bytes -Expected $script:Pa5BudgetFields -FailureCode 'MALFORMED_BUDGET_METADATA'
    try {
        $p = $checked.Properties
        $budget = [pscustomobject]@{ schema=$p.schema.GetString(); goal=$p.goal.GetString(); run_id=$p.run_id.GetString(); created_utc=$p.created_utc.GetString() }
    }
    finally { $checked.Document.Dispose() }
    if ($budget.schema -cnotmatch '^[a-z0-9.-]+\.budget\.v1$') { Throw-Pa5Rejected 'MALFORMED_BUDGET_METADATA' }
    foreach ($pair in @(@{v=$budget.goal;n='budget_goal'},@{v=$budget.run_id;n='budget_run_id'})) { Assert-Pa5SafeIdentifier -Value $pair.v -Field $pair.n }
    ConvertTo-Pa5Utc -Value $budget.created_utc -Field 'budget_created_utc' | Out-Null
    return [pscustomobject]@{ value=$budget; sha256=(Get-Pa5BytesSha256 -Bytes $bytes); path=(Get-Pa5FullPath -Path $Path) }
}

function ConvertTo-Pa5CanonicalRelativePath {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ([string]::IsNullOrWhiteSpace($Value) -or [System.IO.Path]::IsPathRooted($Value) -or $Value -match ':' -or $Value -match '(^|[\\/])\.\.?(?:[\\/]|$)') { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    $normalized = $Value.Replace('\','/')
    if ($normalized.StartsWith('/') -or $normalized.EndsWith('/') -or $normalized.Contains('//')) { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    return $normalized
}

function Resolve-Pa5MetadataReference {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$Reference,[Parameter(Mandatory)][string]$Field)
    $relative = ConvertTo-Pa5CanonicalRelativePath -Value $Reference -Field $Field
    $coordinationRoot = Assert-Pa5Directory -Path (Join-Path $TaskRoot '.coord-local')
    $candidate = Join-Path $TaskRoot $relative
    if (-not (Test-Pa5PathWithin -Root $coordinationRoot -Candidate $candidate)) { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    return (Assert-Pa5RegularFile -Path $candidate)
}

function Resolve-Pa5ArtifactReference {
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$Reference,
        [Parameter(Mandatory)][string]$RequiredRootRelative,
        [Parameter(Mandatory)][string]$Field
    )
    $relative = ConvertTo-Pa5CanonicalRelativePath -Value $Reference -Field $Field
    $requiredRoot = ConvertTo-Pa5CanonicalRelativePath -Value $RequiredRootRelative -Field $Field
    if (-not $relative.StartsWith($requiredRoot + '/', [System.StringComparison]::Ordinal)) { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    $root = Assert-Pa5Directory -Path (Join-Path $TaskRoot $requiredRoot)
    $candidate = Join-Path $TaskRoot $relative
    if (-not (Test-Pa5PathWithin -Root $root -Candidate $candidate)) { Throw-Pa5Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    return (Assert-Pa5RegularFile -Path $candidate)
}

function Assert-Pa5HolderNotDemonstrablyLive {
    param([Parameter(Mandatory)][object]$Lease)
    if ($Lease.holder -match '^pid:(\d+)$') {
        $holderPid = [int]$Matches[1]
        if ($null -ne (Get-Process -Id $holderPid -ErrorAction SilentlyContinue)) { Throw-Pa5Rejected 'LIVE_HOLDER' }
    }
}

function Assert-Pa5ProtectedGoal {
    param([Parameter(Mandatory)][object]$Lease,[Parameter(Mandatory)][object]$Goal,[Parameter(Mandatory)][object]$Budget,[Parameter(Mandatory)][string]$LeaseBudgetPath,[Parameter(Mandatory)][string]$GoalBudgetPath)
    if ($Goal.goal -cne $Lease.goal -or $Budget.goal -cne $Lease.goal -or $Budget.run_id -cne $Goal.run_id -or -not $LeaseBudgetPath.Equals($GoalBudgetPath, (Get-Pa5PathComparison))) { Throw-Pa5Rejected 'METADATA_BINDING' }
    $ordinary = $Goal.profile -ceq 'INTERACTIVE_REPOSITORY_V1' -and $Goal.authority_class -match '^A2(?:\b|\s)' -and $Goal.current_layer -match '^L[0-2]$' -and $Goal.max_admitted_layer -match '^L[0-2]$'
    if ($ordinary) { Throw-Pa5Rejected 'ORDINARY_DEVELOPMENT_LEASE' }
    if ($Goal.profile -cne 'PROTECTED_TRANSACTION_V2' -or $Goal.authority_class -cne 'A5' -or $Goal.elasticity_grade -cne 'B4' -or $Goal.current_layer -notin @('L4','L5') -or $Goal.max_admitted_layer -cne 'L5' -or $Goal.protected_boundaries.Count -eq 0 -or $Goal.owner_only_boundaries.Count -eq 0) {
        Throw-Pa5Rejected 'PROTECTED_A5_REQUIRED'
    }
}

function Get-Pa5Metadata {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][object]$Lease)
    $goalPath = Resolve-Pa5MetadataReference -TaskRoot $TaskRoot -Reference $Lease.goal_ref -Field 'goal_ref'
    $budgetPath = Resolve-Pa5MetadataReference -TaskRoot $TaskRoot -Reference $Lease.budget_state_ref -Field 'budget_state_ref'
    $goalRecord = Read-Pa5Goal -Path $goalPath
    $goalBudgetPath = Resolve-Pa5MetadataReference -TaskRoot $TaskRoot -Reference $goalRecord.value.budget_state_ref -Field 'goal_budget_state_ref'
    $budgetRecord = Read-Pa5Budget -Path $budgetPath
    Assert-Pa5ProtectedGoal -Lease $Lease -Goal $goalRecord.value -Budget $budgetRecord.value -LeaseBudgetPath $budgetPath -GoalBudgetPath $goalBudgetPath
    return [pscustomobject]@{ goal=$goalRecord.value; budget=$budgetRecord.value; goal_path=$goalRecord.path; budget_path=$budgetRecord.path; goal_sha256=$goalRecord.sha256; budget_sha256=$budgetRecord.sha256 }
}

function Get-Pa5LeasePaths {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath)
    $root = Assert-Pa5Directory -Path $TaskRoot
    $coordinationRoot = Assert-Pa5Directory -Path (Join-Path $root '.coord-local')
    $leaseDirectory = Assert-Pa5Directory -Path (Join-Path $coordinationRoot 'leases')
    $expected = Get-Pa5FullPath -Path (Join-Path $leaseDirectory 'taskroot-writer.active.json')
    $actual = Get-Pa5FullPath -Path $LeasePath
    if (-not $actual.Equals($expected, (Get-Pa5PathComparison))) { Throw-Pa5Rejected 'NONCANONICAL_LEASE_PATH' }
    return [pscustomobject]@{ task_root=$root; coordination_root=$coordinationRoot; lease_directory=$leaseDirectory; lease_path=$expected; source_relative_path='.coord-local/leases/taskroot-writer.active.json' }
}

function Get-Pa5HistoryPaths {
    param([Parameter(Mandatory)][object]$LeasePaths,[Parameter(Mandatory)][string]$ExpectedLeaseSha256)
    $root = Join-Path $LeasePaths.lease_directory 'history/protected-a5'
    $historicalRelative = '.coord-local/leases/history/protected-a5/leases/' + $ExpectedLeaseSha256 + '.writer-lease.v1.json'
    $receiptRelative = '.coord-local/leases/history/protected-a5/finalizations/' + $ExpectedLeaseSha256 + '.finalization.json'
    return [pscustomobject]@{
        root=$root; leases=(Join-Path $root 'leases'); finalizations=(Join-Path $root 'finalizations')
        lock_path=(Join-Path $root '.protected-a5-governance-finalization.lock')
        historical_path=(Join-Path $LeasePaths.task_root $historicalRelative); receipt_path=(Join-Path $LeasePaths.task_root $receiptRelative)
        historical_relative_path=$historicalRelative; receipt_relative_path=$receiptRelative
    }
}

function Ensure-Pa5HistoryDirectories {
    param([Parameter(Mandatory)][object]$HistoryPaths)
    foreach ($path in @($HistoryPaths.root,$HistoryPaths.leases,$HistoryPaths.finalizations)) {
        Assert-Pa5NoReparseExistingAncestors -Path $path | Out-Null
        [System.IO.Directory]::CreateDirectory($path) | Out-Null
        Assert-Pa5Directory -Path $path | Out-Null
    }
}

function Get-Pa5State {
    param([Parameter(Mandatory)][object]$LeasePaths,[Parameter(Mandatory)][object]$HistoryPaths)
    $active = Test-Path -LiteralPath $LeasePaths.lease_path -PathType Leaf
    $historical = Test-Path -LiteralPath $HistoryPaths.historical_path -PathType Leaf
    $receipt = Test-Path -LiteralPath $HistoryPaths.receipt_path -PathType Leaf
    if ($active -and -not $historical -and -not $receipt) { return 'ACTIVE' }
    if (-not $active -and $historical -and -not $receipt) { return 'RECOVERY_PENDING' }
    if (-not $active -and $historical -and $receipt) { return 'COMPLETE' }
    if ($active -and $historical) { Throw-Pa5Rejected 'IMMUTABLE_HISTORY_COLLISION' }
    if ($receipt) { Throw-Pa5Rejected 'CONFLICTING_FINALIZATION_RECEIPT' }
    Throw-Pa5Rejected 'ACTIVE_LEASE_MISSING'
}

function Assert-Pa5NoFinalizationInProgress {
    param([Parameter(Mandatory)][object]$HistoryPaths)
    if (-not (Test-Path -LiteralPath $HistoryPaths.lock_path)) { return }
    $lockPath = Assert-Pa5RegularFile -Path $HistoryPaths.lock_path
    $probe = $null
    try { $probe = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-Pa5Rejected 'FINALIZATION_IN_PROGRESS' }
    finally { if ($null -ne $probe) { $probe.Dispose() } }
}

function Read-Pa5Authorization {
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$AuthorizationPath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][DateTimeOffset]$ReferenceUtc,
        [switch]$RequireCurrent
    )
    if ([string]::IsNullOrWhiteSpace($AuthorizationPath)) { Throw-Pa5Rejected 'AUTHORIZATION_REQUIRED' }
    $authorizationRoot = Assert-Pa5Directory -Path (Join-Path $TaskRoot '.coord-local/authorizations')
    $path = Assert-Pa5RegularFile -Path $AuthorizationPath
    if (-not (Test-Pa5PathWithin -Root $authorizationRoot -Candidate $path)) { Throw-Pa5Rejected 'AUTHORIZATION_PATH' }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $checked = Get-Pa5StrictJsonRoot -Bytes $bytes -Expected $script:Pa5AuthorizationFields -FailureCode 'MALFORMED_AUTHORIZATION'
    try {
        $p = $checked.Properties
        $authorization = [pscustomobject]@{}
        foreach ($name in $script:Pa5AuthorizationFields.Keys) { $authorization | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString() }
    }
    finally { $checked.Document.Dispose() }
    if ($authorization.schema -cne 'protected-a5-governance-finalization-authorization.v1' -or $authorization.authorization_scope -cne 'PROTECTED_A5_GOVERNANCE_FINALIZE' -or $authorization.authorized_by -cne 'OWNER') { Throw-Pa5Rejected 'AUTHORIZATION_REQUIRED' }
    Assert-Pa5SafeIdentifier -Value $authorization.authorization_id -Field 'authorization_id'
    foreach ($pair in @(@{v=$authorization.expected_lease_sha256;n='expected_lease_sha256'},@{v=$authorization.expected_goal_metadata_sha256;n='expected_goal_metadata_sha256'},@{v=$authorization.expected_budget_metadata_sha256;n='expected_budget_metadata_sha256'},@{v=$authorization.expected_finalization_evidence_sha256;n='expected_finalization_evidence_sha256'},@{v=$authorization.expected_reconciliation_receipt_sha256;n='expected_reconciliation_receipt_sha256'},@{v=$authorization.expected_independent_verifier_receipt_sha256;n='expected_independent_verifier_receipt_sha256'})) { Assert-Pa5Sha256 -Value $pair.v -Field $pair.n }
    if ($authorization.expected_lease_sha256 -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'AUTHORIZATION_LEASE_BINDING' }
    foreach ($pair in @(@{v=$authorization.expected_goal;n='expected_goal'},@{v=$authorization.expected_run_id;n='expected_run_id'},@{v=$authorization.transaction_id;n='transaction_id'})) { Assert-Pa5SafeIdentifier -Value $pair.v -Field $pair.n }
    if ((ConvertTo-Pa5CanonicalRelativePath -Value $authorization.task_root_relative_lease_path -Field 'task_root_relative_lease_path') -cne '.coord-local/leases/taskroot-writer.active.json') { Throw-Pa5Rejected 'AUTHORIZATION_LEASE_PATH' }
    if ($authorization.expected_terminal_result -cne 'FAILED_BEFORE_CONFIG') { Throw-Pa5Rejected 'UNSUPPORTED_TERMINAL_RESULT' }
    if ($authorization.expected_terminal_failure_code -cne 'OWNER_ABORTED_PREPARED') { Throw-Pa5Rejected 'UNSUPPORTED_TERMINAL_FAILURE_CODE' }
    $authorized = ConvertTo-Pa5Utc -Value $authorization.authorized_utc -Field 'authorization_authorized_utc'
    $expires = ConvertTo-Pa5Utc -Value $authorization.expires_utc -Field 'authorization_expires_utc'
    if ($authorized -ge $expires -or ($expires - $authorized).TotalMinutes -gt 30) { Throw-Pa5Rejected 'AUTHORIZATION_EXPIRED_OR_UNBOUNDED' }
    if ($RequireCurrent) {
        if ($authorized -gt $ReferenceUtc.ToUniversalTime() -or $expires -le $ReferenceUtc.ToUniversalTime()) { Throw-Pa5Rejected 'AUTHORIZATION_EXPIRED_OR_UNBOUNDED' }
    }
    elseif ($authorized -gt $ReferenceUtc.ToUniversalTime() -or $expires -le $ReferenceUtc.ToUniversalTime()) { Throw-Pa5Rejected 'AUTHORIZATION_NOT_VALID_AT_FINALIZATION' }
    return [pscustomobject]@{ value=$authorization; path=$path; sha256=(Get-Pa5BytesSha256 -Bytes $bytes); authorized=$authorized; expires=$expires }
}

function Read-Pa5Evidence {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][object]$Authorization,[Parameter(Mandatory)][DateTimeOffset]$NowUtc)
    $auth = $Authorization.value
    $path = Resolve-Pa5ArtifactReference -TaskRoot $TaskRoot -Reference $auth.finalization_evidence_path -RequiredRootRelative '.coord-local/finalization-evidence' -Field 'finalization_evidence_path'
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $digest = Get-Pa5BytesSha256 -Bytes $bytes
    if ($digest -cne $auth.expected_finalization_evidence_sha256) { Throw-Pa5Rejected 'FINALIZATION_EVIDENCE_SHA256' }
    $checked = Get-Pa5StrictJsonRoot -Bytes $bytes -Expected $script:Pa5EvidenceFields -FailureCode 'MALFORMED_FINALIZATION_EVIDENCE'
    try {
        $p = $checked.Properties
        $evidence = [pscustomobject]@{}
        foreach ($name in $script:Pa5EvidenceFields.Keys) {
            $value = if ($script:Pa5EvidenceFields[$name] -eq 'Boolean') { $p[$name].GetBoolean() } else { $p[$name].GetString() }
            $evidence | Add-Member -NotePropertyName $name -NotePropertyValue $value
        }
    }
    finally { $checked.Document.Dispose() }
    if ($evidence.schema -cne 'protected-a5-finalization-evidence.v1') { Throw-Pa5Rejected 'MALFORMED_FINALIZATION_EVIDENCE' }
    Assert-Pa5SafeIdentifier -Value $evidence.evidence_id -Field 'evidence_id'
    $created = ConvertTo-Pa5Utc -Value $evidence.created_utc -Field 'evidence_created_utc'
    if ($created -gt $NowUtc.ToUniversalTime()) { Throw-Pa5Rejected 'FUTURE_FINALIZATION_EVIDENCE' }
    foreach ($pair in @(@{v=$evidence.expected_lease_sha256;n='expected_lease_sha256'},@{v=$evidence.goal_metadata_sha256;n='goal_metadata_sha256'},@{v=$evidence.budget_metadata_sha256;n='budget_metadata_sha256'},@{v=$evidence.reconciliation_receipt_sha256;n='reconciliation_receipt_sha256'},@{v=$evidence.independent_verifier_receipt_sha256;n='independent_verifier_receipt_sha256'})) { Assert-Pa5Sha256 -Value $pair.v -Field $pair.n }
    if ($evidence.expected_lease_sha256 -cne $auth.expected_lease_sha256 -or $evidence.goal -cne $auth.expected_goal -or $evidence.run_id -cne $auth.expected_run_id -or $evidence.goal_metadata_sha256 -cne $auth.expected_goal_metadata_sha256 -or $evidence.budget_metadata_sha256 -cne $auth.expected_budget_metadata_sha256 -or $evidence.transaction_id -cne $auth.transaction_id) { Throw-Pa5Rejected 'FINALIZATION_EVIDENCE_BINDING' }
    if ($evidence.terminal_result -cne $auth.expected_terminal_result) { Throw-Pa5Rejected 'TERMINAL_RESULT_MISMATCH' }
    if ($evidence.terminal_failure_code -cne $auth.expected_terminal_failure_code) { Throw-Pa5Rejected 'TERMINAL_FAILURE_CODE_MISMATCH' }
    if (-not $evidence.transaction_terminal) { Throw-Pa5Rejected 'NONTERMINAL_TRANSACTION' }
    if ($evidence.terminal_result -cne 'FAILED_BEFORE_CONFIG' -or $evidence.terminal_failure_code -cne 'OWNER_ABORTED_PREPARED') { Throw-Pa5Rejected 'UNSUPPORTED_TERMINAL_CLASS' }
    if ($evidence.reconciliation_status -cne 'PASS') { Throw-Pa5Rejected 'RECONCILIATION_NOT_PASS' }
    if ($evidence.final_supervisor_status -cne 'PASS') { Throw-Pa5Rejected 'INDEPENDENT_VERIFIER_NOT_PASS' }
    if (-not $evidence.fresh_transaction_evidence -or $evidence.live_prestate_status -cne 'EXACT' -or $evidence.configuration_mutation_status -cne 'NONE_UNRESOLVED' -or $evidence.rollback_packet_status -cne 'VALIDATED_WHERE_RELEVANT' -or $evidence.rollback_status -cne 'NOT_REQUIRED') { Throw-Pa5Rejected 'FAILED_BEFORE_CONFIG_EVIDENCE' }
    if (-not $evidence.no_unresolved_protected_mutation -or -not $evidence.no_contradictory_later_transaction_evidence -or -not $evidence.no_fabricated_historical_receipt -or $evidence.unresolved_rollback) { Throw-Pa5Rejected 'UNRESOLVED_PROTECTED_STATE' }
    if ($evidence.conflicting_evidence) { Throw-Pa5Rejected 'CONFLICTING_EVIDENCE' }
    if ($evidence.accepted_target_status -cne 'NOT_APPLICABLE' -or $evidence.final_protected_verification_status -cne 'NOT_APPLICABLE') { Throw-Pa5Rejected 'FAILED_BEFORE_CONFIG_EVIDENCE' }
    if ($evidence.reconciliation_receipt_path -cne $auth.reconciliation_receipt_path -or $evidence.reconciliation_receipt_sha256 -cne $auth.expected_reconciliation_receipt_sha256 -or $evidence.independent_verifier_receipt_path -cne $auth.independent_verifier_receipt_path -or $evidence.independent_verifier_receipt_sha256 -cne $auth.expected_independent_verifier_receipt_sha256) { Throw-Pa5Rejected 'RECEIPT_AUTHORIZATION_BINDING' }
    $reconciliationPath = Resolve-Pa5ArtifactReference -TaskRoot $TaskRoot -Reference $evidence.reconciliation_receipt_path -RequiredRootRelative '.coord-local/receipts' -Field 'reconciliation_receipt_path'
    $verifierPath = Resolve-Pa5ArtifactReference -TaskRoot $TaskRoot -Reference $evidence.independent_verifier_receipt_path -RequiredRootRelative '.coord-local/receipts' -Field 'independent_verifier_receipt_path'
    $reconciliationSha = Get-Pa5BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($reconciliationPath))
    $verifierSha = Get-Pa5BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($verifierPath))
    if ($reconciliationSha -cne $evidence.reconciliation_receipt_sha256) { Throw-Pa5Rejected 'RECONCILIATION_RECEIPT_SHA256' }
    if ($verifierSha -cne $evidence.independent_verifier_receipt_sha256) { Throw-Pa5Rejected 'INDEPENDENT_VERIFIER_RECEIPT_SHA256' }
    return [pscustomobject]@{ value=$evidence; path=$path; sha256=$digest; reconciliation_path=$reconciliationPath; reconciliation_sha256=$reconciliationSha; verifier_path=$verifierPath; verifier_sha256=$verifierSha }
}

function Get-Pa5AdmissionFromLeaseFile {
    param(
        [Parameter(Mandatory)][object]$LeasePaths,
        [Parameter(Mandatory)][string]$LeaseFilePath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][AllowEmptyString()][string]$AuthorizationPath,
        [Parameter(Mandatory)][DateTimeOffset]$NowUtc
    )
    Assert-Pa5Sha256 -Value $ExpectedLeaseSha256 -Field 'expected_lease_sha256'
    $leaseFile = Assert-Pa5RegularFile -Path $LeaseFilePath
    $leaseBytes = [System.IO.File]::ReadAllBytes($leaseFile)
    $leaseSha = Get-Pa5BytesSha256 -Bytes $leaseBytes
    if ($leaseSha -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'LEASE_CONTENT_DRIFT' }
    $lease = Read-Pa5Lease -Bytes $leaseBytes
    Assert-Pa5HolderNotDemonstrablyLive -Lease $lease
    $metadata = Get-Pa5Metadata -TaskRoot $LeasePaths.task_root -Lease $lease
    $authorization = Read-Pa5Authorization -TaskRoot $LeasePaths.task_root -AuthorizationPath $AuthorizationPath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -ReferenceUtc $NowUtc -RequireCurrent
    $auth = $authorization.value
    if ($auth.expected_goal -cne $metadata.goal.goal -or $auth.expected_run_id -cne $metadata.goal.run_id -or $auth.expected_goal_metadata_sha256 -cne $metadata.goal_sha256 -or $auth.expected_budget_metadata_sha256 -cne $metadata.budget_sha256) { Throw-Pa5Rejected 'AUTHORIZATION_METADATA_BINDING' }
    $evidence = Read-Pa5Evidence -TaskRoot $LeasePaths.task_root -Authorization $authorization -NowUtc $NowUtc
    return [pscustomobject]@{
        lease=$lease; lease_path=$leaseFile; lease_sha256=$leaseSha; metadata=$metadata; authorization=$authorization; evidence=$evidence
        transaction_id=$auth.transaction_id; terminal_result=$auth.expected_terminal_result; terminal_failure_code=$auth.expected_terminal_failure_code
    }
}

function Compare-Pa5Admissions {
    param([Parameter(Mandatory)][object]$Initial,[Parameter(Mandatory)][object]$Recheck)
    $left = @($Initial.lease_sha256,$Initial.metadata.goal_sha256,$Initial.metadata.budget_sha256,$Initial.authorization.sha256,$Initial.evidence.sha256,$Initial.evidence.reconciliation_sha256,$Initial.evidence.verifier_sha256)
    $right = @($Recheck.lease_sha256,$Recheck.metadata.goal_sha256,$Recheck.metadata.budget_sha256,$Recheck.authorization.sha256,$Recheck.evidence.sha256,$Recheck.evidence.reconciliation_sha256,$Recheck.evidence.verifier_sha256)
    for ($i=0; $i -lt $left.Count; $i++) { if ($left[$i] -cne $right[$i]) { Throw-Pa5Rejected 'ADMISSION_INPUT_DRIFT' } }
}

function Enter-Pa5FinalizationLock {
    param([Parameter(Mandatory)][object]$HistoryPaths)
    Assert-Pa5NoReparseExistingAncestors -Path $HistoryPaths.lock_path | Out-Null
    try { return [System.IO.File]::Open($HistoryPaths.lock_path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-Pa5Rejected 'FINALIZATION_IN_PROGRESS' }
}

function Write-Pa5ImmutableJson {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Value)
    Assert-Pa5Directory -Path (Split-Path -Parent $Path) | Out-Null
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes(($Value | ConvertTo-Json -Depth 12 -Compress))
    $temporaryPath = $Path + '.next.' + [guid]::NewGuid().ToString('N')
    try {
        $stream = [System.IO.File]::Open($temporaryPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
        finally { $stream.Dispose() }
        try { [System.IO.File]::Move($temporaryPath, $Path) }
        catch [System.IO.IOException] { Throw-Pa5Rejected 'IMMUTABLE_RECEIPT_COLLISION' }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) { [System.IO.File]::Delete($temporaryPath) }
    }
    $item = Get-Item -LiteralPath $Path -Force
    $item.Attributes = ($item.Attributes -bor [System.IO.FileAttributes]::ReadOnly)
    Assert-Pa5RegularFile -Path $Path | Out-Null
}

function Read-Pa5Receipt {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes((Assert-Pa5RegularFile -Path $Path))
    $checked = Get-Pa5StrictJsonRoot -Bytes $bytes -Expected $script:Pa5ReceiptFields -FailureCode 'HISTORY_INTEGRITY'
    try {
        $p = $checked.Properties
        $receipt = [pscustomobject]@{}
        foreach ($name in $script:Pa5ReceiptFields.Keys) {
            $value = if ($script:Pa5ReceiptFields[$name] -eq 'Boolean') { $p[$name].GetBoolean() } else { $p[$name].GetString() }
            $receipt | Add-Member -NotePropertyName $name -NotePropertyValue $value
        }
        return $receipt
    }
    finally { $checked.Document.Dispose() }
}

function Get-Pa5CompleteFinalization {
    param([Parameter(Mandatory)][object]$LeasePaths,[Parameter(Mandatory)][object]$HistoryPaths,[Parameter(Mandatory)][string]$ExpectedLeaseSha256,[Parameter(Mandatory)][AllowEmptyString()][string]$AuthorizationPath,[Parameter(Mandatory)][DateTimeOffset]$NowUtc)
    if (Test-Path -LiteralPath $LeasePaths.lease_path) { Throw-Pa5Rejected 'ACTIVE_MARKER_REMAINS' }
    $historical = Assert-Pa5RegularFile -Path $HistoryPaths.historical_path
    if ((Get-Pa5BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historical))) -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'HISTORY_INTEGRITY' }
    $receipt = Read-Pa5Receipt -Path $HistoryPaths.receipt_path
    $finalized = ConvertTo-Pa5Utc -Value $receipt.finalized_utc -Field 'receipt_finalized_utc'
    $authorization = Read-Pa5Authorization -TaskRoot $LeasePaths.task_root -AuthorizationPath $AuthorizationPath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -ReferenceUtc $finalized
    $evidence = Read-Pa5Evidence -TaskRoot $LeasePaths.task_root -Authorization $authorization -NowUtc $NowUtc
    $expected = [ordered]@{
        schema='protected-a5-governance-finalization-receipt.v1'; finalization_id=('sha256-' + $ExpectedLeaseSha256)
        finalization_status='PROTECTED_A5_GOVERNANCE_RELEASED'; transaction_id=$authorization.value.transaction_id
        terminal_result=$authorization.value.expected_terminal_result; terminal_failure_code=$authorization.value.expected_terminal_failure_code
        goal=$authorization.value.expected_goal; run_id=$authorization.value.expected_run_id; source_relative_path=$LeasePaths.source_relative_path
        historical_relative_path=$HistoryPaths.historical_relative_path; original_lease_schema='jpc.taskroot-writer-lease.v1'
        original_lease_sha256=$ExpectedLeaseSha256; goal_metadata_sha256=$authorization.value.expected_goal_metadata_sha256
        budget_metadata_sha256=$authorization.value.expected_budget_metadata_sha256; authorization_sha256=$authorization.sha256
        finalization_evidence_sha256=$evidence.sha256; reconciliation_receipt_sha256=$evidence.reconciliation_sha256
        independent_verifier_receipt_sha256=$evidence.verifier_sha256
    }
    foreach ($name in $expected.Keys) { if ([string]$receipt.$name -cne [string]$expected[$name]) { Throw-Pa5Rejected 'HISTORY_INTEGRITY' } }
    if ($receipt.production_transaction_mutated) { Throw-Pa5Rejected 'HISTORY_INTEGRITY' }
    return [pscustomobject]@{ receipt=$receipt; authorization=$authorization; evidence=$evidence; historical_path=$historical; receipt_path=(Assert-Pa5RegularFile -Path $HistoryPaths.receipt_path) }
}

function Test-ProtectedA5GovernanceFinalizationAdmission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [string]$AuthorizationPath = '',
        [DateTimeOffset]$NowUtc = [DateTimeOffset]::UtcNow
    )
    try {
        $leasePaths = Get-Pa5LeasePaths -TaskRoot $TaskRoot -LeasePath $LeasePath
        $historyPaths = Get-Pa5HistoryPaths -LeasePaths $leasePaths -ExpectedLeaseSha256 $ExpectedLeaseSha256
        if ((Get-Pa5State -LeasePaths $leasePaths -HistoryPaths $historyPaths) -cne 'ACTIVE') { Throw-Pa5Rejected 'ACTIVE_LEASE_REQUIRED' }
        Assert-Pa5NoFinalizationInProgress -HistoryPaths $historyPaths
        $admission = Get-Pa5AdmissionFromLeaseFile -LeasePaths $leasePaths -LeaseFilePath $leasePaths.lease_path -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath -NowUtc $NowUtc
        return [pscustomobject]@{ status='FINALIZATION_ADMISSION_ACCEPTED'; transaction_id=$admission.transaction_id; terminal_result=$admission.terminal_result; terminal_failure_code=$admission.terminal_failure_code; lease_sha256=$admission.lease_sha256; active_lease=$true; production_transaction_mutated=$false }
    }
    catch {
        $status = [string]$_.Exception.Message
        if ($status -notmatch '^FINALIZATION_REJECTED_[A-Z0-9_]+$') { $status='FINALIZATION_REJECTED_INTERNAL' }
        return [pscustomobject]@{ status=$status; transaction_id=''; terminal_result=''; terminal_failure_code=''; lease_sha256=''; active_lease=(Test-Path -LiteralPath $LeasePath -PathType Leaf); production_transaction_mutated=$false }
    }
}

function Invoke-ProtectedA5GovernanceFinalizationInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [string]$AuthorizationPath = '',
        [DateTimeOffset]$NowUtc = [DateTimeOffset]::UtcNow,
        [scriptblock]$BeforeLockHook = $null,
        [ValidateSet('','AfterArchive')][string]$FaultInjection = ''
    )
    try {
        Assert-Pa5Sha256 -Value $ExpectedLeaseSha256 -Field 'expected_lease_sha256'
        $leasePaths = Get-Pa5LeasePaths -TaskRoot $TaskRoot -LeasePath $LeasePath
        $historyPaths = Get-Pa5HistoryPaths -LeasePaths $leasePaths -ExpectedLeaseSha256 $ExpectedLeaseSha256
        $state = Get-Pa5State -LeasePaths $leasePaths -HistoryPaths $historyPaths
        if ($state -ceq 'COMPLETE') {
            $complete = Get-Pa5CompleteFinalization -LeasePaths $leasePaths -HistoryPaths $historyPaths -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath -NowUtc $NowUtc
            return [pscustomobject]@{ status='FINALIZATION_ALREADY_COMPLETE'; finalization_status=$complete.receipt.finalization_status; historical_lease_path=$complete.historical_path; receipt_path=$complete.receipt_path; active_lease=$false; production_transaction_mutated=$false }
        }
        Assert-Pa5NoFinalizationInProgress -HistoryPaths $historyPaths
        $sourcePath = if ($state -ceq 'ACTIVE') { $leasePaths.lease_path } else { $historyPaths.historical_path }
        $initial = Get-Pa5AdmissionFromLeaseFile -LeasePaths $leasePaths -LeaseFilePath $sourcePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath -NowUtc $NowUtc
        if ($null -ne $BeforeLockHook) { & $BeforeLockHook }
        Ensure-Pa5HistoryDirectories -HistoryPaths $historyPaths
        $lock = Enter-Pa5FinalizationLock -HistoryPaths $historyPaths
        try {
            $lockedState = Get-Pa5State -LeasePaths $leasePaths -HistoryPaths $historyPaths
            if ($lockedState -cne $state) { Throw-Pa5Rejected 'FINALIZATION_STATE_DRIFT' }
            $lockedSource = if ($lockedState -ceq 'ACTIVE') { $leasePaths.lease_path } else { $historyPaths.historical_path }
            $recheck = Get-Pa5AdmissionFromLeaseFile -LeasePaths $leasePaths -LeaseFilePath $lockedSource -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath -NowUtc $NowUtc
            Compare-Pa5Admissions -Initial $initial -Recheck $recheck
            if ($lockedState -ceq 'ACTIVE') {
                if (Test-Path -LiteralPath $historyPaths.historical_path) { Throw-Pa5Rejected 'IMMUTABLE_HISTORY_COLLISION' }
                if (Test-Path -LiteralPath $historyPaths.receipt_path) { Throw-Pa5Rejected 'CONFLICTING_FINALIZATION_RECEIPT' }
                $immediateBytes = [System.IO.File]::ReadAllBytes((Assert-Pa5RegularFile -Path $leasePaths.lease_path))
                if ((Get-Pa5BytesSha256 -Bytes $immediateBytes) -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'LEASE_CONTENT_DRIFT' }
                [System.IO.File]::Move($leasePaths.lease_path, $historyPaths.historical_path)
                if (Test-Path -LiteralPath $leasePaths.lease_path) { Throw-Pa5Rejected 'ACTIVE_MARKER_REMAINS' }
                $historicalItem = Get-Item -LiteralPath $historyPaths.historical_path -Force
                $historicalItem.Attributes = ($historicalItem.Attributes -bor [System.IO.FileAttributes]::ReadOnly)
                $historicalBytes = [System.IO.File]::ReadAllBytes((Assert-Pa5RegularFile -Path $historyPaths.historical_path))
                if ((Get-Pa5BytesSha256 -Bytes $historicalBytes) -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'HISTORY_INTEGRITY' }
                if ($FaultInjection -ceq 'AfterArchive') { Throw-Pa5Rejected 'FAULT_INJECTED_AFTER_ARCHIVE' }
            }
            elseif ((Test-Path -LiteralPath $leasePaths.lease_path -PathType Leaf) -or (Test-Path -LiteralPath $historyPaths.receipt_path -PathType Leaf)) { Throw-Pa5Rejected 'FINALIZATION_STATE_DRIFT' }
            else {
                $historicalItem = Get-Item -LiteralPath $historyPaths.historical_path -Force
                $historicalItem.Attributes = ($historicalItem.Attributes -bor [System.IO.FileAttributes]::ReadOnly)
                if ((Get-Pa5BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historyPaths.historical_path))) -cne $ExpectedLeaseSha256) { Throw-Pa5Rejected 'HISTORY_INTEGRITY' }
            }
            $finalizedUtc = [DateTimeOffset]::UtcNow
            if ($recheck.authorization.authorized -gt $finalizedUtc -or $recheck.authorization.expires -le $finalizedUtc) { Throw-Pa5Rejected 'AUTHORIZATION_EXPIRED_OR_UNBOUNDED' }
            $receipt = [ordered]@{
                schema='protected-a5-governance-finalization-receipt.v1'; finalization_id=('sha256-' + $ExpectedLeaseSha256)
                finalization_status='PROTECTED_A5_GOVERNANCE_RELEASED'; finalized_utc=$finalizedUtc.ToString('o')
                transaction_id=$recheck.transaction_id; terminal_result=$recheck.terminal_result; terminal_failure_code=$recheck.terminal_failure_code
                goal=$recheck.metadata.goal.goal; run_id=$recheck.metadata.goal.run_id; source_relative_path=$leasePaths.source_relative_path
                historical_relative_path=$historyPaths.historical_relative_path; original_lease_schema=$recheck.lease.schema
                original_lease_sha256=$ExpectedLeaseSha256; goal_metadata_sha256=$recheck.metadata.goal_sha256; budget_metadata_sha256=$recheck.metadata.budget_sha256
                authorization_sha256=$recheck.authorization.sha256; finalization_evidence_sha256=$recheck.evidence.sha256
                reconciliation_receipt_sha256=$recheck.evidence.reconciliation_sha256; independent_verifier_receipt_sha256=$recheck.evidence.verifier_sha256
                production_transaction_mutated=$false
            }
            Write-Pa5ImmutableJson -Path $historyPaths.receipt_path -Value $receipt
            $complete = Get-Pa5CompleteFinalization -LeasePaths $leasePaths -HistoryPaths $historyPaths -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath -NowUtc $NowUtc
            return [pscustomobject]@{ status='PROTECTED_A5_GOVERNANCE_RELEASED'; finalization_status=$complete.receipt.finalization_status; historical_lease_path=$complete.historical_path; receipt_path=$complete.receipt_path; active_lease=$false; production_transaction_mutated=$false }
        }
        finally { $lock.Dispose() }
    }
    catch {
        $status = [string]$_.Exception.Message
        if ($status -notmatch '^FINALIZATION_REJECTED_[A-Z0-9_]+$') { $status='FINALIZATION_REJECTED_INTERNAL' }
        return [pscustomobject]@{ status=$status; finalization_status='REJECTED'; historical_lease_path=''; receipt_path=''; active_lease=(Test-Path -LiteralPath $LeasePath -PathType Leaf); production_transaction_mutated=$false }
    }
}

function Invoke-ProtectedA5GovernanceFinalization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [string]$AuthorizationPath = ''
    )
    return Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -AuthorizationPath $AuthorizationPath
}

Export-ModuleMember -Function @(
    'Invoke-ProtectedA5GovernanceFinalization',
    'Test-ProtectedA5GovernanceFinalizationAdmission'
)
