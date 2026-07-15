[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Plan','RunStep','Status','Stop','DryRun')][string]$Mode,
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
    [string]$RoutingPath = (Join-Path $HOME '.codex\profile-routing.meta.json'),
    [string]$PriorReceiptPath = 'V:\src\integration-inventory\repo-health\w1-s01-completion-checkpoint.json',
    [string]$Wave,
    [string]$Step,
    [string]$Repository,
    [string]$RepositoryPath,
    [string]$GoalPath,
    [switch]$ProductWrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'RepoHealthManifestCoordinator.psm1') -Force

function Get-Head {
    $head = (git -C (Split-Path -Parent $PSScriptRoot | Split-Path -Parent) rev-parse HEAD).Trim()
    if ($head -notmatch '^[0-9a-f]{40}$') { throw 'Unable to establish admitted governance head.' }
    return $head
}

switch ($Mode) {
    'Plan' {
        $manifestResult = Test-RepoHealthRunManifest -ManifestPath $ManifestPath
        $routingResult = Test-RepoHealthRoutingContract -RoutingPath $RoutingPath
        $receiptResult = Test-RepoHealthPriorReceipt -ReceiptPath $PriorReceiptPath
        if (-not $manifestResult.valid -or -not $routingResult.valid -or -not $receiptResult.valid) {
            [pscustomobject]@{ mode = 'Plan'; admitted = $false; manifest_reasons = $manifestResult.reasons; routing_reasons = $routingResult.reasons; prior_receipt_reasons = $receiptResult.reasons } | ConvertTo-Json -Depth 8
            exit 2
        }
        $newRepositoryDeadline = Get-RepoHealthNewRepositoryDeadline -ManifestPath $ManifestPath
        $state = New-RepoHealthManifestState -RunId $RunId -Manifest $manifestResult.manifest -AdmittedGovernanceHead (Get-Head) -NewRepositoryDeadlineUtc $newRepositoryDeadline
        Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
        [pscustomobject]@{ mode = 'Plan'; admitted = $true; run_status = $state.run_status; current_step = $state.current_step; pending_steps = $state.pending_steps } | ConvertTo-Json -Depth 8
    }
    'Status' {
        $state = Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
        if ($null -eq $state) { throw 'Manifest state is missing.' }
        [pscustomobject]@{ mode = 'Status'; run_status = $state.run_status; current_wave = $state.current_wave; current_step = $state.current_step; current_repository = $state.current_repository; active_writer = $state.active_writer; active_child_count = @($state.active_children).Count; pending_steps = $state.pending_steps; stop_requested = $state.stop_requested } | ConvertTo-Json -Depth 8
    }
    'RunStep' {
        foreach ($name in @('Wave','Step','Repository','RepositoryPath','GoalPath')) {
            if ([string]::IsNullOrWhiteSpace([string](Get-Variable -Name $name -ValueOnly))) { throw ($name + ' is required for RunStep.') }
        }
        Invoke-RepoHealthManifestStep -RunId $RunId -Wave $Wave -Step $Step -Repository $Repository -RepositoryPath $RepositoryPath -GoalPath $GoalPath -ProductWrite:$ProductWrite -InventoryRoot $InventoryRoot | ConvertTo-Json -Depth 8
    }
    'Stop' {
        $state = Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
        if ($null -eq $state) { throw 'Manifest state is missing.' }
        Request-RepoHealthManifestStop -State $state | Out-Null
        Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
        [pscustomobject]@{ mode = 'Stop'; run_status = $state.run_status; stop_requested = $state.stop_requested } | ConvertTo-Json
    }
    'DryRun' {
        $manifestResult = Test-RepoHealthRunManifest -ManifestPath $ManifestPath
        $routingResult = Test-RepoHealthRoutingContract -RoutingPath $RoutingPath
        $receiptResult = Test-RepoHealthPriorReceipt -ReceiptPath $PriorReceiptPath
        [pscustomobject]@{ mode = 'DryRun'; manifest_valid = $manifestResult.valid; routing_valid = $routingResult.valid; prior_receipt_valid = $receiptResult.valid; product_writing_session_started = $false } | ConvertTo-Json
    }
}
