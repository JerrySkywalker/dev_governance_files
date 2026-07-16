[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Plan','RunStep','Status','Stop','DryRun')][string]$Mode,
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$GoalPath,
    [ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
    [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
    [string]$LogRoot = 'V:\src\codex-run-logs\repo-health',
    [string]$StateRoot = 'V:\src\integration-inventory\repo-health\state'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'RepoHealthManifestCoordinator.psm1') -Force

switch ($Mode) {
    'Plan' { Initialize-RepoHealthRun -ManifestPath $ManifestPath -InventoryRoot $InventoryRoot | ConvertTo-Json -Depth 8 }
    'RunStep' {
        if ([string]::IsNullOrWhiteSpace($GoalPath) -or [string]::IsNullOrWhiteSpace($Role)) { throw 'GoalPath and Role are required for RunStep.' }
        Invoke-RepoHealthRoleProcess -ManifestPath $ManifestPath -RunId $RunId -GoalPath $GoalPath -Role $Role -InventoryRoot $InventoryRoot -LogRoot $LogRoot -StateRoot $StateRoot | ConvertTo-Json -Depth 8
    }
    'Status' {
        $state=Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
        if($null -eq $state){throw 'Manifest state is missing.'};$state | ConvertTo-Json -Depth 8
    }
    'Stop' {
        $state=Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
        if($null -eq $state){throw 'Manifest state is missing.'};$state.stop_requested=$true;$state.run_status='SAFE_PAUSE_REQUESTED';Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null;$state | ConvertTo-Json -Depth 8
    }
    'DryRun' { $manifest=Test-RepoHealthRunManifest -ManifestPath $ManifestPath;[pscustomobject]@{mode='DryRun';manifest_valid=$manifest.valid;reasons=$manifest.reasons;product_writing_session_started=$false}|ConvertTo-Json -Depth 8 }
}
