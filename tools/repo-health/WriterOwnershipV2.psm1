Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Writer Lease v2 – per-overlap resource ownership
#
# Architecture:
#   - Every distinct resource (worktree path, branch ref, coordination key,
#     production transaction domain) has a monotonically increasing epoch and
#     an acquisition ID.
#   - Ordinary development sessions own only the overlapping admitted resources
#     they declare; they do NOT hold a global product-writer exclusion.
#   - Two sessions whose resource sets do not overlap proceed concurrently.
#   - Same worktree or same branch conflicts fail closed.
#   - The sentinel handle is the live locking primitive; durable JSON is audit
#     metadata, not the sole lock.
#   - Dead-holder recovery is internal to acquisition; there is no public
#     Reclaim / ForceAcquire / DeleteLock path.
#   - V1_COMPATIBILITY=BLOCKING_SHADOW: active or unsettled v1 sessions block
#     v2 acquisition until a canonical v1 terminal record exists.
#   - Production transaction domains remain separately serialized and are
#     never ordinary-development.
#
# Timing constants (from audit JERRY-WRITER-LEASE-V2-ARCHITECTURE-AUDIT-001):
#   TTL                 = 180 s
#   HEARTBEAT_INTERVAL  =  30 s
#   STALE_AFTER         =  90 s
#   DEAD_HOLDER_GRACE   =  30 s
#   REBOOT_GRACE        =  60 s
# ---------------------------------------------------------------------------

$script:Wlv2DefaultTtl               = 180
$script:Wlv2DefaultHeartbeat         =  30
$script:Wlv2DefaultStaleAfter        =  90
$script:Wlv2DefaultDeadHolderGrace   =  30
$script:Wlv2DefaultRebootGrace       =  60
$script:Wlv2Schema                   = 'writer-lease-v2-active.v1'
$script:Wlv2EpochSchema              = 'writer-lease-v2-epoch.v1'
$script:Wlv2TerminalReceiptSchema    = 'writer-lease-v2-terminal-receipt.v1'
$script:Wlv2RecoverySchema           = 'writer-lease-v2-recovery.v1'

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function Throw-Wlv2Rejected {
    param([Parameter(Mandatory)][string]$Code)
    throw ('WRITER_LEASE_V2_REJECTED_' + $Code)
}

function Get-Wlv2BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return -join ($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Get-Wlv2TextSha256 {
    param([Parameter(Mandatory)][string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    return Get-Wlv2BytesSha256 -Bytes $bytes
}

function ConvertTo-Wlv2Json {
    param([Parameter(Mandatory)][object]$Value)
    return ($Value | ConvertTo-Json -Depth 32 -Compress)
}

function Assert-Wlv2SafeId {
    param([Parameter(Mandatory)][string]$Value, [Parameter(Mandatory)][string]$Field)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,191}$') {
        Throw-Wlv2Rejected ('MALFORMED_' + $Field.ToUpperInvariant())
    }
}

function Assert-Wlv2ResourceId {
    param([Parameter(Mandatory)][string]$Value)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._:/-]{0,255}$') {
        Throw-Wlv2Rejected 'MALFORMED_RESOURCE_ID'
    }
}

function Get-Wlv2NowUtc { return [DateTime]::UtcNow.ToString('o') }

function Get-Wlv2NewGuid { return [guid]::NewGuid().ToString('N') }

function Write-Wlv2JsonAtomic {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$Value
    )
    $parent = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    $tmp = Join-Path $parent ('.' + [System.IO.Path]::GetFileName($Path) + '.' + (Get-Wlv2NewGuid) + '.tmp')
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8.GetBytes((ConvertTo-Wlv2Json -Value $Value))
    $stream = New-Object System.IO.FileStream($tmp, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::WriteThrough)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
    if (Test-Path -LiteralPath $Path) {
        $bak = Join-Path $parent ('.' + [System.IO.Path]::GetFileName($Path) + '.previous.bak')
        [System.IO.File]::Replace($tmp, $Path, $bak)
    }
    else {
        [System.IO.File]::Move($tmp, $Path)
    }
    return $Path
}

function Read-Wlv2JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json
    $digest = Get-Wlv2TextSha256 -Text $raw
    return [pscustomobject]@{ data = $obj; raw = $raw; digest = $digest }
}

function Get-Wlv2ActivePath {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$ResourceKey)
    $safe = $ResourceKey -replace '[^A-Za-z0-9._-]', '_'
    return Join-Path $StateRoot ('writer-lease-v2.' + $safe + '.active.json')
}

function Get-Wlv2SentinelPath {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$ResourceKey)
    $safe = $ResourceKey -replace '[^A-Za-z0-9._-]', '_'
    return Join-Path $StateRoot ('writer-lease-v2.' + $safe + '.sentinel')
}

function Get-Wlv2EpochPath {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$ResourceKey)
    $safe = $ResourceKey -replace '[^A-Za-z0-9._-]', '_'
    return Join-Path $StateRoot ('writer-lease-v2.' + $safe + '.epoch.json')
}

function Get-Wlv2TerminalReceiptPath {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$AcquisitionId)
    $safe = $AcquisitionId -replace '[^A-Za-z0-9._-]', '_'
    return Join-Path $StateRoot ('writer-lease-v2.terminal.' + $safe + '.json')
}

function Get-Wlv2RecoveryReceiptPath {
    param([Parameter(Mandatory)][string]$StateRoot, [Parameter(Mandatory)][string]$RecoveryId)
    $safe = $RecoveryId -replace '[^A-Za-z0-9._-]', '_'
    return Join-Path $StateRoot ('writer-lease-v2.recovery.' + $safe + '.json')
}

# ---------------------------------------------------------------------------
# Sentinel handle management (Windows: exclusive file open = OS-level lock)
# On non-Windows, emulate with a file-stream lock for test portability.
# ---------------------------------------------------------------------------

function Open-Wlv2Sentinel {
    param([Parameter(Mandatory)][string]$Path)
    $parent = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    # Provision sentinel file if absent (permanent, never deleted).
    if (-not (Test-Path -LiteralPath $Path)) {
        try {
            $provStream = New-Object System.IO.FileStream(
                $Path,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
            $provStream.Dispose()
        }
        catch [System.IO.IOException] { <# lost provisioning race – file now exists #> }
    }
    # Try to open with exclusive share – this is the live lock.
    try {
        $handle = New-Object System.IO.FileStream(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None)
        return $handle
    }
    catch [System.IO.IOException] {
        return $null
    }
}

function Close-Wlv2Sentinel {
    param([Parameter(Mandatory)][System.IO.FileStream]$Handle)
    try { $Handle.Dispose() } catch { }
}

# ---------------------------------------------------------------------------
# Holder identity
# ---------------------------------------------------------------------------

function Get-Wlv2HolderIdentity {
    [CmdletBinding()]
    param()
    $pid = $PID
    $creationFiletime = ''
    $machineId = ''
    $bootGen = ''
    $hostPid = $pid
    $hostCft = ''
    try {
        if ($IsWindows -or $env:OS -eq 'Windows_NT') {
            $proc = [System.Diagnostics.Process]::GetCurrentProcess()
            $creationFiletime = $proc.StartTime.ToFileTimeUtc().ToString()
            $hostPid = $proc.Id
            $hostCft = $creationFiletime
            # Machine ID: use MachineGuid from registry if available.
            $regKey = 'HKLM:\SOFTWARE\Microsoft\Cryptography'
            if (Test-Path $regKey) {
                $machineId = (Get-ItemProperty -Path $regKey -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid
            }
            # Boot generation: use last boot UTC.
            try {
                $wmiOS = [System.Management.ManagementObject][WMI]'\\.\root\cimv2:Win32_OperatingSystem=@'
                $bootGen = (Get-Date -Format 'o' $wmiOS.LastBootUpTime)
            }
            catch { }
        }
    }
    catch { }
    if (-not $machineId) { $machineId = [System.Net.Dns]::GetHostName() }
    if (-not $bootGen) {
        try { $bootGen = ([System.Diagnostics.Process]::GetProcessById(1).StartTime.ToFileTimeUtc().ToString()) } catch { $bootGen = 'unknown' }
    }
    return [pscustomobject]@{
        machine_id              = $machineId
        boot_generation         = $bootGen
        host_pid                = [int]$hostPid
        host_creation_filetime  = $hostCft
        writer_pid              = [int]$pid
        writer_creation_filetime = $creationFiletime
    }
}

# ---------------------------------------------------------------------------
# Liveness probe – prove a holder is gone before recovery
# ---------------------------------------------------------------------------

function Test-Wlv2HolderGone {
    param([Parameter(Mandatory)][object]$Holder)
    $writerPid = [int]$Holder.writer_pid
    $cft = [string]$Holder.writer_creation_filetime
    if ($writerPid -le 0) { return $true }
    try {
        $proc = [System.Diagnostics.Process]::GetProcessById($writerPid)
        if ($cft) {
            # PID exists; verify creation time to guard against PID reuse.
            try {
                $procCft = $proc.StartTime.ToFileTimeUtc().ToString()
                return ($procCft -ne $cft)
            }
            catch { return $false }
        }
        # No creation-time available (non-Windows); PID is alive.
        return $false
    }
    catch [System.ArgumentException] { return $true }
    catch { return $true }
}

function Test-Wlv2HeartbeatStale {
    param(
        [Parameter(Mandatory)][object]$Active,
        [int]$StaleAfterSeconds = $script:Wlv2DefaultStaleAfter
    )
    $hb = [string]$Active.last_heartbeat_utc
    if (-not $hb) { $hb = [string]$Active.acquired_utc }
    $parsed = [DateTimeOffset]::MinValue
    $parseOk = [DateTimeOffset]::TryParseExact($hb, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed)
    if (-not $parseOk) {
        $parseOk = [DateTimeOffset]::TryParse($hb, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)
    }
    if (-not $parseOk) { return $true }
    return ([DateTimeOffset]::UtcNow - $parsed).TotalSeconds -gt $StaleAfterSeconds
}

# ---------------------------------------------------------------------------
# Resource overlap detection
# ---------------------------------------------------------------------------

function Test-Wlv2ResourceOverlap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$RequestedResources,
        [Parameter(Mandatory)][string[]]$HeldResources
    )
    foreach ($r in $RequestedResources) {
        if ($HeldResources -contains $r) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Epoch management
# ---------------------------------------------------------------------------

function Get-Wlv2CurrentEpoch {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$ResourceId
    )
    $path = Get-Wlv2EpochPath -StateRoot $StateRoot -ResourceKey $ResourceId
    $rec = Read-Wlv2JsonFile -Path $path
    if ($null -eq $rec) { return 0 }
    return [int]$rec.data.epoch
}

function Write-Wlv2EpochEntry {
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter(Mandatory)][int]$Epoch,
        [Parameter(Mandatory)][string]$AcquisitionId,
        [Parameter(Mandatory)][int]$ActivationGeneration,
        [Parameter(Mandatory)][string]$GoalDigest,
        [Parameter(Mandatory)][string]$Reason
    )
    $prev = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $ResourceId
    $entry = [ordered]@{
        schema               = $script:Wlv2EpochSchema
        resource_id          = $ResourceId
        epoch                = $Epoch
        previous_epoch       = $prev
        acquisition_id       = $AcquisitionId
        activation_generation = $ActivationGeneration
        goal_digest          = $GoalDigest
        recorded_utc         = (Get-Wlv2NowUtc)
        reason               = $Reason
    }
    $path = Get-Wlv2EpochPath -StateRoot $StateRoot -ResourceKey $ResourceId
    Write-Wlv2JsonAtomic -Path $path -Value $entry | Out-Null
    return $Epoch
}

# ---------------------------------------------------------------------------
# Fencing check – called before every governed mutation
# ---------------------------------------------------------------------------

function Assert-Wlv2FenceValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string]$AcquisitionId,
        [Parameter(Mandatory)][hashtable]$ExpectedEpochVector,
        [Parameter(Mandatory)][System.IO.FileStream[]]$SentinelHandles
    )
    # 1. All sentinel handles must still be open (not disposed/invalid).
    foreach ($h in $SentinelHandles) {
        if ($null -eq $h -or -not $h.CanRead) {
            Throw-Wlv2Rejected 'STALE_WRITER_SENTINEL_LOST'
        }
    }
    # 2. Each resource epoch must match the expected epoch exactly.
    foreach ($resourceId in $ExpectedEpochVector.Keys) {
        $live = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $resourceId
        if ($live -ne $ExpectedEpochVector[$resourceId]) {
            Throw-Wlv2Rejected 'STALE_WRITER_EPOCH'
        }
    }
    # 3. Active metadata acquisition_id must match.
    $primaryResourceId = @($ExpectedEpochVector.Keys)[0]
    $activePath = Get-Wlv2ActivePath -StateRoot $StateRoot -ResourceKey $primaryResourceId
    $rec = Read-Wlv2JsonFile -Path $activePath
    if ($null -eq $rec -or $rec.data.acquisition_id -ne $AcquisitionId) {
        Throw-Wlv2Rejected 'STALE_WRITER_EPOCH'
    }
}

# ---------------------------------------------------------------------------
# Acquisition
# ---------------------------------------------------------------------------

function Invoke-Wlv2Acquire {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string[]]$ResourceIds,
        [Parameter(Mandatory)][string]$GoalDigest,
        [Parameter(Mandatory)][int]$ActivationGeneration,
        [int]$TtlSeconds              = $script:Wlv2DefaultTtl,
        [int]$HeartbeatIntervalSeconds = $script:Wlv2DefaultHeartbeat,
        [int]$StaleAfterSeconds        = $script:Wlv2DefaultStaleAfter,
        [int]$DeadHolderGraceSeconds   = $script:Wlv2DefaultDeadHolderGrace,
        [bool]$V1CompatibilityCheck    = $true
    )

    foreach ($rid in $ResourceIds) { Assert-Wlv2ResourceId -Value $rid }

    $acquisitionId  = 'WLV2-' + (Get-Wlv2NowUtc).Replace(':', '-').Replace('.', '-') + '-' + (Get-Wlv2NewGuid)
    $identity       = Get-Wlv2HolderIdentity
    $sentinelHandles = [System.Collections.Generic.List[System.IO.FileStream]]::new()
    $epochVector    = @{}
    $errors         = [System.Collections.Generic.List[string]]::new()

    [System.IO.Directory]::CreateDirectory($StateRoot) | Out-Null

    try {
        foreach ($rid in $ResourceIds) {
            $sentinelPath = Get-Wlv2SentinelPath -StateRoot $StateRoot -ResourceKey $rid
            $activePath   = Get-Wlv2ActivePath   -StateRoot $StateRoot -ResourceKey $rid
            $handle = Open-Wlv2Sentinel -Path $sentinelPath

            if ($null -ne $handle) {
                # We obtained the exclusive sentinel handle – previous holder (if any) is gone.
                # Check for existing non-terminal active metadata from a previous holder and
                # write a recovery receipt if needed.
                $prevRec = Read-Wlv2JsonFile -Path $activePath
                if ($null -ne $prevRec -and $prevRec.data.schema -eq $script:Wlv2Schema) {
                    $prevActive = $prevRec.data
                    if ([string]$prevActive.state -ne 'RELEASED' -and $prevActive.acquisition_id) {
                        # Check V1 compatibility shadow.
                        if ($V1CompatibilityCheck -and $prevActive.v1_compatibility -eq 'BLOCKING_SHADOW') {
                            $handle.Dispose()
                            Throw-Wlv2Rejected 'V1_BLOCKING_SHADOW_ACTIVE'
                        }
                        # Production-attached: fail closed.
                        if ($prevActive.production_transaction_attached) {
                            $handle.Dispose()
                            Throw-Wlv2Rejected 'PRODUCTION_TRANSACTION_ATTACHED'
                        }
                        # Previous holder is gone (we hold sentinel). Record dead-holder recovery.
                        $prevEpoch  = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $rid
                        $newEpoch   = $prevEpoch + 1
                        $recoveryId = 'WLV2-REC-' + (Get-Wlv2NewGuid)
                        $recoveryReceipt = [ordered]@{
                            schema                          = $script:Wlv2RecoverySchema
                            recovery_id                     = $recoveryId
                            new_acquisition_id              = $acquisitionId
                            resource_ids                    = @($rid)
                            previous_acquisition_id         = [string]$prevActive.acquisition_id
                            previous_metadata_digest        = $prevRec.digest
                            new_epoch_vector                = @{ $rid = $newEpoch }
                            recovery_class                  = 'DEAD_HOLDER_STALE_HEARTBEAT'
                            recovered_utc                   = (Get-Wlv2NowUtc)
                            dead_holder_grace_held_seconds  = 0
                            production_transaction_attached = $false
                        }
                        $recoveryPath = Get-Wlv2RecoveryReceiptPath -StateRoot $StateRoot -RecoveryId $recoveryId
                        Write-Wlv2JsonAtomic -Path $recoveryPath -Value $recoveryReceipt | Out-Null
                        $epochVector[$rid] = $newEpoch
                    }
                    else {
                        # Previous record is RELEASED or has no acquisition_id – fresh acquisition.
                        $prevEpoch = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $rid
                        $epochVector[$rid] = $prevEpoch + 1
                    }
                }
                else {
                    # No previous metadata – truly fresh acquisition.
                    $prevEpoch = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $rid
                    $epochVector[$rid] = $prevEpoch + 1
                }
            }
            else {
                # Sentinel is held by another live process.
                # Check metadata for V1 shadow / production-attached / liveness.
                $rec = Read-Wlv2JsonFile -Path $activePath
                if ($null -ne $rec -and $rec.data.schema -eq $script:Wlv2Schema) {
                    $active = $rec.data
                    if ($V1CompatibilityCheck -and $active.v1_compatibility -eq 'BLOCKING_SHADOW') {
                        Throw-Wlv2Rejected 'V1_BLOCKING_SHADOW_ACTIVE'
                    }
                    if ($active.production_transaction_attached) {
                        Throw-Wlv2Rejected 'PRODUCTION_TRANSACTION_ATTACHED'
                    }
                    # Is holder gone AND heartbeat stale?
                    $holderGone     = Test-Wlv2HolderGone     -Holder $active.holder
                    $heartbeatStale = Test-Wlv2HeartbeatStale -Active $active -StaleAfterSeconds $StaleAfterSeconds
                    if (-not $holderGone -or -not $heartbeatStale) {
                        Throw-Wlv2Rejected 'LIVE_OR_FRESH_HOLDER_BLOCKING'
                    }
                    # Holder is gone and heartbeat is stale; hold grace period then re-check.
                    Start-Sleep -Seconds $DeadHolderGraceSeconds
                    $rec2 = Read-Wlv2JsonFile -Path $activePath
                    if ($null -eq $rec2 -or $rec2.digest -ne $rec.digest) {
                        Throw-Wlv2Rejected 'METADATA_DRIFTED_DURING_RECOVERY'
                    }
                    # Try sentinel again after grace.
                    $handle = Open-Wlv2Sentinel -Path $sentinelPath
                    if ($null -eq $handle) {
                        Throw-Wlv2Rejected 'SENTINEL_STILL_HELD_AFTER_GRACE'
                    }
                    $prevEpoch  = Get-Wlv2CurrentEpoch -StateRoot $StateRoot -ResourceId $rid
                    $newEpoch   = $prevEpoch + 1
                    $recoveryId = 'WLV2-REC-' + (Get-Wlv2NewGuid)
                    $recoveryReceipt = [ordered]@{
                        schema                          = $script:Wlv2RecoverySchema
                        recovery_id                     = $recoveryId
                        new_acquisition_id              = $acquisitionId
                        resource_ids                    = @($rid)
                        previous_acquisition_id         = [string]$active.acquisition_id
                        previous_metadata_digest        = $rec.digest
                        new_epoch_vector                = @{ $rid = $newEpoch }
                        recovery_class                  = 'DEAD_HOLDER_STALE_HEARTBEAT'
                        recovered_utc                   = (Get-Wlv2NowUtc)
                        dead_holder_grace_held_seconds  = $DeadHolderGraceSeconds
                        production_transaction_attached = $false
                    }
                    $recoveryPath = Get-Wlv2RecoveryReceiptPath -StateRoot $StateRoot -RecoveryId $recoveryId
                    Write-Wlv2JsonAtomic -Path $recoveryPath -Value $recoveryReceipt | Out-Null
                    $epochVector[$rid] = $newEpoch
                }
                else {
                    Throw-Wlv2Rejected ('SENTINEL_HELD_NO_METADATA_RESOURCE_' + $rid)
                }
            }
            $sentinelHandles.Add($handle) | Out-Null
        }

        # Write epoch journal entries.
        foreach ($rid in $ResourceIds) {
            Write-Wlv2EpochEntry `
                -StateRoot $StateRoot `
                -ResourceId $rid `
                -Epoch $epochVector[$rid] `
                -AcquisitionId $acquisitionId `
                -ActivationGeneration $ActivationGeneration `
                -GoalDigest $GoalDigest `
                -Reason 'ACQUISITION' | Out-Null
        }

        # Write active metadata.
        $activeRecord = [ordered]@{
            schema                       = $script:Wlv2Schema
            acquisition_id               = $acquisitionId
            resource_ids                 = @($ResourceIds)
            epoch_vector                 = $epochVector
            holder                       = $identity
            acquired_utc                 = (Get-Wlv2NowUtc)
            last_heartbeat_utc           = (Get-Wlv2NowUtc)
            ttl_seconds                  = $TtlSeconds
            heartbeat_interval_seconds   = $HeartbeatIntervalSeconds
            stale_after_seconds          = $StaleAfterSeconds
            goal_digest                  = $GoalDigest
            activation_generation        = $ActivationGeneration
            state                        = 'ACTIVE'
            production_transaction_attached = $false
        }
        $primaryRid = $ResourceIds[0]
        $activePath = Get-Wlv2ActivePath -StateRoot $StateRoot -ResourceKey $primaryRid
        Write-Wlv2JsonAtomic -Path $activePath -Value $activeRecord | Out-Null

        return [pscustomobject]@{
            acquisition_id   = $acquisitionId
            resource_ids     = @($ResourceIds)
            epoch_vector     = $epochVector
            sentinel_handles = $sentinelHandles.ToArray()
            state_root       = $StateRoot
            active_path      = $activePath
            heartbeat_interval_seconds = $HeartbeatIntervalSeconds
        }
    }
    catch {
        foreach ($h in $sentinelHandles) { if ($h) { try { $h.Dispose() } catch {} } }
        throw
    }
}

# ---------------------------------------------------------------------------
# Heartbeat update
# ---------------------------------------------------------------------------

function Update-Wlv2Heartbeat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Session
    )
    $rec = Read-Wlv2JsonFile -Path $Session.active_path
    if ($null -eq $rec) { return }
    $active = $rec.data
    if ($active.acquisition_id -ne $Session.acquisition_id) { return }
    $active.last_heartbeat_utc = (Get-Wlv2NowUtc)
    Write-Wlv2JsonAtomic -Path $Session.active_path -Value $active | Out-Null
}

# ---------------------------------------------------------------------------
# Canonical release (outermost finally)
# ---------------------------------------------------------------------------

function Invoke-Wlv2Release {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Session,
        [string]$Outcome = ''
    )

    $stateRoot    = $Session.state_root
    $acquisitionId = $Session.acquisition_id
    $receiptPersisted = $false
    $terminalState = 'RELEASED'

    # 1. Revalidate the epoch vector.
    $currentEpochs = @{}
    foreach ($rid in $Session.resource_ids) {
        $currentEpochs[$rid] = Get-Wlv2CurrentEpoch -StateRoot $stateRoot -ResourceId $rid
    }

    # 2. Write terminal receipt.
    $receiptId = 'WLV2-RCPT-' + (Get-Wlv2NewGuid)
    $receiptRecord = [ordered]@{
        schema               = $script:Wlv2TerminalReceiptSchema
        receipt_id           = $receiptId
        acquisition_id       = $acquisitionId
        resource_ids         = @($Session.resource_ids)
        final_epoch_vector   = $currentEpochs
        terminal_state       = $terminalState
        released_utc         = (Get-Wlv2NowUtc)
        goal_digest          = ''
        activation_generation = 0
    }
    if ($Outcome) { $receiptRecord['outcome'] = $Outcome }

    # Populate from active record if available.
    $activePath = $Session.active_path
    try {
        $rec = Read-Wlv2JsonFile -Path $activePath
        if ($rec -and $rec.data.acquisition_id -eq $acquisitionId) {
            $receiptRecord['goal_digest']          = $rec.data.goal_digest
            $receiptRecord['activation_generation'] = $rec.data.activation_generation
        }
    }
    catch { $terminalState = 'RELEASE_RECEIPT_PERSIST_FAILURE' }

    try {
        $receiptPath = Get-Wlv2TerminalReceiptPath -StateRoot $stateRoot -AcquisitionId $acquisitionId
        Write-Wlv2JsonAtomic -Path $receiptPath -Value $receiptRecord | Out-Null
        $receiptPersisted = $true
    }
    catch { $terminalState = 'RELEASE_RECEIPT_PERSIST_FAILURE' }

    # 3. Publish RELEASED state in active metadata.
    try {
        $rec = Read-Wlv2JsonFile -Path $activePath
        if ($rec -and $rec.data.acquisition_id -eq $acquisitionId) {
            $active = $rec.data
            $active.state              = 'RELEASED'
            $active.last_heartbeat_utc = (Get-Wlv2NowUtc)
            Write-Wlv2JsonAtomic -Path $activePath -Value $active | Out-Null
        }
    }
    catch { }

    # 4. Advance release epoch entries.
    foreach ($rid in $Session.resource_ids) {
        try {
            Write-Wlv2EpochEntry `
                -StateRoot $stateRoot `
                -ResourceId $rid `
                -Epoch ($currentEpochs[$rid]) `
                -AcquisitionId $acquisitionId `
                -ActivationGeneration ($receiptRecord['activation_generation']) `
                -GoalDigest ($receiptRecord['goal_digest']) `
                -Reason 'RELEASE' | Out-Null
        }
        catch { }
    }

    # 5. Dispose sentinel handles – MUST occur even if receipt persistence failed.
    foreach ($h in $Session.sentinel_handles) {
        if ($h) { try { $h.Dispose() } catch {} }
    }

    return [pscustomobject]@{
        receipt_id        = $receiptId
        receipt_persisted = $receiptPersisted
        terminal_state    = $terminalState
    }
}

# ---------------------------------------------------------------------------
# New-Wlv2Session  –  public entry point
# Acquires ownership, returns a session object that MUST be passed to
# Remove-Wlv2Session in a finally block.
# ---------------------------------------------------------------------------

function New-Wlv2Session {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string[]]$ResourceIds,
        [Parameter(Mandatory)][string]$GoalDigest,
        [Parameter(Mandatory)][int]$ActivationGeneration,
        [int]$TtlSeconds               = $script:Wlv2DefaultTtl,
        [int]$HeartbeatIntervalSeconds  = $script:Wlv2DefaultHeartbeat,
        [int]$StaleAfterSeconds         = $script:Wlv2DefaultStaleAfter,
        [int]$DeadHolderGraceSeconds    = $script:Wlv2DefaultDeadHolderGrace,
        [bool]$V1CompatibilityCheck     = $true
    )

    return Invoke-Wlv2Acquire `
        -StateRoot $StateRoot `
        -ResourceIds $ResourceIds `
        -GoalDigest $GoalDigest `
        -ActivationGeneration $ActivationGeneration `
        -TtlSeconds $TtlSeconds `
        -HeartbeatIntervalSeconds $HeartbeatIntervalSeconds `
        -StaleAfterSeconds $StaleAfterSeconds `
        -DeadHolderGraceSeconds $DeadHolderGraceSeconds `
        -V1CompatibilityCheck $V1CompatibilityCheck
}

function Remove-Wlv2Session {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Session,
        [string]$Outcome = ''
    )
    return Invoke-Wlv2Release -Session $Session -Outcome $Outcome
}

# ---------------------------------------------------------------------------
# Test-Wlv2ResourcesAdmitted  –  check non-overlapping concurrent access
# Returns $true if the given resource set can be admitted (no live holder).
# ---------------------------------------------------------------------------

function Test-Wlv2ResourcesAdmitted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StateRoot,
        [Parameter(Mandatory)][string[]]$ResourceIds,
        [int]$StaleAfterSeconds = $script:Wlv2DefaultStaleAfter
    )
    foreach ($rid in $ResourceIds) {
        $activePath = Get-Wlv2ActivePath -StateRoot $StateRoot -ResourceKey $rid
        $rec = Read-Wlv2JsonFile -Path $activePath
        if ($null -eq $rec) { continue }
        $active = $rec.data
        if ($active.schema -ne $script:Wlv2Schema) { continue }
        if ($active.state -eq 'RELEASED') { continue }
        if (Test-Wlv2HolderGone -Holder $active.holder) { continue }
        if (Test-Wlv2HeartbeatStale -Active $active -StaleAfterSeconds $StaleAfterSeconds) { continue }
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# Get-Wlv2DefaultTimings  –  export canonical timing constants
# ---------------------------------------------------------------------------

function Get-Wlv2DefaultTimings {
    [CmdletBinding()]
    param()
    return [pscustomobject]@{
        ttl_seconds               = $script:Wlv2DefaultTtl
        heartbeat_interval_seconds = $script:Wlv2DefaultHeartbeat
        stale_after_seconds       = $script:Wlv2DefaultStaleAfter
        dead_holder_grace_seconds  = $script:Wlv2DefaultDeadHolderGrace
        reboot_grace_seconds       = $script:Wlv2DefaultRebootGrace
    }
}

Export-ModuleMember -Function @(
    'Assert-Wlv2FenceValid',
    'Get-Wlv2DefaultTimings',
    'Get-Wlv2HolderIdentity',
    'New-Wlv2Session',
    'Remove-Wlv2Session',
    'Test-Wlv2HeartbeatStale',
    'Test-Wlv2HolderGone',
    'Test-Wlv2ResourceOverlap',
    'Test-Wlv2ResourcesAdmitted',
    'Update-Wlv2Heartbeat'
)
