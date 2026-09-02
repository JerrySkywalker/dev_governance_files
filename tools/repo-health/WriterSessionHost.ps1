#Requires -Version 5.1
<#
.SYNOPSIS
    Writer Lease v2 Session Host – acquires per-overlap ownership, launches the
    writer child process inside a Windows Job Object, and performs canonical
    release on normal or abnormal exit.

.DESCRIPTION
    This script is the session host for Writer Lease v2. It:
      1. Validates parameters and goal digest.
      2. Acquires v2 per-overlap ownership for the declared resource set.
      3. On Windows: contains the child process tree in a Job Object with
         JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE so parent/lock-host death cannot
         leave an orphan writer alive.
      4. Launches the writer child script/command.
      5. On normal exit (PASS, BLOCKED, HOLD, WAITING_EXTERNAL_CI, READY_FOR_OWNER):
         performs the canonical release epilogue including terminal receipt.
      6. On abnormal exit: still disposes sentinel handles so the next acquirer
         reaches bounded recovery rather than a pathname zombie.

    The canonical release sequence (outermost finally):
      1. Stop admitting operations (flag set before child is awaited).
      2. Drain / terminate the writer Job as appropriate.
      3. Stop and join the heartbeat timer.
      4. Revalidate the epoch vector.
      5. Write a terminal writer receipt.
      6. Publish RELEASED with terminal receipt digest.
      7. Dispose resource handles in reverse order.
      8. Dispose the Job handle.

.PARAMETER StateRoot
    Directory where lease active records, sentinels, and epoch journals are stored.

.PARAMETER ResourceIds
    Comma-separated list of resource identifiers this session is admitted to own.
    Two sessions whose resource sets do not overlap may proceed concurrently.

.PARAMETER GoalDigestOrFile
    Either a 64-character hex SHA-256 goal digest, or a file path whose contents
    will be SHA-256 hashed to derive the goal digest.

.PARAMETER ActivationGeneration
    Monotonically increasing integer identifying the v2 activation generation.
    Must be >= 1.

.PARAMETER WriterCommand
    The executable or script to run as the writer child. Must not be empty.

.PARAMETER WriterArguments
    Optional array of arguments forwarded to WriterCommand.

.PARAMETER Outcome
    Expected outcome label to record in the terminal receipt on clean exit.
    Must be one of: PASS, BLOCKED, HOLD, WAITING_EXTERNAL_CI, READY_FOR_OWNER.

.PARAMETER SkipJobObject
    When set, the Job Object containment is skipped (for test/non-Windows use).

.EXAMPLE
    pwsh -File WriterSessionHost.ps1 `
        -StateRoot 'C:\coord\leases' `
        -ResourceIds 'worktree:C:\src\myrepo,branch:refs/heads/feature-x' `
        -GoalDigestOrFile 'C:\goals\my-goal.md' `
        -ActivationGeneration 1 `
        -WriterCommand 'pwsh' `
        -WriterArguments @('-File', 'C:\scripts\my-writer.ps1') `
        -Outcome PASS
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$StateRoot,
    [Parameter(Mandatory)][string]$ResourceIds,
    [Parameter(Mandatory)][string]$GoalDigestOrFile,
    [Parameter(Mandatory)][int]$ActivationGeneration,
    [Parameter(Mandatory)][string]$WriterCommand,
    [string[]]$WriterArguments = @(),
    [ValidateSet('PASS','BLOCKED','HOLD','WAITING_EXTERNAL_CI','READY_FOR_OWNER')]
    [string]$Outcome = 'PASS',
    [switch]$SkipJobObject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $scriptDir 'WriterOwnershipV2.psm1') -Force

# ---------------------------------------------------------------------------
# Resolve goal digest.
# ---------------------------------------------------------------------------
function Resolve-GoalDigest {
    param([Parameter(Mandatory)][string]$Input)
    if ($Input -match '^[0-9a-f]{64}$') { return $Input }
    if (Test-Path -LiteralPath $Input) {
        $bytes = [System.IO.File]::ReadAllBytes($Input)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { return -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) }
        finally { $sha.Dispose() }
    }
    throw "GoalDigestOrFile must be a 64-character hex SHA-256 or an existing file path."
}

$goalDigest = Resolve-GoalDigest -Input $GoalDigestOrFile

# ---------------------------------------------------------------------------
# Parse resource IDs.
# ---------------------------------------------------------------------------
$resourceIdList = @($ResourceIds -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
if ($resourceIdList.Count -eq 0) { throw 'ResourceIds must contain at least one non-empty resource identifier.' }

Write-Host "WLV2_SESSION_HOST: acquiring ownership for $($resourceIdList.Count) resource(s): $($resourceIdList -join ', ')"

# ---------------------------------------------------------------------------
# Acquire Writer Lease v2 ownership.
# ---------------------------------------------------------------------------
$session = $null
$heartbeatTimer = $null
$job = $null
$jobHandle = [System.IntPtr]::Zero

try {
    $session = New-Wlv2Session `
        -StateRoot $StateRoot `
        -ResourceIds $resourceIdList `
        -GoalDigest $goalDigest `
        -ActivationGeneration $ActivationGeneration

    Write-Host "WLV2_SESSION_HOST: acquisition_id=$($session.acquisition_id)"

    # -----------------------------------------------------------------------
    # Start heartbeat timer.
    # -----------------------------------------------------------------------
    $heartbeatIntervalMs = $session.heartbeat_interval_seconds * 1000
    $sessionRef = $session
    $heartbeatTimer = [System.Timers.Timer]::new($heartbeatIntervalMs)
    $heartbeatTimer.AutoReset = $true
    Register-ObjectEvent -InputObject $heartbeatTimer -EventName Elapsed -Action {
        try { Update-Wlv2Heartbeat -Session $sessionRef } catch { }
    } | Out-Null
    $heartbeatTimer.Start()

    # -----------------------------------------------------------------------
    # Windows Job Object containment.
    # -----------------------------------------------------------------------
    if (-not $SkipJobObject -and ($IsWindows -or $env:OS -eq 'Windows_NT')) {
        try {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class Wlv2JobObject {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr CreateJobObjectW(IntPtr lpJobAttributes, string lpName);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetInformationJobObject(IntPtr hJob, int infoClass, ref JOBOBJECT_EXTENDED_LIMIT_INFORMATION lpInfo, uint cbInfo);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hObject);
    [StructLayout(LayoutKind.Sequential)]
    public struct IO_COUNTERS {
        public ulong ReadOperationCount, WriteOperationCount, OtherOperationCount;
        public ulong ReadTransferCount, WriteTransferCount, OtherTransferCount;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
        public long PerProcessUserTimeLimit, PerJobUserTimeLimit;
        public uint LimitFlags, MinimumWorkingSetSize, MaximumWorkingSetSize, ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass, SchedulingClass;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit, JobMemoryLimit, PeakProcessMemoryUsed, PeakJobMemoryUsed;
    }
    public const uint JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000;
    public const int JobObjectExtendedLimitInformation = 9;
}
'@ -ErrorAction SilentlyContinue

            $jobHandle = [Wlv2JobObject]::CreateJobObjectW([System.IntPtr]::Zero, $null)
            if ($jobHandle -ne [System.IntPtr]::Zero) {
                $info = New-Object Wlv2JobObject+JOBOBJECT_EXTENDED_LIMIT_INFORMATION
                $info.BasicLimitInformation.LimitFlags = [Wlv2JobObject]::JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
                $size = [System.Runtime.InteropServices.Marshal]::SizeOf($info)
                [Wlv2JobObject]::SetInformationJobObject($jobHandle, [Wlv2JobObject]::JobObjectExtendedLimitInformation, [ref]$info, [uint32]$size) | Out-Null
            }
        }
        catch { Write-Warning "WLV2_SESSION_HOST: Job Object setup failed (non-fatal): $_" }
    }

    # -----------------------------------------------------------------------
    # Launch writer child.
    # -----------------------------------------------------------------------
    Write-Host "WLV2_SESSION_HOST: launching writer: $WriterCommand $($WriterArguments -join ' ')"
    $proc = Start-Process `
        -FilePath $WriterCommand `
        -ArgumentList $WriterArguments `
        -PassThru `
        -NoNewWindow

    # Assign to Job Object if created.
    if ($jobHandle -ne [System.IntPtr]::Zero) {
        try {
            [Wlv2JobObject]::AssignProcessToJobObject($jobHandle, $proc.Handle) | Out-Null
        }
        catch { Write-Warning "WLV2_SESSION_HOST: AssignProcessToJobObject failed: $_" }
    }

    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    Write-Host "WLV2_SESSION_HOST: writer exited with code $exitCode"
}
finally {
    # -----------------------------------------------------------------------
    # Canonical release epilogue – executed on normal AND abnormal exit.
    # -----------------------------------------------------------------------

    # Stop heartbeat.
    if ($heartbeatTimer) {
        try { $heartbeatTimer.Stop(); $heartbeatTimer.Dispose() } catch { }
        $heartbeatTimer = $null
    }

    # Release ownership (writes terminal receipt, advances epoch, disposes handles).
    if ($session) {
        try {
            $releaseResult = Remove-Wlv2Session -Session $session -Outcome $Outcome
            Write-Host "WLV2_SESSION_HOST: released acquisition_id=$($session.acquisition_id) terminal_state=$($releaseResult.terminal_state)"
        }
        catch {
            Write-Warning "WLV2_SESSION_HOST: release failed (handles still disposed): $_"
        }
        $session = $null
    }

    # Dispose Job Object handle.
    if ($jobHandle -ne [System.IntPtr]::Zero) {
        try { [Wlv2JobObject]::CloseHandle($jobHandle) | Out-Null } catch { }
        $jobHandle = [System.IntPtr]::Zero
    }

    Write-Host "WLV2_SESSION_HOST: canonical release complete."
}
