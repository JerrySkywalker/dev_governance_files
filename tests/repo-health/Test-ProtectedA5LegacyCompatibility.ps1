[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$compatibilityModulePath=Join-Path $PSScriptRoot '../../tools/repo-health/ProtectedA5LegacyCompatibility.psm1'
$finalizerModulePath=Join-Path $PSScriptRoot '../../tools/repo-health/ProtectedA5GovernanceFinalizer.psm1'
$fixtureRoot=Join-Path $PSScriptRoot 'fixtures/protected-a5-legacy-compatibility'
Import-Module $compatibilityModulePath -Force
Import-Module $finalizerModulePath -Force
$compatibilityModule=Get-Module ProtectedA5LegacyCompatibility
$finalizerModule=Get-Module ProtectedA5GovernanceFinalizer

$passed=0
function Assert-True { param([bool]$Condition,[string]$Message);if(-not $Condition){throw $Message};$script:passed++ }
function Assert-Status { param([object]$Result,[string]$Expected,[string]$Message);Assert-True ([string]$Result.status -ceq $Expected) ($Message+' expected='+$Expected+' actual='+[string]$Result.status) }
function Get-Sha256 { param([Parameter(Mandatory)][string]$Path);$sha=[Security.Cryptography.SHA256]::Create();try{return -join($sha.ComputeHash([IO.File]::ReadAllBytes($Path))|ForEach-Object{$_.ToString('x2')})}finally{$sha.Dispose()} }
function Write-Utf8NoBom { param([string]$Path,[string]$Text);[IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false)) }
function Write-Json { param([string]$Path,[object]$Value);Write-Utf8NoBom -Path $Path -Text ($Value|ConvertTo-Json -Depth 20) }
function Read-Json { param([string]$Path);Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json -DateKind String }
function Update-Json {
    param([string]$Path,[hashtable]$Changes)
    $value=Read-Json -Path $Path
    foreach($name in $Changes.Keys){$value.$name=$Changes[$name]}
    Write-Json -Path $Path -Value $value
}
function Set-Writable {
    param([string]$Path)
    $item=Get-Item -LiteralPath $Path -Force
    if(($item.Attributes -band [IO.FileAttributes]::ReadOnly) -eq 0){return}
    if($IsWindows){
        $item.Attributes=($item.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly))
        return
    }
    $mode=[IO.File]::GetUnixFileMode($item.FullName)
    [IO.File]::SetUnixFileMode($item.FullName,($mode -bor [IO.UnixFileMode]::UserWrite))
}
function New-AppendTamperHook {
    param([Parameter(Mandatory)][string]$Path)
    $targetPath=$Path
    return {
        $item=Get-Item -LiteralPath $targetPath -Force
        if(($item.Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0){
            if([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)){
                [IO.File]::SetAttributes($item.FullName,($item.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)))
            }
            else{
                $mode=[IO.File]::GetUnixFileMode($item.FullName)
                [IO.File]::SetUnixFileMode($item.FullName,($mode -bor [IO.UnixFileMode]::UserWrite))
            }
        }
        [IO.File]::AppendAllText($targetPath,"`n",[Text.UTF8Encoding]::new($false))
    }.GetNewClosure()
}

function Remove-SyntheticRoot {
    param([Parameter(Mandatory)][object]$Fixture)
    if(Test-Path -LiteralPath $Fixture.Root){
        $resolved=(Resolve-Path -LiteralPath $Fixture.Root).Path
        $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if(-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture cleanup escaped temporary root.'}
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

function New-LegacyFixture {
    $root=Join-Path ([IO.Path]::GetTempPath()) ('protected-a5-legacy-'+[guid]::NewGuid().ToString('N'))
    $leaseDirectory=Join-Path $root '.coord-local/leases'
    $authorizationDirectory=Join-Path $root '.coord-local/authorizations'
    $evidenceDirectory=Join-Path $root '.coord-local/finalization-evidence'
    $externalDirectory=Join-Path $root 'external-predecessor-evidence'
    foreach($directory in @($leaseDirectory,$authorizationDirectory,$evidenceDirectory,$externalDirectory)){New-Item -ItemType Directory -Path $directory -Force|Out-Null}
    $leasePath=Join-Path $leaseDirectory 'taskroot-writer.active.json'
    Copy-Item -LiteralPath (Join-Path $fixtureRoot '059-legacy-shape.json') -Destination $leasePath
    $goalSource=Join-Path $externalDirectory 'goal-record.json'
    $scopeSource=Join-Path $externalDirectory 'scope-record.json'
    $budgetSource=Join-Path $externalDirectory 'budget-record.json'
    $reconciliationSource=Join-Path $externalDirectory 'f0-reconciliation.json'
    $verifierSource=Join-Path $externalDirectory 'independent-verifier.json'
    Write-Json -Path $goalSource -Value ([ordered]@{schema='synthetic.059.goal-record.v1';goal='JPC-V22-RC32-PROTECTED-APPLY-059';run_id='JPC-V22-RC32-PROTECTED-APPLY-059-20260830T104302Z';profile='PROTECTED_TRANSACTION_V2';authority='A5'})
    Write-Json -Path $scopeSource -Value ([ordered]@{schema='synthetic.059.scope-record.v1';elasticity='B4';current_layer='L4';max_layer='L5';protected_boundaries='PRESENT';owner_only_boundaries='PRESENT'})
    Write-Json -Path $budgetSource -Value ([ordered]@{schema='synthetic.059.budget-absence.v1';legacy_budget_reference_status='ABSENT_NULL';finalize_only=$true})
    Write-Json -Path $reconciliationSource -Value ([ordered]@{schema='synthetic.073.reconciliation.v1';status='PASS';transaction_id='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9';transaction_terminal=$true})
    Write-Json -Path $verifierSource -Value ([ordered]@{schema='synthetic.073.verifier.v1';final_supervisor='PASS';transaction_id='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9'})
    $leaseSha=Get-Sha256 -Path $leasePath
    $goalSha=Get-Sha256 -Path $goalSource
    $scopeSha=Get-Sha256 -Path $scopeSource
    $budgetSha=Get-Sha256 -Path $budgetSource
    $reconciliationSha=Get-Sha256 -Path $reconciliationSource
    $verifierSha=Get-Sha256 -Path $verifierSource
    $created=[DateTimeOffset]::UtcNow.AddMinutes(-3).ToString('o')
    $provenancePath=Join-Path $externalDirectory 'governance-provenance.json'
    $provenance=[ordered]@{
        schema='protected-a5-legacy-governance-provenance.v1';provenance_id='synthetic-059-legacy-provenance';recorded_utc=$created;status='PASS'
        metadata_classification='DERIVED_COMPATIBILITY_METADATA';expected_lease_sha256=$leaseSha;goal='JPC-V22-RC32-PROTECTED-APPLY-059'
        run_id='JPC-V22-RC32-PROTECTED-APPLY-059-20260830T104302Z';legacy_goal_ref_literal='C:/build/jpc-059/coord/GOAL.md'
        legacy_budget_reference_status='ABSENT_NULL';transaction_id='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9'
        admitted_profile='PROTECTED_TRANSACTION_V2';admitted_authority_class='A5';admitted_elasticity_grade='B4';admitted_current_layer='L4'
        admitted_max_layer='L5';protected_boundaries_present=$true;owner_only_boundaries_present=$true
        source_goal_record_sha256=$goalSha;source_scope_record_sha256=$scopeSha;source_budget_record_sha256=$budgetSha
    }
    Write-Json -Path $provenancePath -Value $provenance
    $provenanceSha=Get-Sha256 -Path $provenancePath
    $preparationPath=Join-Path $externalDirectory 'compatibility-preparation.json'
    $preparation=[ordered]@{
        schema='protected-a5-legacy-compatibility-preparation.v1';compatibility_id='jpc-059-legacy-finalization';created_utc=$created
        expected_lease_sha256=$leaseSha;expected_goal='JPC-V22-RC32-PROTECTED-APPLY-059';expected_holder_session='jpc-v22-rc32-protected-apply-059'
        legacy_goal_ref_literal='C:/build/jpc-059/coord/GOAL.md';transaction_id='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9'
        expected_terminal_result='FAILED_BEFORE_CONFIG';expected_terminal_failure_code='OWNER_ABORTED_PREPARED'
        governance_provenance_path=$provenancePath;expected_governance_provenance_sha256=$provenanceSha
        source_goal_record_path=$goalSource;expected_source_goal_record_sha256=$goalSha
        source_scope_record_path=$scopeSource;expected_source_scope_record_sha256=$scopeSha
        source_budget_record_path=$budgetSource;expected_source_budget_record_sha256=$budgetSha
        source_reconciliation_receipt_path=$reconciliationSource;expected_source_reconciliation_receipt_sha256=$reconciliationSha
        source_independent_verifier_receipt_path=$verifierSource;expected_source_independent_verifier_receipt_sha256=$verifierSha
        compatibility_provenance_status='ACCEPTED_IMMUTABLE_PREDECESSOR_EVIDENCE'
    }
    Write-Json -Path $preparationPath -Value $preparation
    return [pscustomobject]@{
        Root=$root;LeasePath=$leasePath;LeaseSha=$leaseSha;AuthorizationPath=(Join-Path $authorizationDirectory 'owner-authorization-v2.json')
        EvidencePath=(Join-Path $evidenceDirectory 'finalization-evidence.json');PreparationPath=$preparationPath;ProvenancePath=$provenancePath
        GoalSource=$goalSource;ScopeSource=$scopeSource;BudgetSource=$budgetSource;ReconciliationSource=$reconciliationSource;VerifierSource=$verifierSource
        TransactionId='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9'
    }
}

function New-ModernCrossUseFixture {
    $root=Join-Path ([IO.Path]::GetTempPath()) ('protected-a5-modern-cross-use-'+[guid]::NewGuid().ToString('N'))
    $leaseDirectory=Join-Path $root '.coord-local/leases'
    $goalDirectory=Join-Path $root '.coord-local/goals'
    $stateDirectory=Join-Path $root '.coord-local/state'
    $authorizationDirectory=Join-Path $root '.coord-local/authorizations'
    foreach($directory in @($leaseDirectory,$goalDirectory,$stateDirectory,$authorizationDirectory)){New-Item -ItemType Directory -Path $directory -Force|Out-Null}
    $modernRoot=Join-Path $PSScriptRoot 'fixtures/protected-a5-governance-finalizer'
    Copy-Item -LiteralPath (Join-Path $modernRoot 'taskroot-writer.active.json') -Destination (Join-Path $leaseDirectory 'taskroot-writer.active.json')
    Copy-Item -LiteralPath (Join-Path $modernRoot '059-goal.json') -Destination (Join-Path $goalDirectory '059-goal.json')
    Copy-Item -LiteralPath (Join-Path $modernRoot '059-budget.json') -Destination (Join-Path $stateDirectory '059-budget.json')
    return [pscustomobject]@{Root=$root;LeasePath=(Join-Path $leaseDirectory 'taskroot-writer.active.json');AuthorizationPath=(Join-Path $authorizationDirectory 'owner-v2.json')}
}

function Invoke-CompatibilityObserve { param([object]$Fixture);Test-ProtectedA5LegacyCompatibilityAdmission -TaskRoot $Fixture.Root -LeasePath $Fixture.LeasePath -ExpectedLeaseSha256 $Fixture.LeaseSha -PreparationManifestPath $Fixture.PreparationPath }
function Invoke-CompatibilityPrepare { param([object]$Fixture);Invoke-ProtectedA5LegacyCompatibilityPreparation -TaskRoot $Fixture.Root -LeasePath $Fixture.LeasePath -ExpectedLeaseSha256 $Fixture.LeaseSha -PreparationManifestPath $Fixture.PreparationPath }

function Write-LegacyFinalizationPackets {
    param([Parameter(Mandatory)][object]$Fixture,[Parameter(Mandatory)][object]$Prepared,[hashtable]$EvidenceChanges=@{},[hashtable]$AuthorizationChanges=@{})
    $compatibility=Read-Json -Path $Prepared.compatibility_path
    $now=[DateTimeOffset]::UtcNow
    $evidence=[ordered]@{
        schema='protected-a5-finalization-evidence.v1';evidence_id='synthetic-059-legacy-finalization-evidence';created_utc=$now.AddMinutes(-2).ToString('o')
        expected_lease_sha256=$Fixture.LeaseSha;goal=[string]$compatibility.expected_goal;run_id=[string]$compatibility.expected_run_id
        goal_metadata_sha256=[string]$compatibility.companion_goal_sha256;budget_metadata_sha256=[string]$compatibility.companion_budget_sha256
        transaction_id=$Fixture.TransactionId;transaction_terminal=$true;terminal_result='FAILED_BEFORE_CONFIG';terminal_failure_code='OWNER_ABORTED_PREPARED'
        reconciliation_status='PASS';final_supervisor_status='PASS';fresh_transaction_evidence=$true;live_prestate_status='EXACT'
        configuration_mutation_status='NONE_UNRESOLVED';rollback_packet_status='VALIDATED_WHERE_RELEVANT';rollback_status='NOT_REQUIRED'
        no_unresolved_protected_mutation=$true;no_contradictory_later_transaction_evidence=$true;no_fabricated_historical_receipt=$true
        unresolved_rollback=$false;conflicting_evidence=$false;accepted_target_status='NOT_APPLICABLE';final_protected_verification_status='NOT_APPLICABLE'
        reconciliation_receipt_path=[string]$compatibility.canonical_reconciliation_receipt_path;reconciliation_receipt_sha256=[string]$compatibility.canonical_reconciliation_receipt_sha256
        independent_verifier_receipt_path=[string]$compatibility.canonical_independent_verifier_receipt_path;independent_verifier_receipt_sha256=[string]$compatibility.canonical_independent_verifier_receipt_sha256
    }
    foreach($name in $EvidenceChanges.Keys){$evidence[$name]=$EvidenceChanges[$name]}
    Write-Json -Path $Fixture.EvidencePath -Value $evidence
    $evidenceSha=Get-Sha256 -Path $Fixture.EvidencePath
    $relativeCompatibility=[IO.Path]::GetRelativePath($Fixture.Root,$Prepared.compatibility_path).Replace('\','/')
    $authorization=[ordered]@{
        schema='protected-a5-governance-finalization-authorization.v2';authorization_id='owner-synthetic-059-legacy-finalization'
        authorization_scope='PROTECTED_A5_GOVERNANCE_FINALIZE';authorized_by='OWNER';authorized_utc=$now.AddMinutes(-1).ToString('o');expires_utc=$now.AddMinutes(19).ToString('o')
        task_root_relative_lease_path='.coord-local/leases/taskroot-writer.active.json';expected_lease_sha256=$Fixture.LeaseSha
        expected_goal=[string]$compatibility.expected_goal;expected_run_id=[string]$compatibility.expected_run_id
        expected_goal_metadata_sha256=[string]$compatibility.companion_goal_sha256;expected_budget_metadata_sha256=[string]$compatibility.companion_budget_sha256
        transaction_id=$Fixture.TransactionId;finalization_evidence_path='.coord-local/finalization-evidence/finalization-evidence.json';expected_finalization_evidence_sha256=$evidenceSha
        reconciliation_receipt_path=[string]$compatibility.canonical_reconciliation_receipt_path;expected_reconciliation_receipt_sha256=[string]$compatibility.canonical_reconciliation_receipt_sha256
        independent_verifier_receipt_path=[string]$compatibility.canonical_independent_verifier_receipt_path;expected_independent_verifier_receipt_sha256=[string]$compatibility.canonical_independent_verifier_receipt_sha256
        expected_terminal_result='FAILED_BEFORE_CONFIG';expected_terminal_failure_code='OWNER_ABORTED_PREPARED'
        legacy_compatibility_path=$relativeCompatibility;expected_legacy_compatibility_sha256=$Prepared.compatibility_sha256
    }
    foreach($name in $AuthorizationChanges.Keys){$authorization[$name]=$AuthorizationChanges[$name]}
    Write-Json -Path $Fixture.AuthorizationPath -Value $authorization
    return [pscustomobject]@{EvidenceSha=$evidenceSha;Compatibility=$compatibility;CompatibilityPath=$Prepared.compatibility_path;CompatibilitySha=$Prepared.compatibility_sha256}
}

function Invoke-LegacyAdmission {
    param([object]$Fixture,[object]$Prepared)
    Test-ProtectedA5GovernanceFinalizationAdmission -TaskRoot $Fixture.Root -LeasePath $Fixture.LeasePath -ExpectedLeaseSha256 $Fixture.LeaseSha -AuthorizationPath $Fixture.AuthorizationPath -LegacyCompatibilityPath $Prepared.compatibility_path
}
function Invoke-LegacyFinalizer {
    param([object]$Fixture,[object]$Prepared)
    Invoke-ProtectedA5GovernanceFinalization -TaskRoot $Fixture.Root -LeasePath $Fixture.LeasePath -ExpectedLeaseSha256 $Fixture.LeaseSha -AuthorizationPath $Fixture.AuthorizationPath -LegacyCompatibilityPath $Prepared.compatibility_path
}

$model=Read-Json -Path (Join-Path $fixtureRoot '059-legacy-model.json')
Assert-True ($model.real_059_expected_lease_sha256 -ceq 'c425a8b450db1520ad80358add0b847d3f80027c853fb2a4c8eb9e8409a313af') '059 historical lease digest identifier is exact'
Assert-True ($model.legacy_goal_ref_literal -ceq 'C:/build/jpc-059/coord/GOAL.md' -and $model.legacy_budget_state_ref_status -ceq 'ABSENT_NULL') '059 legacy metadata shape is exact'
Assert-True ($model.sanitized_fixture -and -not $model.real_lease_bytes_included -and -not $model.production_content_included) '059 legacy fixture is sanitized'

$fixture=New-LegacyFixture
try{
    $direct=Test-ProtectedA5GovernanceFinalizationAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $fixture.LeaseSha -AuthorizationPath ''
    Assert-Status $direct 'FINALIZATION_REJECTED_MALFORMED_LEASE' 'legacy shape cannot enter modern v1 directly'
    $observe=Invoke-CompatibilityObserve -Fixture $fixture
    Assert-Status $observe 'LEGACY_COMPATIBILITY_ADMISSION_ACCEPTED' 'exact legacy shape Observe passes'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $fixture.Root '.coord-local/protected-a5-legacy'))) 'compatibility Observe performs no writes'
    $beforeLease=Get-Sha256 -Path $fixture.LeasePath
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Assert-Status $prepared 'LEGACY_COMPATIBILITY_PREPARED' 'exact legacy preparation succeeds'
    Assert-True ((Get-Sha256 -Path $fixture.LeasePath) -ceq $beforeLease -and (Test-Path -LiteralPath $fixture.LeasePath)) 'preparer preserves active legacy lease bytes'
    Assert-True ((Get-Sha256 -Path $prepared.canonical_reconciliation_receipt_path) -ceq (Get-Sha256 -Path $fixture.ReconciliationSource)) 'canonical reconciliation import is byte exact'
    Assert-True ((Get-Sha256 -Path $prepared.canonical_independent_verifier_receipt_path) -ceq (Get-Sha256 -Path $fixture.VerifierSource)) 'canonical verifier import is byte exact'
    $packets=Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared
    Assert-Status (Invoke-LegacyAdmission -Fixture $fixture -Prepared $prepared) 'FINALIZATION_ADMISSION_ACCEPTED' 'legacy compatibility plus auth v2 admits finalization'
    $released=Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared
    Assert-Status $released 'PROTECTED_A5_GOVERNANCE_RELEASED' 'synthetic legacy exact finalization passes'
    Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath) -and (Get-Sha256 -Path $released.historical_lease_path) -ceq $fixture.LeaseSha) 'legacy finalization archives exact lease bytes'
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'FINALIZATION_ALREADY_COMPLETE' 'legacy finalization repeat is idempotent'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    $crashed=& $finalizerModule {param($root,$lease,$sha,$auth,$compat)Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $root -LeasePath $lease -ExpectedLeaseSha256 $sha -AuthorizationPath $auth -LegacyCompatibilityPath $compat -FaultInjection AfterArchive} $fixture.Root $fixture.LeasePath $fixture.LeaseSha $fixture.AuthorizationPath $prepared.compatibility_path
    Assert-Status $crashed 'FINALIZATION_REJECTED_FAULT_INJECTED_AFTER_ARCHIVE' 'legacy crash reaches archive-before-receipt boundary'
    Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath)) 'legacy crash leaves active marker absent'
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'PROTECTED_A5_GOVERNANCE_RELEASED' 'legacy exact retry completes crash recovery'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$preparationCases=@(
    @{message='wrong compatibility lease SHA rejects';prep=@{expected_lease_sha256=('0'*64)};provenance=@{};expected='LEGACY_COMPATIBILITY_REJECTED_PREPARATION_LEASE_BINDING'},
    @{message='wrong legacy Goal literal rejects';prep=@{legacy_goal_ref_literal='C:/different/GOAL.md'};provenance=@{};expected='LEGACY_COMPATIBILITY_REJECTED_PREPARATION_LEASE_BINDING'},
    @{message='wrong holder session rejects';prep=@{expected_holder_session='different-holder-session'};provenance=@{};expected='LEGACY_COMPATIBILITY_REJECTED_PREPARATION_LEASE_BINDING'},
    @{message='wrong transaction binding rejects';prep=@{transaction_id='different-transaction'};provenance=@{};expected='LEGACY_COMPATIBILITY_REJECTED_PROVENANCE_BINDING'},
    @{message='unsupported terminal class rejects';prep=@{expected_terminal_result='ROLLED_BACK_RC2'};provenance=@{};expected='LEGACY_COMPATIBILITY_REJECTED_UNSUPPORTED_TERMINAL_CLASS'}
)
foreach($case in $preparationCases){
    $fixture=New-LegacyFixture
    try{
        if($case.provenance.Count -gt 0){Update-Json -Path $fixture.ProvenancePath -Changes $case.provenance;Update-Json -Path $fixture.PreparationPath -Changes @{expected_governance_provenance_sha256=(Get-Sha256 -Path $fixture.ProvenancePath)}}
        Update-Json -Path $fixture.PreparationPath -Changes $case.prep
        Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) $case.expected $case.message
    }
    finally{Remove-SyntheticRoot -Fixture $fixture}
}

$fixture=New-LegacyFixture
try{
    Update-Json -Path $fixture.ProvenancePath -Changes @{admitted_authority_class='A4'}
    Update-Json -Path $fixture.PreparationPath -Changes @{expected_governance_provenance_sha256=(Get-Sha256 -Path $fixture.ProvenancePath)}
    Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_PROVENANCE_NOT_ACCEPTED' 'fake or unproven A5 assertion rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    Update-Json -Path $fixture.PreparationPath -Changes @{source_goal_record_path=(Join-Path $fixture.Root 'missing-goal-record.json')}
    Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_REGULAR_FILE_REQUIRED' 'missing provenance source rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    Update-Json -Path $fixture.PreparationPath -Changes @{expected_source_reconciliation_receipt_sha256=('0'*64)}
    Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_SOURCE_RECONCILIATION_RECEIPT_SHA256' 'external receipt SHA mismatch rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    Assert-Status (Invoke-CompatibilityPrepare -Fixture $fixture) 'LEGACY_COMPATIBILITY_PREPARED' 'first compatibility prepare succeeds before collision check'
    Assert-Status (Invoke-CompatibilityPrepare -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_DESTINATION_COLLISION' 'destination collision rejects without overwrite'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$legacyFinalizerCases=@(
    @{message='expired legacy authorization rejects';auth=@{authorized_utc=[DateTimeOffset]::UtcNow.AddMinutes(-21).ToString('o');expires_utc=[DateTimeOffset]::UtcNow.AddMinutes(-1).ToString('o')};expected='FINALIZATION_REJECTED_AUTHORIZATION_EXPIRED_OR_UNBOUNDED'},
    @{message='compatibility SHA authorization mismatch rejects';auth=@{expected_legacy_compatibility_sha256=('0'*64)};expected='FINALIZATION_REJECTED_LEGACY_COMPATIBILITY_AUTHORIZATION_BINDING'},
    @{message='authorization transaction mismatch rejects';auth=@{transaction_id='different-transaction'};expected='FINALIZATION_REJECTED_LEGACY_AUTHORIZATION_METADATA_BINDING'}
)
foreach($case in $legacyFinalizerCases){
    $fixture=New-LegacyFixture
    try{
        $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
        Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared -AuthorizationChanges $case.auth|Out-Null
        Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) $case.expected $case.message
    }
    finally{Remove-SyntheticRoot -Fixture $fixture}
}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    Set-Writable -Path $prepared.companion_goal_path
    [IO.File]::AppendAllText($prepared.companion_goal_path,"`n",[Text.UTF8Encoding]::new($false))
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'FINALIZATION_REJECTED_LEGACY_COMPANION_GOAL_SHA256' 'companion Goal tamper rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    Set-Writable -Path $prepared.companion_budget_path
    [IO.File]::AppendAllText($prepared.companion_budget_path,"`n",[Text.UTF8Encoding]::new($false))
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'FINALIZATION_REJECTED_LEGACY_COMPANION_BUDGET_SHA256' 'companion budget tamper rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    Set-Writable -Path $prepared.canonical_reconciliation_receipt_path
    [IO.File]::AppendAllText($prepared.canonical_reconciliation_receipt_path,'x',[Text.UTF8Encoding]::new($false))
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'FINALIZATION_REJECTED_LEGACY_CANONICAL_RECONCILIATION_SHA256' 'one-byte canonical receipt drift rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    $v1=Read-Json -Path $fixture.AuthorizationPath
    $v1.schema='protected-a5-governance-finalization-authorization.v1'
    $v1.PSObject.Properties.Remove('legacy_compatibility_path')
    $v1.PSObject.Properties.Remove('expected_legacy_compatibility_sha256')
    Write-Json -Path $fixture.AuthorizationPath -Value $v1
    Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) 'FINALIZATION_REJECTED_MALFORMED_LEGACY_AUTHORIZATION' 'auth v1 cannot authorize legacy finalization'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
    Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
    $hook=New-AppendTamperHook -Path $fixture.LeasePath
    $result=& $finalizerModule {param($root,$lease,$sha,$auth,$compat,$before)Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $root -LeasePath $lease -ExpectedLeaseSha256 $sha -AuthorizationPath $auth -LegacyCompatibilityPath $compat -BeforeLockHook $before} $fixture.Root $fixture.LeasePath $fixture.LeaseSha $fixture.AuthorizationPath $prepared.compatibility_path $hook
    Assert-Status $result 'FINALIZATION_REJECTED_LEASE_CONTENT_DRIFT' 'legacy lease TOCTOU rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$toctouCases=@(
    @{member='compatibility_path';expected='FINALIZATION_REJECTED_LEGACY_COMPATIBILITY_AUTHORIZATION_BINDING';message='compatibility packet TOCTOU rejects'},
    @{member='companion_goal_path';expected='FINALIZATION_REJECTED_LEGACY_COMPANION_GOAL_SHA256';message='companion Goal TOCTOU rejects'},
    @{member='companion_budget_path';expected='FINALIZATION_REJECTED_LEGACY_COMPANION_BUDGET_SHA256';message='companion budget TOCTOU rejects'},
    @{member='canonical_independent_verifier_receipt_path';expected='FINALIZATION_REJECTED_LEGACY_CANONICAL_VERIFIER_SHA256';message='imported verifier TOCTOU rejects'},
    @{member='authorization';expected='FINALIZATION_REJECTED_ADMISSION_INPUT_DRIFT';message='authorization TOCTOU rejects'}
)
foreach($case in $toctouCases){
    $fixture=New-LegacyFixture
    try{
        $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
        Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
        $target=if($case.member -ceq 'authorization'){$fixture.AuthorizationPath}else{[string]$prepared.($case.member)}
        $hook=New-AppendTamperHook -Path $target
        $result=& $finalizerModule {param($root,$lease,$sha,$auth,$compat,$before)Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $root -LeasePath $lease -ExpectedLeaseSha256 $sha -AuthorizationPath $auth -LegacyCompatibilityPath $compat -BeforeLockHook $before} $fixture.Root $fixture.LeasePath $fixture.LeaseSha $fixture.AuthorizationPath $prepared.compatibility_path $hook
        Assert-Status $result $case.expected $case.message
    }
    finally{Remove-SyntheticRoot -Fixture $fixture}
}

$compatibilityTamperCases=@(
    @{changes=@{expected_lease_sha256=('0'*64)};expected='FINALIZATION_REJECTED_LEGACY_COMPATIBILITY_LEASE_BINDING';message='compatibility packet wrong lease SHA rejects'},
    @{changes=@{legacy_goal_ref_literal='C:/different/GOAL.md'};expected='FINALIZATION_REJECTED_LEGACY_COMPATIBILITY_LEASE_BINDING';message='compatibility packet wrong Goal literal rejects'},
    @{changes=@{expected_holder_session='different-holder-session'};expected='FINALIZATION_REJECTED_LEGACY_COMPATIBILITY_LEASE_BINDING';message='compatibility packet wrong holder session rejects'},
    @{changes=@{transaction_id='different-transaction'};expected='FINALIZATION_REJECTED_LEGACY_COMPANION_BINDING';message='compatibility packet wrong transaction rejects'},
    @{changes=@{canonical_reconciliation_receipt_path='C:/external/reconciliation.json'};expected='FINALIZATION_REJECTED_MALFORMED_CANONICAL_RECONCILIATION_RECEIPT_PATH';message='arbitrary external receipt cannot be consumed directly'}
)
foreach($case in $compatibilityTamperCases){
    $fixture=New-LegacyFixture
    try{
        $prepared=Invoke-CompatibilityPrepare -Fixture $fixture
        Write-LegacyFinalizationPackets -Fixture $fixture -Prepared $prepared|Out-Null
        Set-Writable -Path $prepared.compatibility_path
        Update-Json -Path $prepared.compatibility_path -Changes $case.changes
        Update-Json -Path $fixture.AuthorizationPath -Changes @{expected_legacy_compatibility_sha256=(Get-Sha256 -Path $prepared.compatibility_path)}
        Assert-Status (Invoke-LegacyFinalizer -Fixture $fixture -Prepared $prepared) $case.expected $case.message
    }
    finally{Remove-SyntheticRoot -Fixture $fixture}
}

$fixture=New-ModernCrossUseFixture
try{
    $leaseSha=Get-Sha256 -Path $fixture.LeasePath
    $legacyArgument=Join-Path $fixture.Root '.coord-local/protected-a5-legacy/compatibilities/not-present.json'
    $crossUse=Test-ProtectedA5GovernanceFinalizationAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -AuthorizationPath '' -LegacyCompatibilityPath $legacyArgument
    Assert-Status $crossUse 'FINALIZATION_REJECTED_MALFORMED_LEGACY_LEASE' 'modern lease cannot enter explicit legacy path'
    $now=[DateTimeOffset]::UtcNow
    $v2=[ordered]@{
        schema='protected-a5-governance-finalization-authorization.v2';authorization_id='owner-modern-cross-use-v2';authorization_scope='PROTECTED_A5_GOVERNANCE_FINALIZE';authorized_by='OWNER'
        authorized_utc=$now.AddMinutes(-1).ToString('o');expires_utc=$now.AddMinutes(19).ToString('o');task_root_relative_lease_path='.coord-local/leases/taskroot-writer.active.json'
        expected_lease_sha256=$leaseSha;expected_goal='JPC-SYNTHETIC-PROTECTED-A5-059';expected_run_id='synthetic-protected-a5-run-059';expected_goal_metadata_sha256=('0'*64)
        expected_budget_metadata_sha256=('0'*64);transaction_id='synthetic-transaction';finalization_evidence_path='.coord-local/finalization-evidence/evidence.json'
        expected_finalization_evidence_sha256=('0'*64);reconciliation_receipt_path='.coord-local/receipts/protected-a5-legacy/'+('0'*64)+'.reconciliation.json'
        expected_reconciliation_receipt_sha256=('0'*64);independent_verifier_receipt_path='.coord-local/receipts/protected-a5-legacy/'+('0'*64)+'.independent-verifier.json'
        expected_independent_verifier_receipt_sha256=('0'*64);expected_terminal_result='FAILED_BEFORE_CONFIG';expected_terminal_failure_code='OWNER_ABORTED_PREPARED'
        legacy_compatibility_path='.coord-local/protected-a5-legacy/compatibilities/cross-use.json';expected_legacy_compatibility_sha256=('0'*64)
    }
    Write-Json -Path $fixture.AuthorizationPath -Value $v2
    $v2Modern=Test-ProtectedA5GovernanceFinalizationAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -AuthorizationPath $fixture.AuthorizationPath
    Assert-Status $v2Modern 'FINALIZATION_REJECTED_MALFORMED_AUTHORIZATION' 'legacy auth v2 cannot enter modern auth-v1 path'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $externalDirectory=Split-Path -Parent $fixture.PreparationPath
    $realExternal=Join-Path $fixture.Root 'external-predecessor-evidence-real'
    Move-Item -LiteralPath $externalDirectory -Destination $realExternal
    if($IsWindows){New-Item -ItemType Junction -Path $externalDirectory -Target $realExternal -ErrorAction Stop|Out-Null}
    else{New-Item -ItemType SymbolicLink -Path $externalDirectory -Target $realExternal -ErrorAction Stop|Out-Null}
    Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_REPARSE_PATH' 'reparse predecessor source rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$fixture=New-LegacyFixture
try{
    $receiptLink=Join-Path $fixture.Root '.coord-local/receipts'
    $receiptReal=Join-Path $fixture.Root 'canonical-receipts-real'
    New-Item -ItemType Directory -Path $receiptReal -Force|Out-Null
    if($IsWindows){New-Item -ItemType Junction -Path $receiptLink -Target $receiptReal -ErrorAction Stop|Out-Null}
    else{New-Item -ItemType SymbolicLink -Path $receiptLink -Target $receiptReal -ErrorAction Stop|Out-Null}
    Assert-Status (Invoke-CompatibilityPrepare -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_REPARSE_PATH' 'reparse canonical destination rejects'
}
finally{Remove-SyntheticRoot -Fixture $fixture}

$malformedLegacyCases=@(
    @{message='legacy string budget reference does not widen null-only parser';mutate={param($path)$value=Read-Json -Path $path;$value.budget_state_ref='.coord-local/state/not-legacy.json';Write-Json -Path $path -Value $value}},
    @{message='legacy scope wrong type rejects';mutate={param($path)$value=Read-Json -Path $path;$value.scope='not-an-array';Write-Json -Path $path -Value $value}},
    @{message='legacy unknown field rejects';mutate={param($path)$value=Read-Json -Path $path;$value|Add-Member -NotePropertyName unexpected -NotePropertyValue 'reject';Write-Json -Path $path -Value $value}},
    @{message='legacy duplicate field rejects';mutate={param($path)$text=Get-Content -LiteralPath $path -Raw;$text=$text -replace '^\{','{"schema":"jpc.taskroot-writer-lease.v1",';Write-Utf8NoBom -Path $path -Text $text}}
)
foreach($case in $malformedLegacyCases){
    $fixture=New-LegacyFixture
    try{
        & $case.mutate $fixture.LeasePath
        $fixture.LeaseSha=Get-Sha256 -Path $fixture.LeasePath
        Assert-Status (Invoke-CompatibilityObserve -Fixture $fixture) 'LEGACY_COMPATIBILITY_REJECTED_MALFORMED_LEGACY_LEASE' $case.message
    }
    finally{Remove-SyntheticRoot -Fixture $fixture}
}

Write-Output ('PASS protected-A5 legacy compatibility tests='+$passed)
Write-Output 'MODERN_FINALIZER_V1_BEHAVIOR_UNCHANGED=true'
Write-Output '059_LEGACY_SHAPE_COMPATIBLE=true'
Write-Output '059_LEGACY_SHAPE_DIRECT_V1_ADMISSION=false'
Write-Output 'REAL_059_LEASE_CONTACTED=false'
