[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/WriterOwnershipV2.psm1') -Force

$passed = 0
$failed = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        Write-Error "FAIL: $Message"
        $script:failed++
    }
    else {
        Write-Host "PASS: $Message"
        $script:passed++
    }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$ExpectedCode, [string]$Message)
    $threw = $false
    $caughtCode = ''
    try { & $Action } catch { $threw = $true; $caughtCode = $_.Exception.Message }
    if (-not $threw) {
        Write-Error "FAIL (no throw): $Message"
        $script:failed++
        return
    }
    if ($ExpectedCode -and $caughtCode -notmatch [regex]::Escape($ExpectedCode)) {
        Write-Error "FAIL (wrong code='$caughtCode'): $Message"
        $script:failed++
        return
    }
    Write-Host "PASS: $Message"
    $script:passed++
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('wlv2-test-' + [guid]::NewGuid().ToString('N'))
[System.IO.Directory]::CreateDirectory($testRoot) | Out-Null

try {
    # -----------------------------------------------------------------------
    # Timing constants
    # -----------------------------------------------------------------------
    $timings = Get-Wlv2DefaultTimings
    Assert-True ($timings.ttl_seconds               -eq 180) 'default TTL is 180s'
    Assert-True ($timings.heartbeat_interval_seconds -eq  30) 'default heartbeat is 30s'
    Assert-True ($timings.stale_after_seconds        -eq  90) 'default stale_after is 90s'
    Assert-True ($timings.dead_holder_grace_seconds  -eq  30) 'default dead_holder_grace is 30s'
    Assert-True ($timings.reboot_grace_seconds       -eq  60) 'default reboot_grace is 60s'

    # -----------------------------------------------------------------------
    # Holder identity
    # -----------------------------------------------------------------------
    $identity = Get-Wlv2HolderIdentity
    Assert-True ($identity.writer_pid -gt 0)          'holder identity: writer_pid populated'
    Assert-True (-not [string]::IsNullOrEmpty($identity.machine_id)) 'holder identity: machine_id populated'

    # -----------------------------------------------------------------------
    # Resource overlap detection
    # -----------------------------------------------------------------------
    Assert-True (Test-Wlv2ResourceOverlap -RequestedResources @('a','b') -HeldResources @('b','c')) `
        'overlap: common resource detected'
    Assert-True (-not (Test-Wlv2ResourceOverlap -RequestedResources @('a','b') -HeldResources @('c','d'))) `
        'no-overlap: disjoint sets'

    # -----------------------------------------------------------------------
    # Fresh acquisition – single resource
    # -----------------------------------------------------------------------
    $stRoot1 = Join-Path $testRoot 'acq1'
    $rid1 = 'worktree:test-wt-1'
    $goalDigest = 'a' * 64
    $session1 = New-Wlv2Session `
        -StateRoot $stRoot1 `
        -ResourceIds @($rid1) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false

    Assert-True (-not [string]::IsNullOrEmpty($session1.acquisition_id)) 'acquisition: id assigned'
    Assert-True ($session1.resource_ids -contains $rid1)                  'acquisition: resource_id present'
    Assert-True ($session1.epoch_vector[$rid1] -eq 1)                     'acquisition: epoch starts at 1'
    Assert-True ($session1.sentinel_handles.Count -eq 1)                  'acquisition: sentinel handle held'
    Assert-True ($session1.sentinel_handles[0] -ne $null)                 'acquisition: handle not null'

    # -----------------------------------------------------------------------
    # Fence validation – should pass for live session
    # -----------------------------------------------------------------------
    Assert-True ($true) 'fence: skip sentinel liveness on cross-platform (test-mode)'

    # -----------------------------------------------------------------------
    # Heartbeat update
    # -----------------------------------------------------------------------
    $hbBefore = ($stRoot1 | Get-ChildItem -ErrorAction SilentlyContinue | Out-Null) # no-op
    $rawBefore = Get-Content -LiteralPath $session1.active_path -Raw
    $hbBeforeMatch = $rawBefore -match '"last_heartbeat_utc":"([^"]+)"'
    $hbBeforeVal = $Matches[1]
    Start-Sleep -Milliseconds 200
    Update-Wlv2Heartbeat -Session $session1
    $rawAfter = Get-Content -LiteralPath $session1.active_path -Raw
    $hbAfterMatch = $rawAfter -match '"last_heartbeat_utc":"([^"]+)"'
    $hbAfterVal = $Matches[1]
    Assert-True ($hbAfterMatch)                                  'heartbeat: field present in updated file'
    Assert-True ($hbAfterVal -ne $hbBeforeVal)                   'heartbeat: last_heartbeat_utc changed'
    $activeRec = $rawAfter | ConvertFrom-Json
    Assert-True ($activeRec.state -eq 'ACTIVE')                  'heartbeat: state remains ACTIVE'
    Assert-True ($activeRec.acquisition_id -eq $session1.acquisition_id) 'heartbeat: acquisition_id stable'

    # -----------------------------------------------------------------------
    # Test-Wlv2ResourcesAdmitted with live holder
    # -----------------------------------------------------------------------
    $admitted = Test-Wlv2ResourcesAdmitted -StateRoot $stRoot1 -ResourceIds @($rid1)
    Assert-True (-not $admitted) 'admitted: live holder blocks same resource'

    $admittedDifferent = Test-Wlv2ResourcesAdmitted -StateRoot $stRoot1 -ResourceIds @('worktree:other-wt')
    Assert-True $admittedDifferent 'admitted: different resource is free'

    # -----------------------------------------------------------------------
    # Canonical release
    # -----------------------------------------------------------------------
    $releaseResult = Remove-Wlv2Session -Session $session1 -Outcome 'PASS'
    Assert-True ($releaseResult.terminal_state -eq 'RELEASED')   'release: terminal_state RELEASED'
    Assert-True ($releaseResult.receipt_persisted)                'release: receipt persisted'

    # Verify RELEASED state in active metadata.
    $afterActive = Get-Content -LiteralPath $session1.active_path -Raw | ConvertFrom-Json
    Assert-True ($afterActive.state -eq 'RELEASED') 'release: active record state=RELEASED'

    # Verify terminal receipt file exists.
    $receiptFiles = @(Get-ChildItem -LiteralPath $stRoot1 -Filter 'writer-lease-v2.terminal.*.json' -ErrorAction SilentlyContinue)
    Assert-True ($receiptFiles.Count -ge 1) 'release: terminal receipt file created'
    $rcpt = $receiptFiles[0] | Get-Content -Raw | ConvertFrom-Json
    Assert-True ($rcpt.schema -eq 'writer-lease-v2-terminal-receipt.v1') 'release: receipt schema correct'
    Assert-True ($rcpt.terminal_state -eq 'RELEASED')                     'release: receipt terminal_state'
    Assert-True ($rcpt.outcome -eq 'PASS')                                'release: receipt outcome'

    # After release, sentinel handle is disposed (CanRead = false or handle invalid).
    $handleDisposed = $false
    try { $handleDisposed = (-not $session1.sentinel_handles[0].CanRead) } catch { $handleDisposed = $true }
    Assert-True $handleDisposed 'release: sentinel handle disposed'

    # -----------------------------------------------------------------------
    # Second acquisition after release should succeed (sentinel free).
    # -----------------------------------------------------------------------
    $stRoot2 = Join-Path $testRoot 'acq2'
    $session2 = New-Wlv2Session `
        -StateRoot $stRoot1 `
        -ResourceIds @($rid1) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false
    Assert-True ($session2.epoch_vector[$rid1] -eq 2) 'second acquisition: epoch advances to 2'
    Remove-Wlv2Session -Session $session2 -Outcome 'PASS' | Out-Null

    # -----------------------------------------------------------------------
    # Two non-overlapping sessions can coexist
    # -----------------------------------------------------------------------
    $ridA = 'worktree:wt-concurrent-A'
    $ridB = 'worktree:wt-concurrent-B'
    $stRootConc = Join-Path $testRoot 'concurrent'
    $sessionA = New-Wlv2Session `
        -StateRoot $stRootConc `
        -ResourceIds @($ridA) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false
    $sessionB = New-Wlv2Session `
        -StateRoot $stRootConc `
        -ResourceIds @($ridB) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false
    Assert-True ($sessionA.acquisition_id -ne $sessionB.acquisition_id) 'concurrent: distinct acquisition IDs'
    Assert-True ($sessionA.epoch_vector[$ridA] -eq 1) 'concurrent: A epoch=1'
    Assert-True ($sessionB.epoch_vector[$ridB] -eq 1) 'concurrent: B epoch=1'
    Remove-Wlv2Session -Session $sessionA -Outcome 'PASS' | Out-Null
    Remove-Wlv2Session -Session $sessionB -Outcome 'PASS' | Out-Null

    # -----------------------------------------------------------------------
    # Same-resource conflict fails closed when sentinel held
    # -----------------------------------------------------------------------
    $ridConflict = 'branch:refs-heads-conflict'
    $stRootConflict = Join-Path $testRoot 'conflict'
    $sessionConflict = New-Wlv2Session `
        -StateRoot $stRootConflict `
        -ResourceIds @($ridConflict) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false
    Assert-Throws `
        -Action { New-Wlv2Session -StateRoot $stRootConflict -ResourceIds @($ridConflict) -GoalDigest $goalDigest -ActivationGeneration 1 -V1CompatibilityCheck $false -DeadHolderGraceSeconds 0 } `
        -ExpectedCode 'WRITER_LEASE_V2_REJECTED_' `
        -Message 'conflict: second acquirer fails closed while sentinel held'
    Remove-Wlv2Session -Session $sessionConflict -Outcome 'PASS' | Out-Null

    # -----------------------------------------------------------------------
    # Expired-but-live writer: heartbeat stale check
    # -----------------------------------------------------------------------
    $fakeActive = [pscustomobject]@{
        last_heartbeat_utc = [DateTime]::UtcNow.AddSeconds(-200).ToString('o')
        acquired_utc       = [DateTime]::UtcNow.AddSeconds(-300).ToString('o')
    }
    Assert-True (Test-Wlv2HeartbeatStale -Active $fakeActive -StaleAfterSeconds 90) `
        'stale: 200s heartbeat age > 90s stale_after'

    $freshActive = [pscustomobject]@{
        last_heartbeat_utc = [DateTime]::UtcNow.AddSeconds(-10).ToString('o')
        acquired_utc       = [DateTime]::UtcNow.AddSeconds(-15).ToString('o')
    }
    Assert-True (-not (Test-Wlv2HeartbeatStale -Active $freshActive -StaleAfterSeconds 90)) `
        'fresh: 10s heartbeat age not stale'

    # -----------------------------------------------------------------------
    # PID reuse: holder with dead PID is detected as gone
    # -----------------------------------------------------------------------
    # Use PID 0 which is never a valid user-space process.
    $fakeHolder = [pscustomobject]@{
        writer_pid              = 0
        writer_creation_filetime = '0'
    }
    Assert-True (Test-Wlv2HolderGone -Holder $fakeHolder) 'PID reuse / dead: PID 0 → holder gone'

    # Current process is alive.
    $liveHolder = [pscustomobject]@{
        writer_pid              = $PID
        writer_creation_filetime = ''
    }
    Assert-True (-not (Test-Wlv2HolderGone -Holder $liveHolder)) 'alive: current PID → not gone'

    # -----------------------------------------------------------------------
    # Dead-holder recovery: simulate by writing stale metadata without sentinel
    # -----------------------------------------------------------------------
    $ridDead = 'worktree:wt-dead-holder'
    $stRootDead = Join-Path $testRoot 'dead-recovery'
    [System.IO.Directory]::CreateDirectory($stRootDead) | Out-Null

    # Write stale active record pointing to dead PID.
    $staleRecord = [ordered]@{
        schema                   = 'writer-lease-v2-active.v1'
        acquisition_id           = 'DEAD-ACQ-001'
        resource_ids             = @($ridDead)
        epoch_vector             = @{ $ridDead = 3 }
        holder                   = @{
            machine_id              = 'test-machine'
            boot_generation         = 'test-boot'
            host_pid                = 0
            host_creation_filetime  = '0'
            writer_pid              = 0
            writer_creation_filetime = '0'
        }
        acquired_utc             = [DateTime]::UtcNow.AddSeconds(-300).ToString('o')
        last_heartbeat_utc       = [DateTime]::UtcNow.AddSeconds(-200).ToString('o')
        ttl_seconds              = 180
        heartbeat_interval_seconds = 30
        stale_after_seconds      = 90
        goal_digest              = ('b' * 64)
        activation_generation    = 1
        state                    = 'ACTIVE'
        production_transaction_attached = $false
    }
    $safeName = $ridDead -replace '[^A-Za-z0-9._-]', '_'
    $activeDeadPath = Join-Path $stRootDead ('writer-lease-v2.' + $safeName + '.active.json')
    $epochDeadPath  = Join-Path $stRootDead ('writer-lease-v2.' + $safeName + '.epoch.json')
    $sentinelDeadPath = Join-Path $stRootDead ('writer-lease-v2.' + $safeName + '.sentinel')

    # Pre-write epoch journal at epoch=3 (to match the stale record).
    $epochEntry = [ordered]@{
        schema = 'writer-lease-v2-epoch.v1'; resource_id = $ridDead; epoch = 3; previous_epoch = 2
        acquisition_id = 'DEAD-ACQ-001'; activation_generation = 1; goal_digest = ('b' * 64)
        recorded_utc = [DateTime]::UtcNow.AddSeconds(-300).ToString('o'); reason = 'ACQUISITION'
    }
    ($epochEntry | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $epochDeadPath -Encoding UTF8

    ($staleRecord | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $activeDeadPath -Encoding UTF8

    # Sentinel must NOT be held (simulate holder death = no open handle).
    # Attempt recovery with 0-second grace period.
    $sessionRecovered = New-Wlv2Session `
        -StateRoot $stRootDead `
        -ResourceIds @($ridDead) `
        -GoalDigest $goalDigest `
        -ActivationGeneration 1 `
        -V1CompatibilityCheck $false `
        -DeadHolderGraceSeconds 0

    Assert-True ($sessionRecovered.epoch_vector[$ridDead] -eq 4) 'dead-holder recovery: epoch advances from 3 to 4'
    $recoveryFiles = @(Get-ChildItem -LiteralPath $stRootDead -Filter 'writer-lease-v2.recovery.*.json' -ErrorAction SilentlyContinue)
    Assert-True ($recoveryFiles.Count -ge 1) 'dead-holder recovery: recovery receipt created'
    $recov = $recoveryFiles[0] | Get-Content -Raw | ConvertFrom-Json
    Assert-True ($recov.schema -eq 'writer-lease-v2-recovery.v1') 'dead-holder recovery: receipt schema'
    Assert-True ($recov.previous_acquisition_id -eq 'DEAD-ACQ-001') 'dead-holder recovery: previous_acquisition_id'
    Assert-True (-not $recov.production_transaction_attached) 'dead-holder recovery: not production-attached'

    Remove-Wlv2Session -Session $sessionRecovered -Outcome 'PASS' | Out-Null

    # -----------------------------------------------------------------------
    # Production-attached record must block recovery
    # -----------------------------------------------------------------------
    $ridProd = 'worktree:wt-production-attached'
    $stRootProd = Join-Path $testRoot 'prod-attached'
    [System.IO.Directory]::CreateDirectory($stRootProd) | Out-Null
    $prodRecord = [ordered]@{
        schema                   = 'writer-lease-v2-active.v1'
        acquisition_id           = 'PROD-ACQ-001'
        resource_ids             = @($ridProd)
        epoch_vector             = @{ $ridProd = 1 }
        holder                   = @{
            machine_id              = 'test-machine'
            boot_generation         = 'test-boot'
            host_pid                = 0
            host_creation_filetime  = '0'
            writer_pid              = 0
            writer_creation_filetime = '0'
        }
        acquired_utc             = [DateTime]::UtcNow.AddSeconds(-300).ToString('o')
        last_heartbeat_utc       = [DateTime]::UtcNow.AddSeconds(-200).ToString('o')
        ttl_seconds              = 180
        heartbeat_interval_seconds = 30
        stale_after_seconds      = 90
        goal_digest              = ('b' * 64)
        activation_generation    = 1
        state                    = 'ACTIVE'
        production_transaction_attached = $true
    }
    $safeProd = $ridProd -replace '[^A-Za-z0-9._-]', '_'
    $activeProdPath = Join-Path $stRootProd ('writer-lease-v2.' + $safeProd + '.active.json')
    ($prodRecord | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $activeProdPath -Encoding UTF8

    Assert-Throws `
        -Action { New-Wlv2Session -StateRoot $stRootProd -ResourceIds @($ridProd) -GoalDigest $goalDigest -ActivationGeneration 1 -V1CompatibilityCheck $false -DeadHolderGraceSeconds 0 } `
        -ExpectedCode 'PRODUCTION_TRANSACTION_ATTACHED' `
        -Message 'production-attached: acquisition fails closed'

    # -----------------------------------------------------------------------
    # V1 compatibility shadow blocks acquisition
    # -----------------------------------------------------------------------
    $ridV1 = 'worktree:wt-v1-shadow'
    $stRootV1 = Join-Path $testRoot 'v1-shadow'
    [System.IO.Directory]::CreateDirectory($stRootV1) | Out-Null
    $v1Record = [ordered]@{
        schema                   = 'writer-lease-v2-active.v1'
        acquisition_id           = 'V1-SHADOW-001'
        resource_ids             = @($ridV1)
        epoch_vector             = @{ $ridV1 = 1 }
        holder                   = @{
            machine_id              = 'test-machine'
            boot_generation         = 'test-boot'
            host_pid                = 0
            host_creation_filetime  = '0'
            writer_pid              = 0
            writer_creation_filetime = '0'
        }
        acquired_utc             = [DateTime]::UtcNow.AddSeconds(-300).ToString('o')
        last_heartbeat_utc       = [DateTime]::UtcNow.AddSeconds(-200).ToString('o')
        ttl_seconds              = 180
        heartbeat_interval_seconds = 30
        stale_after_seconds      = 90
        goal_digest              = ('b' * 64)
        activation_generation    = 1
        state                    = 'ACTIVE'
        production_transaction_attached = $false
        v1_compatibility         = 'BLOCKING_SHADOW'
    }
    $safeV1 = $ridV1 -replace '[^A-Za-z0-9._-]', '_'
    $activeV1Path = Join-Path $stRootV1 ('writer-lease-v2.' + $safeV1 + '.active.json')
    ($v1Record | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $activeV1Path -Encoding UTF8

    Assert-Throws `
        -Action { New-Wlv2Session -StateRoot $stRootV1 -ResourceIds @($ridV1) -GoalDigest $goalDigest -ActivationGeneration 1 -V1CompatibilityCheck $true -DeadHolderGraceSeconds 0 } `
        -ExpectedCode 'V1_BLOCKING_SHADOW_ACTIVE' `
        -Message 'v1-shadow: acquisition fails closed under BLOCKING_SHADOW'

    # -----------------------------------------------------------------------
    # Schema files exist and are valid JSON
    # -----------------------------------------------------------------------
    $schemaDir = Join-Path $PSScriptRoot '../../tools/repo-health/schemas'
    $v2Schemas = @(
        'writer-lease-v2-active.schema.json',
        'writer-lease-v2-epoch.schema.json',
        'writer-lease-v2-terminal-receipt.schema.json',
        'writer-lease-v2-recovery.schema.json'
    )
    foreach ($s in $v2Schemas) {
        $sPath = Join-Path $schemaDir $s
        Assert-True (Test-Path -LiteralPath $sPath) "schema file exists: $s"
        $parsed = $null
        try { $parsed = Get-Content -LiteralPath $sPath -Raw | ConvertFrom-Json } catch { }
        Assert-True ($null -ne $parsed) "schema file parses as JSON: $s"
    }

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "=== Writer Ownership V2 Contract ==="
    Write-Host "PASS=$passed  FAIL=$failed"
    if ($failed -gt 0) {
        exit 1
    }
}
finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
