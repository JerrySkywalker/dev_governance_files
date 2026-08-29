[CmdletBinding()]
param([ValidateSet('All','Core','Evidence','Close','CloseGuards','CloseCommit','Fault')][string]$Group = 'All')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../../tools/repo-health/Jpc054DProtectedScopeClosure.psm1'
$seedRoot = Join-Path $PSScriptRoot 'fixtures/jpc-054d-protected-scope-closure/accepted'
Import-Module $modulePath -Force
$closureModule = Get-Module Jpc054DProtectedScopeClosure
$passed = 0

function Assert-True { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw $Message }; $script:passed++ }
function Assert-Fails { param([scriptblock]$Action,[string]$Message) $failed=$false;try { & $Action } catch { $failed=$true };Assert-True $failed $Message }
function Write-Utf8NoBom { param([string]$Path,[string]$Text) [System.IO.File]::WriteAllText($Path,$Text,[System.Text.UTF8Encoding]::new($false)) }
function Replace-Text { param([string]$Path,[string]$From,[string]$To) $text=[System.IO.File]::ReadAllText($Path,[System.Text.UTF8Encoding]::new($false));if(-not $text.Contains($From,[StringComparison]::Ordinal)){throw "fixture token absent: $From"};Write-Utf8NoBom -Path $Path -Text $text.Replace($From,$To) }
function Get-FixtureGithubEvidence { [pscustomobject]@{current_state='open';merged_at='';current_head_sha='b892cd6f50eef7c0b35a1a6609547fda2056644f';merge_commit_sha=''} }
function New-ReparseDirectoryLink {
    param([string]$Path,[string]$Target)
    if($IsWindows){New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null}
    else{New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null}
}

function New-ClosureFixture {
    $parent=Join-Path ([IO.Path]::GetTempPath()) ('jpc-054d-closure-'+[guid]::NewGuid().ToString('N'))
    $root=Join-Path $parent 'coord';$history=Join-Path $parent 'closure-history';$handoff=Join-Path $parent 'handoff'
    New-Item -ItemType Directory -Path $parent,$handoff -Force | Out-Null
    Copy-Item -LiteralPath $seedRoot -Destination $root -Recurse -Force
    $contract=& $closureModule { param($r,$h) New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture } $root $history
    [pscustomobject]@{parent=$parent;root=$root;history=$history;handoff=$handoff;contract=$contract}
}

function Remove-ClosureFixture {
    param([object]$Fixture)
    if(Test-Path -LiteralPath $Fixture.parent){$resolved=(Resolve-Path -LiteralPath $Fixture.parent).Path;$temp=(Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path;if(-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'fixture cleanup escaped temp root'};Get-ChildItem -LiteralPath $resolved -Force -Recurse -File | ForEach-Object { $_.Attributes=$_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly) };Remove-Item -LiteralPath $resolved -Recurse -Force}
}

function Invoke-FixtureClosure {
    param([ValidateSet('Verify','Close')][string]$Mode,[object]$Fixture,[string]$AuthorizationPath='',[string]$FaultInjection='')
    $github=Get-FixtureGithubEvidence
    return (& $closureModule { param($m,$c,$a,$g,$f) Invoke-Jpc054DProtectedScopeClosureInternal -Mode $m -AuthorizationPath $a -Contract $c -GitHubEvidence $g -FaultInjection $f } $Mode $Fixture.contract $AuthorizationPath $github $FaultInjection)
}
function Get-Verify { param([object]$Fixture) Invoke-FixtureClosure -Mode Verify -Fixture $Fixture }
function New-Authorization {
    param([object]$Fixture,[object]$Verification,[switch]$Expired)
    $now=[DateTimeOffset]::UtcNow
    $authorized=if($Expired){$now.AddHours(-2)}else{$now.AddMinutes(-1)}
    $expires=if($Expired){$now.AddHours(-1)}else{$now.AddMinutes(20)}
    $payload=[ordered]@{
        schema='jpc.protected-scope-closure-authorization.v1';authorization_id='owner-054d-close-001';authorized_by='Owner';authorized_utc=$authorized.ToString('o');expires_utc=$expires.ToString('o')
        source_lease_path=$Fixture.contract.lease_path;lease_sha256=$Verification.lease_sha256;goal=$Fixture.contract.goal;run_id=$Fixture.contract.run_id
        evidence_manifest_sha256=$Verification.evidence_manifest_sha256;non_activation_proof_sha256=$Verification.non_activation_proof_sha256;classification='CLOSED_WITHOUT_PROTECTED_ACTIVATION'
        historical_lease_path=$Verification.closure_destination;receipt_path=$Verification.receipt_destination;production_apply_executed=$false;production_rollback_required=$false;new_production_authority_granted=$false
    }
    $path=Join-Path $Fixture.handoff 'owner-authorization.json';Write-Utf8NoBom -Path $path -Text ($payload|ConvertTo-Json -Compress -Depth 8)
    [pscustomobject]@{path=$path;payload=$payload}
}

function Assert-VerifyRejects {
    param([object]$Fixture,[string]$Message)
    $result=Get-Verify -Fixture $Fixture
    Assert-True ($result.closure_verification -eq 'FAIL_CLOSED') $Message
}

try {
    if($Group -in @('All','Core')) {
    $fixture=New-ClosureFixture
    try {
        $verification=Get-Verify -Fixture $fixture
        Assert-True ($verification.status -eq 'CLOSURE_VERIFY_PASS') 'exact accepted 054D fixture verifies'
        Assert-True ($verification.closure_classification -eq 'CLOSED_WITHOUT_PROTECTED_ACTIVATION' -and $verification.closure_safe) 'accepted fixture proves closure-safe nonactivation'
        Assert-True ($verification.root_file_count -eq 14 -and $verification.lease_expired -and $verification.holder_dead) 'fixture establishes exact inventory, expiry, and dead holder'
        Assert-True (-not $verification.production_apply_executed -and -not $verification.production_rollback_required -and -not $verification.new_production_authority_granted) 'verification cannot claim production mutation'
    } finally {Remove-ClosureFixture $fixture}

    $fixture=New-ClosureFixture;try{$fixture.contract.expected_lease_sha256=('0'*64);Assert-VerifyRejects $fixture 'wrong lease SHA rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$fixture.contract.expected_root_manifest_sha256=('0'*64);Assert-VerifyRejects $fixture 'wrong root manifest SHA rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$fixture.contract.goal='WRONG-GOAL';Assert-VerifyRejects $fixture 'wrong Goal rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$fixture.contract.run_id='WRONG-RUN';Assert-VerifyRejects $fixture 'wrong run ID rejects'}finally{Remove-ClosureFixture $fixture}

    $fixture=New-ClosureFixture;try{Replace-Text (Join-Path $fixture.root 'leases/writer.active.json') '2020-08-29T18:14:47.0106711+00:00' ([DateTimeOffset]::UtcNow.AddMinutes(30).ToString('o'));$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'unexpired lease rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Replace-Text (Join-Path $fixture.root 'leases/writer.active.json') '9692' "$PID";$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'live recorded holder rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Write-Utf8NoBom (Join-Path $fixture.root 'leases/writer.active.json') '{';$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'malformed lease rejects'}finally{Remove-ClosureFixture $fixture}

    $fixture=New-ClosureFixture;try{$moved=Join-Path $fixture.parent 'coord-real';Move-Item -LiteralPath $fixture.root -Destination $moved;New-ReparseDirectoryLink -Path $fixture.root -Target $moved;Assert-VerifyRejects $fixture 'reparse coordination root rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$leases=Join-Path $fixture.root 'leases';$moved=Join-Path $fixture.parent 'leases-real';Move-Item -LiteralPath $leases -Destination $moved;New-ReparseDirectoryLink -Path $leases -Target $moved;Assert-VerifyRejects $fixture 'reparse lease directory rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$lease=Join-Path $fixture.root 'leases/writer.active.json';$real=Join-Path $fixture.parent 'writer-reparse-target';Move-Item -LiteralPath $lease -Destination (Join-Path $fixture.parent 'writer.real.json');New-Item -ItemType Directory -Path $real | Out-Null;New-ReparseDirectoryLink -Path $lease -Target $real;Assert-VerifyRejects $fixture 'reparse lease path rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$real=Join-Path $fixture.parent 'history-real';New-Item -ItemType Directory -Path $real | Out-Null;New-ReparseDirectoryLink -Path $fixture.history -Target $real;Assert-VerifyRejects $fixture 'reparse history destination rejects before any closure write';Assert-True (@(Get-ChildItem -LiteralPath $real -Force).Count -eq 0) 'reparse history target remains untouched'}finally{Remove-ClosureFixture $fixture}

    $fixture=New-ClosureFixture;try{Write-Utf8NoBom (Join-Path $fixture.root 'receipts/A5-protected-envelope.json') '{}';Assert-VerifyRejects $fixture 'unknown extra evidence and A5 envelope reject'}finally{Remove-ClosureFixture $fixture}
    }
    if($Group -in @('All','Evidence')) {
    $fixture=New-ClosureFixture;try{Add-Content -LiteralPath (Join-Path $fixture.root 'GOAL.md') -Value 'drift';Assert-VerifyRejects $fixture 'changed evidence manifest rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Remove-Item -LiteralPath (Join-Path $fixture.root 'receipts/R5B-PR-55-CANDIDATE.json');Assert-VerifyRejects $fixture 'missing required receipt rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Replace-Text (Join-Path $fixture.root 'receipts/INTERIM-STATUS-EXTERNAL-CI-QUEUE.json') '"promotion_started": false' '"promotion_started": true';$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'conflicting receipt rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Write-Utf8NoBom (Join-Path $fixture.root 'receipts/production-journal.json') '{}';Assert-VerifyRejects $fixture 'production journal rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Write-Utf8NoBom (Join-Path $fixture.root 'receipts/rollback-journal.json') '{}';Assert-VerifyRejects $fixture 'rollback journal rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Write-Utf8NoBom (Join-Path $fixture.root 'receipts/Apply-receipt.json') '{}';Assert-VerifyRejects $fixture 'Apply receipt rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Replace-Text (Join-Path $fixture.root 'receipts/R3-PR-64-EXACT-MAIN-ACCEPTED.json') 'false' 'true';$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'public_stage0_updated true rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{Replace-Text (Join-Path $fixture.root 'receipts/INTERIM-STATUS-EXTERNAL-CI-QUEUE.json') '"rc32_source_created": false' '"rc32_source_created": true';$fixture.contract=& $closureModule {param($r,$h)New-Jpc054DContract -CoordinationRoot $r -HistoryRoot $h -Fixture}$fixture.root $fixture.history;Assert-VerifyRejects $fixture 'release evidence proving protected admission rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$during=[pscustomobject]@{current_state='closed';merged_at='2020-08-29T18:14:47.0106710+00:00';current_head_sha='x';merge_commit_sha='x'};$result=& $closureModule {param($c,$g)Invoke-Jpc054DProtectedScopeClosureInternal -Mode Verify -Contract $c -GitHubEvidence $g}$fixture.contract $during;Assert-True ($result.closure_verification -eq 'FAIL_CLOSED') 'PR55 merge within 054D rejects transition proof'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$later=[pscustomobject]@{current_state='closed';merged_at='2020-08-29T18:14:47.0106712+00:00';current_head_sha='x';merge_commit_sha='x'};$result=& $closureModule {param($c,$g)Invoke-Jpc054DProtectedScopeClosureInternal -Mode Verify -Contract $c -GitHubEvidence $g}$fixture.contract $later;Assert-True ($result.closure_verification -eq 'PASS' -and $result.github_state_is_later) 'later PR55 state remains distinct from historical 054D proof'}finally{Remove-ClosureFixture $fixture}
    }

    if($Group -in @('All','Close','CloseGuards')) {
    $fixture=New-ClosureFixture;try{$verification=Get-Verify $fixture;$close=Invoke-FixtureClosure -Mode Close -Fixture $fixture;Assert-True ($close.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.contract.lease_path)) 'Close without Owner authorization rejects before mutation'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification;$auth.payload.evidence_manifest_sha256=('0'*64);Write-Utf8NoBom $auth.path ($auth.payload|ConvertTo-Json -Compress -Depth 8);$close=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path;Assert-True ($close.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.contract.lease_path)) 'Owner authorization digest mismatch rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification -Expired;$close=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path;Assert-True ($close.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.contract.lease_path)) 'expired Owner authorization rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification;Add-Content -LiteralPath $fixture.contract.lease_path -Value ' ';$close=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path;Assert-True ($close.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.contract.lease_path)) 'source bytes drift after Verify rejects'}finally{Remove-ClosureFixture $fixture}
    $fixture=New-ClosureFixture;try{$verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification;Add-Content -LiteralPath (Join-Path $fixture.root 'GOAL.md') -Value ' ';$close=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path;Assert-True ($close.closure_verification -eq 'FAIL_CLOSED' -and (Test-Path -LiteralPath $fixture.contract.lease_path)) 'evidence drift after Verify rejects'}finally{Remove-ClosureFixture $fixture}

    }
    if($Group -in @('All','Close','CloseCommit')) {
    $fixture=New-ClosureFixture
    try {
        $verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification
        $close=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path
        Assert-True ($close.status -eq 'CLOSURE_CLOSE_PASS') 'first Close passes only with exact Owner authorization'
        Assert-True (-not (Test-Path -LiteralPath $fixture.contract.lease_path)) 'first Close removes active source marker by move'
        $historicalSha=(Get-FileHash -LiteralPath $close.historical_lease_path -Algorithm SHA256).Hash.ToLowerInvariant()
        Assert-True ($historicalSha -eq $verification.lease_sha256) 'historical lease hash equals original exact SHA'
        $receiptBytes=[IO.File]::ReadAllBytes($close.receipt_path);$receipt=$receiptBytes|ForEach-Object { } # retain immutable path check without logging receipt data
        Assert-True (((Get-Item -LiteralPath $close.receipt_path -Force).Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0) 'closure receipt is create-once and read-only'
        $before=(Get-Item -LiteralPath $close.receipt_path).LastWriteTimeUtc;$closedWithoutAuthorization=Invoke-FixtureClosure -Mode Close -Fixture $fixture
        Assert-True ($closedWithoutAuthorization.closure_verification -eq 'FAIL_CLOSED') 'idempotent Close still requires exact Owner authorization'
        $second=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path
        Assert-True ($second.status -eq 'CLOSURE_ALREADY_CLOSED' -and (Get-Item -LiteralPath $close.receipt_path).LastWriteTimeUtc -eq $before) 'second Close is an idempotent observation without a second mutation'
        Assert-True (-not $close.production_apply_executed -and -not $close.production_rollback_required -and -not $close.new_production_authority_granted) 'Close invokes neither production mutation nor rollback'
    } finally { Remove-ClosureFixture $fixture }

    }
    if($Group -in @('All','Close','Fault')) {
    $fixture=New-ClosureFixture
    try {
        $verification=Get-Verify $fixture;$auth=New-Authorization $fixture $verification
        $fault=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path -FaultInjection AfterMove
        Assert-True ($fault.closure_verification -eq 'FAIL_CLOSED' -and -not (Test-Path -LiteralPath $fixture.contract.lease_path)) 'fault after move never recreates or overwrites source bytes'
        $recovery=Invoke-FixtureClosure -Mode Close -Fixture $fixture -AuthorizationPath $auth.path
        Assert-True ($recovery.status -match 'INTERRUPTED_CLOSE_RECOVERY_REQUIRED') 'interrupted close requires explicit recovery classification rather than retry'
    } finally { Remove-ClosureFixture $fixture }
    }
}
finally { Remove-Module Jpc054DProtectedScopeClosure -Force -ErrorAction SilentlyContinue }

Write-Output ('PASS jpc-054d protected-scope closure tests=' + $passed)
