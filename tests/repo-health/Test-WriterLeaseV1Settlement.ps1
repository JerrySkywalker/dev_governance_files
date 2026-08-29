[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../../tools/repo-health/WriterLeaseV1Settlement.psm1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures/writer-lease-v1/054d-ordinary-development'
Import-Module $modulePath -Force

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
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash([System.IO.File]::ReadAllBytes($Path)) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}
function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}
function Replace-FileText {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$From,[Parameter(Mandatory)][string]$To)
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    if (-not $text.Contains($From, [System.StringComparison]::Ordinal)) { throw 'Fixture replacement token is absent.' }
    Write-Utf8NoBom -Path $Path -Text $text.Replace($From, $To)
}
function New-FixtureTaskRoot {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('writer-lease-v1-' + [guid]::NewGuid().ToString('N'))
    $leaseDirectory = Join-Path $root '.coord-local/leases'
    $goalDirectory = Join-Path $root '.coord-local/goals'
    $stateDirectory = Join-Path $root '.coord-local/state'
    $authorizationDirectory = Join-Path $root '.coord-local/authorizations'
    foreach ($directory in @($leaseDirectory,$goalDirectory,$stateDirectory,$authorizationDirectory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'taskroot-writer.active.json') -Destination (Join-Path $leaseDirectory 'taskroot-writer.active.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot '054d-goal.json') -Destination (Join-Path $goalDirectory '054d-goal.json')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot '054d-budget.json') -Destination (Join-Path $stateDirectory '054d-budget.json')
    Write-Utf8NoBom -Path (Join-Path $root '.gitignore') -Text ".coord-local/`n"
    Write-Utf8NoBom -Path (Join-Path $root 'README.md') -Text "synthetic writer lease fixture`n"
    git -C $root init --initial-branch=main -q
    git -C $root config user.email 'repo-health-test@example.invalid'
    git -C $root config user.name 'repo-health-test'
    git -C $root config core.autocrlf false
    git -C $root add -- README.md .gitignore
    git -C $root commit -q -m fixture
    [pscustomobject]@{
        Root = $root
        LeasePath = Join-Path $leaseDirectory 'taskroot-writer.active.json'
        GoalPath = Join-Path $goalDirectory '054d-goal.json'
        AuthorizationPath = Join-Path $authorizationDirectory '054d-settlement-authorization.json'
        HolderSession = '00000000-0000-0000-0000-000000000054'
    }
}
function Write-Authorization {
    param([Parameter(Mandatory)][object]$Fixture,[Parameter(Mandatory)][string]$LeaseSha256)
    $authorizationNow = [DateTimeOffset]::UtcNow
    $authorization = [ordered]@{
        schema='writer-lease-v1-settlement-authorization.v1'; authorization_id='owner-054d-settlement-001'; authorization_scope='EXPIRED_ORDINARY_DEVELOPMENT_V1_SETTLEMENT'
        task_root_relative_lease_path='.coord-local/leases/taskroot-writer.active.json'; expected_lease_sha256=$LeaseSha256; authorized_by='OWNER'
        authorized_utc=$authorizationNow.AddMinutes(-1).ToString('o'); expires_utc=$authorizationNow.AddHours(1).ToString('o')
    }
    Write-Utf8NoBom -Path $Fixture.AuthorizationPath -Text ($authorization | ConvertTo-Json -Depth 8)
}
function Set-FixtureLeaseExpiredNow {
    param([Parameter(Mandatory)][object]$Fixture)
    $now = [DateTimeOffset]::UtcNow
    Replace-FileText -Path $Fixture.LeasePath -From '2026-08-29T16:14:46.0000000Z' -To $now.AddMinutes(-3).ToString('o')
    Replace-FileText -Path $Fixture.LeasePath -From '2026-08-29T16:14:47.0000000Z' -To $now.AddMinutes(-2).ToString('o')
    Replace-FileText -Path $Fixture.LeasePath -From '2026-08-29T18:14:47.0000000Z' -To $now.AddMinutes(-1).ToString('o')
}
function Remove-FixtureTaskRoot {
    param([Parameter(Mandatory)][object]$Fixture)
    if (Test-Path -LiteralPath $Fixture.Root) {
        $resolved = (Resolve-Path -LiteralPath $Fixture.Root).Path
        if (-not $resolved.StartsWith([System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()), [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped temp root.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

$beforeExpiry = [DateTimeOffset]::ParseExact('2026-08-29T18:14:46.0000000Z', 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)
$afterExpiry = [DateTimeOffset]::ParseExact('2026-08-29T18:14:48.0000000Z', 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)

try {
    $fixture = New-FixtureTaskRoot
    try {
        $before = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $beforeExpiry
        Assert-True ($before.status -eq 'SETTLEMENT_REJECTED_NOT_EXPIRED') '054D sanitized fixture rejects before expiry'
        $after = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($after.status -eq 'SETTLEMENT_ACCEPTED') '054D sanitized fixture accepts after simulated expiry'
        Set-FixtureLeaseExpiredNow -Fixture $fixture
        $leaseSha = Get-Sha256 -Path $fixture.LeasePath
        Write-Authorization -Fixture $fixture -LeaseSha256 $leaseSha
        $settled = Invoke-WriterLeaseV1InterimSettlement -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -AuthorizationPath $fixture.AuthorizationPath
        Assert-True ($settled.status -eq 'SETTLEMENT_PASS') 'expired ordinary-development lease with dead or opaque holder settles'
        Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath)) 'settlement independently removes active marker by move'
        $historicalBytesSha = Get-Sha256 -Path $settled.historical_lease_path
        Assert-True ($historicalBytesSha -eq $leaseSha) 'terminal historical record retains the exact original lease digest'
        $receipt = Get-Content -LiteralPath $settled.receipt_path -Raw | ConvertFrom-Json
        Assert-True ($receipt.original_lease_sha256 -eq $leaseSha -and $receipt.settlement_status -eq 'SETTLED') 'terminal settlement receipt is digest-bound'
        $second = Invoke-WriterLeaseV1InterimSettlement -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -AuthorizationPath $fixture.AuthorizationPath
        Assert-True ($second.status -eq 'SETTLEMENT_ALREADY_SETTLED') 'second settlement is an idempotent observation'
        Assert-True (@(Get-ChildItem -LiteralPath (Split-Path -Parent $settled.receipt_path) -Filter '*.settlement.json').Count -eq 1) 'two settlement attempts create exactly one terminal settlement receipt'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        $unexpired = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $beforeExpiry
        Assert-True ($unexpired.status -eq 'SETTLEMENT_REJECTED_NOT_EXPIRED') 'unexpired lease rejects even when holder is not demonstrably live'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        Replace-FileText -Path $fixture.LeasePath -From '"holder": "codex-legacy-holder"' -To ('"holder": "pid:' + $PID + '"')
        $live = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($live.status -eq 'SETTLEMENT_REJECTED_LIVE_HOLDER') 'expired lease with a demonstrably live holder rejects'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        Replace-FileText -Path $fixture.LeasePath -From '2026-08-29T18:14:47.0000000Z' -To 'not-a-date'
        $malformedExpiry = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($malformedExpiry.status -eq 'SETTLEMENT_REJECTED_MALFORMED_HARD_STOP_UTC') 'malformed expiry rejects'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        Replace-FileText -Path $fixture.LeasePath -From 'jpc.taskroot-writer-lease.v1' -To 'jpc.taskroot-writer-lease.v0'
        $malformedSchema = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($malformedSchema.status -eq 'SETTLEMENT_REJECTED_UNSUPPORTED_SCHEMA') 'unsupported legacy schema rejects'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        $leaseDirectory = Split-Path -Parent $fixture.LeasePath
        $targetDirectory = Join-Path $fixture.Root 'real-leases'
        Move-Item -LiteralPath $leaseDirectory -Destination $targetDirectory
        New-Item -ItemType Junction -Path $leaseDirectory -Target $targetDirectory -ErrorAction Stop | Out-Null
        $reparse = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($reparse.status -eq 'SETTLEMENT_REJECTED_REPARSE_PATH') 'reparse lease rejects'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        $admission = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($admission.status -eq 'SETTLEMENT_ACCEPTED') 'pre-drift admission captures lease digest'
        $capturedSha = $admission.lease_sha256
        [System.IO.File]::AppendAllText($fixture.LeasePath, "`n", [System.Text.UTF8Encoding]::new($false))
        Write-Authorization -Fixture $fixture -LeaseSha256 $capturedSha
        $drift = Invoke-WriterLeaseV1InterimSettlement -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $capturedSha -AuthorizationPath $fixture.AuthorizationPath
        Assert-True ($drift.status -eq 'SETTLEMENT_REJECTED_CONTENT_DRIFT') 'lease bytes changed after admission reject'
        Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'content drift leaves the active marker in place'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        Replace-FileText -Path $fixture.GoalPath -From '"profile": "INTERACTIVE_REPOSITORY_V1"' -To '"profile": "PROTECTED_TRANSACTION_V2"'
        $production = Test-WriterLeaseV1SettlementAdmission -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -NowUtc $afterExpiry
        Assert-True ($production.status -eq 'SETTLEMENT_REJECTED_PRODUCTION_ATTACHED') 'production attachment rejects'
        Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'production attachment does not retire the active marker'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    foreach ($outcome in @('PASS','BLOCKED','HOLD','WAITING_EXTERNAL_CI','READY_FOR_OWNER')) {
        $fixture = New-FixtureTaskRoot
        try {
            $leaseSha = Get-Sha256 -Path $fixture.LeasePath
            $normal = Invoke-WriterLeaseV1OrdinaryDevelopmentCoordinator -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -ExpectedHolderSession $fixture.HolderSession -Run ([scriptblock]::Create("'$outcome'"))
            Assert-True ($normal.normal_return_release.status -eq 'NORMAL_RETURN_RELEASED' -and -not $normal.normal_return_release.active_lease) ('normal Implementer ' + $outcome + ' releases the ordinary-development lease')
            Assert-True (-not (Test-Path -LiteralPath $fixture.LeasePath)) ('normal Implementer ' + $outcome + ' independently proves ACTIVE_LEASE=false')
        }
        finally { Remove-FixtureTaskRoot -Fixture $fixture }
    }

    $fixture = New-FixtureTaskRoot
    try {
        $leaseSha = Get-Sha256 -Path $fixture.LeasePath
        Assert-Fails { Invoke-WriterLeaseV1OrdinaryDevelopmentCoordinator -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -ExpectedHolderSession $fixture.HolderSession -Run { throw 'synthetic abnormal process crash' } | Out-Null } 'abnormal process crash propagates'
        Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'abnormal process crash does not falsely claim clean release'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }

    $fixture = New-FixtureTaskRoot
    try {
        Replace-FileText -Path $fixture.GoalPath -From '"profile": "INTERACTIVE_REPOSITORY_V1"' -To '"profile": "PROTECTED_TRANSACTION_V2"'
        $leaseSha = Get-Sha256 -Path $fixture.LeasePath
        $productionNormal = Complete-WriterLeaseV1NormalReturn -TaskRoot $fixture.Root -LeasePath $fixture.LeasePath -ExpectedLeaseSha256 $leaseSha -ExpectedHolderSession $fixture.HolderSession -Outcome PASS
        Assert-True ($productionNormal.status -eq 'SETTLEMENT_REJECTED_PRODUCTION_ATTACHED' -and $productionNormal.active_lease) 'existing production transaction semantics remain unchanged'
        Assert-True (Test-Path -LiteralPath $fixture.LeasePath) 'normal-return path never releases a production attachment'
    }
    finally { Remove-FixtureTaskRoot -Fixture $fixture }
}
finally {
    # Every fixture is individually cleaned up so that a failed case cannot create a later false pass.
}

Write-Output ('PASS writer-lease-v1 settlement tests=' + $passed)
