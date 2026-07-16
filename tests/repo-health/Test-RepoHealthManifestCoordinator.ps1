[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../tools/repo-health/RepoHealthManifestCoordinator.psm1') -Force

$passed = 0
function Assert-True { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw $Message }; $script:passed++ }
function Assert-Fails { param([scriptblock]$Action,[string]$Message) $failed=$false;try { & $Action } catch { $failed=$true };Assert-True $failed $Message }
function New-StepRecord {
    param([object]$Goal,[string]$Dependency='')
    [ordered]@{
        goal_id=$Goal.header.goal_id;wave_id=$Goal.header.wave_id;step_id=$Goal.header.step_id;phase_id=$Goal.header.phase_id;role=$Goal.header.role
        repository_id=$Goal.header.repository_id;goal_file_path=$Goal.header.goal_file_path;goal_sha256=$Goal.header.goal_sha256
        expected_input_sha=$Goal.header.expected_input_sha;expected_output_sha_or_empty=$Goal.header.expected_output_sha_or_empty
        allowed_write_surfaces=@($Goal.header.allowed_write_surfaces);prohibited_write_surfaces=@($Goal.header.prohibited_write_surfaces)
        dependency_goal_ids=$(if($Dependency){@($Dependency)}else{@()});completion_state='pending'
    }
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('repo-health-manifest-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $repo = Join-Path $testRoot 'synthetic-repo'; New-Item -ItemType Directory -Path $repo | Out-Null
    git -C $repo init --initial-branch=main | Out-Null; git -C $repo config user.email 'repo-health-test@example.invalid'; git -C $repo config user.name 'repo-health-test'
    Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'synthetic' -NoNewline
    git -C $repo add README.md; git -C $repo commit -m 'synthetic root' | Out-Null
    git -C $repo remote add origin 'https://github.com/JerrySkywalker/synthetic-repo.git'
    $sha = (git -C $repo rev-parse HEAD).Trim()
    $goals = Join-Path $testRoot 'goals'; $runId='synthetic-run-20260716'; $goalPath=Join-Path $goals 'architect.md'
    $goal=New-RepoHealthBoundGoal -GoalId 'goal-architect' -ParentGoalId 'root-goal' -RunId $runId -WaveId W1 -StepId W1-S02 -PhaseId ARCHITECT_PLAN -Role Architect -WorkingDirectory $repo -RepositoryId synthetic-repo -RepositoryPath $repo -GithubRepository JerrySkywalker/synthetic-repo -StableBranch main -ExpectedInputSha $sha -AllowedWriteSurfaces @('none') -ProhibitedWriteSurfaces @('all-product-writes') -GoalFilePath $goalPath -Body 'Read-only architecture plan. Return a strict v3 envelope.'
    $manifest=[ordered]@{
        schema='repo-health-run-manifest.v2';run_id=$runId;execution_mode='process-isolated';execution_surface='interactive-tui';detached_runner_enabled=$false;interactive_resume_required=$true;single_product_writer=$true
        repositories=@([ordered]@{repository_id='synthetic-repo';repository_path=$repo;github_repository='JerrySkywalker/synthetic-repo';stable_branch='main'})
        steps=@(New-StepRecord $goal);required_prior_milestones=@('PRIOR_COMPLETE');initial_completed_milestones=@('PRIOR_COMPLETE')
    }
    $manifestPath=Join-Path $goals 'run-manifest.json';$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -NoNewline
    $manifestResult=Test-RepoHealthRunManifest -ManifestPath $manifestPath
    Assert-True $manifestResult.valid ('strict manifest and bound Goal validate: ' + ($manifestResult.reasons -join ','))
    $pathMismatch=$manifest | ConvertTo-Json -Depth 10 | ConvertFrom-Json;$pathMismatch.repositories[0].repository_path=$testRoot;$pathMismatchPath=Join-Path $goals 'path-mismatch.json';$pathMismatch | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $pathMismatchPath -NoNewline
    Assert-True (-not (Test-RepoHealthRunManifest -ManifestPath $pathMismatchPath).valid) 'manifest repository path mismatch rejected'
    $repositoryMismatch=$manifest | ConvertTo-Json -Depth 10 | ConvertFrom-Json;$repositoryMismatch.steps[0].repository_id='other-repository';$repositoryMismatchPath=Join-Path $goals 'repository-mismatch.json';$repositoryMismatch | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $repositoryMismatchPath -NoNewline
    Assert-True (-not (Test-RepoHealthRunManifest -ManifestPath $repositoryMismatchPath).valid) 'manifest repository id mismatch rejected'
    $badHeader=[ordered]@{};foreach($property in $goal.header.PSObject.Properties){$badHeader[$property.Name]=$property.Value};$badHeader.working_directory=$testRoot;$badGoalPath=Join-Path $goals 'working-directory-mismatch.md';((ConvertTo-Json -InputObject $badHeader -Compress -Depth 8)+"`n"+'bad goal'+"`n") | Set-Content -LiteralPath $badGoalPath -NoNewline
    Assert-Fails { Read-RepoHealthBoundGoal -GoalFilePath $badGoalPath } 'Goal working directory mismatch rejected'
    $state=Initialize-RepoHealthRun -ManifestPath $manifestPath -InventoryRoot $testRoot
    Assert-True ($state.completed_milestones -contains 'PRIOR_COMPLETE') 'prior milestone persisted for resume'
    $request=Assert-RepoHealthRunStepRequest -ManifestPath $manifestPath -RunId $runId -GoalPath $goalPath -Role Architect -InventoryRoot $testRoot
    Assert-True ($request.observed_head -eq $sha -and $request.header.working_directory -eq $repo) 'RunStep binds repository and working directory'
    Assert-Fails { Assert-RepoHealthRunStepRequest -ManifestPath $manifestPath -RunId $runId -GoalPath $goalPath -Role Implementer -InventoryRoot $testRoot } 'role-phase mismatch rejection'
    Assert-Fails { Assert-RepoHealthRunStepRequest -ManifestPath $manifestPath -RunId 'wrong-run' -GoalPath $goalPath -Role Architect -InventoryRoot $testRoot } 'manifest run mismatch rejection'

    $supervisorGoal=New-RepoHealthBoundGoal -GoalId 'goal-supervisor' -ParentGoalId 'root-goal' -RunId $runId -WaveId W1 -StepId W1-S02 -PhaseId SUPERVISOR_AUDIT -Role Supervisor -WorkingDirectory $repo -RepositoryId synthetic-repo -RepositoryPath $repo -GithubRepository JerrySkywalker/synthetic-repo -StableBranch main -ExpectedInputSha $sha -AllowedWriteSurfaces @('none') -ProhibitedWriteSurfaces @('all-writes') -GoalFilePath (Join-Path $goals 'supervisor.md') -Body 'Read-only supervisor. Return a strict v3 envelope.'
    $envelope=[pscustomobject](New-RepoHealthProcessEnvelope -GoalHeader $supervisorGoal.header -Outcome PASS -ObservedSha $sha -AuditedSha $sha -SanitizedSummary 'supervisor_audit_ready')
    Assert-True (Test-RepoHealthProcessEnvelope -Envelope $envelope).valid 'strict supervisor envelope accepts exact whitelist'
    $extra=[pscustomobject]@{};foreach($property in $envelope.PSObject.Properties){$extra | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value};$extra | Add-Member -NotePropertyName harmless_extra -NotePropertyValue 'one'
    Assert-True (-not (Test-RepoHealthProcessEnvelope -Envelope $extra).valid) 'harmless extra envelope field rejected'
    $duplicateRaw='{"schema":"repo-health-process-envelope.v3","schema":"repo-health-process-envelope.v3"}'
    Assert-True (-not (Test-RepoHealthProcessEnvelope -Envelope $envelope -RawJson $duplicateRaw).valid) 'duplicate semantic envelope field rejected'
    $envelope.git_mutation=$true
    Assert-True (-not (Test-RepoHealthProcessEnvelope -Envelope $envelope).valid) 'supervisor mutation envelope rejected'

    $implementerGoal=New-RepoHealthBoundGoal -GoalId 'goal-implementer' -ParentGoalId 'root-goal' -RunId $runId -WaveId W1 -StepId W1-S02 -PhaseId IMPLEMENT -Role Implementer -WorkingDirectory $repo -RepositoryId synthetic-repo -RepositoryPath $repo -GithubRepository JerrySkywalker/synthetic-repo -StableBranch main -ExpectedInputSha $sha -AllowedWriteSurfaces @($repo) -ProhibitedWriteSurfaces @('all-other-product-repositories') -GoalFilePath (Join-Path $goals 'implementer.md') -Body 'Implementer. Return a strict v3 envelope.'
    $implementerEnvelope=[pscustomobject](New-RepoHealthProcessEnvelope -GoalHeader $implementerGoal.header -Outcome PASS -ObservedSha $sha -SanitizedSummary 'implementer_candidate_ready' -ProductRepositoryWrite $true -GitMutation $true)
    Assert-RepoHealthPostImplementerSha -ImplementerEnvelope $implementerEnvelope -ObservedCandidateSha $sha
    Assert-True $true 'post-Implementer exact candidate SHA accepted'
    Assert-Fails { Assert-RepoHealthPostImplementerSha -ImplementerEnvelope $implementerEnvelope -ObservedCandidateSha ('b'*40) } 'post-Implementer SHA mismatch rejected'
    Assert-RepoHealthBranchStability -LocalCandidateSha $sha -RemoteCandidateSha $sha -PrHeadSha $sha -SupervisorAuditedSha $sha -ExpectedMergeHeadSha $sha -PrBaseBranch main -StableBranch main
    Assert-True $true 'audited branch stability accepted'
    Assert-Fails { Assert-RepoHealthBranchStability -LocalCandidateSha $sha -RemoteCandidateSha ('c'*40) -PrHeadSha $sha -SupervisorAuditedSha $sha -ExpectedMergeHeadSha $sha -PrBaseBranch main -StableBranch main } 'candidate movement after supervisor rejected'

    $state.completed_goal_ids=@('goal-architect');Save-RepoHealthManifestState -State $state -InventoryRoot $testRoot | Out-Null
    Assert-Fails { Assert-RepoHealthRunStepRequest -ManifestPath $manifestPath -RunId $runId -GoalPath $goalPath -Role Architect -InventoryRoot $testRoot } 'completed Goal cannot resume as a new launch'
    Assert-True ((Read-RepoHealthManifestState -RunId $runId -InventoryRoot $testRoot).completed_goal_ids -contains 'goal-architect') 'durable resume state retained'

    $stateRoot=Join-Path $testRoot 'state';$lease=Enter-RepoHealthWriterLease -Repository synthetic-repo -SessionId writerone -StateRoot $stateRoot
    try { Assert-Fails { Enter-RepoHealthWriterLease -Repository othertarget -SessionId writertwo -StateRoot $stateRoot } 'global one-writer lock exclusion' }
    finally { Exit-RepoHealthWriterLease -Lease $lease }
    Assert-Fails { Assert-RepoHealthLaunchArguments -Arguments @('--yolo') } 'yolo override rejected'
    Assert-Fails { Assert-RepoHealthLaunchArguments -Arguments @('--sandbox','danger-full-access') } 'sandbox override rejected'
    Assert-True ((Resolve-RepoHealthCodexHost).file_name.Length -gt 0) 'Codex host resolved without override'

    foreach($file in Get-ChildItem -Path (Join-Path $PSScriptRoot '../../tools/repo-health'),$PSScriptRoot -Recurse -File | Where-Object {$_.Extension -in @('.ps1','.psm1')}) {
        $tokens=$null;$errors=$null;[System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)|Out-Null;Assert-True ($errors.Count -eq 0) ('PowerShell AST '+$file.Name)
    }
    foreach($file in Get-ChildItem -Path (Join-Path $PSScriptRoot '../../tools/repo-health/schemas') -Filter '*.json') { Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null;Assert-True $true ('JSON parse '+$file.Name) }
}
finally {
    if(Test-Path -LiteralPath $testRoot){$resolved=(Resolve-Path -LiteralPath $testRoot).Path;if(-not $resolved.StartsWith([System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()),[System.StringComparison]::OrdinalIgnoreCase)){throw 'Synthetic fixture cleanup escaped temp root.'};Remove-Item -LiteralPath $resolved -Recurse -Force}
}
Write-Output ('PASS repo-health manifest tests=' + $passed)
