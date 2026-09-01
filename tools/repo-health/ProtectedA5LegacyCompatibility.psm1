Set-StrictMode -Version Latest

$script:LacLegacyLeaseFields = [ordered]@{
    schema='String'; goal='String'; holder='String'; holder_session='String'; state='String'
    acquired_utc='String'; created_utc='String'; hard_stop_utc='String'; single_intentional_writer='Boolean'
    scope='StringArray'; goal_ref='String'; budget_state_ref='Null'
}
$script:LacPreparationFields = [ordered]@{
    schema='String'; compatibility_id='String'; created_utc='String'; expected_lease_sha256='String'
    expected_goal='String'; expected_holder_session='String'; legacy_goal_ref_literal='String'; transaction_id='String'
    expected_terminal_result='String'; expected_terminal_failure_code='String'; governance_provenance_path='String'
    expected_governance_provenance_sha256='String'; source_goal_record_path='String'; expected_source_goal_record_sha256='String'
    source_scope_record_path='String'; expected_source_scope_record_sha256='String'; source_budget_record_path='String'
    expected_source_budget_record_sha256='String'; source_reconciliation_receipt_path='String'
    expected_source_reconciliation_receipt_sha256='String'; source_independent_verifier_receipt_path='String'
    expected_source_independent_verifier_receipt_sha256='String'; compatibility_provenance_status='String'
}
$script:LacProvenanceFields = [ordered]@{
    schema='String'; provenance_id='String'; recorded_utc='String'; status='String'; metadata_classification='String'
    expected_lease_sha256='String'; goal='String'; run_id='String'; legacy_goal_ref_literal='String'
    legacy_budget_reference_status='String'; transaction_id='String'; admitted_profile='String'
    admitted_authority_class='String'; admitted_elasticity_grade='String'; admitted_current_layer='String'
    admitted_max_layer='String'; protected_boundaries_present='Boolean'; owner_only_boundaries_present='Boolean'
    source_goal_record_sha256='String'; source_scope_record_sha256='String'; source_budget_record_sha256='String'
}

function Throw-LacRejected {
    param([Parameter(Mandatory)][string]$Code)
    throw ('LEGACY_COMPATIBILITY_REJECTED_' + $Code)
}

function Get-LacBytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Get-LacPathComparison {
    if ($IsWindows) { return [System.StringComparison]::OrdinalIgnoreCase }
    return [System.StringComparison]::Ordinal
}

function Get-LacFullPath {
    param([Parameter(Mandatory)][string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) }
    catch { Throw-LacRejected 'INVALID_PATH' }
}

function Test-LacPathWithin {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Candidate)
    $comparison = Get-LacPathComparison
    $fullRoot = (Get-LacFullPath -Path $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullCandidate = Get-LacFullPath -Path $Candidate
    if ($fullCandidate.Equals($fullRoot, $comparison)) { return $true }
    return $fullCandidate.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, $comparison)
}

function Assert-LacNoReparseExistingAncestors {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Get-LacFullPath -Path $Path
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) { Throw-LacRejected 'INVALID_PATH' }
    $current = $root
    $separators = [char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $tail = $fullPath.Substring($root.Length).Split($separators, [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($segment in $tail) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { break }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-LacRejected 'REPARSE_PATH' }
    }
    return $fullPath
}

function Assert-LacDirectory {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-LacNoReparseExistingAncestors -Path $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) { Throw-LacRejected 'DIRECTORY_REQUIRED' }
    return $fullPath
}

function Assert-LacRegularFile {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = Assert-LacNoReparseExistingAncestors -Path $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { Throw-LacRejected 'REGULAR_FILE_REQUIRED' }
    if (-not ((Get-Item -LiteralPath $fullPath -Force) -is [System.IO.FileInfo])) { Throw-LacRejected 'REGULAR_FILE_REQUIRED' }
    return $fullPath
}

function Assert-LacSafeIdentifier {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,191}$') { Throw-LacRejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function Assert-LacSha256 {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ($Value -cnotmatch '^[0-9a-f]{64}$') { Throw-LacRejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function Assert-LacBoundedString {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 1024 -or $Value -match '[\x00-\x1f]') { Throw-LacRejected ('MALFORMED_' + $Field.ToUpperInvariant()) }
}

function Assert-LacAbsoluteLegacyLiteral {
    param([Parameter(Mandatory)][string]$Value)
    Assert-LacBoundedString -Value $Value -Field 'legacy_goal_ref_literal'
    $isAbsolute = $Value -match '^[A-Za-z]:[\\/]' -or $Value -match '^[/]' -or $Value -match '^\\\\[^\\]'
    if (-not $isAbsolute -or $Value -match '(^|[\\/])\.\.?(?:[\\/]|$)') { Throw-LacRejected 'MALFORMED_LEGACY_GOAL_REF_LITERAL' }
}

function ConvertTo-LacUtc {
    param([Parameter(Mandatory)][string]$Value,[Parameter(Mandatory)][string]$Field)
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact($Value, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        Throw-LacRejected ('MALFORMED_' + $Field.ToUpperInvariant())
    }
    return $parsed.ToUniversalTime()
}

function Get-LacStrictJsonRoot {
    param([Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][System.Collections.IDictionary]$Expected,[Parameter(Mandatory)][string]$FailureCode)
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 131072) { Throw-LacRejected $FailureCode }
    try { $text = [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes) }
    catch { Throw-LacRejected $FailureCode }
    try { $document = [System.Text.Json.JsonDocument]::Parse($text) }
    catch { Throw-LacRejected $FailureCode }
    try {
        $root = $document.RootElement
        if ($root.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) { Throw-LacRejected $FailureCode }
        $expectedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($name in $Expected.Keys) { $expectedNames.Add([string]$name) | Out-Null }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $properties = @{}
        foreach ($property in $root.EnumerateObject()) {
            if (-not $seen.Add($property.Name) -or -not $expectedNames.Contains($property.Name)) { Throw-LacRejected $FailureCode }
            $properties[$property.Name] = $property.Value
        }
        if ($properties.Count -ne $Expected.Count) { Throw-LacRejected $FailureCode }
        foreach ($entry in $Expected.GetEnumerator()) {
            if (-not $properties.ContainsKey($entry.Key)) { Throw-LacRejected $FailureCode }
            $kind = $properties[$entry.Key].ValueKind.ToString()
            if ($entry.Value -eq 'StringArray') {
                if ($kind -ne 'Array') { Throw-LacRejected $FailureCode }
                foreach ($element in $properties[$entry.Key].EnumerateArray()) { if ($element.ValueKind -ne [System.Text.Json.JsonValueKind]::String) { Throw-LacRejected $FailureCode } }
            }
            elseif ($entry.Value -eq 'Boolean') { if ($kind -notin @('True','False')) { Throw-LacRejected $FailureCode } }
            elseif ($kind -ne $entry.Value) { Throw-LacRejected $FailureCode }
        }
        return [pscustomobject]@{Document=$document;Properties=$properties}
    }
    catch { $document.Dispose(); throw }
}

function Get-LacStringArray {
    param([Parameter(Mandatory)][System.Text.Json.JsonElement]$Element)
    return @($Element.EnumerateArray() | ForEach-Object { $_.GetString() })
}

function Read-LacLegacyLease {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $checked = Get-LacStrictJsonRoot -Bytes $Bytes -Expected $script:LacLegacyLeaseFields -FailureCode 'MALFORMED_LEGACY_LEASE'
    try {
        $p=$checked.Properties
        $lease=[pscustomobject]@{
            schema=$p.schema.GetString();goal=$p.goal.GetString();holder=$p.holder.GetString();holder_session=$p.holder_session.GetString()
            state=$p.state.GetString();acquired_utc=$p.acquired_utc.GetString();created_utc=$p.created_utc.GetString();hard_stop_utc=$p.hard_stop_utc.GetString()
            single_intentional_writer=$p.single_intentional_writer.GetBoolean();scope=Get-LacStringArray -Element $p.scope
            goal_ref=$p.goal_ref.GetString();budget_state_ref=$null
        }
    }
    finally { $checked.Document.Dispose() }
    if ($lease.schema -cne 'jpc.taskroot-writer-lease.v1' -or $lease.state -cne 'active' -or -not $lease.single_intentional_writer) { Throw-LacRejected 'MALFORMED_LEGACY_LEASE' }
    foreach($pair in @(@{v=$lease.goal;n='goal'},@{v=$lease.holder_session;n='holder_session'})){Assert-LacSafeIdentifier -Value $pair.v -Field $pair.n}
    Assert-LacBoundedString -Value $lease.holder -Field 'holder'
    Assert-LacAbsoluteLegacyLiteral -Value $lease.goal_ref
    if ($lease.scope.Count -eq 0 -or $lease.scope.Count -gt 32 -or @($lease.scope | Where-Object { [string]::IsNullOrWhiteSpace($_) -or $_.Length -gt 191 -or $_ -match '[\x00-\x1f]' }).Count -ne 0) { Throw-LacRejected 'MALFORMED_SCOPE' }
    $created=ConvertTo-LacUtc -Value $lease.created_utc -Field 'created_utc'
    $acquired=ConvertTo-LacUtc -Value $lease.acquired_utc -Field 'acquired_utc'
    $hardStop=ConvertTo-LacUtc -Value $lease.hard_stop_utc -Field 'hard_stop_utc'
    if($created -gt $acquired -or $acquired -gt $hardStop){Throw-LacRejected 'MALFORMED_LEGACY_LEASE'}
    if($lease.holder -match '^pid:(\d+)$' -and $null -ne (Get-Process -Id ([int]$Matches[1]) -ErrorAction SilentlyContinue)){Throw-LacRejected 'LIVE_HOLDER'}
    return $lease
}

function Read-LacFlatRecord {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][System.Collections.IDictionary]$Fields,[Parameter(Mandatory)][string]$FailureCode)
    $full=Assert-LacRegularFile -Path $Path
    $bytes=[System.IO.File]::ReadAllBytes($full)
    $checked=Get-LacStrictJsonRoot -Bytes $bytes -Expected $Fields -FailureCode $FailureCode
    try {
        $value=[pscustomobject]@{}
        foreach($name in $Fields.Keys){
            $kind=$Fields[$name]
            $v=if($kind -eq 'Boolean'){$checked.Properties[$name].GetBoolean()}elseif($kind -eq 'Null'){$null}else{$checked.Properties[$name].GetString()}
            $value|Add-Member -NotePropertyName $name -NotePropertyValue $v
        }
    }
    finally{$checked.Document.Dispose()}
    return [pscustomobject]@{value=$value;path=$full;bytes=$bytes;sha256=(Get-LacBytesSha256 -Bytes $bytes)}
}

function Get-LacVerifiedSource {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$ExpectedSha256,[Parameter(Mandatory)][string]$Field)
    Assert-LacSha256 -Value $ExpectedSha256 -Field $Field
    if(-not [System.IO.Path]::IsPathRooted($Path)){Throw-LacRejected ('MALFORMED_' + $Field.ToUpperInvariant() + '_PATH')}
    $full=Assert-LacRegularFile -Path $Path
    $bytes=[System.IO.File]::ReadAllBytes($full)
    $sha=Get-LacBytesSha256 -Bytes $bytes
    if($sha -cne $ExpectedSha256){Throw-LacRejected ($Field.ToUpperInvariant() + '_SHA256')}
    return [pscustomobject]@{path=$full;bytes=$bytes;sha256=$sha}
}

function ConvertTo-LacJsonBytes {
    param([Parameter(Mandatory)][object]$Value)
    return [System.Text.UTF8Encoding]::new($false).GetBytes(($Value | ConvertTo-Json -Depth 16 -Compress))
}

function Get-LacRelativePaths {
    param([Parameter(Mandatory)][object]$Preparation)
    $id=$Preparation.compatibility_id
    $reconciliation='.coord-local/receipts/protected-a5-legacy/' + $Preparation.expected_source_reconciliation_receipt_sha256 + '.reconciliation.json'
    $verifier='.coord-local/receipts/protected-a5-legacy/' + $Preparation.expected_source_independent_verifier_receipt_sha256 + '.independent-verifier.json'
    return [pscustomobject]@{
        companion_goal='.coord-local/protected-a5-legacy/companions/goals/' + $id + '.json'
        companion_budget='.coord-local/protected-a5-legacy/companions/budgets/' + $id + '.json'
        compatibility='.coord-local/protected-a5-legacy/compatibilities/' + $id + '.json'
        reconciliation=$reconciliation
        verifier=$verifier
    }
}

function Get-LacPreparationPlan {
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath,[Parameter(Mandatory)][string]$ExpectedLeaseSha256,[Parameter(Mandatory)][string]$PreparationManifestPath,[Parameter(Mandatory)][DateTimeOffset]$NowUtc)
    Assert-LacSha256 -Value $ExpectedLeaseSha256 -Field 'expected_lease_sha256'
    $root=Assert-LacDirectory -Path $TaskRoot
    $coord=Assert-LacDirectory -Path (Join-Path $root '.coord-local')
    $leaseDir=Assert-LacDirectory -Path (Join-Path $coord 'leases')
    $canonical=Get-LacFullPath -Path (Join-Path $leaseDir 'taskroot-writer.active.json')
    if(-not (Get-LacFullPath -Path $LeasePath).Equals($canonical,(Get-LacPathComparison))){Throw-LacRejected 'NONCANONICAL_LEASE_PATH'}
    $leaseFile=Assert-LacRegularFile -Path $canonical
    $leaseBytes=[System.IO.File]::ReadAllBytes($leaseFile)
    $leaseSha=Get-LacBytesSha256 -Bytes $leaseBytes
    if($leaseSha -cne $ExpectedLeaseSha256){Throw-LacRejected 'LEASE_CONTENT_DRIFT'}
    $lease=Read-LacLegacyLease -Bytes $leaseBytes

    $preparationRecord=Read-LacFlatRecord -Path $PreparationManifestPath -Fields $script:LacPreparationFields -FailureCode 'MALFORMED_PREPARATION_MANIFEST'
    $preparation=$preparationRecord.value
    foreach($value in @($preparation.compatibility_id,$preparation.expected_goal,$preparation.expected_holder_session,$preparation.transaction_id)){Assert-LacSafeIdentifier -Value $value -Field 'preparation_identifier'}
    foreach($name in @('expected_lease_sha256','expected_governance_provenance_sha256','expected_source_goal_record_sha256','expected_source_scope_record_sha256','expected_source_budget_record_sha256','expected_source_reconciliation_receipt_sha256','expected_source_independent_verifier_receipt_sha256')){Assert-LacSha256 -Value ([string]$preparation.$name) -Field $name}
    Assert-LacAbsoluteLegacyLiteral -Value $preparation.legacy_goal_ref_literal
    $created=ConvertTo-LacUtc -Value $preparation.created_utc -Field 'preparation_created_utc'
    if($created -gt $NowUtc.ToUniversalTime()){Throw-LacRejected 'FUTURE_PREPARATION_MANIFEST'}
    if($preparation.schema -cne 'protected-a5-legacy-compatibility-preparation.v1' -or $preparation.compatibility_provenance_status -cne 'ACCEPTED_IMMUTABLE_PREDECESSOR_EVIDENCE'){Throw-LacRejected 'PROVENANCE_NOT_ACCEPTED'}
    if($preparation.expected_terminal_result -cne 'FAILED_BEFORE_CONFIG' -or $preparation.expected_terminal_failure_code -cne 'OWNER_ABORTED_PREPARED'){Throw-LacRejected 'UNSUPPORTED_TERMINAL_CLASS'}
    if($preparation.expected_lease_sha256 -cne $leaseSha -or $preparation.expected_goal -cne $lease.goal -or $preparation.expected_holder_session -cne $lease.holder_session -or $preparation.legacy_goal_ref_literal -cne $lease.goal_ref){Throw-LacRejected 'PREPARATION_LEASE_BINDING'}

    if(-not [System.IO.Path]::IsPathRooted($preparation.governance_provenance_path)){Throw-LacRejected 'MALFORMED_GOVERNANCE_PROVENANCE_PATH'}
    $provenanceRecord=Read-LacFlatRecord -Path $preparation.governance_provenance_path -Fields $script:LacProvenanceFields -FailureCode 'MALFORMED_GOVERNANCE_PROVENANCE'
    if($provenanceRecord.sha256 -cne $preparation.expected_governance_provenance_sha256){Throw-LacRejected 'GOVERNANCE_PROVENANCE_SHA256'}
    $provenance=$provenanceRecord.value
    foreach($value in @($provenance.provenance_id,$provenance.goal,$provenance.run_id,$provenance.transaction_id)){Assert-LacSafeIdentifier -Value $value -Field 'provenance_identifier'}
    foreach($name in @('expected_lease_sha256','source_goal_record_sha256','source_scope_record_sha256','source_budget_record_sha256')){Assert-LacSha256 -Value ([string]$provenance.$name) -Field $name}
    Assert-LacAbsoluteLegacyLiteral -Value $provenance.legacy_goal_ref_literal
    if((ConvertTo-LacUtc -Value $provenance.recorded_utc -Field 'provenance_recorded_utc') -gt $NowUtc.ToUniversalTime()){Throw-LacRejected 'FUTURE_GOVERNANCE_PROVENANCE'}
    $provenanceAccepted = $provenance.schema -ceq 'protected-a5-legacy-governance-provenance.v1' -and $provenance.status -ceq 'PASS' -and $provenance.metadata_classification -ceq 'DERIVED_COMPATIBILITY_METADATA' -and $provenance.admitted_profile -ceq 'PROTECTED_TRANSACTION_V2' -and $provenance.admitted_authority_class -ceq 'A5' -and $provenance.admitted_elasticity_grade -ceq 'B4' -and $provenance.admitted_current_layer -in @('L4','L5') -and $provenance.admitted_max_layer -ceq 'L5' -and $provenance.protected_boundaries_present -and $provenance.owner_only_boundaries_present -and $provenance.legacy_budget_reference_status -ceq 'ABSENT_NULL'
    if(-not $provenanceAccepted){Throw-LacRejected 'PROVENANCE_NOT_ACCEPTED'}
    if($provenance.expected_lease_sha256 -cne $leaseSha -or $provenance.goal -cne $lease.goal -or $provenance.legacy_goal_ref_literal -cne $lease.goal_ref -or $provenance.transaction_id -cne $preparation.transaction_id){Throw-LacRejected 'PROVENANCE_BINDING'}

    $goalSource=Get-LacVerifiedSource -Path $preparation.source_goal_record_path -ExpectedSha256 $preparation.expected_source_goal_record_sha256 -Field 'source_goal_record'
    $scopeSource=Get-LacVerifiedSource -Path $preparation.source_scope_record_path -ExpectedSha256 $preparation.expected_source_scope_record_sha256 -Field 'source_scope_record'
    $budgetSource=Get-LacVerifiedSource -Path $preparation.source_budget_record_path -ExpectedSha256 $preparation.expected_source_budget_record_sha256 -Field 'source_budget_record'
    $reconciliationSource=Get-LacVerifiedSource -Path $preparation.source_reconciliation_receipt_path -ExpectedSha256 $preparation.expected_source_reconciliation_receipt_sha256 -Field 'source_reconciliation_receipt'
    $verifierSource=Get-LacVerifiedSource -Path $preparation.source_independent_verifier_receipt_path -ExpectedSha256 $preparation.expected_source_independent_verifier_receipt_sha256 -Field 'source_independent_verifier_receipt'
    if($provenance.source_goal_record_sha256 -cne $goalSource.sha256 -or $provenance.source_scope_record_sha256 -cne $scopeSource.sha256 -or $provenance.source_budget_record_sha256 -cne $budgetSource.sha256){Throw-LacRejected 'PROVENANCE_SOURCE_BINDING'}

    $relative=Get-LacRelativePaths -Preparation $preparation
    $goalCompanion=[ordered]@{
        schema='protected-a5-legacy-goal-companion.v1';compatibility_id=$preparation.compatibility_id;created_utc=$preparation.created_utc
        metadata_classification='DERIVED_COMPATIBILITY_METADATA';legacy_goal=$lease.goal;run_id=$provenance.run_id;legacy_goal_ref_literal=$lease.goal_ref
        expected_lease_sha256=$leaseSha;transaction_id=$preparation.transaction_id;admitted_profile=$provenance.admitted_profile
        admitted_authority_class=$provenance.admitted_authority_class;admitted_elasticity_grade=$provenance.admitted_elasticity_grade
        admitted_current_layer=$provenance.admitted_current_layer;admitted_max_layer=$provenance.admitted_max_layer
        protected_boundaries_present=$true;owner_only_boundaries_present=$true;governance_provenance_reference=$preparation.governance_provenance_path
        governance_provenance_sha256=$provenanceRecord.sha256;source_goal_record_sha256=$goalSource.sha256;source_scope_record_sha256=$scopeSource.sha256
    }
    $goalBytes=ConvertTo-LacJsonBytes -Value $goalCompanion
    $goalSha=Get-LacBytesSha256 -Bytes $goalBytes
    $budgetCompanion=[ordered]@{
        schema='protected-a5-legacy-budget-companion.v1';compatibility_id=$preparation.compatibility_id;created_utc=$preparation.created_utc
        metadata_classification='DERIVED_COMPATIBILITY_METADATA';expected_lease_sha256=$leaseSha;goal=$lease.goal;run_id=$provenance.run_id
        legacy_budget_reference_status='ABSENT_NULL';authorized_operation='PROTECTED_A5_GOVERNANCE_FINALIZE';apply_authority=$false
        rollback_authority=$false;promotion_authority=$false;finalize_window='ONE';governance_provenance_reference=$preparation.governance_provenance_path
        governance_provenance_sha256=$provenanceRecord.sha256;source_budget_record_sha256=$budgetSource.sha256
    }
    $budgetBytes=ConvertTo-LacJsonBytes -Value $budgetCompanion
    $budgetSha=Get-LacBytesSha256 -Bytes $budgetBytes
    $compatibility=[ordered]@{
        schema='protected-a5-legacy-lease-compatibility.v1';compatibility_id=$preparation.compatibility_id;created_utc=$preparation.created_utc
        metadata_classification='DERIVED_COMPATIBILITY_METADATA';expected_lease_sha256=$leaseSha;expected_lease_schema=$lease.schema
        expected_goal=$lease.goal;expected_run_id=$provenance.run_id;expected_holder_session=$lease.holder_session;legacy_goal_ref_literal=$lease.goal_ref
        legacy_budget_state_ref_status='ABSENT_NULL';transaction_id=$preparation.transaction_id;expected_terminal_result=$preparation.expected_terminal_result
        expected_terminal_failure_code=$preparation.expected_terminal_failure_code;companion_goal_path=$relative.companion_goal;companion_goal_sha256=$goalSha
        companion_budget_path=$relative.companion_budget;companion_budget_sha256=$budgetSha;canonical_reconciliation_receipt_path=$relative.reconciliation
        canonical_reconciliation_receipt_sha256=$reconciliationSource.sha256;canonical_independent_verifier_receipt_path=$relative.verifier
        canonical_independent_verifier_receipt_sha256=$verifierSource.sha256;source_reconciliation_receipt_sha256=$reconciliationSource.sha256
        source_independent_verifier_receipt_sha256=$verifierSource.sha256;governance_provenance_reference=$preparation.governance_provenance_path
        governance_provenance_sha256=$provenanceRecord.sha256;compatibility_provenance_status='ACCEPTED_IMMUTABLE_PREDECESSOR_EVIDENCE'
    }
    $compatibilityBytes=ConvertTo-LacJsonBytes -Value $compatibility
    return [pscustomobject]@{
        task_root=$root;lease_path=$leaseFile;lease=$lease;lease_sha256=$leaseSha;lease_bytes=$leaseBytes
        preparation=$preparationRecord;provenance=$provenanceRecord;goal_source=$goalSource;scope_source=$scopeSource;budget_source=$budgetSource
        reconciliation_source=$reconciliationSource;verifier_source=$verifierSource;relative=$relative
        goal_companion=$goalCompanion;goal_bytes=$goalBytes;goal_sha256=$goalSha;budget_companion=$budgetCompanion;budget_bytes=$budgetBytes;budget_sha256=$budgetSha
        compatibility=$compatibility;compatibility_bytes=$compatibilityBytes;compatibility_sha256=(Get-LacBytesSha256 -Bytes $compatibilityBytes)
    }
}

function Compare-LacPreparationPlans {
    param([Parameter(Mandatory)][object]$Initial,[Parameter(Mandatory)][object]$Recheck)
    $left=@($Initial.lease_sha256,$Initial.preparation.sha256,$Initial.provenance.sha256,$Initial.goal_source.sha256,$Initial.scope_source.sha256,$Initial.budget_source.sha256,$Initial.reconciliation_source.sha256,$Initial.verifier_source.sha256,$Initial.goal_sha256,$Initial.budget_sha256,$Initial.compatibility_sha256)
    $right=@($Recheck.lease_sha256,$Recheck.preparation.sha256,$Recheck.provenance.sha256,$Recheck.goal_source.sha256,$Recheck.scope_source.sha256,$Recheck.budget_source.sha256,$Recheck.reconciliation_source.sha256,$Recheck.verifier_source.sha256,$Recheck.goal_sha256,$Recheck.budget_sha256,$Recheck.compatibility_sha256)
    for($i=0;$i -lt $left.Count;$i++){if($left[$i] -cne $right[$i]){Throw-LacRejected 'PREPARATION_INPUT_DRIFT'}}
}

function Write-LacImmutableBytes {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][byte[]]$Bytes,[Parameter(Mandatory)][string]$ExpectedSha256)
    Assert-LacNoReparseExistingAncestors -Path $Path | Out-Null
    try { $stream=[System.IO.File]::Open($Path,[System.IO.FileMode]::CreateNew,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None) }
    catch [System.IO.IOException] { Throw-LacRejected 'DESTINATION_COLLISION' }
    try{$stream.Write($Bytes,0,$Bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
    $item=Get-Item -LiteralPath $Path -Force
    $item.Attributes=($item.Attributes -bor [System.IO.FileAttributes]::ReadOnly)
    $readback=[System.IO.File]::ReadAllBytes((Assert-LacRegularFile -Path $Path))
    if((Get-LacBytesSha256 -Bytes $readback) -cne $ExpectedSha256 -or -not [System.Linq.Enumerable]::SequenceEqual([byte[]]$Bytes,[byte[]]$readback)){Throw-LacRejected 'IMMUTABLE_COPY_INTEGRITY'}
}

function Get-LacOutputPaths {
    param([Parameter(Mandatory)][object]$Plan)
    return [pscustomobject]@{
        companion_goal=Join-Path $Plan.task_root $Plan.relative.companion_goal
        companion_budget=Join-Path $Plan.task_root $Plan.relative.companion_budget
        compatibility=Join-Path $Plan.task_root $Plan.relative.compatibility
        reconciliation=Join-Path $Plan.task_root $Plan.relative.reconciliation
        verifier=Join-Path $Plan.task_root $Plan.relative.verifier
    }
}

function Invoke-ProtectedA5LegacyCompatibilityPreparationInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Observe','Prepare')][string]$Mode,
        [Parameter(Mandatory)][string]$TaskRoot,
        [Parameter(Mandatory)][string]$LeasePath,
        [Parameter(Mandatory)][string]$ExpectedLeaseSha256,
        [Parameter(Mandatory)][string]$PreparationManifestPath,
        [DateTimeOffset]$NowUtc=[DateTimeOffset]::UtcNow,
        [scriptblock]$BeforeLockHook=$null
    )
    try{
        $initial=Get-LacPreparationPlan -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath -NowUtc $NowUtc
        $outputs=Get-LacOutputPaths -Plan $initial
        if($Mode -ceq 'Observe'){
            return [pscustomobject]@{status='LEGACY_COMPATIBILITY_ADMISSION_ACCEPTED';compatibility_id=$initial.compatibility.compatibility_id;compatibility_path=$outputs.compatibility;compatibility_sha256=$initial.compatibility_sha256;companion_goal_sha256=$initial.goal_sha256;companion_budget_sha256=$initial.budget_sha256;active_lease=$true;active_lease_mutated=$false;production_transaction_mutated=$false}
        }
        if($null -ne $BeforeLockHook){& $BeforeLockHook}
        $base=Join-Path $initial.task_root '.coord-local/protected-a5-legacy'
        Assert-LacNoReparseExistingAncestors -Path $base | Out-Null
        [System.IO.Directory]::CreateDirectory($base)|Out-Null
        $lockPath=Join-Path $base '.compatibility-preparation.lock'
        try { $lock=[System.IO.File]::Open($lockPath,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None) }
        catch [System.IO.IOException] { Throw-LacRejected 'PREPARATION_IN_PROGRESS' }
        try{
            $recheck=Get-LacPreparationPlan -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath -NowUtc $NowUtc
            Compare-LacPreparationPlans -Initial $initial -Recheck $recheck
            $outputs=Get-LacOutputPaths -Plan $recheck
            foreach($path in @($outputs.companion_goal,$outputs.companion_budget,$outputs.compatibility,$outputs.reconciliation,$outputs.verifier)){if(Test-Path -LiteralPath $path){Throw-LacRejected 'DESTINATION_COLLISION'}}
            foreach($directory in @((Split-Path -Parent $outputs.companion_goal),(Split-Path -Parent $outputs.companion_budget),(Split-Path -Parent $outputs.compatibility),(Split-Path -Parent $outputs.reconciliation))){Assert-LacNoReparseExistingAncestors -Path $directory|Out-Null;[System.IO.Directory]::CreateDirectory($directory)|Out-Null;Assert-LacDirectory -Path $directory|Out-Null}
            Write-LacImmutableBytes -Path $outputs.reconciliation -Bytes $recheck.reconciliation_source.bytes -ExpectedSha256 $recheck.reconciliation_source.sha256
            Write-LacImmutableBytes -Path $outputs.verifier -Bytes $recheck.verifier_source.bytes -ExpectedSha256 $recheck.verifier_source.sha256
            Write-LacImmutableBytes -Path $outputs.companion_goal -Bytes $recheck.goal_bytes -ExpectedSha256 $recheck.goal_sha256
            Write-LacImmutableBytes -Path $outputs.companion_budget -Bytes $recheck.budget_bytes -ExpectedSha256 $recheck.budget_sha256
            Write-LacImmutableBytes -Path $outputs.compatibility -Bytes $recheck.compatibility_bytes -ExpectedSha256 $recheck.compatibility_sha256
            if((Get-LacBytesSha256 -Bytes ([System.IO.File]::ReadAllBytes($recheck.lease_path))) -cne $ExpectedLeaseSha256){Throw-LacRejected 'LEASE_CONTENT_DRIFT'}
            return [pscustomobject]@{status='LEGACY_COMPATIBILITY_PREPARED';compatibility_id=$recheck.compatibility.compatibility_id;compatibility_path=$outputs.compatibility;compatibility_sha256=$recheck.compatibility_sha256;companion_goal_path=$outputs.companion_goal;companion_goal_sha256=$recheck.goal_sha256;companion_budget_path=$outputs.companion_budget;companion_budget_sha256=$recheck.budget_sha256;canonical_reconciliation_receipt_path=$outputs.reconciliation;canonical_reconciliation_receipt_sha256=$recheck.reconciliation_source.sha256;canonical_independent_verifier_receipt_path=$outputs.verifier;canonical_independent_verifier_receipt_sha256=$recheck.verifier_source.sha256;active_lease=$true;active_lease_mutated=$false;production_transaction_mutated=$false}
        }
        finally{$lock.Dispose()}
    }
    catch{
        $status=[string]$_.Exception.Message
        if($status -notmatch '^LEGACY_COMPATIBILITY_REJECTED_[A-Z0-9_]+$'){$status='LEGACY_COMPATIBILITY_REJECTED_INTERNAL'}
        return [pscustomobject]@{status=$status;compatibility_id='';compatibility_path='';compatibility_sha256='';active_lease=(Test-Path -LiteralPath $LeasePath -PathType Leaf);active_lease_mutated=$false;production_transaction_mutated=$false}
    }
}

function Test-ProtectedA5LegacyCompatibilityAdmission {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath,[Parameter(Mandatory)][string]$ExpectedLeaseSha256,[Parameter(Mandatory)][string]$PreparationManifestPath)
    return Invoke-ProtectedA5LegacyCompatibilityPreparationInternal -Mode Observe -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath
}

function Invoke-ProtectedA5LegacyCompatibilityPreparation {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TaskRoot,[Parameter(Mandatory)][string]$LeasePath,[Parameter(Mandatory)][string]$ExpectedLeaseSha256,[Parameter(Mandatory)][string]$PreparationManifestPath)
    return Invoke-ProtectedA5LegacyCompatibilityPreparationInternal -Mode Prepare -TaskRoot $TaskRoot -LeasePath $LeasePath -ExpectedLeaseSha256 $ExpectedLeaseSha256 -PreparationManifestPath $PreparationManifestPath
}

Export-ModuleMember -Function @('Test-ProtectedA5LegacyCompatibilityAdmission','Invoke-ProtectedA5LegacyCompatibilityPreparation')
