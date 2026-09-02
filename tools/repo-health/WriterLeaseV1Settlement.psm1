Set-StrictMode -Version Latest

$script:Wlv1LeaseFields = [ordered]@{
    schema = 'String'; goal = 'String'; holder = 'String'; holder_session = 'String'; state = 'String'
    acquired_utc = 'String'; created_utc = 'String'; hard_stop_utc = 'String'; single_intentional_writer = 'True'
    scope = 'StringArray'; goal_ref = 'String'; budget_state_ref = 'String'
}

$script:Wlv1GoalFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; profile = 'String'; authority_class = 'String'
    elasticity_grade = 'String'; initial_progress_state = 'String'; current_layer = 'String'; max_admitted_layer = 'String'
    next_proof_vector = 'String'; allowed_repositories = 'StringArray'; allowed_paths = 'StringArray'; allowed_services = 'StringArray'
    protected_boundaries = 'StringArray'; owner_only_boundaries = 'StringArray'; budget_overrides = 'Object'
    budget_state_ref = 'String'; last_accepted_checkpoint = 'String'; context_modules = 'StringArray'; stop_conditions = 'StringArray'; created_utc = 'String'
}

$script:Wlv1BudgetFields = [ordered]@{ schema = 'String'; goal = 'String'; run_id = 'String'; created_utc = 'String'; domains = 'Object' }
$script:Wlv1AuthorizationFields = [ordered]@{
    schema = 'String'; authorization_id = 'String'; authorization_scope = 'String'; task_root_relative_lease_path = 'String'
    expected_lease_sha256 = 'String'; authorized_by = 'String'; authorized_utc = 'String'; expires_utc = 'String'
}
$script:Wlv1SettlementReceiptFields = [ordered]@{
    schema = 'String'; settlement_id = 'String'; settlement_kind = 'String'; settlement_status = 'String'; settled_utc = 'String'
    source_relative_path = 'String'; historical_relative_path = 'String'; original_lease_schema = 'String'
    original_lease_sha256 = 'String'; authorization_sha256 = 'String'
}
$script:Wlv1NormalReturnReceiptFields = [ordered]@{
    schema = 'String'; normal_return_id = 'String'; normal_return_status = 'String'; outcome = 'String'; recorded_utc = 'String'
    source_relative_path = 'String'; historical_relative_path = 'String'; original_lease_schema = 'String'
    original_lease_sha256 = 'String'; holder_session = 'String'
}

function Throw-Wlv1Rejected {
    param([Parameter(Mandatory)][string]$Code)
    throw ('SETTLEMENT_REJECTED_' + $Code)
}

function Get-Wlv1BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Get-Wlv1FullPath {
    param([Parameter(Mandatory)][string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) }
    catch { Throw-Wlv1Rejected 'INVALID_PATH' }
}

function Test-Wlv1PathWithin {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Candidate)
    $fullRoot = (Get-Wlv1FullPath -Path $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullCandidate = Get-Wlv1FullPath -Path $Candidate
    if ($fullCandidate.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    return $fullCandidate.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-Wlv1NoReparseAncestors {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Get-Wlv1FullPath -Path $Path
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) { Throw-Wlv1Rejected 'INVALID_PATH' }
    $current = $root
    $tail = $fullPath.Substring($root.Length).Split(@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $tail) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { Throw-Wlv1Rejected 'PATH_MISSING' }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-Wlv1Rejected 'REPARSE_PATH' }
    }
    return $fullPath
}

function Assert-Wlv1Directory {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Wlv1NoReparseAncestors -Path $Path
    $item = Get-Item -LiteralPath $fullPath -Force
    if (-not ($item -is [System.IO.DirectoryInfo])) { Throw-Wlv1Rejected 'DIRECTORY_REQUIRED' }
    return $fullPath
}

function Assert-Wlv1RegularFile {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Wlv1NoReparseAncestors -Path $Path
    $item = Get-Item -LiteralPath $fullPath -Force
    if (-not ($item -is [System.IO.FileInfo])) { Throw-Wlv1Rejected 'REGULAR_FILE_REQUIRED' }
    return $fullPath
}

function Assert-Wlv1SafeIdentifier {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,191}$') { Throw-Wlv1Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function ConvertTo-Wlv1Utc {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact($Value, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        Throw-Wlv1Rejected ('MALFORMED_' + $Field.ToUpperInvariant())
    }
    return $parsed.ToUniversalTime()
}

function Get-Wlv1StrictJsonRoot {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][System.Collections.IDictionary]$Expected,[Parameter(Mandatory)][string]$FailureCode)
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 65536) { Throw-Wlv1Rejected $FailureCode }
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes) }
    catch { Throw-Wlv1Rejected $FailureCode }
    try { $document = [System.Text.Json.JsonDocument]::Parse($text) }
    catch { Throw-Wlv1Rejected $FailureCode }
    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) { Throw-Wlv1Rejected $FailureCode }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $properties = @{}
        foreach ($property in $root.EnumerateObject()) {
            if (-not $seen.Add($property.Name) -or -not $Expected.Contains($property.Name)) { Throw-Wlv1Rejected $FailureCode }
            $properties[$property.Name] = $property.Value
        }
        if ($properties.Count -ne $Expected.Count) { Throw-Wlv1Rejected $FailureCode }
        foreach ($entry in $Expected.GetEnumerator()) {
            if (-not $properties.ContainsKey($entry.Key)) { Throw-Wlv1Rejected $FailureCode }
            $kind = $properties[$entry.Key].ValueKind.ToString()
            if ($entry.Value -eq 'StringArray' -and $kind -ne 'Array') { Throw-Wlv1Rejected $FailureCode }
            if ($entry.Value -ne 'StringArray' -and $kind -ne $entry.Value) { Throw-Wlv1Rejected $FailureCode }
            if ($entry.Value -eq 'StringArray') {
                foreach ($element in $properties[$entry.Key].EnumerateArray()) {
                    if ($element.ValueKind -ne [System.Text.Json.JsonValueKind]::String) { Throw-Wlv1Rejected $FailureCode }
                }
            }
        }
        return [pscustomobject]@{ Document = $document; Properties = $properties }
    }
    catch {
        $document.Dispose()
        throw
    }
}

function Get-Wlv1StringArray {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Element)
    return @($Element.EnumerateArray() | ForEach-Object { $_.GetString() })
}

function Read-Wlv1Lease {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $checked = Get-Wlv1StrictJsonRoot -Bytes $Bytes -Expected $script:Wlv1LeaseFields -FailureCode 'MALFORMED_LEASE'
    try {
        $p = $checked.Properties
        $lease = [pscustomobject]@{
            schema = $p.schema.GetString(); goal = $p.goal.GetString(); holder = $p.holder.GetString(); holder_session = $p.holder_session.GetString(); state = $p.state.GetString()
            acquired_utc = $p.acquired_utc.GetString(); created_utc = $p.created_utc.GetString(); hard_stop_utc = $p.hard_stop_utc.GetString()
            single_intentional_writer = $p.single_intentional_writer.GetBoolean(); scope = @(Get-Wlv1StringArray -Element $p.scope)
            goal_ref = $p.goal_ref.GetString(); budget_state_ref = $p.budget_state_ref.GetString(); created = $null; acquired = $null; hard_stop = $null
        }
    }
    finally { $checked.Document.Dispose() }
    if ($lease.schema -ne 'jpc.taskroot-writer-lease.v1') { Throw-Wlv1Rejected 'UNSUPPORTED_SCHEMA' }
    foreach ($pair in @(@{v=$lease.goal;n='goal'}, @{v=$lease.holder_session;n='holder_session'})) { Assert-Wlv1SafeIdentifier -Value $pair.v -Field $pair.n }
    if ([string]::IsNullOrWhiteSpace($lease.holder) -or $lease.holder.Length -gt 191 -or $lease.holder -match '[\x00-\x1f]') { Throw-Wlv1Rejected 'MALFORMED_HOLDER' }
    if ($lease.state -cne 'active' -or -not $lease.single_intentional_writer) { Throw-Wlv1Rejected 'MALFORMED_LEASE' }
    if ($lease.scope.Count -eq 0 -or $lease.scope.Count -gt 32 -or @($lease.scope | Where-Object { [string]::IsNullOrWhiteSpace($_) -or $_.Length -gt 191 }).Count -ne 0) { Throw-Wlv1Rejected 'MALFORMED_SCOPE' }
    $lease.created = ConvertTo-Wlv1Utc -Value $lease.created_utc -Field 'created_utc'
    $lease.acquired = ConvertTo-Wlv1Utc -Value $lease.acquired_utc -Field 'acquired_utc'
    $lease.hard_stop = ConvertTo-Wlv1Utc -Value $lease.hard_stop_utc -Field 'hard_stop_utc'
    if ($lease.created -gt $lease.acquired -or $lease.acquired -gt $lease.hard_stop) { Throw-Wlv1Rejected 'MALFORMED_LEASE' }
    return $lease
}

function Read-Wlv1Goal {
    param([Parameter(Mandatory)][string]$Path)
    $checked = Get-Wlv1StrictJsonRoot -Bytes ([System.IO.File]::ReadAllBytes((Assert-Wlv1RegularFile -Path $Path))) -Expected $script:Wlv1GoalFields -FailureCode 'MALFORMED_GOAL_METADATA'
    try {
        $p = $checked.Properties
        $goal = [pscustomobject]@{ created = $null }
        foreach ($name in @('schema','goal','run_id','profile','authority_class','elasticity_grade','initial_progress_state','current_layer','max_admitted_layer','next_proof_vector','budget_state_ref','last_accepted_checkpoint','created_utc')) { $goal | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString() }
        foreach ($name in @('allowed_repositories','allowed_paths','allowed_services','protected_boundaries','owner_only_boundaries','context_modules','stop_conditions')) { $goal | Add-Member -NotePropertyName $name -NotePropertyValue @(Get-Wlv1StringArray -Element $p[$name]) }
    }
    finally { $checked.Document.Dispose() }
    if ($goal.schema -ne 'jpc.frozen-goal.v1') { Throw-Wlv1Rejected 'MALFORMED_GOAL_METADATA' }
    foreach ($pair in @(@{v=$goal.goal;n='goal'},@{v=$goal.run_id;n='run_id'})) { Assert-Wlv1SafeIdentifier -Value $pair.v -Field $pair.n }
    $goal.created = ConvertTo-Wlv1Utc -Value $goal.created_utc -Field 'goal_created_utc'
    return $goal
}

function Read-Wlv1Budget {
    param([Parameter(Mandatory)][string]$Path)
    $checked = Get-Wlv1StrictJsonRoot -Bytes ([System.IO.File]::ReadAllBytes((Assert-Wlv1RegularFile -Path $Path))) -Expected $script:Wlv1BudgetFields -FailureCode 'MALFORMED_BUDGET_METADATA'
    try {
        $p = $checked.Properties
        $budget = [pscustomobject]@{ schema=$p.schema.GetString(); goal=$p.goal.GetString(); run_id=$p.run_id.GetString(); created_utc=$p.created_utc.GetString(); created=$null }
    }
    finally { $checked.Document.Dispose() }
    if ($budget.schema -notmatch '^[a-z0-9.-]+\.budget\.v1$') { Throw-Wlv1Rejected 'MALFORMED_BUDGET_METADATA' }
    foreach ($pair in @(@{v=$budget.goal;n='budget_goal'},@{v=$budget.run_id;n='budget_run_id'})) { Assert-Wlv1SafeIdentifier -Value $pair.v -Field $pair.n }
    $budget.created = ConvertTo-Wlv1Utc -Value $budget.created_utc -Field 'budget_created_utc'
    return $budget
}

function Resolve-Wlv1MetadataReference {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$Reference,[Parameter(Mandatory)][string]$Field)
    if ([System.IO.Path]::IsPathRooted($Reference) -or $Reference -match '(^|[\\/])\.\.([\\/]|$)' -or $Reference -match ':') { Throw-Wlv1Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    $coordinationRoot = Assert-Wlv1Directory -Path (Join-Path $TaskRoot '.coord-local')
    $candidate = Join-Path $TaskRoot $Reference
    if (-not (Test-Wlv1PathWithin -Root $coordinationRoot -Candidate $candidate)) { Throw-Wlv1Rejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
    return (Assert-Wlv1RegularFile -Path $candidate)
}

function Assert-Wlv1OrdinaryDevelopmentGoal {
    param([Parameter(Mandatory)][object]$Lease,[Parameter(Mandatory)][object]$Goal,[Parameter(Mandatory)][object]$Budget,[Parameter(Mandatory)][string]$LeaseBudgetPath,[Parameter(Mandatory)][string]$GoalBudgetPath)
    if ($Goal.goal -ne $Lease.goal -or $Budget.goal -ne $Lease.goal -or $Budget.run_id -ne $Goal.run_id -or $LeaseBudgetPath -ne $GoalBudgetPath) { Throw-Wlv1Rejected 'MALFORMED_METADATA_BINDING' }
    $looksProtected = $Goal.profile -match '(?i)PROTECTED|TRANSACTION|PRODUCTION' -or $Goal.authority_class -match '^A[45](?:\b|\s)' -or $Goal.max_admitted_layer -match '^L[4-9]$' -or $Goal.current_layer -match '^L[4-9]$' -or $Goal.protected_boundaries.Count -ne 0 -or $Goal.owner_only_boundaries.Count -ne 0 -or $Goal.allowed_services.Count -ne 0 -or @($Lease.scope | Where-Object { $_ -match '(?i)production|protected|transaction' }).Count -ne 0
    if ($looksProtected) { Throw-Wlv1Rejected 'PRODUCTION_ATTACHED' }
    if ($Goal.profile -cne 'INTERACTIVE_REPOSITORY_V1' -or $Goal.authority_class -notmatch '^A2(?:\b|\s)' -or $Goal.elasticity_grade -cne 'B2' -or $Goal.current_layer -notmatch '^L[0-2]$' -or $Goal.max_admitted_layer -notmatch '^L[0-2]$') { Throw-Wlv1Rejected 'ORDINARY_DEVELOPMENT_REQUIRED' }
}

function Assert-Wlv1NoActiveWorktreeWriter {
    param([Parameter(Mandatory)][string]$TaskRoot)
    $inside = (& git -C $TaskRoot rev-parse --is-inside-work-tree 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') { Throw-Wlv1Rejected 'WORKTREE_UNVERIFIED' }
    $status = @(& git -C $TaskRoot status --porcelain=v1 2>$null)
    if ($LASTEXITCODE -ne 0 -or $status.Count -ne 0) { Throw-Wlv1Rejected 'WORKTREE_ACTIVE_OR_DIRTY' }
    $indexLock = (& git -C $TaskRoot rev-parse --git-path index.lock 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($indexLock)) { Throw-Wlv1Rejected 'WORKTREE_UNVERIFIED' }
    $indexLockPath = if ([System.IO.Path]::IsPathRooted($indexLock)) { $indexLock } else { Join-Path $TaskRoot $indexLock }
    if (Test-Path -LiteralPath $indexLockPath) { Throw-Wlv1Rejected 'WORKTREE_ACTIVE_OR_DIRTY' }
}

function Assert-Wlv1HolderNotDemonstrablyLive {
    param([Parameter(Mandatory)][object]$Lease)
    # holder_session is deliberately not a liveness or ownership probe: codex resume is not proof.
    if ($Lease.holder -match '^pid:(?<pid>[1-9][0-9]{0,9})$') {
        try { Get-Process -Id ([int]$Matches.pid) -ErrorAction Stop | Out-Null; Throw-Wlv1Rejected 'LIVE_HOLDER' }
        catch [System.Management.Automation.ItemNotFoundException] { return }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] { return }
    }
}

function Get-Wlv1LeasePaths {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath)
    $root = Assert-Wlv1Directory -Path $TaskRoot
    $expected = Join-Path $root '.coord-local\leases\taskroot-writer.active.json'
    $lease = Get-Wlv1FullPath -Path $LeasePath
    if (-not $lease.Equals((Get-Wlv1FullPath -Path $expected), [System.StringComparison]::OrdinalIgnoreCase)) { Throw-Wlv1Rejected 'NONCANONICAL_LEASE_PATH' }
    [pscustomobject]@{ TaskRoot=$root; LeasePath=(Assert-Wlv1RegularFile -Path $lease); LeaseDirectory=(Assert-Wlv1Directory -Path (Split-Path -Parent $lease)) }
}

function Test-WriterLeaseV1SettlementAdmission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [DateTimeOffset]$NowUtc = [DateTimeOffset]::UtcNow,
        [string]$ExpectedLeaseSha256 = ''
    )
    try {
        $paths = Get-Wlv1LeasePaths -TaskRoot $TaskRoot -LeasePath $LeasePath
        $bytes = [System.IO.File]::ReadAllBytes($paths.LeasePath)
        $digest = Get-Wlv1BytesSha256 -Bytes $bytes
        if ($ExpectedLeaseSha256 -and ($ExpectedLeaseSha256 -notmatch '^[0-9a-f]{64}$' -or $ExpectedLeaseSha256 -ne $digest)) { Throw-Wlv1Rejected 'CONTENT_DRIFT' }
        $lease = Read-Wlv1Lease -Bytes $bytes
        if (-not ($lease.hard_stop -lt $NowUtc.ToUniversalTime())) { Throw-Wlv1Rejected 'NOT_EXPIRED' }
        $goalPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $lease.goal_ref -Field 'goal_ref'
        $budgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $lease.budget_state_ref -Field 'budget_state_ref'
        $goal = Read-Wlv1Goal -Path $goalPath
        $goalBudgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $goal.budget_state_ref -Field 'goal_budget_state_ref'
        $budget = Read-Wlv1Budget -Path $budgetPath
        Assert-Wlv1OrdinaryDevelopmentGoal -Lease $lease -Goal $goal -Budget $budget -LeaseBudgetPath $budgetPath -GoalBudgetPath $goalBudgetPath
        Assert-Wlv1HolderNotDemonstrablyLive -Lease $lease
        Assert-Wlv1NoActiveWorktreeWriter -TaskRoot $paths.TaskRoot
        [pscustomobject]@{ status='SETTLEMENT_ACCEPTED'; lease_sha256=$digest; lease_schema=$lease.schema; task_root=$paths.TaskRoot; lease_path=$paths.LeasePath; hard_stop_utc=$lease.hard_stop.ToString('o'); goal_path=$goalPath; budget_path=$budgetPath }
    }
    catch {
        $status = [string]$_.Exception.Message
        if ($status -notmatch '^SETTLEMENT_REJECTED_[A-Z0-9_]+$') { $status = 'SETTLEMENT_REJECTED_INTERNAL' }
        [pscustomobject]@{ status=$status; lease_sha256=''; lease_schema=''; task_root=''; lease_path=''; hard_stop_utc=''; goal_path=''; budget_path='' }
    }
}

function Read-Wlv1Authorization {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$AuthorizationPath,[Parameter(Mandatory)][string]$ExpectedLeaseSha256,[Parameter(Mandatory)][DateTimeOffset]$NowUtc)
    $authorizationRoot = Assert-Wlv1Directory -Path (Join-Path $TaskRoot '.coord-local\authorizations')
    $path = Assert-Wlv1RegularFile -Path $AuthorizationPath
    if (-not (Test-Wlv1PathWithin -Root $authorizationRoot -Candidate $path)) { Throw-Wlv1Rejected 'AUTHORIZATION_PATH' }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $digest = Get-Wlv1BytesSha256 -Bytes $bytes
    $checked = Get-Wlv1StrictJsonRoot -Bytes $bytes -Expected $script:Wlv1AuthorizationFields -FailureCode 'MALFORMED_AUTHORIZATION'
    try {
        $p = $checked.Properties
        $authorization = [pscustomobject]@{ schema=$p.schema.GetString(); authorization_id=$p.authorization_id.GetString(); authorization_scope=$p.authorization_scope.GetString(); task_root_relative_lease_path=$p.task_root_relative_lease_path.GetString(); expected_lease_sha256=$p.expected_lease_sha256.GetString(); authorized_by=$p.authorized_by.GetString(); authorized_utc=$p.authorized_utc.GetString(); expires_utc=$p.expires_utc.GetString() }
    }
    finally { $checked.Document.Dispose() }
    if ($authorization.schema -ne 'writer-lease-v1-settlement-authorization.v1' -or $authorization.authorization_scope -ne 'EXPIRED_ORDINARY_DEVELOPMENT_V1_SETTLEMENT' -or $authorization.expected_lease_sha256 -ne $ExpectedLeaseSha256 -or $authorization.authorized_by -notin @('OWNER','COORDINATOR')) { Throw-Wlv1Rejected 'AUTHORIZATION_REQUIRED' }
    Assert-Wlv1SafeIdentifier -Value $authorization.authorization_id -Field 'authorization_id'
    $authorized = ConvertTo-Wlv1Utc -Value $authorization.authorized_utc -Field 'authorization_authorized_utc'
    $expires = ConvertTo-Wlv1Utc -Value $authorization.expires_utc -Field 'authorization_expires_utc'
    if ($authorized -gt $NowUtc.ToUniversalTime() -or $expires -le $NowUtc.ToUniversalTime()) { Throw-Wlv1Rejected 'AUTHORIZATION_REQUIRED' }
    $expectedRelative = '.coord-local/leases/taskroot-writer.active.json'
    if ($authorization.task_root_relative_lease_path.Replace('\','/') -cne $expectedRelative) { Throw-Wlv1Rejected 'AUTHORIZATION_REQUIRED' }
    [pscustomobject]@{ path=$path; sha256=$digest; authorization=$authorization }
}

function Ensure-Wlv1HistoryDirectories {
    param([Parameter(Mandatory)][string]$TaskRoot)
    $history = Join-Path $TaskRoot '.coord-local\leases\history'
    [System.IO.Directory]::CreateDirectory((Join-Path $history 'leases')) | Out-Null
    [System.IO.Directory]::CreateDirectory((Join-Path $history 'settlements')) | Out-Null
    [System.IO.Directory]::CreateDirectory((Join-Path $history 'normal-returns')) | Out-Null
    $history = Assert-Wlv1Directory -Path $history
    [pscustomobject]@{ root=$history; leases=(Assert-Wlv1Directory -Path (Join-Path $history 'leases')); settlements=(Assert-Wlv1Directory -Path (Join-Path $history 'settlements')); normal_returns=(Assert-Wlv1Directory -Path (Join-Path $history 'normal-returns')) }
}

function Enter-Wlv1SettlementLock {
    param([Parameter(Mandatory)][string]$HistoryRoot)
    $path = Join-Path $HistoryRoot '.writer-lease-v1-settlement.lock'
    try { return [System.IO.File]::Open($path, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-Wlv1Rejected 'SETTLEMENT_IN_PROGRESS' }
}

function Write-Wlv1ImmutableJson {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Value)
    $parent = Assert-Wlv1Directory -Path (Split-Path -Parent $Path)
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes(($Value | ConvertTo-Json -Depth 12 -Compress))
    try { $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-Wlv1Rejected 'IMMUTABLE_RECORD_COLLISION' }
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
    Assert-Wlv1RegularFile -Path $Path | Out-Null
}

function Read-Wlv1SettlementReceipt {
    param([Parameter(Mandatory)][string]$Path)
    $checked = Get-Wlv1StrictJsonRoot -Bytes ([System.IO.File]::ReadAllBytes((Assert-Wlv1RegularFile -Path $Path))) -Expected $script:Wlv1SettlementReceiptFields -FailureCode 'HISTORY_INTEGRITY'
    try {
        $p = $checked.Properties
        return [pscustomobject]@{ schema=$p.schema.GetString(); settlement_status=$p.settlement_status.GetString(); original_lease_sha256=$p.original_lease_sha256.GetString() }
    }
    finally { $checked.Document.Dispose() }
}

function Get-Wlv1AlreadySettled {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath,[Parameter(Mandatory)][string]$ExpectedLeaseSha256)
    $active = Get-Wlv1FullPath -Path $LeasePath
    if (Test-Path -LiteralPath $active) { return $null }
    $history = Join-Path $TaskRoot '.coord-local\leases\history'
    if (-not (Test-Path -LiteralPath $history -PathType Container)) { return $null }
    $history = Assert-Wlv1Directory -Path $history
    $historicalLease = Join-Path (Join-Path $history 'leases') ($ExpectedLeaseSha256 + '.writer-lease.v1.json')
    $receiptPath = Join-Path (Join-Path $history 'settlements') ($ExpectedLeaseSha256 + '.settlement.json')
    if (-not (Test-Path -LiteralPath $historicalLease -PathType Leaf) -or -not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { return $null }
    $historicalLease = Assert-Wlv1RegularFile -Path $historicalLease
    $receipt = Read-Wlv1SettlementReceipt -Path $receiptPath
    if ((Get-Wlv1BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historicalLease))) -ne $ExpectedLeaseSha256 -or $receipt.schema -ne 'writer-lease-v1-interim-settlement-receipt.v1' -or $receipt.settlement_status -ne 'SETTLED' -or $receipt.original_lease_sha256 -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'HISTORY_INTEGRITY' }
    [pscustomobject]@{ status='SETTLEMENT_ALREADY_SETTLED'; historical_lease_path=$historicalLease; receipt_path=(Assert-Wlv1RegularFile -Path $receiptPath) }
}

function Invoke-WriterLeaseV1InterimSettlement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][string]$AuthorizationPath
    )
    try {
        $nowUtc = [DateTimeOffset]::UtcNow
        $root = Assert-Wlv1Directory -Path $TaskRoot
        $already = Get-Wlv1AlreadySettled -TaskRoot $root -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256
        if ($null -ne $already) { return $already }
        $admission = Test-WriterLeaseV1SettlementAdmission -TaskRoot $root -LeasePath $LeasePath -NowUtc $nowUtc -ExpectedLeaseSha256 $ExpectedLeaseSha256
        if ($admission.status -ne 'SETTLEMENT_ACCEPTED') { return $admission }
        $authorization = Read-Wlv1Authorization -TaskRoot $root -AuthorizationPath $AuthorizationPath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -NowUtc $nowUtc
        $history = Ensure-Wlv1HistoryDirectories -TaskRoot $root
        $lock = Enter-Wlv1SettlementLock -HistoryRoot $history.root
        try {
            $recheck = Test-WriterLeaseV1SettlementAdmission -TaskRoot $root -LeasePath $LeasePath -NowUtc $nowUtc -ExpectedLeaseSha256 $ExpectedLeaseSha256
            if ($recheck.status -ne 'SETTLEMENT_ACCEPTED') { return $recheck }
            $authorization = Read-Wlv1Authorization -TaskRoot $root -AuthorizationPath $AuthorizationPath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -NowUtc $nowUtc
            $immediateBytes = [System.IO.File]::ReadAllBytes((Assert-Wlv1RegularFile -Path $recheck.lease_path))
            if ((Get-Wlv1BytesSha256 -Bytes $immediateBytes) -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'CONTENT_DRIFT' }
            $historicalLeasePath = Join-Path $history.leases ($ExpectedLeaseSha256 + '.writer-lease.v1.json')
            if (Test-Path -LiteralPath $historicalLeasePath) { Throw-Wlv1Rejected 'IMMUTABLE_RECORD_COLLISION' }
            [System.IO.File]::Move($admission.lease_path, $historicalLeasePath)
            if (Test-Path -LiteralPath $admission.lease_path) { Throw-Wlv1Rejected 'ACTIVE_MARKER_REMAINS' }
            $historicalLeasePath = Assert-Wlv1RegularFile -Path $historicalLeasePath
            if ((Get-Wlv1BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historicalLeasePath))) -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'HISTORY_INTEGRITY' }
            $receiptPath = Join-Path $history.settlements ($ExpectedLeaseSha256 + '.settlement.json')
            $receipt = [ordered]@{
                schema='writer-lease-v1-interim-settlement-receipt.v1'; settlement_id=('sha256-' + $ExpectedLeaseSha256); settlement_kind='EXPIRED_ORDINARY_DEVELOPMENT_V1'; settlement_status='SETTLED'; settled_utc=$nowUtc.ToUniversalTime().ToString('o')
                source_relative_path='.coord-local/leases/taskroot-writer.active.json'; historical_relative_path=('.coord-local/leases/history/leases/' + $ExpectedLeaseSha256 + '.writer-lease.v1.json'); original_lease_schema=$admission.lease_schema; original_lease_sha256=$ExpectedLeaseSha256; authorization_sha256=$authorization.sha256
            }
            Write-Wlv1ImmutableJson -Path $receiptPath -Value $receipt
            $verified = Get-Wlv1AlreadySettled -TaskRoot $root -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256
            if ($null -eq $verified) { Throw-Wlv1Rejected 'HISTORY_INTEGRITY' }
            [pscustomobject]@{ status='SETTLEMENT_PASS'; historical_lease_path=$verified.historical_lease_path; receipt_path=$verified.receipt_path; lease_sha256=$ExpectedLeaseSha256 }
        }
        finally { $lock.Dispose() }
    }
    catch {
        $status = [string]$_.Exception.Message
        if ($status -notmatch '^SETTLEMENT_REJECTED_[A-Z0-9_]+$') { $status = 'SETTLEMENT_REJECTED_INTERNAL' }
        [pscustomobject]@{ status=$status; historical_lease_path=''; receipt_path=''; lease_sha256='' }
    }
}

function Complete-WriterLeaseV1NormalReturn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][string]$ExpectedHolderSession,
        [Parameter(Mandatory)][ValidateSet('PASS','BLOCKED','HOLD','WAITING_EXTERNAL_CI','READY_FOR_OWNER')][string]$Outcome
    )
    try {
        $paths = Get-Wlv1LeasePaths -TaskRoot $TaskRoot -LeasePath $LeasePath
        $bytes = [System.IO.File]::ReadAllBytes($paths.LeasePath)
        $digest = Get-Wlv1BytesSha256 -Bytes $bytes
        if ($digest -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'CONTENT_DRIFT' }
        $lease = Read-Wlv1Lease -Bytes $bytes
        if ($lease.holder_session -cne $ExpectedHolderSession) { Throw-Wlv1Rejected 'HOLDER_SESSION_MISMATCH' }
        $goalPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $lease.goal_ref -Field 'goal_ref'
        $budgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $lease.budget_state_ref -Field 'budget_state_ref'
        $goal = Read-Wlv1Goal -Path $goalPath
        $goalBudgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $goal.budget_state_ref -Field 'goal_budget_state_ref'
        $budget = Read-Wlv1Budget -Path $budgetPath
        Assert-Wlv1OrdinaryDevelopmentGoal -Lease $lease -Goal $goal -Budget $budget -LeaseBudgetPath $budgetPath -GoalBudgetPath $goalBudgetPath
        $history = Ensure-Wlv1HistoryDirectories -TaskRoot $paths.TaskRoot
        $lock = Enter-Wlv1SettlementLock -HistoryRoot $history.root
        try {
            $currentBytes = [System.IO.File]::ReadAllBytes((Assert-Wlv1RegularFile -Path $paths.LeasePath))
            if ((Get-Wlv1BytesSha256 -Bytes $currentBytes) -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'CONTENT_DRIFT' }
            $currentLease = Read-Wlv1Lease -Bytes $currentBytes
            if ($currentLease.holder_session -cne $ExpectedHolderSession) { Throw-Wlv1Rejected 'HOLDER_SESSION_MISMATCH' }
            $currentGoalPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $currentLease.goal_ref -Field 'goal_ref'
            $currentBudgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $currentLease.budget_state_ref -Field 'budget_state_ref'
            $currentGoal = Read-Wlv1Goal -Path $currentGoalPath
            $currentGoalBudgetPath = Resolve-Wlv1MetadataReference -TaskRoot $paths.TaskRoot -Reference $currentGoal.budget_state_ref -Field 'goal_budget_state_ref'
            $currentBudget = Read-Wlv1Budget -Path $currentBudgetPath
            Assert-Wlv1OrdinaryDevelopmentGoal -Lease $currentLease -Goal $currentGoal -Budget $currentBudget -LeaseBudgetPath $currentBudgetPath -GoalBudgetPath $currentGoalBudgetPath
            $historicalLeasePath = Join-Path $history.leases ($ExpectedLeaseSha256 + '.normal-return.writer-lease.v1.json')
            $receiptPath = Join-Path $history.normal_returns ($ExpectedLeaseSha256 + '.normal-return.json')
            $receipt = [ordered]@{
                schema='writer-lease-v1-normal-return-receipt.v1'; normal_return_id=('sha256-' + $ExpectedLeaseSha256); normal_return_status='TERMINAL_NORMAL_RETURN_RECORDED'; outcome=$Outcome; recorded_utc=[DateTimeOffset]::UtcNow.ToString('o')
                source_relative_path='.coord-local/leases/taskroot-writer.active.json'; historical_relative_path=('.coord-local/leases/history/leases/' + $ExpectedLeaseSha256 + '.normal-return.writer-lease.v1.json'); original_lease_schema=$lease.schema; original_lease_sha256=$ExpectedLeaseSha256; holder_session=$ExpectedHolderSession
            }
            Write-Wlv1ImmutableJson -Path $receiptPath -Value $receipt
            [System.IO.File]::Move($paths.LeasePath, $historicalLeasePath)
            if (Test-Path -LiteralPath $paths.LeasePath) { Throw-Wlv1Rejected 'ACTIVE_MARKER_REMAINS' }
            $historicalLeasePath = Assert-Wlv1RegularFile -Path $historicalLeasePath
            if ((Get-Wlv1BytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historicalLeasePath))) -ne $ExpectedLeaseSha256) { Throw-Wlv1Rejected 'HISTORY_INTEGRITY' }
            [pscustomobject]@{ status='NORMAL_RETURN_RELEASED'; outcome=$Outcome; receipt_path=(Assert-Wlv1RegularFile -Path $receiptPath); historical_lease_path=$historicalLeasePath; active_lease=$false }
        }
        finally { $lock.Dispose() }
    }
    catch {
        $status = [string]$_.Exception.Message
        if ($status -notmatch '^SETTLEMENT_REJECTED_[A-Z0-9_]+$') { $status = 'SETTLEMENT_REJECTED_INTERNAL' }
        [pscustomobject]@{ status=$status; outcome=$Outcome; receipt_path=''; historical_lease_path=''; active_lease=$true }
    }
}

function Invoke-WriterLeaseV1OrdinaryDevelopmentCoordinator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][string]$ExpectedHolderSession,
        [Parameter(Mandatory)][scriptblock]$Run
    )
    $outcome = ''
    $release = $null
    try {
        $outcome = [string](& $Run)
        if ($outcome -notin @('PASS','BLOCKED','HOLD','WAITING_EXTERNAL_CI','READY_FOR_OWNER')) { throw 'NORMAL_RETURN_OUTCOME_INVALID' }
    }
    finally {
        if ($outcome -in @('PASS','BLOCKED','HOLD','WAITING_EXTERNAL_CI','READY_FOR_OWNER')) {
            $release = Complete-WriterLeaseV1NormalReturn -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -ExpectedHolderSession $ExpectedHolderSession -Outcome $outcome
            if ($release.status -ne 'NORMAL_RETURN_RELEASED' -or $release.active_lease) { throw ('NORMAL_RETURN_RELEASE_FAILED=' + $release.status) }
        }
    }
    [pscustomobject]@{ outcome=$outcome; normal_return_release=$release }
}

Export-ModuleMember -Function @(
    'Complete-WriterLeaseV1NormalReturn',
    'Invoke-WriterLeaseV1InterimSettlement',
    'Invoke-WriterLeaseV1OrdinaryDevelopmentCoordinator',
    'Test-WriterLeaseV1SettlementAdmission'
)
