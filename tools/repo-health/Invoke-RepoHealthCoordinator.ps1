[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Plan', 'Start', 'Resume', 'Status', 'Audit', 'DryRun')]
    [string]$Mode,
    [Parameter(Mandatory)]
    [string]$Repository,
    [string]$SessionId = 'manual-attach',
    [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state',
    [string]$GoalRoot = 'V:\src\goals\repo-health',
    [string]$LogRoot = 'V:\src\codex-run-logs\repo-health',
    [switch]$RequiresDevIntegration,
    [switch]$RequiresArchive
)

Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'RepoHealthCoordinator.psm1') -Force

function Get-OrCreateCoordinatorState {
    $state = Read-RepoHealthState -Repository $Repository -StateRoot $StateRoot
    if ($null -eq $state) {
        $state = New-RepoHealthState -Repository $Repository
        Save-RepoHealthState -State $state -StateRoot $StateRoot | Out-Null
    }
    return $state
}

switch ($Mode) {
    'Plan' {
        $state = Get-OrCreateCoordinatorState
        $implementer = Write-RepoHealthGoalQueue -Role Implementer -Repository $Repository -State $state.current_state -GoalRoot $GoalRoot
        $supervisor = Write-RepoHealthGoalQueue -Role Supervisor -Repository $Repository -State $state.current_state -GoalRoot $GoalRoot
        [pscustomobject]@{ mode = 'Plan'; automatic_session_launch_supported = $false; implementer_goal_id = (Split-Path $implementer -Leaf); supervisor_goal_id = (Split-Path $supervisor -Leaf); state = $state.current_state } | ConvertTo-Json -Depth 8
    }
    'Start' {
        $lock = Enter-RepoHealthLock -Repository $Repository -SessionId $SessionId -StateRoot $StateRoot
        try {
            $state = Get-OrCreateCoordinatorState
            Assert-RepoHealthWriterAdmission -State $state -SessionId $SessionId -Role Implementer | Out-Null
            Save-RepoHealthState -State $state -StateRoot $StateRoot | Out-Null
            $implementer = Write-RepoHealthGoalQueue -Role Implementer -Repository $Repository -State $state.current_state -GoalRoot $GoalRoot
            $supervisor = Write-RepoHealthGoalQueue -Role Supervisor -Repository $Repository -State $state.current_state -GoalRoot $GoalRoot
            [pscustomobject]@{ mode = 'Start'; automatic_session_launch_supported = $false; launch_mode = 'queue-file-manual-attach'; implementer_goal_id = (Split-Path $implementer -Leaf); supervisor_goal_id = (Split-Path $supervisor -Leaf) } | ConvertTo-Json -Depth 8
        }
        finally {
            Exit-RepoHealthLock -Lock $lock
        }
    }
    'Resume' {
        $state = Get-OrCreateCoordinatorState
        $state.current_state = Get-NextRepoHealthState -CurrentState $state.current_state -RequiresDevIntegration:$RequiresDevIntegration -RequiresArchive:$RequiresArchive
        Save-RepoHealthState -State $state -StateRoot $StateRoot | Out-Null
        New-RepoHealthSafeReport -State $state | ConvertTo-Json -Depth 8
    }
    'Status' {
        $state = Get-OrCreateCoordinatorState
        New-RepoHealthSafeReport -State $state | ConvertTo-Json -Depth 8
    }
    'Audit' {
        $state = Get-OrCreateCoordinatorState
        $schemaResult = Test-RepoHealthResultEnvelope -Envelope ([pscustomobject]@{
            schema = 'repo-health-result-envelope.v1'
            role = 'Supervisor'
            repository = $Repository
            outcome = 'PASS'
            product_repository_write = $false
            git_mutation = $false
            sanitized_summary = 'coordinator state audit'
        })
        [pscustomobject]@{ mode = 'Audit'; state_schema = $state.schema; state_valid = ($state.current_state -in (Get-RepoHealthStateNames)); envelope_contract_valid = $schemaResult.valid; automatic_session_launch_supported = $false } | ConvertTo-Json -Depth 8
    }
    'DryRun' {
        $state = New-RepoHealthState -Repository $Repository
        [pscustomobject]@{ mode = 'DryRun'; next_state = (Get-NextRepoHealthState -CurrentState $state.current_state); automatic_session_launch_supported = $false; product_writing_session_started = $false } | ConvertTo-Json -Depth 8
    }
}
