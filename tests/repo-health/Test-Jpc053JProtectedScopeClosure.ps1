[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../../tools/repo-health/Jpc054DProtectedScopeClosure.psm1'
$fixtureSource = Join-Path $PSScriptRoot 'fixtures/jpc-053j-protected-scope-closure/accepted'
$fixtureBase = Join-Path ([System.IO.Path]::GetTempPath()) 'jpc-081-053j-test-fixtures'
Import-Module $modulePath -Force
$closureModule = Get-Module Jpc054DProtectedScopeClosure

$passed = 0
function Assert-True {
    param([bool]$Condition,[string]$Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}
function Assert-Fails {
    param([scriptblock]$Action,[string]$Message)
    $failed = $false
    try { & $Action } catch { $failed = $true }
    Assert-True $failed $Message
}
function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}
function New-053JFixture {
    [System.IO.Directory]::CreateDirectory($fixtureBase) | Out-Null
    $root = Join-Path $fixtureBase ([guid]::NewGuid().ToString('N'))
    $receiptRelative = 'receipts\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z'
    $directories = @(
        '.coord-local\leases', '.coord-local\goals',
        '.coord-local\state\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z',
        ('.coord-local\' + $receiptRelative), '.coord-local\protected-scope-closeout\evidence', '.coord-local\authorizations'
    )
    foreach ($relative in $directories) { [System.IO.Directory]::CreateDirectory((Join-Path $root $relative)) | Out-Null }
    $copies = [ordered]@{
        (Join-Path $fixtureSource 'leases\taskroot-writer.active.json') = (Join-Path $root '.coord-local\leases\taskroot-writer.active.json')
        (Join-Path $fixtureSource 'goals\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J.json') = (Join-Path $root '.coord-local\goals\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J.json')
        (Join-Path $fixtureSource 'state\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z\budget.json') = (Join-Path $root '.coord-local\state\JPC-V22-GA-FASTLANE-AUTONOMOUS-CLOSEOUT-12H-053J-20260828T043116Z\budget.json')
        (Join-Path $fixtureSource ($receiptRelative + '\PROMOTION-1-INTENT.json')) = (Join-Path $root ('.coord-local\' + $receiptRelative + '\PROMOTION-1-INTENT.json'))
        (Join-Path $fixtureSource ($receiptRelative + '\PROMOTION-1-TERMINAL.json')) = (Join-Path $root ('.coord-local\' + $receiptRelative + '\PROMOTION-1-TERMINAL.json'))
        (Join-Path $fixtureSource ($receiptRelative + '\FINAL-RECEIPT.md')) = (Join-Path $root ('.coord-local\' + $receiptRelative + '\FINAL-RECEIPT.md'))
        (Join-Path $fixtureSource 'evidence\PREDECESSOR-053J-SETTLEMENT.json') = (Join-Path $root '.coord-local\protected-scope-closeout\evidence\PREDECESSOR-053J-SETTLEMENT.json')
    }
    foreach ($entry in $copies.GetEnumerator()) { [System.IO.File]::Copy($entry.Key, $entry.Value, $false) }
    $predecessor = Join-Path $root '.coord-local\protected-scope-closeout\evidence\PREDECESSOR-053J-SETTLEMENT.json'
    $contract = & $closureModule { param($r,$p) New-Jpc053JContract -TaskRoot $r -PredecessorSettlementPath $p -ShadowAudit } $root $predecessor
    return [pscustomobject]@{ Root=$root; Contract=$contract; LeasePath=$contract.lease_path; AuthorizationPath=(Join-Path $root '.coord-local\authorizations\shadow-audit.json') }
}
function Remove-053JFixture {
    param([Parameter(Mandatory)][object]$Fixture)
    if (-not (Test-Path -LiteralPath $Fixture.Root)) { return }
    $resolved = (Resolve-Path -LiteralPath $Fixture.Root).Path
    $safeBase = [System.IO.Path]::GetFullPath($fixtureBase).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($safeBase, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped the exact test root.' }
    Get-ChildItem -LiteralPath $resolved -Recurse -Force | ForEach-Object { $_.Attributes = ($_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)) }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
function Invoke-053JFixture {
    param([Parameter(Mandatory)][ValidateSet('Observe','Close')][string]$Mode,[Parameter(Mandatory)][object]$Fixture,[string]$AuthorizationPath='',[string]$FaultInjection='')
    return & $closureModule { param($m,$c,$a,$f) Invoke-Jpc053JProtectedScopeClosureInternal -Mode $m -Contract $c -AuthorizationPath $a -FaultInjection $f } $Mode $Fixture.Contract $AuthorizationPath $FaultInjection
}
function New-053JAuthorization {
    param([Parameter(Mandatory)][object]$Fixture,[Parameter(Mandatory)][object]$Verification)
    $now = [DateTimeOffset]::UtcNow
    $c = $Fixture.Contract
    $authorization = [ordered]@{
        schema='jpc.053j-protected-scope-closure-authorization.v1'; authorization_id='goal-081-shadow-audit'; authorization_scope='SHADOW_AUDIT_AUTHORIZATION'
        authority_environment='SHADOW_AUDIT_ONLY'; real_task_root_authority='NOT_VALID_FOR_REAL_TASK_ROOT'; authorized_by='OwnerFixture'
        authorized_utc=$now.AddMinutes(-1).ToString('o'); expires_utc=$now.AddMinutes(14).ToString('o'); task_root=$c.task_root
        source_lease_path=$c.lease_path; lease_sha256=$c.expected_lease_sha256; goal=$c.goal; run_id=$c.run_id; transaction_id=$c.transaction_id
        goal_sha256=$c.expected_goal_sha256; budget_sha256=$c.expected_budget_sha256; intent_sha256=$c.expected_intent_sha256
        terminal_sha256=$c.expected_terminal_sha256; final_receipt_sha256=$c.expected_final_receipt_sha256; predecessor_settlement_sha256=$c.expected_predecessor_settlement_sha256
        evidence_manifest_sha256=$Verification.evidence_manifest_sha256; non_activation_proof_sha256=$Verification.non_activation_proof_sha256
        classification=$c.classification; terminal_class=$c.terminal_class; terminal_reason=$c.terminal_reason
        historical_lease_path=$Verification.historical_lease_path; receipt_path=$Verification.receipt_path
        protected_activation_occurred=$false; production_apply_executed=$false; rollback_required=$false; rollback_executed=$false; new_production_authority_granted=$false
    }
    Write-Utf8NoBom -Path $Fixture.AuthorizationPath -Text ($authorization | ConvertTo-Json -Depth 12)
    return $Fixture.AuthorizationPath
}
function Replace-ExactText {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$From,[Parameter(Mandatory)][string]$To)
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false, $true))
    if (-not $text.Contains($From, [System.StringComparison]::Ordinal)) { throw 'Expected fixture text is absent.' }
    Write-Utf8NoBom -Path $Path -Text $text.Replace($From, $To)
}

try {
    $fixture = New-053JFixture
    try {
        $observe = Invoke-053JFixture -Mode Observe -Fixture $fixture
        Assert-True ($observe.status -eq 'CLOSURE_VERIFY_PASS' -and $observe.closure_verification -eq 'PASS') 'exact 053J fixture admits for nonactivation closeout'
        Assert-True ($observe.lease_sha256 -eq '2a68e7130affb8e39ae821e80b10c1e3891254b2de091bf81e5f60100d20100a') 'exact 053J lease digest is mandatory'
        Assert-True ($observe.terminal_class -eq 'UNCONSUMED_PRE_APPLY_REJECTED' -and $observe.terminal_reason -eq 'PUBLIC_MANIFEST_FETCH_REJECTED') 'terminal class derives from immutable evidence'
        Assert-True (-not $observe.protected_activation_occurred -and -not $observe.production_apply_executed -and -not $observe.rollback_required -and -not $observe.rollback_executed -and -not $observe.new_production_authority_granted) 'nonactivation proof grants no production authority'
    }
    finally { Remove-053JFixture $fixture }

    Assert-Fails { & $closureModule { New-Jpc053JContract -TaskRoot 'V:\src\jpc-multi-device-enrollment-train' -ShadowAudit } | Out-Null } 'shadow authorization contract can never target the real task root'

    $fixture = New-053JFixture
    try {
        Replace-ExactText -Path $fixture.Contract.terminal_path -From 'PUBLIC_MANIFEST_FETCH_REJECTED' -To 'ARBITRARY_LEGACY_TERMINAL'
        $rejected = Invoke-053JFixture -Mode Observe -Fixture $fixture
        Assert-True ($rejected.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.LeasePath)) 'terminal evidence drift rejects without moving the active marker'
    }
    finally { Remove-053JFixture $fixture }

    $fixture = New-053JFixture
    try {
        $observe = Invoke-053JFixture -Mode Observe -Fixture $fixture
        $authorization = New-053JAuthorization -Fixture $fixture -Verification $observe
        Replace-ExactText -Path $authorization -From 'SHADOW_AUDIT_AUTHORIZATION' -To 'EXACT_053J_UNCONSUMED_PRE_APPLY_CLOSEOUT'
        $rejected = Invoke-053JFixture -Mode Close -Fixture $fixture -AuthorizationPath $authorization
        Assert-True ($rejected.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.LeasePath)) 'real authorization scope is rejected for a shadow task root'
    }
    finally { Remove-053JFixture $fixture }

    $fixture = New-053JFixture
    try {
        $observe = Invoke-053JFixture -Mode Observe -Fixture $fixture
        $authorization = New-053JAuthorization -Fixture $fixture -Verification $observe
        $close = Invoke-053JFixture -Mode Close -Fixture $fixture -AuthorizationPath $authorization
        Assert-True ($close.status -eq 'CLOSURE_CLOSE_PASS' -and $close.closure_verification -eq 'PASS') 'first exact close succeeds with bounded shadow authorization'
        Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath)) 'exact close removes the active marker only by canonical move'
        Assert-True ((Get-Sha256 -Path $close.historical_lease_path) -eq $fixture.Contract.expected_lease_sha256) 'historical lease preserves the exact 053J bytes'
        Assert-True ((((Get-Item -LiteralPath $close.historical_lease_path -Force).Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0) -and (((Get-Item -LiteralPath $close.receipt_path -Force).Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0)) 'archive and receipt are immutable'
        $receiptWrite = (Get-Item -LiteralPath $close.receipt_path -Force).LastWriteTimeUtc
        $second = Invoke-053JFixture -Mode Close -Fixture $fixture -AuthorizationPath $authorization
        Assert-True ($second.status -eq 'CLOSURE_ALREADY_CLOSED' -and (Get-Item -LiteralPath $close.receipt_path -Force).LastWriteTimeUtc -eq $receiptWrite) 'repeat close is an idempotent observation'
        Assert-True (-not $close.production_apply_executed -and -not $close.rollback_required -and -not $close.rollback_executed -and -not $close.new_production_authority_granted) 'close performs no production transaction action'
    }
    finally { Remove-053JFixture $fixture }

    $fixture = New-053JFixture
    try {
        $observe = Invoke-053JFixture -Mode Observe -Fixture $fixture
        $authorization = New-053JAuthorization -Fixture $fixture -Verification $observe
        $fault = Invoke-053JFixture -Mode Close -Fixture $fixture -AuthorizationPath $authorization -FaultInjection AfterMove
        Assert-True ($fault.closure_verification -eq 'FAIL_CLOSED' -and -not (Test-Path -LiteralPath $fixture.LeasePath)) 'fault after move leaves recoverable history and never recreates active bytes'
        $pending = Invoke-053JFixture -Mode Observe -Fixture $fixture
        Assert-True ($pending.status -eq 'CLOSURE_RECOVERY_PENDING' -and $pending.closure_verification -eq 'PASS') 'interrupted close is explicitly classified RECOVERY_PENDING'
        $recovered = Invoke-053JFixture -Mode Close -Fixture $fixture -AuthorizationPath $authorization
        Assert-True ($recovered.status -eq 'CLOSURE_RECOVERY_COMPLETED') 'bounded authorization completes a documented RECOVERY_PENDING closeout'
    }
    finally { Remove-053JFixture $fixture }
}
finally {
    Remove-Module Jpc054DProtectedScopeClosure -Force -ErrorAction SilentlyContinue
}

Write-Output ('PASS jpc-053j protected-scope closure tests=' + $passed)
