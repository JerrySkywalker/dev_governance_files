Set-StrictMode -Version Latest

# This module deliberately has two exact historical contracts.  It is not a
# reusable lease settlement mechanism: 054D was a mixed historical
# coordination lease, while 053J was an A5 lease rejected before protected
# activation.  Neither may be treated as ordinary development.

$script:Jpc054DLeaseFields = [ordered]@{
    schema = 'String'; goal = 'String'; generation = 'String'; holder = 'String'; holder_process_id = 'Number'
    state = 'String'; acquired_utc = 'String'; hard_stop_utc = 'String'; single_intentional_writer = 'True'
    predecessor_goal = 'String'; predecessor_reason = 'String'; scope = 'StringArray'; goal_ref = 'String'
}

$script:Jpc054DAuthorizationFields = [ordered]@{
    schema = 'String'; authorization_id = 'String'; authorized_by = 'String'; authorized_utc = 'String'; expires_utc = 'String'
    source_lease_path = 'String'; lease_sha256 = 'String'; goal = 'String'; run_id = 'String'
    evidence_manifest_sha256 = 'String'; non_activation_proof_sha256 = 'String'; classification = 'String'
    historical_lease_path = 'String'; receipt_path = 'String'; production_apply_executed = 'False'
    production_rollback_required = 'False'; new_production_authority_granted = 'False'
}

$script:Jpc054DReceiptFields = [ordered]@{
    schema = 'String'; closure_id = 'String'; closed_utc = 'String'; classification = 'String'
    source_lease_path = 'String'; historical_lease_path = 'String'; receipt_path = 'String'
    original_lease_schema = 'String'; original_lease_sha256 = 'String'; goal = 'String'; run_id = 'String'
    evidence_manifest_sha256 = 'String'; non_activation_proof_sha256 = 'String'; authorization_sha256 = 'String'
    production_apply_executed = 'False'; production_rollback_required = 'False'; new_production_authority_granted = 'False'
}

$script:Jpc053JLeaseFields = [ordered]@{
    schema = 'String'; goal = 'String'; holder = 'String'; holder_session = 'String'; state = 'String'
    acquired_utc = 'String'; created_utc = 'String'; hard_stop_utc = 'String'; single_intentional_writer = 'True'
    scope = 'StringArray'; goal_ref = 'String'; budget_state_ref = 'String'
}

$script:Jpc053JGoalFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; profile = 'String'; authority_class = 'String'
    elasticity_grade = 'String'; initial_progress_state = 'String'; current_layer = 'String'; max_admitted_layer = 'String'
    next_proof_vector = 'String'; allowed_repositories = 'StringArray'; allowed_paths = 'StringArray'; allowed_services = 'StringArray'
    protected_boundaries = 'StringArray'; owner_only_boundaries = 'StringArray'; budget_overrides = 'Object'
    budget_state_ref = 'String'; last_accepted_checkpoint = 'String'; context_modules = 'StringArray'; stop_conditions = 'StringArray'; created_utc = 'String'
}

$script:Jpc053JBudgetFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; created_utc = 'String'; domains = 'Object'
}

$script:Jpc053JIntentFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; captured_utc = 'String'; transaction_id = 'String'
    access_main = 'String'; client_source = 'String'; adapter_sha256 = 'String'; remote_script_sha256 = 'String'
    prestate_sha256 = 'String'; target_sha256 = 'String'; binary_sha256 = 'String'; target_disposition = 'String'
    target_metadata_mutated = 'False'; custody_rehash_pass = 'True'; source_anchor_pass = 'True'; prestate_probe_pass = 'True'
    mutation_readiness_pass = 'True'; remote_privilege = 'String'; production_mutation_started = 'False'; sanitization = 'Object'
}

$script:Jpc053JTerminalFields = [ordered]@{
    schema = 'String'; goal = 'String'; run_id = 'String'; captured_utc = 'String'; transaction_id = 'String'
    result = 'String'; failure_code = 'String'; adapter_launch_reached_remote_prepare = 'False'
    production_mutation_started = 'False'; rollback_required = 'False'; rollback_verified = 'String'
    same_transaction_replay_prohibited = 'True'; subsequent_observation = 'String'
}

$script:Jpc053JAuthorizationFields = [ordered]@{
    schema = 'String'; authorization_id = 'String'; authorization_scope = 'String'; authority_environment = 'String'
    real_task_root_authority = 'String'; authorized_by = 'String'; authorized_utc = 'String'; expires_utc = 'String'
    task_root = 'String'; source_lease_path = 'String'; lease_sha256 = 'String'; goal = 'String'; run_id = 'String'
    transaction_id = 'String'; goal_sha256 = 'String'; budget_sha256 = 'String'; intent_sha256 = 'String'
    terminal_sha256 = 'String'; final_receipt_sha256 = 'String'; predecessor_settlement_sha256 = 'String'
    evidence_manifest_sha256 = 'String'; non_activation_proof_sha256 = 'String'; classification = 'String'
    terminal_class = 'String'; terminal_reason = 'String'; historical_lease_path = 'String'; receipt_path = 'String'
    protected_activation_occurred = 'False'; production_apply_executed = 'False'; rollback_required = 'False'
    rollback_executed = 'False'; new_production_authority_granted = 'False'
}

$script:Jpc053JReceiptFields = [ordered]@{
    schema = 'String'; closure_id = 'String'; closed_utc = 'String'; classification = 'String'
    terminal_class = 'String'; terminal_reason = 'String'; source_lease_path = 'String'; historical_lease_path = 'String'
    receipt_path = 'String'; original_lease_schema = 'String'; original_lease_sha256 = 'String'; goal = 'String'
    run_id = 'String'; transaction_id = 'String'; goal_sha256 = 'String'; budget_sha256 = 'String'; intent_sha256 = 'String'
    terminal_sha256 = 'String'; final_receipt_sha256 = 'String'; predecessor_settlement_sha256 = 'String'
    evidence_manifest_sha256 = 'String'; non_activation_proof_sha256 = 'String'; authorization_sha256 = 'String'
    protected_activation_occurred = 'False'; production_apply_executed = 'False'; rollback_required = 'False'
    rollback_executed = 'False'; new_production_authority_granted = 'False'
}

function Throw-Jpc054DRejected {
    param([Parameter(Mandatory)][string]$Code)
    throw ('CLOSURE_VERIFICATION_FAIL_CLOSED_' + $Code)
}

function Get-Jpc054DBytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    # SHA256.HashData is unavailable in Windows PowerShell 5.1/.NET Framework.
    # Use the standard one-shot algorithm object so hashing itself does not
    # impose a newer runtime requirement on the legacy Windows host.
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algorithm.ComputeHash($Bytes)
        return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Get-Jpc054DTextSha256 {
    param([Parameter(Mandatory)][string]$Text)
    return Get-Jpc054DBytesSha256 -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($Text))
}

function Get-Jpc054DFullPath {
    param([Parameter(Mandatory)][string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) }
    catch { Throw-Jpc054DRejected 'INVALID_PATH' }
}

function Test-Jpc054DPathWithin {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Candidate)
    $fullRoot = (Get-Jpc054DFullPath -Path $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullCandidate = Get-Jpc054DFullPath -Path $Candidate
    if ($fullCandidate.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    return $fullCandidate.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-Jpc054DNoReparseAncestors {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Get-Jpc054DFullPath -Path $Path
    $volumeRoot = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($volumeRoot)) { Throw-Jpc054DRejected 'INVALID_PATH' }
    $current = $volumeRoot
    $segments = $fullPath.Substring($volumeRoot.Length).Split(@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $segments) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { Throw-Jpc054DRejected 'PATH_MISSING' }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-Jpc054DRejected 'REPARSE_PATH' }
    }
    return $fullPath
}

# Unlike Assert-Jpc054DNoReparseAncestors this is safe to use before creating a
# destination.  Every existing ancestor is checked, but a missing final
# component is permitted.  That prevents Close from creating any directory
# beneath an existing junction or symbolic link.
function Assert-Jpc054DNoReparseExistingAncestors {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Get-Jpc054DFullPath -Path $Path
    $volumeRoot = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($volumeRoot)) { Throw-Jpc054DRejected 'INVALID_PATH' }
    $current = $volumeRoot
    $segments = $fullPath.Substring($volumeRoot.Length).Split(@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $segments) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { return $fullPath }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-Jpc054DRejected 'REPARSE_PATH' }
    }
    return $fullPath
}

function Assert-Jpc054DDirectory {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Jpc054DNoReparseAncestors -Path $Path
    if (-not ((Get-Item -LiteralPath $fullPath -Force) -is [System.IO.DirectoryInfo])) { Throw-Jpc054DRejected 'DIRECTORY_REQUIRED' }
    return $fullPath
}

function Assert-Jpc054DRegularFile {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-Jpc054DNoReparseAncestors -Path $Path
    if (-not ((Get-Item -LiteralPath $fullPath -Force) -is [System.IO.FileInfo])) { Throw-Jpc054DRejected 'REGULAR_FILE_REQUIRED' }
    return $fullPath
}

function ConvertTo-Jpc054DUtc {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact($Value, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        Throw-Jpc054DRejected ('MALFORMED_' + $Field.ToUpperInvariant())
    }
    return $parsed.ToUniversalTime()
}

function Get-Jpc054DStrictJsonRoot {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][System.Collections.IDictionary]$Expected,[Parameter(Mandatory)][string]$FailureCode)
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 262144) { Throw-Jpc054DRejected $FailureCode }
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes) }
    catch { Throw-Jpc054DRejected $FailureCode }
    try { $document = [System.Text.Json.JsonDocument]::Parse($text) }
    catch { Throw-Jpc054DRejected $FailureCode }
    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) { Throw-Jpc054DRejected $FailureCode }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $properties = @{}
        foreach ($property in $root.EnumerateObject()) {
            if (-not $seen.Add($property.Name) -or -not $Expected.Contains($property.Name)) { Throw-Jpc054DRejected $FailureCode }
            $properties[$property.Name] = $property.Value
        }
        if ($properties.Count -ne $Expected.Count) { Throw-Jpc054DRejected $FailureCode }
        foreach ($entry in $Expected.GetEnumerator()) {
            if (-not $properties.ContainsKey($entry.Key)) { Throw-Jpc054DRejected $FailureCode }
            $kind = $properties[$entry.Key].ValueKind.ToString()
            if ($entry.Value -eq 'StringArray') {
                if ($kind -ne 'Array') { Throw-Jpc054DRejected $FailureCode }
                foreach ($element in $properties[$entry.Key].EnumerateArray()) { if ($element.ValueKind -ne [System.Text.Json.JsonValueKind]::String) { Throw-Jpc054DRejected $FailureCode } }
            }
            elseif ($kind -ne $entry.Value) { Throw-Jpc054DRejected $FailureCode }
        }
        return [pscustomobject]@{ Document=$document; Properties=$properties }
    }
    catch { $document.Dispose(); throw }
}

function Get-Jpc054DJsonObject {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][string]$FailureCode)
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 262144) { Throw-Jpc054DRejected $FailureCode }
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes); $document = [System.Text.Json.JsonDocument]::Parse($text) }
    catch { Throw-Jpc054DRejected $FailureCode }
    try {
        if ($document.RootElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) { Throw-Jpc054DRejected $FailureCode }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $document.RootElement.EnumerateObject()) { if (-not $seen.Add($property.Name)) { Throw-Jpc054DRejected $FailureCode } }
        return $document
    }
    catch { $document.Dispose(); throw }
}

function Get-Jpc054DProperty {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Object,[Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][System.Text.Json.JsonValueKind]$Kind,[Parameter(Mandatory)][string]$FailureCode)
    $value = [System.Text.Json.JsonElement]::new()
    if (-not $Object.TryGetProperty($Name, [ref]$value) -or $value.ValueKind -ne $Kind) { Throw-Jpc054DRejected $FailureCode }
    return $value
}

function Get-Jpc054DFileBytes {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.File]::ReadAllBytes((Assert-Jpc054DRegularFile -Path $Path))
}

function Get-Jpc054DRelativePath {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Path)
    $fullRoot = (Get-Jpc054DFullPath -Path $Root).TrimEnd('\','/')
    $fullPath = Get-Jpc054DFullPath -Path $Path
    if (-not (Test-Jpc054DPathWithin -Root $fullRoot -Candidate $fullPath)) { Throw-Jpc054DRejected 'ROOT_CONTAINMENT' }
    return $fullPath.Substring($fullRoot.Length).TrimStart('\','/').Replace('\','/')
}

function New-Jpc054DContract {
    param([string]$CoordinationRoot = 'C:\build\jpc-054d\coord',[string]$HistoryRoot = 'C:\build\jpc-054d-closure-history',[switch]$Fixture)
    $root = Get-Jpc054DFullPath -Path $CoordinationRoot
    $history = Get-Jpc054DFullPath -Path $HistoryRoot
    $leaseRelative = 'leases/writer.active.json'
    $evidence = @(
        'GOAL.md','PLAN.md','WRITE-SURFACES.json','admission/ADMISSION.md','admission/budget.json',
        'admission/WRITE-SURFACES-AMENDMENT-001.json','admission/r5b-selective-source.patch',
        'receipts/PREDECESSOR-053J-SETTLEMENT.json','receipts/R3-PR-64-EXACT-HEAD.json',
        'receipts/R3-PR-64-EXACT-MAIN-ACCEPTED.json','receipts/R5B-LOCAL-VALIDATION-2C5DF1A.json',
        'receipts/R5B-PR-55-CANDIDATE.json','receipts/INTERIM-STATUS-EXTERNAL-CI-QUEUE.json'
    )
    $allFiles = @($evidence + $leaseRelative)
    $contract = [ordered]@{
        coordination_root=$root; history_root=$history; lease_relative_path=$leaseRelative; lease_path=(Join-Path $root $leaseRelative)
        goal='JPC-V22-COORDINATION-RECOVERY-AND-RC32-AUTONOMOUS-12H-054D'
        run_id='JPC-V22-COORDINATION-RECOVERY-AND-RC32-AUTONOMOUS-12H-054D-20260829T061447Z'
        lease_schema='jpc.coordination-writer-lease.v1'; expected_lease_sha256='f5509eea17fd0f275049ad0bc424eab2194ac876ae4b02b974a02c4913bc6fea'
        expected_root_manifest_sha256='7eae491bb49175bd6adf0cf5221651bc37333ef76910663ca12eeadea68d0cdb'
        expected_directories=@('admission','leases','receipts'); evidence_relative_paths=$evidence; all_relative_paths=$allFiles; expected_file_sha256=@{}
    }
    if ($Fixture) {
        $contract.expected_lease_sha256 = Get-Jpc054DBytesSha256 -Bytes (Get-Jpc054DFileBytes -Path $contract.lease_path)
        foreach ($relative in $allFiles) { $contract.expected_file_sha256[$relative] = Get-Jpc054DBytesSha256 -Bytes (Get-Jpc054DFileBytes -Path (Join-Path $root $relative)) }
        $fixtureRootRecords = @(
            foreach ($relative in $allFiles) {
                $path = Assert-Jpc054DRegularFile -Path (Join-Path $root $relative)
                [pscustomobject]@{ relative=$relative; length=[int64](Get-Item -LiteralPath $path -Force).Length; sha256=$contract.expected_file_sha256[$relative] }
            }
        ) | Sort-Object relative
        $fixtureRootText = (($fixtureRootRecords | ForEach-Object { $_.relative + '|' + $_.length + '|' + $_.sha256 }) -join "`n") + "`n"
        $contract.expected_root_manifest_sha256 = Get-Jpc054DTextSha256 -Text $fixtureRootText
    }
    else {
        $contract.expected_file_sha256 = [ordered]@{
            'admission/ADMISSION.md'='44cbc8bb195eb02020e88e016cb7685cd0e008f1dd2f5f2dae19916757dff459'; 'admission/budget.json'='514cce506d723088a30523ab2bf1ebae5971ba2992539368375dcdf242ad01c6'
            'admission/r5b-selective-source.patch'='0eaf3cafba506faa4652e2bc8a67046636b37bf413f3a4638499744f6bcbc1d0'; 'admission/WRITE-SURFACES-AMENDMENT-001.json'='70b84188ebcf905bb3d67ec2641dfe022e42d201b4e18577755fac0cb126bbcf'
            'GOAL.md'='949840f657133e1223019b24b5291f0b03f3f1681d083dc8eb5c0c395ac4300b'; 'leases/writer.active.json'='f5509eea17fd0f275049ad0bc424eab2194ac876ae4b02b974a02c4913bc6fea'
            'PLAN.md'='8a7bfa5729c7e8d717a1c786d414752d2c69b95d63382fda8bd408fd762cd8eb'; 'receipts/INTERIM-STATUS-EXTERNAL-CI-QUEUE.json'='bb589dd263ef8799ff7fdb102b1508d409035fb9b3554b84b9912371c393b4f3'
            'receipts/PREDECESSOR-053J-SETTLEMENT.json'='3e479110e263c2263f552df0632d9911262f3af759696149065390630e686ab4'; 'receipts/R3-PR-64-EXACT-HEAD.json'='cf8efb2a6985105ddac8c622f690b1ff4485b374e616acf23c2166aed8bc85cd'
            'receipts/R3-PR-64-EXACT-MAIN-ACCEPTED.json'='b05d473158360cec3c9e58f8cd27e371c3d0b5c29312027fcd9341f4d2d3a3c4'; 'receipts/R5B-LOCAL-VALIDATION-2C5DF1A.json'='f4f0606fcee24ce3b82ba9a1fa8e09ce204132a912eb69007cdc696fce47bf5b'
            'receipts/R5B-PR-55-CANDIDATE.json'='0f752eb6a129383f79cbed26e39d5ba1a2fa31035893ddfa45642aa5720c5a51'; 'WRITE-SURFACES.json'='f9e7c5a676f75b0c7885f0995b5ba33510984d143b58e0f0cff510ab4e9290ec'
        }
    }
    return [pscustomobject]$contract
}

function Get-Jpc054DInventory {
    param([Parameter(Mandatory)][object]$Contract)
    $root = Assert-Jpc054DDirectory -Path $Contract.coordination_root
    if ($root -cne $Contract.coordination_root) { Throw-Jpc054DRejected 'NONCANONICAL_COORDINATION_ROOT' }
    $directories = @(); $files = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force -Recurse)) {
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-Jpc054DRejected 'REPARSE_PATH' }
        $relative = Get-Jpc054DRelativePath -Root $root -Path $item.FullName
        if ($item -is [System.IO.DirectoryInfo]) { $directories += $relative; continue }
        if (-not ($item -is [System.IO.FileInfo])) { Throw-Jpc054DRejected 'REGULAR_FILE_REQUIRED' }
        $files += [pscustomobject]@{ relative=$relative; path=$item.FullName; length=[int64]$item.Length; sha256=(Get-Jpc054DBytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($item.FullName))) }
    }
    $directories = @($directories | Sort-Object); $files = @($files | Sort-Object relative)
    if (($directories -join "`0") -cne ((@($Contract.expected_directories | Sort-Object)) -join "`0")) { Throw-Jpc054DRejected 'UNKNOWN_TRANSACTION_NAMESPACE' }
    $actual = @($files | ForEach-Object { $_.relative })
    $expected = @($Contract.all_relative_paths | Sort-Object)
    if ($actual.Count -ne $expected.Count -or ($actual -join "`0") -cne ($expected -join "`0")) { Throw-Jpc054DRejected 'UNKNOWN_OR_MISSING_EVIDENCE_FILE' }
    foreach ($entry in $files) {
        if (-not $Contract.expected_file_sha256.Contains($entry.relative) -or $Contract.expected_file_sha256[$entry.relative] -cne $entry.sha256) { Throw-Jpc054DRejected 'EVIDENCE_CONTENT_DRIFT' }
    }
    $evidenceEntries = @($files | Where-Object { $_.relative -in @($Contract.evidence_relative_paths) })
    $manifestText = 'jpc-054d-evidence-manifest.v1' + "`n" + (($evidenceEntries | ForEach-Object { $_.relative + "`t" + $_.length + "`t" + $_.sha256 }) -join "`n") + "`n"
    # This inventory format is pinned to the accepted historical root digest.
    # Its simple byte-level records make the published count/digest independently
    # reproducible without accepting an alternate manifest representation.
    $rootText = (($files | ForEach-Object { $_.relative + '|' + $_.length + '|' + $_.sha256 }) -join "`n") + "`n"
    $rootDigest = Get-Jpc054DTextSha256 -Text $rootText
    if ([string]::IsNullOrWhiteSpace([string]$Contract.expected_root_manifest_sha256) -or $rootDigest -cne $Contract.expected_root_manifest_sha256) { Throw-Jpc054DRejected 'ROOT_MANIFEST_SHA256' }
    [pscustomobject]@{ root=$root; files=$files; root_file_count=$files.Count; root_manifest_sha256=$rootDigest; evidence_manifest_sha256=(Get-Jpc054DTextSha256 -Text $manifestText) }
}

function Read-Jpc054DLease {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][object]$Contract)
    $checked = Get-Jpc054DStrictJsonRoot -Bytes $Bytes -Expected $script:Jpc054DLeaseFields -FailureCode 'MALFORMED_LEASE'
    try {
        $p = $checked.Properties
        $lease = [pscustomobject]@{ schema=$p.schema.GetString(); goal=$p.goal.GetString(); generation=$p.generation.GetString(); holder=$p.holder.GetString(); holder_process_id=$p.holder_process_id.GetInt64(); state=$p.state.GetString(); acquired_utc=$p.acquired_utc.GetString(); hard_stop_utc=$p.hard_stop_utc.GetString(); single_intentional_writer=$p.single_intentional_writer.GetBoolean(); goal_ref=$p.goal_ref.GetString(); scope=@($p.scope.EnumerateArray() | ForEach-Object { $_.GetString() }) }
    }
    finally { $checked.Document.Dispose() }
    if ($lease.schema -cne $Contract.lease_schema -or $lease.goal -cne $Contract.goal -or $lease.generation -cne $Contract.run_id -or $lease.state -cne 'active' -or -not $lease.single_intentional_writer) { Throw-Jpc054DRejected 'LEASE_BINDING' }
    if ($lease.holder_process_id -lt 1 -or $lease.holder_process_id -gt [int]::MaxValue -or [string]::IsNullOrWhiteSpace($lease.holder) -or $lease.scope.Count -eq 0 -or $lease.goal_ref -cne 'GOAL.md') { Throw-Jpc054DRejected 'MALFORMED_LEASE' }
    $lease | Add-Member -NotePropertyName acquired -NotePropertyValue (ConvertTo-Jpc054DUtc -Value $lease.acquired_utc -Field 'lease_acquired_utc')
    $lease | Add-Member -NotePropertyName hard_stop -NotePropertyValue (ConvertTo-Jpc054DUtc -Value $lease.hard_stop_utc -Field 'lease_hard_stop_utc')
    if ($lease.acquired -ge $lease.hard_stop) { Throw-Jpc054DRejected 'MALFORMED_LEASE' }
    return $lease
}

function Assert-Jpc054DHolderDead {
    param([Parameter(Mandatory)][object]$Lease)
    try { Get-Process -Id ([int]$Lease.holder_process_id) -ErrorAction Stop | Out-Null; Throw-Jpc054DRejected 'LIVE_HOLDER' }
    catch [System.Management.Automation.ItemNotFoundException] { return $true }
    catch [Microsoft.PowerShell.Commands.ProcessCommandException] { return $true }
    catch { Throw-Jpc054DRejected 'HOLDER_LIVENESS_UNPROVEN' }
}

function Get-Jpc054DJsonEvidence {
    param([Parameter(Mandatory)][object]$Inventory,[Parameter(Mandatory)][string]$Relative)
    $entry = @($Inventory.files | Where-Object { $_.relative -ceq $Relative })
    if ($entry.Count -ne 1) { Throw-Jpc054DRejected 'MISSING_REQUIRED_RECEIPT' }
    return Get-Jpc054DJsonObject -Bytes ([System.IO.File]::ReadAllBytes($entry[0].path)) -FailureCode 'MALFORMED_EVIDENCE_JSON'
}

function Assert-Jpc054DNonActivationEvidence {
    param([Parameter(Mandatory)][object]$Inventory,[Parameter(Mandatory)][object]$Contract)
    $goalText = [System.Text.UTF8Encoding]::new($false, $true).GetString((Get-Jpc054DFileBytes -Path (Join-Path $Inventory.root 'GOAL.md')))
    $planText = [System.Text.UTF8Encoding]::new($false, $true).GetString((Get-Jpc054DFileBytes -Path (Join-Path $Inventory.root 'PLAN.md')))
    $surfaceText = [System.Text.UTF8Encoding]::new($false, $true).GetString((Get-Jpc054DFileBytes -Path (Join-Path $Inventory.root 'WRITE-SURFACES.json')))
    foreach ($binding in @(('GOAL_ID=' + $Contract.goal),('RUN_ID=' + $Contract.run_id),'HARNESS_PROFILE=COMPRESSED_TRAIN_V1','AUTHORITY_CLASS=A3','MAX_ADMITTED_LAYER=L3')) { if ($goalText -notmatch [regex]::Escape($binding)) { Throw-Jpc054DRejected 'FROZEN_GOAL_BINDING' } }
    if ($goalText -notmatch 'separately durable\s+`PROTECTED_TRANSACTION_V2`\s+A5\s+envelope' -or $planText -notmatch 'fresh A5-only promotion envelope' -or $surfaceText -notmatch 'new A5-only envelope') { Throw-Jpc054DRejected 'TRANSITION_IMPOSSIBILITY_UNPROVEN' }
    $r3 = Get-Jpc054DJsonEvidence -Inventory $Inventory -Relative 'receipts/R3-PR-64-EXACT-MAIN-ACCEPTED.json'
    $final = Get-Jpc054DJsonEvidence -Inventory $Inventory -Relative 'receipts/INTERIM-STATUS-EXTERNAL-CI-QUEUE.json'
    $r5 = Get-Jpc054DJsonEvidence -Inventory $Inventory -Relative 'receipts/R5B-PR-55-CANDIDATE.json'
    try {
        $r3Root=$r3.RootElement; $finalRoot=$final.RootElement; $r5Root=$r5.RootElement
        if ((Get-Jpc054DProperty -Object $r3Root -Name 'goal_id' -Kind String -FailureCode 'CONFLICTING_R3_RECEIPT').GetString() -cne $Contract.goal -or (Get-Jpc054DProperty -Object $r3Root -Name 'public_stage0_updated' -Kind False -FailureCode 'CONFLICTING_R3_RECEIPT').GetBoolean()) { Throw-Jpc054DRejected 'CONFLICTING_R3_RECEIPT' }
        if ((Get-Jpc054DProperty -Object $finalRoot -Name 'goal_id' -Kind String -FailureCode 'CONFLICTING_FINAL_RECEIPT').GetString() -cne $Contract.goal) { Throw-Jpc054DRejected 'CONFLICTING_FINAL_RECEIPT' }
        $release=Get-Jpc054DProperty -Object $finalRoot -Name 'release' -Kind Object -FailureCode 'CONFLICTING_FINAL_RECEIPT'
        $owner=Get-Jpc054DProperty -Object $finalRoot -Name 'owner_boundary' -Kind Object -FailureCode 'CONFLICTING_FINAL_RECEIPT'
        foreach($name in @('rc32_source_created','qualification_started','promotion_started')) { if((Get-Jpc054DProperty -Object $release -Name $name -Kind False -FailureCode 'CONFLICTING_FINAL_RECEIPT').GetBoolean()){Throw-Jpc054DRejected 'CONFLICTING_FINAL_RECEIPT'} }
        foreach($name in @('zenbook_contacted','skyforge_contacted')) { if((Get-Jpc054DProperty -Object $owner -Name $name -Kind False -FailureCode 'CONFLICTING_FINAL_RECEIPT').GetBoolean()){Throw-Jpc054DRejected 'CONFLICTING_FINAL_RECEIPT'} }
        if((Get-Jpc054DProperty -Object $owner -Name 'pkce_runs' -Kind Number -FailureCode 'CONFLICTING_FINAL_RECEIPT').GetInt64() -ne 0){Throw-Jpc054DRejected 'CONFLICTING_FINAL_RECEIPT'}
        if ((Get-Jpc054DProperty -Object $r5Root -Name 'goal' -Kind String -FailureCode 'CONFLICTING_R5B_RECEIPT').GetString() -cne $Contract.goal -or (Get-Jpc054DProperty -Object $r5Root -Name 'ci_status_at_recording' -Kind String -FailureCode 'CONFLICTING_R5B_RECEIPT').GetString() -cne 'IN_PROGRESS') { Throw-Jpc054DRejected 'CONFLICTING_R5B_RECEIPT' }
    }
    finally { $r3.Dispose();$final.Dispose();$r5.Dispose() }
    return [pscustomobject]@{ frozen_a5_required=$true; no_protected_transaction_namespace=$true; r3_public_stage0_updated=$false; final_nonactivation_assertions=$true }
}

function Get-Jpc054DGithubEvidence {
    param([Parameter(Mandatory)][object]$Lease,[object]$SuppliedEvidence = $null)
    if ($null -ne $SuppliedEvidence) { return $SuppliedEvidence }
    try { $raw = (& gh api 'repos/JerrySkywalker/jerry-proxy-client/pulls/55' --method GET 2>$null) -join "`n"; $pr = $raw | ConvertFrom-Json }
    catch { Throw-Jpc054DRejected 'GITHUB_EVIDENCE_UNAVAILABLE' }
    if ($null -eq $pr -or [string]$pr.number -ne '55') { Throw-Jpc054DRejected 'GITHUB_EVIDENCE_UNAVAILABLE' }
    [pscustomobject]@{ current_state=[string]$pr.state; merged_at=[string]$pr.merged_at; current_head_sha=[string]$pr.head.sha; merge_commit_sha=[string]$pr.merge_commit_sha }
}

function Assert-Jpc054DHistoricalPrChainIncomplete {
    param([Parameter(Mandatory)][object]$GitHubEvidence,[Parameter(Mandatory)][object]$Lease)
    $state = [string]$GitHubEvidence.current_state; $mergedAt = [string]$GitHubEvidence.merged_at
    if ($state -notin @('open','closed')) { Throw-Jpc054DRejected 'GITHUB_EVIDENCE_CONFLICT' }
    # The historical chain is conjunctive and starts with PR55 merge:
    # merge -> exact-main -> rc.3.2 -> custody -> fresh A5 admission.  Thus a
    # missing merge, or a merge after the 054D hard stop, is a positive proof
    # that no later edge can be attributed to 054D.  Do not use later public
    # release state as attribution evidence for this historical transaction.
    if ([string]::IsNullOrWhiteSpace($mergedAt)) { return [pscustomobject]@{ historical_chain_incomplete=$true; github_state=$state; later_state=$false; first_required_edge='PR55_MERGE'; remaining_required_edges='EXACT_MAIN_RC32_CUSTODY_FRESH_A5' } }
    $merged = ConvertTo-Jpc054DUtc -Value $mergedAt -Field 'github_merged_at'
    if ($merged -le $Lease.hard_stop) { Throw-Jpc054DRejected 'HISTORICAL_PR55_MERGE_CONFLICT' }
    return [pscustomobject]@{ historical_chain_incomplete=$true; github_state=$state; later_state=$true; first_required_edge='PR55_MERGE'; remaining_required_edges='EXACT_MAIN_RC32_CUSTODY_FRESH_A5' }
}

function Get-Jpc054DClosurePaths {
    param([Parameter(Mandatory)][object]$Contract)
    $history = Get-Jpc054DFullPath -Path $Contract.history_root
    if (Test-Jpc054DPathWithin -Root $Contract.coordination_root -Candidate $history) { Throw-Jpc054DRejected 'HISTORY_WITHIN_EVIDENCE_ROOT' }
    Assert-Jpc054DNoReparseExistingAncestors -Path $history | Out-Null
    $sha = $Contract.expected_lease_sha256
    [pscustomobject]@{ root=$history; lease_path=(Join-Path $history ('historical-leases\' + $sha + '.jpc.coordination-writer-lease.v1.json')); receipt_path=(Join-Path $history ('closure-receipts\' + $sha + '.protected-scope-closure.json')); lock_path=(Join-Path $history ('.locks\' + $sha + '.054d-protected-scope-closure.lock')) }
}

function Get-Jpc054DVerification {
    param([Parameter(Mandatory)][object]$Contract,[DateTimeOffset]$NowUtc=[DateTimeOffset]::UtcNow,[object]$GitHubEvidence=$null,[switch]$AllowHeldClosureLock)
    try {
        $paths = Get-Jpc054DClosurePaths -Contract $Contract
        if (-not $AllowHeldClosureLock -and (Test-Path -LiteralPath $paths.lock_path)) { Throw-Jpc054DRejected 'CONCURRENT_CLOSURE_LOCK' }
        $inventory = Get-Jpc054DInventory -Contract $Contract
        if ($inventory.root_file_count -ne 14) { Throw-Jpc054DRejected 'ROOT_FILE_COUNT' }
        $leaseBytes = Get-Jpc054DFileBytes -Path $Contract.lease_path
        $leaseSha = Get-Jpc054DBytesSha256 -Bytes $leaseBytes
        if ($leaseSha -cne $Contract.expected_lease_sha256) { Throw-Jpc054DRejected 'LEASE_SHA256' }
        $lease = Read-Jpc054DLease -Bytes $leaseBytes -Contract $Contract
        if (-not ($lease.hard_stop -lt $NowUtc.ToUniversalTime())) { Throw-Jpc054DRejected 'LEASE_NOT_EXPIRED' }
        $holderDead = Assert-Jpc054DHolderDead -Lease $lease
        $proof = Assert-Jpc054DNonActivationEvidence -Inventory $inventory -Contract $Contract
        $github = Get-Jpc054DGithubEvidence -Lease $lease -SuppliedEvidence $GitHubEvidence
        $chain = Assert-Jpc054DHistoricalPrChainIncomplete -GitHubEvidence $github -Lease $lease
        $proofText = ([ordered]@{ schema='jpc.054d-non-activation-proof.v1'; lease_sha256=$leaseSha; evidence_manifest_sha256=$inventory.evidence_manifest_sha256; frozen_a5_required=[bool]$proof.frozen_a5_required; no_protected_transaction_namespace=[bool]$proof.no_protected_transaction_namespace; r3_public_stage0_updated=[bool]$proof.r3_public_stage0_updated; final_nonactivation_assertions=[bool]$proof.final_nonactivation_assertions; github_pr55_state=[string]$chain.github_state; github_state_is_later=[bool]$chain.later_state; historical_pr55_chain_incomplete=[bool]$chain.historical_chain_incomplete; historical_chain_first_required_edge=[string]$chain.first_required_edge; historical_chain_remaining_required_edges=[string]$chain.remaining_required_edges } | ConvertTo-Json -Compress -Depth 8)
        [pscustomobject]@{ status='CLOSURE_VERIFY_PASS'; closure_verification='PASS'; lease_path=$Contract.lease_path; lease_sha256=$leaseSha; lease_expired=$true; holder_dead=$holderDead; holder_live=$false; root_file_count=$inventory.root_file_count; root_manifest_sha256=$inventory.root_manifest_sha256; evidence_manifest_sha256=$inventory.evidence_manifest_sha256; non_activation_proof_sha256=(Get-Jpc054DTextSha256 -Text $proofText); closure_classification='CLOSED_WITHOUT_PROTECTED_ACTIVATION'; production_apply_executed=$false; production_rollback_required=$false; new_production_authority_granted=$false; closure_destination=$paths.lease_path; receipt_destination=$paths.receipt_path; closure_safe=$true; github_pr55_state=[string]$chain.github_state; github_state_is_later=[bool]$chain.later_state }
    }
    catch {
        $code = [string]$_.Exception.Message
        if ($code -notmatch '^CLOSURE_VERIFICATION_FAIL_CLOSED_[A-Z0-9_]+$') { $code='CLOSURE_VERIFICATION_FAIL_CLOSED_INTERNAL' }
        [pscustomobject]@{ status=$code; closure_verification='FAIL_CLOSED'; lease_path=''; lease_sha256=''; lease_expired=$false; holder_dead=$false; holder_live=$false; root_file_count=0; root_manifest_sha256=''; evidence_manifest_sha256=''; non_activation_proof_sha256=''; closure_classification=''; production_apply_executed=$false; production_rollback_required=$false; new_production_authority_granted=$false; closure_destination=''; receipt_destination=''; closure_safe=$false; github_pr55_state=''; github_state_is_later=$false }
    }
}

function Read-Jpc054DAuthorization {
    param([Parameter(Mandatory)][string]$AuthorizationPath,[Parameter(Mandatory)][object]$Verification,[Parameter(Mandatory)][object]$Contract,[DateTimeOffset]$NowUtc=[DateTimeOffset]::UtcNow)
    $path = Assert-Jpc054DRegularFile -Path $AuthorizationPath
    if (Test-Jpc054DPathWithin -Root $Contract.coordination_root -Candidate $path) { Throw-Jpc054DRejected 'AUTHORIZATION_INSIDE_EVIDENCE_ROOT' }
    $bytes = [System.IO.File]::ReadAllBytes($path); $checked=Get-Jpc054DStrictJsonRoot -Bytes $bytes -Expected $script:Jpc054DAuthorizationFields -FailureCode 'MALFORMED_AUTHORIZATION'
    try { $p=$checked.Properties; $authorization=[pscustomobject]@{}; foreach($name in @('schema','authorization_id','authorized_by','authorized_utc','expires_utc','source_lease_path','lease_sha256','goal','run_id','evidence_manifest_sha256','non_activation_proof_sha256','classification','historical_lease_path','receipt_path')){$authorization|Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString()}; foreach($name in @('production_apply_executed','production_rollback_required','new_production_authority_granted')){$authorization|Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetBoolean()} }
    finally { $checked.Document.Dispose() }
    if ($authorization.schema -cne 'jpc.protected-scope-closure-authorization.v1' -or $authorization.authorized_by -cne 'Owner' -or $authorization.lease_sha256 -cne $Verification.lease_sha256 -or $authorization.goal -cne $Contract.goal -or $authorization.run_id -cne $Contract.run_id -or $authorization.evidence_manifest_sha256 -cne $Verification.evidence_manifest_sha256 -or $authorization.non_activation_proof_sha256 -cne $Verification.non_activation_proof_sha256 -or $authorization.classification -cne 'CLOSED_WITHOUT_PROTECTED_ACTIVATION' -or $authorization.source_lease_path -cne $Contract.lease_path -or $authorization.historical_lease_path -cne $Verification.closure_destination -or $authorization.receipt_path -cne $Verification.receipt_destination -or $authorization.production_apply_executed -or $authorization.production_rollback_required -or $authorization.new_production_authority_granted) { Throw-Jpc054DRejected 'AUTHORIZATION_BINDING' }
    if ($authorization.authorization_id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') { Throw-Jpc054DRejected 'MALFORMED_AUTHORIZATION' }
    $authorized=ConvertTo-Jpc054DUtc -Value $authorization.authorized_utc -Field 'authorization_authorized_utc';$expires=ConvertTo-Jpc054DUtc -Value $authorization.expires_utc -Field 'authorization_expires_utc'
    if($authorized -gt $NowUtc.ToUniversalTime() -or $expires -le $NowUtc.ToUniversalTime() -or ($expires-$authorized).TotalMinutes -gt 30){Throw-Jpc054DRejected 'AUTHORIZATION_EXPIRED_OR_UNBOUNDED'}
    [pscustomobject]@{ authorization=$authorization; sha256=(Get-Jpc054DBytesSha256 -Bytes $bytes); path=$path }
}

function Ensure-Jpc054DHistoryDirectories {
    param([Parameter(Mandatory)][object]$ClosurePaths)
    $directories = @($ClosurePaths.root,(Split-Path -Parent $ClosurePaths.lease_path),(Split-Path -Parent $ClosurePaths.receipt_path),(Split-Path -Parent $ClosurePaths.lock_path))
    foreach($path in $directories){
        Assert-Jpc054DNoReparseExistingAncestors -Path $path | Out-Null
        [System.IO.Directory]::CreateDirectory($path) | Out-Null
        Assert-Jpc054DDirectory -Path $path | Out-Null
    }
}

function Enter-Jpc054DClosureLock {
    param([Parameter(Mandatory)][object]$ClosurePaths)
    try { return [System.IO.File]::Open($ClosurePaths.lock_path,[System.IO.FileMode]::CreateNew,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-Jpc054DRejected 'CONCURRENT_CLOSURE_LOCK' }
}

function Write-Jpc054DImmutableJson {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Value)
    $parent=Assert-Jpc054DDirectory -Path (Split-Path -Parent $Path)
    $bytes=[System.Text.UTF8Encoding]::new($false).GetBytes(($Value|ConvertTo-Json -Compress -Depth 16))
    try{$stream=[System.IO.File]::Open($Path,[System.IO.FileMode]::CreateNew,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None)}catch [System.IO.IOException]{Throw-Jpc054DRejected 'IMMUTABLE_RECEIPT_COLLISION'}
    try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
    (Get-Item -LiteralPath $Path -Force).Attributes = ((Get-Item -LiteralPath $Path -Force).Attributes -bor [System.IO.FileAttributes]::ReadOnly)
    Assert-Jpc054DRegularFile -Path $Path|Out-Null
}

function Read-Jpc054DClosureReceipt {
    param([Parameter(Mandatory)][string]$Path)
    $checked=Get-Jpc054DStrictJsonRoot -Bytes (Get-Jpc054DFileBytes -Path $Path) -Expected $script:Jpc054DReceiptFields -FailureCode 'HISTORY_INTEGRITY'
    try{$p=$checked.Properties;[pscustomobject]@{schema=$p.schema.GetString();classification=$p.classification.GetString();source_lease_path=$p.source_lease_path.GetString();historical_lease_path=$p.historical_lease_path.GetString();receipt_path=$p.receipt_path.GetString();original_lease_schema=$p.original_lease_schema.GetString();original_lease_sha256=$p.original_lease_sha256.GetString();goal=$p.goal.GetString();run_id=$p.run_id.GetString();evidence_manifest_sha256=$p.evidence_manifest_sha256.GetString();non_activation_proof_sha256=$p.non_activation_proof_sha256.GetString();production_apply_executed=$p.production_apply_executed.GetBoolean();production_rollback_required=$p.production_rollback_required.GetBoolean();new_production_authority_granted=$p.new_production_authority_granted.GetBoolean()}}
    finally{$checked.Document.Dispose()}
}

function Get-Jpc054DAlreadyClosed {
    param([Parameter(Mandatory)][object]$Contract)
    $paths=Get-Jpc054DClosurePaths -Contract $Contract
    if(Test-Path -LiteralPath $Contract.lease_path){return $null}
    if(-not (Test-Path -LiteralPath $paths.lease_path) -or -not (Test-Path -LiteralPath $paths.receipt_path)){Throw-Jpc054DRejected 'INTERRUPTED_CLOSE_RECOVERY_REQUIRED'}
    $historical=Assert-Jpc054DRegularFile -Path $paths.lease_path
    if((Get-Jpc054DBytesSha256 -Bytes ([IO.File]::ReadAllBytes($historical))) -cne $Contract.expected_lease_sha256){Throw-Jpc054DRejected 'HISTORY_INTEGRITY'}
    $receipt=Read-Jpc054DClosureReceipt -Path $paths.receipt_path
    if($receipt.schema -cne 'jpc.protected-scope-closure-without-activation.v1' -or $receipt.classification -cne 'CLOSED_WITHOUT_PROTECTED_ACTIVATION' -or $receipt.source_lease_path -cne $Contract.lease_path -or $receipt.historical_lease_path -cne $paths.lease_path -or $receipt.receipt_path -cne $paths.receipt_path -or $receipt.original_lease_schema -cne $Contract.lease_schema -or $receipt.original_lease_sha256 -cne $Contract.expected_lease_sha256 -or $receipt.goal -cne $Contract.goal -or $receipt.run_id -cne $Contract.run_id -or $receipt.evidence_manifest_sha256 -notmatch '^[0-9a-f]{64}$' -or $receipt.non_activation_proof_sha256 -notmatch '^[0-9a-f]{64}$' -or $receipt.production_apply_executed -or $receipt.production_rollback_required -or $receipt.new_production_authority_granted){Throw-Jpc054DRejected 'HISTORY_INTEGRITY'}
    [pscustomobject]@{status='CLOSURE_ALREADY_CLOSED';historical_lease_path=$historical;receipt_path=(Assert-Jpc054DRegularFile -Path $paths.receipt_path);receipt=$receipt}
}

function Invoke-Jpc054DProtectedScopeClosureInternal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Verify','Close')][string]$Mode,[string]$AuthorizationPath='', [object]$Contract=$null,[object]$GitHubEvidence=$null,[string]$FaultInjection='')
    if($null -eq $Contract){$Contract=New-Jpc054DContract}
    if($Mode -eq 'Verify'){return Get-Jpc054DVerification -Contract $Contract -GitHubEvidence $GitHubEvidence}
    try {
        $already=Get-Jpc054DAlreadyClosed -Contract $Contract
        if($null -ne $already){
            if([string]::IsNullOrWhiteSpace($AuthorizationPath)){Throw-Jpc054DRejected 'AUTHORIZATION_REQUIRED'}
            $closedVerification=[pscustomobject]@{lease_sha256=$Contract.expected_lease_sha256;evidence_manifest_sha256=$already.receipt.evidence_manifest_sha256;non_activation_proof_sha256=$already.receipt.non_activation_proof_sha256;closure_destination=$already.historical_lease_path;receipt_destination=$already.receipt_path}
            Read-Jpc054DAuthorization -AuthorizationPath $AuthorizationPath -Verification $closedVerification -Contract $Contract | Out-Null
            return [pscustomobject]@{status=$already.status;closure_verification='PASS';historical_lease_path=$already.historical_lease_path;receipt_path=$already.receipt_path;production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false}
        }
        $verification=Get-Jpc054DVerification -Contract $Contract -GitHubEvidence $GitHubEvidence
        if($verification.status -ne 'CLOSURE_VERIFY_PASS'){return [pscustomobject]@{status=$verification.status;closure_verification='FAIL_CLOSED';historical_lease_path='';receipt_path='';production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false}}
        if([string]::IsNullOrWhiteSpace($AuthorizationPath)){Throw-Jpc054DRejected 'AUTHORIZATION_REQUIRED'}
        $authorization=Read-Jpc054DAuthorization -AuthorizationPath $AuthorizationPath -Verification $verification -Contract $Contract
        $paths=Get-Jpc054DClosurePaths -Contract $Contract;Ensure-Jpc054DHistoryDirectories -ClosurePaths $paths
        $lock=Enter-Jpc054DClosureLock -ClosurePaths $paths
        try {
            $recheck=Get-Jpc054DVerification -Contract $Contract -GitHubEvidence $GitHubEvidence -AllowHeldClosureLock
            if($recheck.status -ne 'CLOSURE_VERIFY_PASS'){return [pscustomobject]@{status=$recheck.status;closure_verification='FAIL_CLOSED';historical_lease_path='';receipt_path='';production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false}}
            $authorization=Read-Jpc054DAuthorization -AuthorizationPath $AuthorizationPath -Verification $recheck -Contract $Contract
            if((Test-Path -LiteralPath $paths.lease_path) -or (Test-Path -LiteralPath $paths.receipt_path)){Throw-Jpc054DRejected 'IMMUTABLE_DESTINATION_COLLISION'}
            $bytes=Get-Jpc054DFileBytes -Path $Contract.lease_path
            if((Get-Jpc054DBytesSha256 -Bytes $bytes) -cne $recheck.lease_sha256){Throw-Jpc054DRejected 'SOURCE_BYTES_DRIFT'}
            [IO.File]::Move($Contract.lease_path,$paths.lease_path)
            if(Test-Path -LiteralPath $Contract.lease_path){Throw-Jpc054DRejected 'ACTIVE_SOURCE_REMAINS'}
            if((Get-Jpc054DBytesSha256 -Bytes (Get-Jpc054DFileBytes -Path $paths.lease_path)) -cne $recheck.lease_sha256){Throw-Jpc054DRejected 'HISTORY_INTEGRITY'}
            if($FaultInjection -eq 'AfterMove'){Throw-Jpc054DRejected 'FAULT_INJECTED_AFTER_MOVE'}
            $receipt=[ordered]@{schema='jpc.protected-scope-closure-without-activation.v1';closure_id=('sha256-'+$recheck.lease_sha256);closed_utc=[DateTimeOffset]::UtcNow.ToString('o');classification='CLOSED_WITHOUT_PROTECTED_ACTIVATION';source_lease_path=$Contract.lease_path;historical_lease_path=$paths.lease_path;receipt_path=$paths.receipt_path;original_lease_schema=$Contract.lease_schema;original_lease_sha256=$recheck.lease_sha256;goal=$Contract.goal;run_id=$Contract.run_id;evidence_manifest_sha256=$recheck.evidence_manifest_sha256;non_activation_proof_sha256=$recheck.non_activation_proof_sha256;authorization_sha256=$authorization.sha256;production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false}
            Write-Jpc054DImmutableJson -Path $paths.receipt_path -Value $receipt
            $closed=Get-Jpc054DAlreadyClosed -Contract $Contract
            if($null -eq $closed){Throw-Jpc054DRejected 'HISTORY_INTEGRITY'}
            [pscustomobject]@{status='CLOSURE_CLOSE_PASS';closure_verification='PASS';historical_lease_path=$closed.historical_lease_path;receipt_path=$closed.receipt_path;production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false}
        }
        finally{$lock.Dispose();if(Test-Path -LiteralPath $paths.lock_path){Remove-Item -LiteralPath $paths.lock_path -Force}}
    }
    catch { $code=[string]$_.Exception.Message;if($code -notmatch '^CLOSURE_VERIFICATION_FAIL_CLOSED_[A-Z0-9_]+$'){$code='CLOSURE_VERIFICATION_FAIL_CLOSED_INTERNAL'};[pscustomobject]@{status=$code;closure_verification='FAIL_CLOSED';historical_lease_path='';receipt_path='';production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false} }
}

function Invoke-Jpc054DProtectedScopeClosure {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Verify','Close')][string]$Mode,[string]$AuthorizationPath='')
    return Invoke-Jpc054DProtectedScopeClosureInternal -Mode $Mode -AuthorizationPath $AuthorizationPath
}

function New-Jpc053JContract {
    param(
        [string]$TaskRoot = 'V:\src\jpc-multi-device-enrollment-train',
        [string]$HistoryRoot = '',
        [string]$PredecessorSettlementPath = 'C:\build\jpc-054d\coord\receipts\PREDECESSOR-053J-SETTLEMENT.json',
        [switch]$ShadowAudit
    )

    $root = Get-Jpc054DFullPath -Path $TaskRoot
    $realRoot = Get-Jpc054DFullPath -Path 'V:\src\jpc-multi-device-enrollment-train'
    if ($ShadowAudit -and $root.Equals($realRoot, [System.StringComparison]::OrdinalIgnoreCase)) { Throw-Jpc054DRejected 'SHADOW_CONTRACT_TARGETS_REAL_ROOT' }
    if (-not $ShadowAudit -and -not $root.Equals($realRoot, [System.StringComparison]::OrdinalIgnoreCase)) { Throw-Jpc054DRejected 'REAL_CONTRACT_TASK_ROOT' }
    if ([string]::IsNullOrWhiteSpace($HistoryRoot)) { $HistoryRoot = Join-Path $root '.coord-local\leases\history\protected-scope-closeouts\053j' }

    $goalRelative = '.coord-local/goals/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J.json'
    $budgetRelative = '.coord-local/state/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z/budget.json'
    $receiptRootRelative = '.coord-local/receipts/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z'
    return [pscustomobject]@{
        task_root = $root
        history_root = (Get-Jpc054DFullPath -Path $HistoryRoot)
        lease_path = (Join-Path $root '.coord-local\leases\taskroot-writer.active.json')
        goal_path = (Join-Path $root $goalRelative)
        budget_path = (Join-Path $root $budgetRelative)
        intent_path = (Join-Path $root ($receiptRootRelative + '/PROMOTION-1-INTENT.json'))
        terminal_path = (Join-Path $root ($receiptRootRelative + '/PROMOTION-1-TERMINAL.json'))
        final_receipt_path = (Join-Path $root ($receiptRootRelative + '/FINAL-RECEIPT.md'))
        predecessor_settlement_path = (Get-Jpc054DFullPath -Path $PredecessorSettlementPath)
        goal = 'JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J'
        run_id = 'JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z'
        transaction_id = 'a5-rc31-053j-promote-86cd67b62939465687cf49efbd1bf872'
        lease_schema = 'jpc.taskroot-writer-lease.v1'
        expected_lease_sha256 = '2a68e7130affb8e39ae821e80b10c1e3891254b2de091bf81e5f60100d20100a'
        expected_goal_sha256 = '218c437a872d8f14c9fe9f33ceb42da0e878d5079ddb403863a71b8dfc196701'
        expected_budget_sha256 = 'fb849059fd1a6923089fbf95d645d905c66a62c945b1b2c00d53e3af01888d0a'
        expected_intent_sha256 = '58184159494c329a4a5f854780ada9f8d6eebbff344588c18e501025cea0c054'
        expected_terminal_sha256 = '0ed6233b068747248d4c18450e8011038af3462a356bf3d8507f33816c22c9d5'
        expected_final_receipt_sha256 = '655138e39e9f4c259ef4d5a56d7c81fde22b0f6450686d489feb8e2dbce15e2b'
        expected_predecessor_settlement_sha256 = '3e479110e263c2263f552df0632d9911262f3af759696149065390630e686ab4'
        classification = 'CLOSED_WITHOUT_PROTECTED_ACTIVATION'
        terminal_class = 'UNCONSUMED_PRE_APPLY_REJECTED'
        terminal_reason = 'PUBLIC_MANIFEST_FETCH_REJECTED'
        authorization_scope = $(if ($ShadowAudit) { 'SHADOW_AUDIT_AUTHORIZATION' } else { 'EXACT_053J_UNCONSUMED_PRE_APPLY_CLOSEOUT' })
        authority_environment = $(if ($ShadowAudit) { 'SHADOW_AUDIT_ONLY' } else { 'REAL_053J_TASK_ROOT_ONLY' })
        real_task_root_authority = $(if ($ShadowAudit) { 'NOT_VALID_FOR_REAL_TASK_ROOT' } else { 'OWNER_BOUNDED_EXACT_053J' })
        authorized_by = $(if ($ShadowAudit) { 'OwnerFixture' } else { 'Owner' })
        shadow_audit = [bool]$ShadowAudit
    }
}

function Assert-Jpc053JExactFile {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$ExpectedSha256,[Parameter(Mandatory)][string]$FailureCode)
    $file = Assert-Jpc054DRegularFile -Path $Path
    $bytes = [System.IO.File]::ReadAllBytes($file)
    if ((Get-Jpc054DBytesSha256 -Bytes $bytes) -cne $ExpectedSha256) { Throw-Jpc054DRejected $FailureCode }
    return [pscustomobject]@{ path=$file; bytes=$bytes; sha256=$ExpectedSha256 }
}

function Read-Jpc053JLease {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][object]$Contract)
    $checked = Get-Jpc054DStrictJsonRoot -Bytes $Bytes -Expected $script:Jpc053JLeaseFields -FailureCode 'MALFORMED_053J_LEASE'
    try {
        $p = $checked.Properties
        $lease = [pscustomobject]@{
            schema=$p.schema.GetString(); goal=$p.goal.GetString(); holder=$p.holder.GetString(); holder_session=$p.holder_session.GetString()
            state=$p.state.GetString(); acquired_utc=$p.acquired_utc.GetString(); created_utc=$p.created_utc.GetString(); hard_stop_utc=$p.hard_stop_utc.GetString()
            single_intentional_writer=$p.single_intentional_writer.GetBoolean(); scope=@($p.scope.EnumerateArray() | ForEach-Object { $_.GetString() })
            goal_ref=$p.goal_ref.GetString(); budget_state_ref=$p.budget_state_ref.GetString()
        }
    }
    finally { $checked.Document.Dispose() }
    if ($lease.schema -cne $Contract.lease_schema -or $lease.goal -cne $Contract.goal -or $lease.holder_session -cne 'jpc-v22-ga-fastlane-053j' -or $lease.state -cne 'active' -or -not $lease.single_intentional_writer -or $lease.scope.Count -ne 3) { Throw-Jpc054DRejected '053J_LEASE_BINDING' }
    if ([string]::IsNullOrWhiteSpace($lease.holder) -or $lease.goal_ref.Replace('\','/') -cne '.coord-local/goals/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J.json' -or $lease.budget_state_ref.Replace('\','/') -cne '.coord-local/state/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z/budget.json') { Throw-Jpc054DRejected '053J_LEASE_BINDING' }
    $lease | Add-Member -NotePropertyName created -NotePropertyValue (ConvertTo-Jpc054DUtc -Value $lease.created_utc -Field '053j_created_utc')
    $lease | Add-Member -NotePropertyName acquired -NotePropertyValue (ConvertTo-Jpc054DUtc -Value $lease.acquired_utc -Field '053j_acquired_utc')
    $lease | Add-Member -NotePropertyName hard_stop -NotePropertyValue (ConvertTo-Jpc054DUtc -Value $lease.hard_stop_utc -Field '053j_hard_stop_utc')
    if ($lease.created -gt $lease.acquired -or $lease.acquired -gt $lease.hard_stop) { Throw-Jpc054DRejected 'MALFORMED_053J_LEASE' }
    return $lease
}

function Assert-Jpc053JImmutableEvidence {
    param([Parameter(Mandatory)][object]$Contract,[Parameter(Mandatory)][object]$Lease)
    $goalFile = Assert-Jpc053JExactFile -Path $Contract.goal_path -ExpectedSha256 $Contract.expected_goal_sha256 -FailureCode '053J_GOAL_SHA256'
    $budgetFile = Assert-Jpc053JExactFile -Path $Contract.budget_path -ExpectedSha256 $Contract.expected_budget_sha256 -FailureCode '053J_BUDGET_SHA256'
    $intentFile = Assert-Jpc053JExactFile -Path $Contract.intent_path -ExpectedSha256 $Contract.expected_intent_sha256 -FailureCode '053J_INTENT_SHA256'
    $terminalFile = Assert-Jpc053JExactFile -Path $Contract.terminal_path -ExpectedSha256 $Contract.expected_terminal_sha256 -FailureCode '053J_TERMINAL_SHA256'
    $finalFile = Assert-Jpc053JExactFile -Path $Contract.final_receipt_path -ExpectedSha256 $Contract.expected_final_receipt_sha256 -FailureCode '053J_FINAL_RECEIPT_SHA256'
    $predecessorFile = Assert-Jpc053JExactFile -Path $Contract.predecessor_settlement_path -ExpectedSha256 $Contract.expected_predecessor_settlement_sha256 -FailureCode '053J_PREDECESSOR_SETTLEMENT_SHA256'

    $goalChecked = Get-Jpc054DStrictJsonRoot -Bytes $goalFile.bytes -Expected $script:Jpc053JGoalFields -FailureCode 'MALFORMED_053J_GOAL'
    try {
        $p = $goalChecked.Properties
        if ($p.schema.GetString() -cne 'jpc.frozen-goal.v1' -or $p.goal.GetString() -cne $Contract.goal -or $p.run_id.GetString() -cne $Contract.run_id -or $p.profile.GetString() -cne 'PROTECTED_TRANSACTION_V2' -or $p.current_layer.GetString() -cne 'L4' -or $p.max_admitted_layer.GetString() -cne 'L5' -or $p.budget_state_ref.GetString().Replace('\','/') -cne '.coord-local/state/JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z/budget.json') { Throw-Jpc054DRejected '053J_GOAL_BINDING' }
        if (@($p.protected_boundaries.EnumerateArray()).Count -ne 2 -or @($p.owner_only_boundaries.EnumerateArray()).Count -ne 2) { Throw-Jpc054DRejected '053J_GOAL_BINDING' }
    }
    finally { $goalChecked.Document.Dispose() }

    $budgetChecked = Get-Jpc054DStrictJsonRoot -Bytes $budgetFile.bytes -Expected $script:Jpc053JBudgetFields -FailureCode 'MALFORMED_053J_BUDGET'
    try {
        $p = $budgetChecked.Properties
        if ($p.schema.GetString() -cne 'jpc.v22.ga-fastlane.budget.v1' -or $p.goal.GetString() -cne $Contract.goal -or $p.run_id.GetString() -cne $Contract.run_id) { Throw-Jpc054DRejected '053J_BUDGET_BINDING' }
    }
    finally { $budgetChecked.Document.Dispose() }

    $intentChecked = Get-Jpc054DStrictJsonRoot -Bytes $intentFile.bytes -Expected $script:Jpc053JIntentFields -FailureCode 'MALFORMED_053J_INTENT'
    try {
        $p = $intentChecked.Properties
        if ($p.schema.GetString() -cne 'jpc.v22.a5-promotion-intent.v1' -or $p.goal.GetString() -cne $Contract.goal -or $p.run_id.GetString() -cne $Contract.run_id -or $p.transaction_id.GetString() -cne $Contract.transaction_id -or $p.target_metadata_mutated.GetBoolean() -or -not $p.custody_rehash_pass.GetBoolean() -or -not $p.source_anchor_pass.GetBoolean() -or -not $p.prestate_probe_pass.GetBoolean() -or -not $p.mutation_readiness_pass.GetBoolean() -or $p.production_mutation_started.GetBoolean()) { Throw-Jpc054DRejected '053J_INTENT_BINDING' }
    }
    finally { $intentChecked.Document.Dispose() }

    $terminalChecked = Get-Jpc054DStrictJsonRoot -Bytes $terminalFile.bytes -Expected $script:Jpc053JTerminalFields -FailureCode 'MALFORMED_053J_TERMINAL'
    try {
        $p = $terminalChecked.Properties
        if ($p.schema.GetString() -cne 'jpc.v22.a5-promotion-terminal.v1' -or $p.goal.GetString() -cne $Contract.goal -or $p.run_id.GetString() -cne $Contract.run_id -or $p.transaction_id.GetString() -cne $Contract.transaction_id -or $p.result.GetString() -cne $Contract.terminal_class -or $p.failure_code.GetString() -cne $Contract.terminal_reason -or $p.adapter_launch_reached_remote_prepare.GetBoolean() -or $p.production_mutation_started.GetBoolean() -or $p.rollback_required.GetBoolean() -or $p.rollback_verified.GetString() -cne 'not-required' -or -not $p.same_transaction_replay_prohibited.GetBoolean()) { Throw-Jpc054DRejected '053J_TERMINAL_BINDING' }
    }
    finally { $terminalChecked.Document.Dispose() }

    $finalText = [System.Text.UTF8Encoding]::new($false, $true).GetString($finalFile.bytes)
    foreach ($line in @('PROMOTION_1_RESULT=UNCONSUMED_PRE_APPLY_REJECTED','PROMOTION_1_FAILURE_CODE=PUBLIC_MANIFEST_FETCH_REJECTED','PROMOTION_2_RESULT=NOT_STARTED','PROMOTION_3_RESULT=NOT_STARTED')) {
        if ($finalText -notmatch ('(?m)^' + [regex]::Escape($line) + '$')) { Throw-Jpc054DRejected '053J_FINAL_RECEIPT_BINDING' }
    }

    $predecessor = Get-Jpc054DJsonObject -Bytes $predecessorFile.bytes -FailureCode 'MALFORMED_053J_PREDECESSOR_SETTLEMENT'
    try {
        $root = $predecessor.RootElement
        if ((Get-Jpc054DProperty -Object $root -Name 'schema' -Kind String -FailureCode '053J_PREDECESSOR_BINDING').GetString() -cne 'jpc.coordination-predecessor-settlement.v1' -or (Get-Jpc054DProperty -Object $root -Name 'reason' -Kind String -FailureCode '053J_PREDECESSOR_BINDING').GetString() -cne 'EXPIRED_LEASE_WITH_NO_CANONICAL_RECLAIM_IMPLEMENTATION') { Throw-Jpc054DRejected '053J_PREDECESSOR_BINDING' }
        $p = Get-Jpc054DProperty -Object $root -Name 'predecessor' -Kind Object -FailureCode '053J_PREDECESSOR_BINDING'
        $leaseSha = (Get-Jpc054DProperty -Object $p -Name 'lease_sha256' -Kind String -FailureCode '053J_PREDECESSOR_BINDING').GetString().ToLowerInvariant()
        $liveness = (Get-Jpc054DProperty -Object $p -Name 'holder_liveness' -Kind String -FailureCode '053J_PREDECESSOR_BINDING').GetString()
        if ((Get-Jpc054DProperty -Object $p -Name 'goal' -Kind String -FailureCode '053J_PREDECESSOR_BINDING').GetString() -cne $Contract.goal -or $leaseSha -cne $Contract.expected_lease_sha256 -or $liveness -cne 'DEAD_RECONFIRMED_NO_PREDECESSOR_SESSION_OR_GOAL_PROCESS_MATCH' -or (Get-Jpc054DProperty -Object $p -Name 'mutated' -Kind False -FailureCode '053J_PREDECESSOR_BINDING').GetBoolean()) { Throw-Jpc054DRejected '053J_PREDECESSOR_BINDING' }
    }
    finally { $predecessor.Dispose() }

    $manifestText = @(
        'jpc-053j-terminal-evidence-manifest.v1',
        ('goal|' + $Contract.expected_goal_sha256),
        ('budget|' + $Contract.expected_budget_sha256),
        ('intent|' + $Contract.expected_intent_sha256),
        ('terminal|' + $Contract.expected_terminal_sha256),
        ('final_receipt|' + $Contract.expected_final_receipt_sha256),
        ('predecessor_settlement|' + $Contract.expected_predecessor_settlement_sha256)
    ) -join "`n"
    $manifestText += "`n"
    $manifestSha = Get-Jpc054DTextSha256 -Text $manifestText
    $proofText = ([ordered]@{
        schema='jpc.053j-nonactivation-proof.v1'; lease_sha256=$Contract.expected_lease_sha256; evidence_manifest_sha256=$manifestSha
        transaction_id=$Contract.transaction_id; terminal_class=$Contract.terminal_class; terminal_reason=$Contract.terminal_reason
        protected_activation_occurred=$false; production_apply_executed=$false; rollback_required=$false; rollback_executed=$false
        new_production_authority_granted=$false; same_transaction_replay_prohibited=$true; predecessor_holder_dead_reconfirmed=$true
    } | ConvertTo-Json -Compress -Depth 8)
    return [pscustomobject]@{ evidence_manifest_sha256=$manifestSha; non_activation_proof_sha256=(Get-Jpc054DTextSha256 -Text $proofText) }
}

function Get-Jpc053JClosurePaths {
    param([Parameter(Mandatory)][object]$Contract)
    $history = Get-Jpc054DFullPath -Path $Contract.history_root
    $sha = $Contract.expected_lease_sha256
    return [pscustomobject]@{
        root=$history
        lease_path=(Join-Path $history ('historical-leases\' + $sha + '.writer-lease.v1.json'))
        receipt_path=(Join-Path $history ('closure-receipts\' + $sha + '.053j-protected-scope-closure.json'))
        lock_path=(Join-Path $history ('.locks\' + $sha + '.053j-protected-scope-closure.lock'))
    }
}

function Get-Jpc053JClosureState {
    param([Parameter(Mandatory)][object]$Contract)
    $paths = Get-Jpc053JClosurePaths -Contract $Contract
    $active = Test-Path -LiteralPath $Contract.lease_path -PathType Leaf
    $historical = Test-Path -LiteralPath $paths.lease_path -PathType Leaf
    $receipt = Test-Path -LiteralPath $paths.receipt_path -PathType Leaf
    if ($active -and ($historical -or $receipt)) { Throw-Jpc054DRejected '053J_HISTORY_COLLISION' }
    if ($active) { return [pscustomobject]@{ state='ACTIVE'; paths=$paths; source_path=$Contract.lease_path } }
    if ($historical -and $receipt) { return [pscustomobject]@{ state='CLOSED'; paths=$paths; source_path=$paths.lease_path } }
    if ($historical -and -not $receipt) { return [pscustomobject]@{ state='RECOVERY_PENDING'; paths=$paths; source_path=$paths.lease_path } }
    if ($receipt) { Throw-Jpc054DRejected '053J_HISTORY_INTEGRITY' }
    Throw-Jpc054DRejected '053J_SOURCE_MISSING'
}

function Get-Jpc053JVerification {
    param([Parameter(Mandatory)][object]$Contract,[Parameter(Mandatory)][string]$SourcePath,[DateTimeOffset]$NowUtc=[DateTimeOffset]::UtcNow,[switch]$AllowHeldClosureLock)
    try {
        $root = Assert-Jpc054DDirectory -Path $Contract.task_root
        if ($root -cne $Contract.task_root) { Throw-Jpc054DRejected '053J_NONCANONICAL_TASK_ROOT' }
        $paths = Get-Jpc053JClosurePaths -Contract $Contract
        if (-not $AllowHeldClosureLock -and (Test-Path -LiteralPath $paths.lock_path)) { Throw-Jpc054DRejected 'CONCURRENT_CLOSURE_LOCK' }
        $leaseFile = Assert-Jpc053JExactFile -Path $SourcePath -ExpectedSha256 $Contract.expected_lease_sha256 -FailureCode '053J_LEASE_SHA256'
        $lease = Read-Jpc053JLease -Bytes $leaseFile.bytes -Contract $Contract
        if (-not ($lease.hard_stop -lt $NowUtc.ToUniversalTime())) { Throw-Jpc054DRejected '053J_LEASE_NOT_EXPIRED' }
        $evidence = Assert-Jpc053JImmutableEvidence -Contract $Contract -Lease $lease
        return [pscustomobject]@{
            status='CLOSURE_VERIFY_PASS'; closure_verification='PASS'; task_root=$Contract.task_root; lease_path=$Contract.lease_path
            lease_sha256=$Contract.expected_lease_sha256; lease_schema=$Contract.lease_schema; lease_expired=$true
            evidence_manifest_sha256=$evidence.evidence_manifest_sha256; non_activation_proof_sha256=$evidence.non_activation_proof_sha256
            closure_classification=$Contract.classification; terminal_class=$Contract.terminal_class; terminal_reason=$Contract.terminal_reason
            transaction_id=$Contract.transaction_id; historical_lease_path=$paths.lease_path; receipt_path=$paths.receipt_path
            protected_activation_occurred=$false; production_apply_executed=$false; rollback_required=$false; rollback_executed=$false
            new_production_authority_granted=$false; closure_safe=$true
        }
    }
    catch {
        $code = [string]$_.Exception.Message
        if ($code -notmatch '^CLOSURE_VERIFICATION_FAIL_CLOSED_[A-Z0-9_]+$') { $code = 'CLOSURE_VERIFICATION_FAIL_CLOSED_INTERNAL' }
        return [pscustomobject]@{ status=$code; closure_verification='FAIL_CLOSED'; task_root=''; lease_path=''; lease_sha256=''; lease_schema=''; lease_expired=$false; evidence_manifest_sha256=''; non_activation_proof_sha256=''; closure_classification=''; terminal_class=''; terminal_reason=''; transaction_id=''; historical_lease_path=''; receipt_path=''; protected_activation_occurred=$false; production_apply_executed=$false; rollback_required=$false; rollback_executed=$false; new_production_authority_granted=$false; closure_safe=$false }
    }
}

function Read-Jpc053JAuthorization {
    param([Parameter(Mandatory)][string]$AuthorizationPath,[Parameter(Mandatory)][object]$Verification,[Parameter(Mandatory)][object]$Contract,[DateTimeOffset]$NowUtc=[DateTimeOffset]::UtcNow)
    $authorizationRoot = Assert-Jpc054DDirectory -Path (Join-Path $Contract.task_root '.coord-local\authorizations')
    $path = Assert-Jpc054DRegularFile -Path $AuthorizationPath
    if (-not (Test-Jpc054DPathWithin -Root $authorizationRoot -Candidate $path)) { Throw-Jpc054DRejected '053J_AUTHORIZATION_PATH' }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $checked = Get-Jpc054DStrictJsonRoot -Bytes $bytes -Expected $script:Jpc053JAuthorizationFields -FailureCode 'MALFORMED_053J_AUTHORIZATION'
    try {
        $p = $checked.Properties
        $strings = @('schema','authorization_id','authorization_scope','authority_environment','real_task_root_authority','authorized_by','authorized_utc','expires_utc','task_root','source_lease_path','lease_sha256','goal','run_id','transaction_id','goal_sha256','budget_sha256','intent_sha256','terminal_sha256','final_receipt_sha256','predecessor_settlement_sha256','evidence_manifest_sha256','non_activation_proof_sha256','classification','terminal_class','terminal_reason','historical_lease_path','receipt_path')
        $authorization = [pscustomobject]@{}
        foreach ($name in $strings) { $authorization | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString() }
        foreach ($name in @('protected_activation_occurred','production_apply_executed','rollback_required','rollback_executed','new_production_authority_granted')) { $authorization | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetBoolean() }
    }
    finally { $checked.Document.Dispose() }
    if ($authorization.schema -cne 'jpc.053j-protected-scope-closure-authorization.v1' -or $authorization.authorization_scope -cne $Contract.authorization_scope -or $authorization.authority_environment -cne $Contract.authority_environment -or $authorization.real_task_root_authority -cne $Contract.real_task_root_authority -or $authorization.authorized_by -cne $Contract.authorized_by -or $authorization.task_root -cne $Contract.task_root -or $authorization.source_lease_path -cne $Contract.lease_path -or $authorization.lease_sha256 -cne $Verification.lease_sha256 -or $authorization.goal -cne $Contract.goal -or $authorization.run_id -cne $Contract.run_id -or $authorization.transaction_id -cne $Contract.transaction_id -or $authorization.goal_sha256 -cne $Contract.expected_goal_sha256 -or $authorization.budget_sha256 -cne $Contract.expected_budget_sha256 -or $authorization.intent_sha256 -cne $Contract.expected_intent_sha256 -or $authorization.terminal_sha256 -cne $Contract.expected_terminal_sha256 -or $authorization.final_receipt_sha256 -cne $Contract.expected_final_receipt_sha256 -or $authorization.predecessor_settlement_sha256 -cne $Contract.expected_predecessor_settlement_sha256 -or $authorization.evidence_manifest_sha256 -cne $Verification.evidence_manifest_sha256 -or $authorization.non_activation_proof_sha256 -cne $Verification.non_activation_proof_sha256 -or $authorization.classification -cne $Contract.classification -or $authorization.terminal_class -cne $Contract.terminal_class -or $authorization.terminal_reason -cne $Contract.terminal_reason -or $authorization.historical_lease_path -cne $Verification.historical_lease_path -or $authorization.receipt_path -cne $Verification.receipt_path -or $authorization.protected_activation_occurred -or $authorization.production_apply_executed -or $authorization.rollback_required -or $authorization.rollback_executed -or $authorization.new_production_authority_granted) { Throw-Jpc054DRejected '053J_AUTHORIZATION_BINDING' }
    if ($authorization.authorization_id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') { Throw-Jpc054DRejected 'MALFORMED_053J_AUTHORIZATION' }
    $authorized = ConvertTo-Jpc054DUtc -Value $authorization.authorized_utc -Field '053j_authorization_authorized_utc'
    $expires = ConvertTo-Jpc054DUtc -Value $authorization.expires_utc -Field '053j_authorization_expires_utc'
    if ($authorized -gt $NowUtc.ToUniversalTime() -or $expires -le $NowUtc.ToUniversalTime() -or ($expires - $authorized).TotalMinutes -gt 30) { Throw-Jpc054DRejected '053J_AUTHORIZATION_EXPIRED_OR_UNBOUNDED' }
    return [pscustomobject]@{ path=$path; sha256=(Get-Jpc054DBytesSha256 -Bytes $bytes); authorization=$authorization }
}

function Ensure-Jpc053JHistoryDirectories {
    param([Parameter(Mandatory)][object]$Paths)
    foreach ($path in @($Paths.root,(Split-Path -Parent $Paths.lease_path),(Split-Path -Parent $Paths.receipt_path),(Split-Path -Parent $Paths.lock_path))) {
        Assert-Jpc054DNoReparseExistingAncestors -Path $path | Out-Null
        [System.IO.Directory]::CreateDirectory($path) | Out-Null
        Assert-Jpc054DDirectory -Path $path | Out-Null
    }
}

function Read-Jpc053JReceipt {
    param([Parameter(Mandatory)][string]$Path)
    $checked = Get-Jpc054DStrictJsonRoot -Bytes (Get-Jpc054DFileBytes -Path $Path) -Expected $script:Jpc053JReceiptFields -FailureCode '053J_HISTORY_INTEGRITY'
    try {
        $p = $checked.Properties
        $receipt = [pscustomobject]@{}
        foreach ($name in @('schema','closure_id','closed_utc','classification','terminal_class','terminal_reason','source_lease_path','historical_lease_path','receipt_path','original_lease_schema','original_lease_sha256','goal','run_id','transaction_id','goal_sha256','budget_sha256','intent_sha256','terminal_sha256','final_receipt_sha256','predecessor_settlement_sha256','evidence_manifest_sha256','non_activation_proof_sha256','authorization_sha256')) { $receipt | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetString() }
        foreach ($name in @('protected_activation_occurred','production_apply_executed','rollback_required','rollback_executed','new_production_authority_granted')) { $receipt | Add-Member -NotePropertyName $name -NotePropertyValue $p[$name].GetBoolean() }
        return $receipt
    }
    finally { $checked.Document.Dispose() }
}

function Assert-Jpc053JClosedHistory {
    param([Parameter(Mandatory)][object]$Contract,[Parameter(Mandatory)][object]$Verification)
    $paths = Get-Jpc053JClosurePaths -Contract $Contract
    $historical = Assert-Jpc054DRegularFile -Path $paths.lease_path
    $receiptPath = Assert-Jpc054DRegularFile -Path $paths.receipt_path
    if ((Get-Jpc054DBytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($historical))) -cne $Contract.expected_lease_sha256) { Throw-Jpc054DRejected '053J_HISTORY_INTEGRITY' }
    if (((Get-Item -LiteralPath $historical -Force).Attributes -band [System.IO.FileAttributes]::ReadOnly) -eq 0 -or ((Get-Item -LiteralPath $receiptPath -Force).Attributes -band [System.IO.FileAttributes]::ReadOnly) -eq 0) { Throw-Jpc054DRejected '053J_HISTORY_NOT_IMMUTABLE' }
    $r = Read-Jpc053JReceipt -Path $receiptPath
    if ($r.schema -cne 'jpc.053j-protected-scope-closure-without-activation.v1' -or $r.closure_id -cne ('sha256-' + $Contract.expected_lease_sha256) -or $r.classification -cne $Contract.classification -or $r.terminal_class -cne $Contract.terminal_class -or $r.terminal_reason -cne $Contract.terminal_reason -or $r.source_lease_path -cne $Contract.lease_path -or $r.historical_lease_path -cne $paths.lease_path -or $r.receipt_path -cne $paths.receipt_path -or $r.original_lease_schema -cne $Contract.lease_schema -or $r.original_lease_sha256 -cne $Contract.expected_lease_sha256 -or $r.goal -cne $Contract.goal -or $r.run_id -cne $Contract.run_id -or $r.transaction_id -cne $Contract.transaction_id -or $r.goal_sha256 -cne $Contract.expected_goal_sha256 -or $r.budget_sha256 -cne $Contract.expected_budget_sha256 -or $r.intent_sha256 -cne $Contract.expected_intent_sha256 -or $r.terminal_sha256 -cne $Contract.expected_terminal_sha256 -or $r.final_receipt_sha256 -cne $Contract.expected_final_receipt_sha256 -or $r.predecessor_settlement_sha256 -cne $Contract.expected_predecessor_settlement_sha256 -or $r.evidence_manifest_sha256 -cne $Verification.evidence_manifest_sha256 -or $r.non_activation_proof_sha256 -cne $Verification.non_activation_proof_sha256 -or $r.authorization_sha256 -notmatch '^[0-9a-f]{64}$' -or $r.protected_activation_occurred -or $r.production_apply_executed -or $r.rollback_required -or $r.rollback_executed -or $r.new_production_authority_granted) { Throw-Jpc054DRejected '053J_HISTORY_INTEGRITY' }
    ConvertTo-Jpc054DUtc -Value $r.closed_utc -Field '053j_closed_utc' | Out-Null
    return [pscustomobject]@{ historical_lease_path=$historical; receipt_path=$receiptPath; receipt=$r }
}

function New-Jpc053JReceipt {
    param([Parameter(Mandatory)][object]$Contract,[Parameter(Mandatory)][object]$Verification,[Parameter(Mandatory)][object]$Authorization)
    return [ordered]@{
        schema='jpc.053j-protected-scope-closure-without-activation.v1'; closure_id=('sha256-' + $Contract.expected_lease_sha256); closed_utc=[DateTimeOffset]::UtcNow.ToString('o')
        classification=$Contract.classification; terminal_class=$Contract.terminal_class; terminal_reason=$Contract.terminal_reason
        source_lease_path=$Contract.lease_path; historical_lease_path=$Verification.historical_lease_path; receipt_path=$Verification.receipt_path
        original_lease_schema=$Contract.lease_schema; original_lease_sha256=$Contract.expected_lease_sha256; goal=$Contract.goal; run_id=$Contract.run_id; transaction_id=$Contract.transaction_id
        goal_sha256=$Contract.expected_goal_sha256; budget_sha256=$Contract.expected_budget_sha256; intent_sha256=$Contract.expected_intent_sha256
        terminal_sha256=$Contract.expected_terminal_sha256; final_receipt_sha256=$Contract.expected_final_receipt_sha256; predecessor_settlement_sha256=$Contract.expected_predecessor_settlement_sha256
        evidence_manifest_sha256=$Verification.evidence_manifest_sha256; non_activation_proof_sha256=$Verification.non_activation_proof_sha256; authorization_sha256=$Authorization.sha256
        protected_activation_occurred=$false; production_apply_executed=$false; rollback_required=$false; rollback_executed=$false; new_production_authority_granted=$false
    }
}

function Get-Jpc053JObserveResult {
    param([Parameter(Mandatory)][object]$Contract)
    try {
        $state = Get-Jpc053JClosureState -Contract $Contract
        $verification = Get-Jpc053JVerification -Contract $Contract -SourcePath $state.source_path
        if ($verification.closure_verification -ne 'PASS') { return $verification }
        if ($state.state -eq 'RECOVERY_PENDING') { $verification.status = 'CLOSURE_RECOVERY_PENDING' }
        elseif ($state.state -eq 'CLOSED') {
            Assert-Jpc053JClosedHistory -Contract $Contract -Verification $verification | Out-Null
            $verification.status = 'CLOSURE_ALREADY_CLOSED'
        }
        $verification | Add-Member -NotePropertyName closeout_state -NotePropertyValue $state.state
        return $verification
    }
    catch {
        $code=[string]$_.Exception.Message
        if($code -notmatch '^CLOSURE_VERIFICATION_FAIL_CLOSED_[A-Z0-9_]+$'){$code='CLOSURE_VERIFICATION_FAIL_CLOSED_INTERNAL'}
        return [pscustomobject]@{status=$code;closure_verification='FAIL_CLOSED';closeout_state='UNKNOWN';closure_safe=$false;production_apply_executed=$false;rollback_required=$false;rollback_executed=$false;new_production_authority_granted=$false}
    }
}

function Invoke-Jpc053JProtectedScopeClosureInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Observe','Close')][string]$Mode,
        [string]$AuthorizationPath='',
        [object]$Contract=$null,
        [string]$FaultInjection=''
    )
    if ($null -eq $Contract) { $Contract = New-Jpc053JContract }
    if ($Mode -eq 'Observe') { return Get-Jpc053JObserveResult -Contract $Contract }
    try {
        $state = Get-Jpc053JClosureState -Contract $Contract
        $verification = Get-Jpc053JVerification -Contract $Contract -SourcePath $state.source_path
        if ($verification.closure_verification -ne 'PASS') { return $verification }
        if ([string]::IsNullOrWhiteSpace($AuthorizationPath)) { Throw-Jpc054DRejected '053J_AUTHORIZATION_REQUIRED' }
        $authorization = Read-Jpc053JAuthorization -AuthorizationPath $AuthorizationPath -Verification $verification -Contract $Contract
        if ($state.state -eq 'CLOSED') {
            $closed = Assert-Jpc053JClosedHistory -Contract $Contract -Verification $verification
            return [pscustomobject]@{status='CLOSURE_ALREADY_CLOSED';closure_verification='PASS';historical_lease_path=$closed.historical_lease_path;receipt_path=$closed.receipt_path;protected_activation_occurred=$false;production_apply_executed=$false;rollback_required=$false;rollback_executed=$false;new_production_authority_granted=$false}
        }

        $paths = $state.paths
        Ensure-Jpc053JHistoryDirectories -Paths $paths
        $lock = Enter-Jpc054DClosureLock -ClosurePaths $paths
        try {
            $recheckState = Get-Jpc053JClosureState -Contract $Contract
            if ($recheckState.state -notin @('ACTIVE','RECOVERY_PENDING')) { Throw-Jpc054DRejected '053J_STATE_DRIFT' }
            $recheck = Get-Jpc053JVerification -Contract $Contract -SourcePath $recheckState.source_path -AllowHeldClosureLock
            if ($recheck.closure_verification -ne 'PASS') { return $recheck }
            $authorization = Read-Jpc053JAuthorization -AuthorizationPath $AuthorizationPath -Verification $recheck -Contract $Contract
            if ($recheckState.state -eq 'ACTIVE') {
                if ((Test-Path -LiteralPath $paths.lease_path) -or (Test-Path -LiteralPath $paths.receipt_path)) { Throw-Jpc054DRejected '053J_IMMUTABLE_DESTINATION_COLLISION' }
                $bytes = Get-Jpc054DFileBytes -Path $Contract.lease_path
                if ((Get-Jpc054DBytesSha256 -Bytes $bytes) -cne $Contract.expected_lease_sha256) { Throw-Jpc054DRejected '053J_SOURCE_BYTES_DRIFT' }
                [System.IO.File]::Move($Contract.lease_path, $paths.lease_path)
                if (Test-Path -LiteralPath $Contract.lease_path) { Throw-Jpc054DRejected '053J_ACTIVE_SOURCE_REMAINS' }
                (Get-Item -LiteralPath $paths.lease_path -Force).Attributes = ((Get-Item -LiteralPath $paths.lease_path -Force).Attributes -bor [System.IO.FileAttributes]::ReadOnly)
                if ((Get-Jpc054DBytesSha256 -Bytes (Get-Jpc054DFileBytes -Path $paths.lease_path)) -cne $Contract.expected_lease_sha256) { Throw-Jpc054DRejected '053J_HISTORY_INTEGRITY' }
                if ($FaultInjection -eq 'AfterMove') { Throw-Jpc054DRejected 'FAULT_INJECTED_AFTER_MOVE' }
                $resultStatus = 'CLOSURE_CLOSE_PASS'
            }
            else {
                if (Test-Path -LiteralPath $paths.receipt_path) { Throw-Jpc054DRejected '053J_STATE_DRIFT' }
                (Get-Item -LiteralPath $paths.lease_path -Force).Attributes = ((Get-Item -LiteralPath $paths.lease_path -Force).Attributes -bor [System.IO.FileAttributes]::ReadOnly)
                $resultStatus = 'CLOSURE_RECOVERY_COMPLETED'
            }
            Write-Jpc054DImmutableJson -Path $paths.receipt_path -Value (New-Jpc053JReceipt -Contract $Contract -Verification $recheck -Authorization $authorization)
            $closedVerification = Get-Jpc053JVerification -Contract $Contract -SourcePath $paths.lease_path -AllowHeldClosureLock
            if ($closedVerification.closure_verification -ne 'PASS') { Throw-Jpc054DRejected '053J_HISTORY_INTEGRITY' }
            $closed = Assert-Jpc053JClosedHistory -Contract $Contract -Verification $closedVerification
            return [pscustomobject]@{status=$resultStatus;closure_verification='PASS';historical_lease_path=$closed.historical_lease_path;receipt_path=$closed.receipt_path;protected_activation_occurred=$false;production_apply_executed=$false;rollback_required=$false;rollback_executed=$false;new_production_authority_granted=$false}
        }
        finally {
            $lock.Dispose()
            if (Test-Path -LiteralPath $paths.lock_path) { Remove-Item -LiteralPath $paths.lock_path -Force }
        }
    }
    catch {
        $code=[string]$_.Exception.Message
        if($code -notmatch '^CLOSURE_VERIFICATION_FAIL_CLOSED_[A-Z0-9_]+$'){$code='CLOSURE_VERIFICATION_FAIL_CLOSED_INTERNAL'}
        return [pscustomobject]@{status=$code;closure_verification='FAIL_CLOSED';historical_lease_path='';receipt_path='';protected_activation_occurred=$false;production_apply_executed=$false;rollback_required=$false;rollback_executed=$false;new_production_authority_granted=$false}
    }
}

function Invoke-Jpc053JProtectedScopeClosure {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Observe','Close')][string]$Mode,[string]$AuthorizationPath='')
    return Invoke-Jpc053JProtectedScopeClosureInternal -Mode $Mode -AuthorizationPath $AuthorizationPath
}

Export-ModuleMember -Function @('Invoke-Jpc054DProtectedScopeClosure','Invoke-Jpc053JProtectedScopeClosure')
