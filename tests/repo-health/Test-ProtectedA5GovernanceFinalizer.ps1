[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../../tools/repo-health/ProtectedA5GovernanceFinalizer.psm1'
$ordinaryModulePath = Join-Path $PSScriptRoot '../../tools/repo-health/WriterLeaseV1Settlement.psm1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures/protected-a5-governance-finalizer'
Import-Module $modulePath -Force
Import-Module $ordinaryModulePath -Force
$finalizerModule = Get-Module ProtectedA5GovernanceFinalizer

$passed = 0
function Assert-True {
    param([bool]$Condition,[string]$Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}
function Assert-Status {
    param([object]$Result,[string]$Expected,[string]$Message)
    Assert-True ([string]$Result.status -ceq $Expected) ($Message + ' expected=' + $Expected + ' actual=' + [string]$Result.status)
}
function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash([System.IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}
function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}
function Write-Json {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Value)
    Write-Utf8NoBom -Path $Path -Text ($Value | ConvertTo-Json -Depth 16)
}
function Update-Json {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][hashtable]$Changes)
    $value = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -DateKind String
    foreach ($name in $Changes.Keys) { $value.$name = $Changes[$name] }
    Write-Json -Path $Path -Value $value
}
function New-FixtureTaskRoot {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('protected-a5-finalizer-' + [guid]::NewGuid().ToString('N'))
    $leaseDirectory = Join-Path $root '.coord-local/leases'
    $goalDirectory = Join-Path $root '.coord-local/goals'
    $stateDirectory = Join-Path $root '.coord-local/state'
    $authorizationDirectory = Join-Path $root '.coord-local/authorizations'
    $evidenceDirectory = Join-Path $root '.coord-local/finalization-evidence'
    $receiptDirectory = Join-Path $root '.coord-local/receipts'
    foreach ($directory in @($leaseDirectory,$goalDirectory,$stateDirectory,$authorizationDirectory,$evidenceDirectory,$receiptDirectory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'taskroot-writer.active.json') -Destination (Join-Path $leaseDirectory 'taskroot-writer.active.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot '059-goal.json') -Destination (Join-Path $goalDirectory '059-goal.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot '059-budget.json') -Destination (Join-Path $stateDirectory '059-budget.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'f0-reconciliation.json') -Destination (Join-Path $receiptDirectory 'f0-reconciliation.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'independent-verifier.json') -Destination (Join-Path $receiptDirectory 'independent-verifier.json')
    [pscustomobject]@{
        Root=$root
        LeasePath=(Join-Path $leaseDirectory 'taskroot-writer.active.json')
        GoalPath=(Join-Path $goalDirectory '059-goal.json')
        BudgetPath=(Join-Path $stateDirectory '059-budget.json')
        AuthorizationPath=(Join-Path $authorizationDirectory 'owner-authorization.json')
        EvidencePath=(Join-Path $evidenceDirectory 'finalization-evidence.json')
        ReconciliationPath=(Join-Path $receiptDirectory 'f0-reconciliation.json')
        VerifierPath=(Join-Path $receiptDirectory 'independent-verifier.json')
        TransactionId='a5-rc32-058-5dbf2907de4b41f688125c691c212ff9'
    }
}
function Remove-FixtureTaskRoot {
    param([Parameter(Mandatory)][object]$Fixture)
    if (Test-Path -LiteralPath $Fixture.Root) {
        $resolved = (Resolve-Path -LiteralPath $Fixture.Root).Path
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if (-not $resolved.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped the temporary root.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
function Write-Packets {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [hashtable]$EvidenceChanges=@{},
        [hashtable]$AuthorizationChanges=@{}
    )
    $now = [DateTimeOffset]::UtcNow
    $leaseSha = Get-Sha256 -Path $Fixture.LeasePath
    $goalSha = Get-Sha256 -Path $Fixture.GoalPath
    $budgetSha = Get-Sha256 -Path $Fixture.BudgetPath
    $reconciliationSha = Get-Sha256 -Path $Fixture.ReconciliationPath
    $verifierSha = Get-Sha256 -Path $Fixture.VerifierPath
    $goal = Get-Content -LiteralPath $Fixture.GoalPath -Raw | ConvertFrom-Json
    $evidence = [ordered]@{
        schema='protected-a5-finalization-evidence.v1'; evidence_id='synthetic-059-finalization-evidence'; created_utc=$now.AddMinutes(-2).ToString('o')
        expected_lease_sha256=$leaseSha; goal=[string]$goal.goal; run_id=[string]$goal.run_id; goal_metadata_sha256=$goalSha; budget_metadata_sha256=$budgetSha
        transaction_id=$Fixture.TransactionId; transaction_terminal=$true; terminal_result='FAILED_BEFORE_CONFIG'; terminal_failure_code='OWNER_ABORTED_PREPARED'
        reconciliation_status='PASS'; final_supervisor_status='PASS'; fresh_transaction_evidence=$true; live_prestate_status='EXACT'
        configuration_mutation_status='NONE_UNRESOLVED'; rollback_packet_status='VALIDATED_WHERE_RELEVANT'; rollback_status='NOT_REQUIRED'
        no_unresolved_protected_mutation=$true; no_contradictory_later_transaction_evidence=$true; no_fabricated_historical_receipt=$true
        unresolved_rollback=$false; conflicting_evidence=$false; accepted_target_status='NOT_APPLICABLE'; final_protected_verification_status='NOT_APPLICABLE'
        reconciliation_receipt_path='.coord-local/receipts/f0-reconciliation.json'; reconciliation_receipt_sha256=$reconciliationSha
        independent_verifier_receipt_path='.coord-local/receipts/independent-verifier.json'; independent_verifier_receipt_sha256=$verifierSha
    }
    foreach ($name in $EvidenceChanges.Keys) { $evidence[$name] = $EvidenceChanges[$name] }
    Write-Json -Path $Fixture.EvidencePath -Value $evidence
    $evidenceSha = Get-Sha256 -Path $Fixture.EvidencePath
    $authorization = [ordered]@{
        schema='protected-a5-governance-finalization-authorization.v1'; authorization_id='owner-synthetic-059-finalization'
        authorization_scope='PROTECTED_A5_GOVERNANCE_FINALIZE'; authorized_by='OWNER'; authorized_utc=$now.AddMinutes(-1).ToString('o')
        expires_utc=$now.AddMinutes(19).ToString('o'); task_root_relative_lease_path='.coord-local/leases/taskroot-writer.active.json'
        expected_lease_sha256=$leaseSha; expected_goal=[string]$goal.goal; expected_run_id=[string]$goal.run_id
        expected_goal_metadata_sha256=$goalSha; expected_budget_metadata_sha256=$budgetSha; transaction_id=$Fixture.TransactionId
        finalization_evidence_path='.coord-local/finalization-evidence/finalization-evidence.json'; expected_finalization_evidence_sha256=$evidenceSha
        reconciliation_receipt_path='.coord-local/receipts/f0-reconciliation.json'; expected_reconciliation_receipt_sha256=$reconciliationSha
        independent_verifier_receipt_path='.coord-local/receipts/independent-verifier.json'; expected_independent_verifier_receipt_sha256=$verifierSha
        expected_terminal_result='FAILED_BEFORE_CONFIG'; expected_terminal_failure_code='OWNER_ABORTED_PREPARED'
    }
    foreach ($name in $AuthorizationChanges.Keys) { $authorization[$name] = $AuthorizationChanges[$name] }
    Write-Json -Path $Fixture.AuthorizationPath -Value $authorization
    return [pscustomobject]@{ LeaseSha=$leaseSha; GoalSha=$goalSha; BudgetSha=$budgetSha; EvidenceSha=$evidenceSha; ReconciliationSha=$reconciliationSha; VerifierSha=$verifierSha }
}
function Invoke-FixtureFinalizer {
    param([Parameter(Mandatory)][object]$Fixture,[Parameter(Mandatory)][string]$LeaseSha)
    Invoke-ProtectedA5GovernanceFinalization -TaskRoot $Fixture.Root -LeasePath $Fixture.LeasePath -ExpectedLeaseSha256 $LeaseSha -AuthorizationPath $Fixture.AuthorizationPath
}

$model = Get-Content -LiteralPath (Join-Path $fixtureRoot '059-incident-model.json') -Raw | ConvertFrom-Json
Assert-True ($model.transaction_id -ceq 'a5-rc32-058-5dbf2907de4b41f688125c691c212ff9') '059 model transaction is exact'
Assert-True ($model.retained_lease_sha256 -ceq 'c425a8b450db1520ad80358add0b847d3f80027c853fb2a4c8eb9e8409a313af') '059 model retained lease digest is exact'
Assert-True ($model.terminal_result -ceq 'FAILED_BEFORE_CONFIG' -and $model.terminal_failure_code -ceq 'OWNER_ABORTED_PREPARED') '059 model terminal class is exact'
Assert-True ($model.f0_reconciliation -ceq 'PASS' -and $model.final_supervisor -ceq 'PASS' -and $model.sanitized_fixture -and -not $model.production_content_included) '059 model is sanitized and evidence-classified'

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $admission = Test-ProtectedA5GovernanceFinalizationAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $packets.LeaseSha -AuthorizationPath $fixture.AuthorizationPath
    Assert-Status $admission 'FINALIZATION_ADMISSION_ACCEPTED' 'exact terminal FAILED_BEFORE_CONFIG admission passes'
    $released = Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha
    Assert-Status $released 'PROTECTED_A5_GOVERNANCE_RELEASED' 'matching synthetic Owner authorization finalizes the 059 model'
    Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath) -and -not $released.active_lease) 'successful finalization proves active marker absent'
    Assert-True ((Get-Sha256 -Path $released.historical_lease_path) -ceq $packets.LeaseSha) 'historical lease preserves exact bytes'
    $receipt = Get-Content -LiteralPath $released.receipt_path -Raw | ConvertFrom-Json
    Assert-True ($receipt.finalization_status -ceq 'PROTECTED_A5_GOVERNANCE_RELEASED' -and -not $receipt.production_transaction_mutated) 'immutable receipt records governance-only release'
    Assert-True ($receipt.authorization_sha256 -ceq (Get-Sha256 -Path $fixture.AuthorizationPath) -and $receipt.finalization_evidence_sha256 -ceq $packets.EvidenceSha) 'receipt binds authorization and typed evidence'
    $again = Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha
    Assert-Status $again 'FINALIZATION_ALREADY_COMPLETE' 'exact repeat is idempotent'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $crashed = & $finalizerModule { param($root,$lease,$sha,$auth) Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $root -LeasePath $lease -ExpectedLeaseSha256 $sha -AuthorizationPath $auth -FaultInjection AfterArchive } $fixture.Root $fixture.LeasePath $packets.LeaseSha $fixture.AuthorizationPath
    Assert-Status $crashed 'FINALIZATION_REJECTED_FAULT_INJECTED_AFTER_ARCHIVE' 'fault injection reaches archive-before-receipt boundary'
    Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath)) 'crash boundary leaves active marker absent'
    $history = Join-Path $fixture.Root ('.coord-local/leases/history/protected-a5/leases/' + $packets.LeaseSha + '.writer-lease.v1.json')
    $receipt = Join-Path $fixture.Root ('.coord-local/leases/history/protected-a5/finalizations/' + $packets.LeaseSha + '.finalization.json')
    Assert-True ((Test-Path -LiteralPath $history) -and -not (Test-Path -LiteralPath $receipt)) 'crash boundary is exact historical-without-receipt state'
    $recovered = Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha
    Assert-Status $recovered 'PROTECTED_A5_GOVERNANCE_RELEASED' 'exact retry completes archive-before-receipt recovery'
    Assert-True ((Test-Path -LiteralPath $recovered.receipt_path) -and -not $recovered.production_transaction_mutated) 'recovery writes only terminal governance receipt'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $leaseSha = Get-Sha256 -Path $fixture.LeasePath
    $withoutAuthorization = Invoke-ProtectedA5GovernanceFinalization -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -AuthorizationPath ''
    Assert-Status $withoutAuthorization 'FINALIZATION_REJECTED_AUTHORIZATION_REQUIRED' '059 model without Owner authorization rejects'
    Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'missing authorization leaves active lease intact'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $wrongSha = ('0' * 64)
    if ($wrongSha -ceq $packets.LeaseSha) { $wrongSha = ('1' * 64) }
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $wrongSha) 'FINALIZATION_REJECTED_LEASE_CONTENT_DRIFT' 'wrong lease SHA rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    [System.IO.File]::AppendAllText($fixture.LeasePath, "`n", [System.Text.UTF8Encoding]::new($false))
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_LEASE_CONTENT_DRIFT' 'lease content drift rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $alternate = Join-Path $fixture.Root '.coord-local/leases/not-canonical.json'
    Copy-Item -LiteralPath $fixture.LeasePath -Destination $alternate
    $result = Invoke-ProtectedA5GovernanceFinalization -TaskRoot $fixture.Root -LeasePath $alternate -ExpectedLeaseSha256 $packets.LeaseSha -AuthorizationPath $fixture.AuthorizationPath
    Assert-Status $result 'FINALIZATION_REJECTED_NONCANONICAL_LEASE_PATH' 'wrong canonical lease path rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $leaseDirectory = Split-Path -Parent $fixture.LeasePath
    $realDirectory = Join-Path $fixture.Root 'real-leases'
    Move-Item -LiteralPath $leaseDirectory -Destination $realDirectory
    if ($IsWindows) { New-Item -ItemType Junction -Path $leaseDirectory -Target $realDirectory -ErrorAction Stop | Out-Null }
    else { New-Item -ItemType SymbolicLink -Path $leaseDirectory -Target $realDirectory -ErrorAction Stop | Out-Null }
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_REPARSE_PATH' 'reparse lease path rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    Update-Json -Path $fixture.GoalPath -Changes @{profile='INTERACTIVE_REPOSITORY_V1';authority_class='A2';elasticity_grade='B2';current_layer='L2';max_admitted_layer='L2';protected_boundaries=@();owner_only_boundaries=@()}
    $packets = Write-Packets -Fixture $fixture
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_ORDINARY_DEVELOPMENT_LEASE' 'ordinary-development lease rejects in protected finalizer'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $leaseSha = Get-Sha256 -Path $fixture.LeasePath
    $ordinary = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha
    Assert-Status $ordinary 'SETTLEMENT_REJECTED_PRODUCTION_ATTACHED' 'protected lease remains rejected by ordinary settlement'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $now=[DateTimeOffset]::UtcNow
    $packets = Write-Packets -Fixture $fixture -AuthorizationChanges @{authorized_utc=$now.AddMinutes(-31).ToString('o');expires_utc=$now.AddMinutes(-1).ToString('o')}
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_AUTHORIZATION_EXPIRED_OR_UNBOUNDED' 'expired Owner authorization rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture -AuthorizationChanges @{authorization_scope='PROTECTED_A5_APPLY'}
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_AUTHORIZATION_REQUIRED' 'wrong authorization scope rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture -AuthorizationChanges @{transaction_id='different-transaction'}
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_FINALIZATION_EVIDENCE_BINDING' 'authorization for another transaction rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture -AuthorizationChanges @{expected_reconciliation_receipt_sha256=('0' * 64)}
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_RECEIPT_AUTHORIZATION_BINDING' 'authorization for another reconciliation receipt rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$evidenceCases = @(
    @{Change=@{reconciliation_status='FAIL'};Status='FINALIZATION_REJECTED_RECONCILIATION_NOT_PASS';Message='reconciliation not PASS rejects'},
    @{Change=@{final_supervisor_status='FAIL'};Status='FINALIZATION_REJECTED_INDEPENDENT_VERIFIER_NOT_PASS';Message='independent verifier not PASS rejects'},
    @{Change=@{transaction_terminal=$false};Status='FINALIZATION_REJECTED_NONTERMINAL_TRANSACTION';Message='nonterminal transaction rejects'},
    @{Change=@{terminal_failure_code='OTHER_FAILURE'};Status='FINALIZATION_REJECTED_TERMINAL_FAILURE_CODE_MISMATCH';Message='terminal failure-code mismatch rejects'},
    @{Change=@{terminal_result='ROLLED_BACK_RC2'};Status='FINALIZATION_REJECTED_TERMINAL_RESULT_MISMATCH';Message='terminal-result mismatch rejects'},
    @{Change=@{unresolved_rollback=$true};Status='FINALIZATION_REJECTED_UNRESOLVED_PROTECTED_STATE';Message='unresolved rollback rejects'},
    @{Change=@{conflicting_evidence=$true};Status='FINALIZATION_REJECTED_CONFLICTING_EVIDENCE';Message='conflicting evidence rejects'}
)
foreach ($case in $evidenceCases) {
    $fixture = New-FixtureTaskRoot
    try {
        $packets = Write-Packets -Fixture $fixture -EvidenceChanges $case.Change
        Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) $case.Status $case.Message
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }
}

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    [System.IO.File]::AppendAllText($fixture.ReconciliationPath, "`n", [System.Text.UTF8Encoding]::new($false))
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_RECONCILIATION_RECEIPT_SHA256' 'reconciliation receipt content drift rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    Write-Utf8NoBom -Path $fixture.AuthorizationPath -Text '{'
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_MALFORMED_AUTHORIZATION' 'malformed JSON rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $text = Get-Content -LiteralPath $fixture.AuthorizationPath -Raw
    $duplicate = $text -replace '^\{', '{"schema":"protected-a5-governance-finalization-authorization.v1",'
    Write-Utf8NoBom -Path $fixture.AuthorizationPath -Text $duplicate
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_MALFORMED_AUTHORIZATION' 'duplicate JSON field rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $authorization = Get-Content -LiteralPath $fixture.AuthorizationPath -Raw | ConvertFrom-Json
    $authorization | Add-Member -NotePropertyName unexpected -NotePropertyValue 'reject'
    Write-Json -Path $fixture.AuthorizationPath -Value $authorization
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_MALFORMED_AUTHORIZATION' 'unknown JSON field rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $historyRoot = Join-Path $fixture.Root '.coord-local/leases/history/protected-a5'
    New-Item -ItemType Directory -Path $historyRoot -Force | Out-Null
    $lockPath = Join-Path $historyRoot '.protected-a5-governance-finalization.lock'
    $heldLock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try { Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_FINALIZATION_IN_PROGRESS' 'conflicting finalization lock rejects' }
    finally { $heldLock.Dispose() }
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $historyDirectory = Join-Path $fixture.Root '.coord-local/leases/history/protected-a5/leases'
    New-Item -ItemType Directory -Path $historyDirectory -Force | Out-Null
    Copy-Item -LiteralPath $fixture.LeasePath -Destination (Join-Path $historyDirectory ($packets.LeaseSha + '.writer-lease.v1.json'))
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_IMMUTABLE_HISTORY_COLLISION' 'immutable history collision rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $receiptDirectory = Join-Path $fixture.Root '.coord-local/leases/history/protected-a5/finalizations'
    New-Item -ItemType Directory -Path $receiptDirectory -Force | Out-Null
    Write-Utf8NoBom -Path (Join-Path $receiptDirectory ($packets.LeaseSha + '.finalization.json')) -Text '{}'
    Assert-Status (Invoke-FixtureFinalizer -Fixture $fixture -LeaseSha $packets.LeaseSha) 'FINALIZATION_REJECTED_CONFLICTING_FINALIZATION_RECEIPT' 'conflicting existing finalization receipt rejects'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

$fixture = New-FixtureTaskRoot
try {
    $packets = Write-Packets -Fixture $fixture
    $hook = { [System.IO.File]::AppendAllText($fixture.LeasePath, "`n", [System.Text.UTF8Encoding]::new($false)) }.GetNewClosure()
    $drift = & $finalizerModule { param($root,$lease,$sha,$auth,$before) Invoke-ProtectedA5GovernanceFinalizationInternal -TaskRoot $root -LeasePath $lease -ExpectedLeaseSha256 $sha -AuthorizationPath $auth -BeforeLockHook $before } $fixture.Root $fixture.LeasePath $packets.LeaseSha $fixture.AuthorizationPath $hook
    Assert-Status $drift 'FINALIZATION_REJECTED_LEASE_CONTENT_DRIFT' 'content change after admission but before lock rejects'
    Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'pre-lock content drift leaves active marker present'
}
finally { Remove-FixtureTaskRoot -Fixture $fixture }

Write-Output ('PASS protected-A5 governance finalizer tests=' + $passed)
Write-Output '059_MODEL_FINALIZABLE_WITH_AUTH=true'
Write-Output '059_MODEL_FINALIZABLE_WITHOUT_AUTH=false'
