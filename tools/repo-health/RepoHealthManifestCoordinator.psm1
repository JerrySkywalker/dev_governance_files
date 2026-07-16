Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'RepoHealthCoordinator.psm1') -Force

$script:RepoHealthRoleProfiles = [ordered]@{
    Architect = 'jerry-architect'
    Implementer = 'jerry-implementer'
    Supervisor = 'jerry-supervisor'
    Auditor = 'jerry-auditor'
    Mechanical = 'jerry-mechanical'
}

$script:GoalHeaderFields = @(
    'goal_schema','goal_id','parent_goal_id','run_id','wave_id','step_id','phase_id','role',
    'working_directory','repository_id','repository_path','github_repository','stable_branch',
    'expected_input_sha','expected_output_sha_or_empty','allowed_write_surfaces',
    'prohibited_write_surfaces','goal_file_path','goal_sha256'
)

$script:EnvelopeFields = @(
    'schema','run_id','wave_id','step_id','phase_id','role','working_directory','repository_id',
    'repository_path','github_repository','stable_branch','expected_input_sha',
    'expected_output_sha_or_empty','observed_sha','audited_sha','remote_candidate_sha',
    'pr_head_sha','pr_base_branch','outcome','product_repository_write','git_mutation',
    'sanitized_summary','blocker_fingerprint','secrets_visible','private_connection_metadata_count'
)

function Get-RepoHealthRoleProfile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role)
    $script:RepoHealthRoleProfiles[$Role]
}

function Get-RepoHealthManifestPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [string]$InventoryRoot = 'V:\src\integration-inventory\repo-health',
        [string]$LogRoot = 'V:\src\codex-run-logs\repo-health'
    )
    Assert-RepoHealthSafeIdentifier -Value $RunId -Field 'run_id'
    $runRoot = Join-Path (Join-Path $InventoryRoot 'runs') $RunId
    [pscustomobject]@{
        RunRoot = $runRoot
        StatePath = Join-Path $runRoot 'manifest-state.json'
        EnvelopeRoot = Join-Path $runRoot 'envelopes'
        LogRoot = Join-Path $LogRoot $RunId
    }
}

function Get-RepoHealthTextSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
        return -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
    }
    finally { $sha.Dispose() }
}

function Test-RepoHealthExactPropertySet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Object,
        [Parameter(Mandatory)][string[]]$Expected,
        [string]$RawJson = ''
    )
    $reasons = New-Object System.Collections.Generic.List[string]
    $names = @($Object.PSObject.Properties.Name)
    foreach ($name in $Expected) { if ($names -notcontains $name) { $reasons.Add('missing_' + $name) } }
    foreach ($name in $names) { if ($Expected -notcontains $name) { $reasons.Add('unknown_' + $name) } }
    if ($names.Count -ne @($names | Select-Object -Unique).Count) { $reasons.Add('duplicate_property') }
    if (-not [string]::IsNullOrWhiteSpace($RawJson)) {
        try {
            $document = [System.Text.Json.JsonDocument]::Parse($RawJson)
            try {
                if ($document.RootElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
                    $reasons.Add('json_not_object')
                }
                else {
                    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                    foreach ($property in $document.RootElement.EnumerateObject()) {
                        if (-not $seen.Add($property.Name)) { $reasons.Add('duplicate_semantic_field') }
                    }
                }
            }
            finally { $document.Dispose() }
        }
        catch { $reasons.Add('invalid_json') }
    }
    [pscustomobject]@{ valid = ($reasons.Count -eq 0); reasons = @($reasons) }
}

function Assert-RepoHealthShaOrEmpty {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value, [Parameter(Mandatory)][string]$Field, [switch]$AllowEmpty)
    if ($AllowEmpty -and [string]::IsNullOrWhiteSpace($Value)) { return }
    if ($Value -notmatch '^[0-9a-f]{40}$') { throw ($Field + ' must be a lower-case SHA-1.') }
}

function Get-RepoHealthGoalCanonicalText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Header, [Parameter(Mandatory)][string]$Body)
    $canonical = [ordered]@{}
    foreach ($field in $script:GoalHeaderFields) {
        $canonical[$field] = if ($field -eq 'goal_sha256') { '' } else { $Header.$field }
    }
    ((ConvertTo-Json -InputObject $canonical -Compress -Depth 8) + "`n" + $Body)
}

function New-RepoHealthBoundGoal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$GoalId,
        [Parameter(Mandatory)][string]$ParentGoalId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$WaveId,
        [Parameter(Mandatory)][string]$StepId,
        [Parameter(Mandatory)][string]$PhaseId,
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$RepositoryId,
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$GithubRepository,
        [Parameter(Mandatory)][string]$StableBranch,
        [Parameter(Mandatory)][string]$ExpectedInputSha,
        [string]$ExpectedOutputShaOrEmpty = '',
        [string[]]$AllowedWriteSurfaces = @('none'),
        [string[]]$ProhibitedWriteSurfaces = @(),
        [Parameter(Mandatory)][string]$GoalFilePath,
        [Parameter(Mandatory)][string]$Body
    )
    foreach ($pair in @(@{v=$GoalId;n='goal_id'},@{v=$ParentGoalId;n='parent_goal_id'},@{v=$RunId;n='run_id'},@{v=$WaveId;n='wave_id'},@{v=$StepId;n='step_id'},@{v=$PhaseId;n='phase_id'},@{v=$RepositoryId;n='repository_id'},@{v=$StableBranch;n='stable_branch'})) {
        Assert-RepoHealthSafeIdentifier -Value ([string]$pair.v) -Field ([string]$pair.n)
    }
    Assert-RepoHealthShaOrEmpty -Value $ExpectedInputSha -Field 'expected_input_sha'
    Assert-RepoHealthShaOrEmpty -Value $ExpectedOutputShaOrEmpty -Field 'expected_output_sha_or_empty' -AllowEmpty
    if ($WorkingDirectory -ne $RepositoryPath) { throw 'Goal working_directory must equal repository_path.' }
    $header = [ordered]@{
        goal_schema = 'repo-health-goal-header.v1'; goal_id = $GoalId; parent_goal_id = $ParentGoalId
        run_id = $RunId; wave_id = $WaveId; step_id = $StepId; phase_id = $PhaseId; role = $Role
        working_directory = $WorkingDirectory; repository_id = $RepositoryId; repository_path = $RepositoryPath
        github_repository = $GithubRepository; stable_branch = $StableBranch; expected_input_sha = $ExpectedInputSha
        expected_output_sha_or_empty = $ExpectedOutputShaOrEmpty; allowed_write_surfaces = @($AllowedWriteSurfaces)
        prohibited_write_surfaces = @($ProhibitedWriteSurfaces); goal_file_path = $GoalFilePath; goal_sha256 = ''
    }
    $normalizedBody = $Body.Replace("`r`n", "`n").Replace("`r", "`n")
    if (-not $normalizedBody.EndsWith("`n")) { $normalizedBody += "`n" }
    $header.goal_sha256 = Get-RepoHealthTextSha256 -Text (Get-RepoHealthGoalCanonicalText -Header $header -Body $normalizedBody)
    $content = (ConvertTo-Json -InputObject $header -Compress -Depth 8) + "`n" + $normalizedBody
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $GoalFilePath)) | Out-Null
    [System.IO.File]::WriteAllText($GoalFilePath, $content, [System.Text.UTF8Encoding]::new($false))
    [pscustomobject]@{ header = [pscustomobject]$header; content = $content }
}

function Read-RepoHealthBoundGoal {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GoalFilePath)
    if (-not (Test-Path -LiteralPath $GoalFilePath)) { throw 'Goal file is missing.' }
    $raw = [System.IO.File]::ReadAllText($GoalFilePath, [System.Text.UTF8Encoding]::new($false)).Replace("`r`n", "`n").Replace("`r", "`n")
    $break = $raw.IndexOf("`n")
    if ($break -lt 1) { throw 'Goal header must be the first JSON line.' }
    $headerRaw = $raw.Substring(0, $break)
    try { $header = $headerRaw | ConvertFrom-Json } catch { throw 'Goal header is not JSON.' }
    $body = $raw.Substring($break + 1)
    $set = Test-RepoHealthExactPropertySet -Object $header -Expected $script:GoalHeaderFields -RawJson $headerRaw
    if (-not $set.valid) { throw ('Invalid goal header property set: ' + ($set.reasons -join ',')) }
    if ([string]$header.goal_schema -ne 'repo-health-goal-header.v1') { throw 'Unsupported goal header schema.' }
    foreach ($field in @('goal_id','parent_goal_id','run_id','wave_id','step_id','phase_id','role','repository_id','stable_branch')) {
        Assert-RepoHealthSafeIdentifier -Value ([string]$header.$field) -Field $field
    }
    if ([string]$header.role -notin $script:RepoHealthRoleProfiles.Keys) { throw 'Goal role is not authorized.' }
    if ([string]$header.working_directory -ne [string]$header.repository_path) { throw 'Goal working_directory differs from repository_path.' }
    if ([string]$header.goal_file_path -ne $GoalFilePath) { throw 'Goal path differs from its header.' }
    Assert-RepoHealthShaOrEmpty -Value ([string]$header.expected_input_sha) -Field 'expected_input_sha'
    Assert-RepoHealthShaOrEmpty -Value ([string]$header.expected_output_sha_or_empty) -Field 'expected_output_sha_or_empty' -AllowEmpty
    if (@($header.allowed_write_surfaces).Count -eq 0 -or @($header.prohibited_write_surfaces).Count -eq 0) { throw 'Goal write-surface declarations are required.' }
    $expected = Get-RepoHealthTextSha256 -Text (Get-RepoHealthGoalCanonicalText -Header $header -Body $body)
    if ($expected -ne [string]$header.goal_sha256) { throw 'Goal SHA-256 does not match canonical goal content.' }
    [pscustomobject]@{ header = $header; body = $body; content = $raw }
}

function Test-RepoHealthRunManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ManifestPath)
    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $ManifestPath)) { return [pscustomobject]@{valid=$false;manifest=$null;reasons=@('manifest_missing')} }
    $raw = Get-Content -LiteralPath $ManifestPath -Raw
    try { $manifest = $raw | ConvertFrom-Json } catch { return [pscustomobject]@{valid=$false;manifest=$null;reasons=@('manifest_invalid_json')} }
    $fields = @('schema','run_id','execution_mode','execution_surface','detached_runner_enabled','interactive_resume_required','single_product_writer','repositories','steps','required_prior_milestones','initial_completed_milestones')
    $set = Test-RepoHealthExactPropertySet -Object $manifest -Expected $fields -RawJson $raw
    foreach ($reason in $set.reasons) { $reasons.Add($reason) }
    if ($reasons.Count -eq 0) {
        if ([string]$manifest.schema -ne 'repo-health-run-manifest.v2') { $reasons.Add('schema') }
        if ([string]$manifest.execution_mode -ne 'process-isolated' -or [string]$manifest.execution_surface -ne 'interactive-tui' -or [bool]$manifest.detached_runner_enabled -or -not [bool]$manifest.interactive_resume_required -or -not [bool]$manifest.single_product_writer) { $reasons.Add('execution_contract') }
        try { Assert-RepoHealthSafeIdentifier -Value ([string]$manifest.run_id) -Field 'run_id' } catch { $reasons.Add('run_id') }
        $repositories = @($manifest.repositories)
        $steps = @($manifest.steps)
        if ($repositories.Count -eq 0 -or $steps.Count -eq 0) { $reasons.Add('empty_manifest') }
        $repoIds = @()
        foreach ($repo in $repositories) {
            $repoFields = @('repository_id','repository_path','github_repository','stable_branch')
            $repoSet = Test-RepoHealthExactPropertySet -Object $repo -Expected $repoFields
            foreach ($reason in $repoSet.reasons) { $reasons.Add('repository_' + $reason) }
            if ([string]::IsNullOrWhiteSpace([string]$repo.repository_id) -or [string]::IsNullOrWhiteSpace([string]$repo.repository_path) -or [string]::IsNullOrWhiteSpace([string]$repo.github_repository) -or [string]::IsNullOrWhiteSpace([string]$repo.stable_branch)) { $reasons.Add('repository_binding') }
            $repoIds += [string]$repo.repository_id
        }
        if ($repoIds.Count -ne @($repoIds | Select-Object -Unique).Count) { $reasons.Add('duplicate_repository_id') }
        $goalIds = @()
        foreach ($step in $steps) {
            $stepFields = @('goal_id','wave_id','step_id','phase_id','role','repository_id','goal_file_path','goal_sha256','expected_input_sha','expected_output_sha_or_empty','allowed_write_surfaces','prohibited_write_surfaces','dependency_goal_ids','completion_state')
            $stepSet = Test-RepoHealthExactPropertySet -Object $step -Expected $stepFields
            foreach ($reason in $stepSet.reasons) { $reasons.Add('step_' + $reason) }
            if ([string]$step.repository_id -notin $repoIds -or [string]$step.role -notin $script:RepoHealthRoleProfiles.Keys -or [string]$step.completion_state -ne 'pending') { $reasons.Add('step_binding') }
            $goalIds += [string]$step.goal_id
            try {
                $goal = Read-RepoHealthBoundGoal -GoalFilePath ([string]$step.goal_file_path)
                $header = $goal.header
                foreach ($field in @('goal_id','wave_id','step_id','phase_id','role','repository_id','expected_input_sha','expected_output_sha_or_empty','goal_sha256')) {
                    if ([string]$header.$field -ne [string]$step.$field) { $reasons.Add('goal_manifest_' + $field) }
                }
                if ((@($header.allowed_write_surfaces) -join "`0") -ne (@($step.allowed_write_surfaces) -join "`0")) { $reasons.Add('goal_manifest_allowed_write_surfaces') }
                if ((@($header.prohibited_write_surfaces) -join "`0") -ne (@($step.prohibited_write_surfaces) -join "`0")) { $reasons.Add('goal_manifest_prohibited_write_surfaces') }
                $repo = @($repositories | Where-Object { $_.repository_id -eq $step.repository_id })[0]
                foreach ($field in @('repository_path','github_repository','stable_branch')) { if ([string]$header.$field -ne [string]$repo.$field) { $reasons.Add('goal_repository_' + $field) } }
            }
            catch { $reasons.Add('goal_invalid') }
        }
        if ($goalIds.Count -ne @($goalIds | Select-Object -Unique).Count) { $reasons.Add('duplicate_goal_id') }
    }
    [pscustomobject]@{ valid = ($reasons.Count -eq 0); manifest = $manifest; reasons = @($reasons | Select-Object -Unique) }
}

function New-RepoHealthManifestState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RunId, [Parameter(Mandatory)][object]$Manifest)
    [pscustomobject]@{
        schema = 'repo-health-manifest-state.v2'; run_id = $RunId; run_status = 'PLANNED'; active_writer = $null
        completed_goal_ids = @(); completed_milestones = @($Manifest.initial_completed_milestones)
        stop_requested = $false; revision = 1; updated_utc = [DateTime]::UtcNow.ToString('o')
    }
}

function Read-RepoHealthManifestState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RunId,[string]$InventoryRoot='V:\src\integration-inventory\repo-health')
    Read-RepoHealthJson -Path (Get-RepoHealthManifestPaths -RunId $RunId -InventoryRoot $InventoryRoot).StatePath
}

function Save-RepoHealthManifestState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$State,[string]$InventoryRoot='V:\src\integration-inventory\repo-health')
    if ([string]$State.schema -ne 'repo-health-manifest-state.v2') { throw 'Unsupported manifest state schema.' }
    $State.revision = [int]$State.revision + 1; $State.updated_utc = [DateTime]::UtcNow.ToString('o')
    Write-RepoHealthJsonAtomic -Path (Get-RepoHealthManifestPaths -RunId ([string]$State.run_id) -InventoryRoot $InventoryRoot).StatePath -Value $State
}

function Initialize-RepoHealthRun {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ManifestPath,[string]$InventoryRoot='V:\src\integration-inventory\repo-health')
    $checked = Test-RepoHealthRunManifest -ManifestPath $ManifestPath
    if (-not $checked.valid) { throw ('Manifest is not launchable: ' + ($checked.reasons -join ',')) }
    $state = New-RepoHealthManifestState -RunId ([string]$checked.manifest.run_id) -Manifest $checked.manifest
    Save-RepoHealthManifestState -State $state -InventoryRoot $InventoryRoot | Out-Null
    $state
}

function Test-RepoHealthRepositoryBinding {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Header)
    if (-not (Test-Path -LiteralPath ([string]$Header.repository_path))) { throw 'Declared repository path is missing.' }
    $top = (git -C ([string]$Header.repository_path) rev-parse --show-toplevel).Trim()
    $declaredPath = (Resolve-Path -LiteralPath ([string]$Header.repository_path)).Path
    $actualPath = (Resolve-Path -LiteralPath $top).Path
    if ($actualPath -ne $declaredPath -or [string]$Header.working_directory -ne [string]$Header.repository_path) { throw 'Repository root or working directory mismatch.' }
    $remote = (git -C $actualPath remote get-url origin).Trim()
    if ($remote -notmatch ('github\.com[/:]' + [regex]::Escape([string]$Header.github_repository) + '(\.git)?$')) { throw 'GitHub repository mismatch.' }
    $head = (git -C $actualPath rev-parse HEAD).Trim()
    if ($head -notmatch '^[0-9a-f]{40}$') { throw 'Repository HEAD is unavailable.' }
    $head
}

function Assert-RepoHealthRunStepRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$GoalPath,
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [string]$InventoryRoot='V:\src\integration-inventory\repo-health'
    )
    $checked = Test-RepoHealthRunManifest -ManifestPath $ManifestPath
    if (-not $checked.valid) { throw ('RunStep rejects invalid manifest: ' + ($checked.reasons -join ',')) }
    $manifest = $checked.manifest
    if ([string]$manifest.run_id -ne $RunId) { throw 'RunStep run_id differs from manifest.' }
    $goal = Read-RepoHealthBoundGoal -GoalFilePath $GoalPath
    $header = $goal.header
    $step = @($manifest.steps | Where-Object { $_.goal_id -eq $header.goal_id })
    if ($step.Count -ne 1) { throw 'RunStep Goal is absent from the manifest.' }
    $step = $step[0]
    foreach ($field in @('run_id','wave_id','step_id','phase_id','role','repository_id','goal_file_path','goal_sha256','expected_input_sha','expected_output_sha_or_empty')) {
        $expected = if ($field -eq 'run_id') { [string]$manifest.run_id } else { [string]$step.$field }
        if ([string]$header.$field -ne $expected) { throw ('RunStep rejects header mismatch: ' + $field) }
    }
    if ($Role -ne [string]$header.role) { throw 'RunStep role is not authorized for this phase.' }
    $repo = @($manifest.repositories | Where-Object { $_.repository_id -eq $header.repository_id })
    if ($repo.Count -ne 1) { throw 'RunStep repository is outside this Goal.' }
    $repo = $repo[0]
    foreach ($field in @('repository_id','repository_path','github_repository','stable_branch')) {
        $expected = if ($field -eq 'repository_id') { [string]$repo.repository_id } else { [string]$repo.$field }
        if ([string]$header.$field -ne $expected) { throw ('RunStep rejects repository mismatch: ' + $field) }
    }
    if ((@($header.allowed_write_surfaces) -join "`0") -ne (@($step.allowed_write_surfaces) -join "`0") -or (@($header.prohibited_write_surfaces) -join "`0") -ne (@($step.prohibited_write_surfaces) -join "`0")) { throw 'RunStep write surfaces differ from manifest.' }
    $state = Read-RepoHealthManifestState -RunId $RunId -InventoryRoot $InventoryRoot
    if ($null -eq $state -or [bool]$state.stop_requested -or [string]$state.run_status -eq 'COMPLETE') { throw 'RunStep resume state rejects launch.' }
    foreach ($milestone in @($manifest.required_prior_milestones)) { if ([string]$milestone -notin @($state.completed_milestones)) { throw 'RunStep prior milestone is incomplete.' } }
    if ([string]$header.goal_id -in @($state.completed_goal_ids)) { throw 'RunStep completion state rejects repeat launch.' }
    foreach ($dependency in @($step.dependency_goal_ids)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$dependency) -and [string]$dependency -notin @($state.completed_goal_ids)) { throw 'RunStep dependency state rejects launch.' }
    }
    if ($Role -eq 'Implementer' -and $null -ne $state.active_writer) { throw 'RunStep active writer rejects another writer.' }
    $head = Test-RepoHealthRepositoryBinding -Header $header
    if ($head -ne [string]$header.expected_input_sha) { throw 'RunStep expected_input_sha does not match current repository head.' }
    [pscustomobject]@{ manifest=$manifest; step=$step; goal=$goal; header=$header; state=$state; observed_head=$head }
}

function New-RepoHealthProcessEnvelope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$GoalHeader,
        [Parameter(Mandatory)][string]$Outcome,
        [Parameter(Mandatory)][string]$ObservedSha,
        [string]$AuditedSha='', [string]$RemoteCandidateSha='', [string]$PrHeadSha='', [string]$PrBaseBranch='',
        [bool]$ProductRepositoryWrite=$false, [bool]$GitMutation=$false,
        [Parameter(Mandatory)][string]$SanitizedSummary, [string]$BlockerFingerprint=''
    )
    [ordered]@{
        schema='repo-health-process-envelope.v3'; run_id=$GoalHeader.run_id; wave_id=$GoalHeader.wave_id; step_id=$GoalHeader.step_id; phase_id=$GoalHeader.phase_id; role=$GoalHeader.role
        working_directory=$GoalHeader.working_directory; repository_id=$GoalHeader.repository_id; repository_path=$GoalHeader.repository_path; github_repository=$GoalHeader.github_repository; stable_branch=$GoalHeader.stable_branch
        expected_input_sha=$GoalHeader.expected_input_sha; expected_output_sha_or_empty=$GoalHeader.expected_output_sha_or_empty; observed_sha=$ObservedSha; audited_sha=$AuditedSha
        remote_candidate_sha=$RemoteCandidateSha; pr_head_sha=$PrHeadSha; pr_base_branch=$PrBaseBranch; outcome=$Outcome; product_repository_write=$ProductRepositoryWrite; git_mutation=$GitMutation
        sanitized_summary=$SanitizedSummary; blocker_fingerprint=$BlockerFingerprint; secrets_visible=$false; private_connection_metadata_count=0
    }
}

function Test-RepoHealthProcessEnvelope {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Envelope,[string]$RawJson='')
    $reasons = New-Object System.Collections.Generic.List[string]
    $set = Test-RepoHealthExactPropertySet -Object $Envelope -Expected $script:EnvelopeFields -RawJson $RawJson
    foreach ($reason in $set.reasons) { $reasons.Add($reason) }
    if ($reasons.Count -eq 0) {
        if ([string]$Envelope.schema -ne 'repo-health-process-envelope.v3') { $reasons.Add('schema') }
        foreach ($field in @('run_id','wave_id','step_id','phase_id','role','repository_id','stable_branch')) { try { Assert-RepoHealthSafeIdentifier -Value ([string]$Envelope.$field) -Field $field } catch { $reasons.Add('unsafe_' + $field) } }
        foreach ($field in @('expected_input_sha','expected_output_sha_or_empty','observed_sha','audited_sha','remote_candidate_sha','pr_head_sha')) { try { Assert-RepoHealthShaOrEmpty -Value ([string]$Envelope.$field) -Field $field -AllowEmpty } catch { $reasons.Add($field) } }
        if ([string]$Envelope.role -notin $script:RepoHealthRoleProfiles.Keys) { $reasons.Add('role') }
        $allowed = if ([string]$Envelope.role -eq 'Supervisor') { @('PASS','CHANGES_REQUIRED','BLOCKED_EXTERNAL','HUMAN_ESCALATION_REQUIRED') } else { @('PASS','HOLD','BLOCKED') }
        if ([string]$Envelope.outcome -notin $allowed) { $reasons.Add('outcome') }
        if ([string]$Envelope.role -eq 'Supervisor' -and [string]::IsNullOrWhiteSpace([string]$Envelope.audited_sha)) { $reasons.Add('supervisor_audited_sha') }
        if ([string]$Envelope.role -ne 'Implementer' -and ([bool]$Envelope.product_repository_write -or [bool]$Envelope.git_mutation)) { $reasons.Add('readonly_mutation') }
        if (-not (Test-RepoHealthSafeSummary -Value ([string]$Envelope.sanitized_summary))) { $reasons.Add('sanitized_summary') }
        if ([bool]$Envelope.secrets_visible -or [int]$Envelope.private_connection_metadata_count -ne 0) { $reasons.Add('safety_fields') }
        if ([string]$Envelope.blocker_fingerprint -and [string]$Envelope.blocker_fingerprint -notmatch '^[0-9a-f]{64}$') { $reasons.Add('blocker_fingerprint') }
    }
    [pscustomobject]@{valid=($reasons.Count -eq 0);reasons=@($reasons | Select-Object -Unique)}
}

function Assert-RepoHealthBoundEnvelope {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Envelope,[Parameter(Mandatory)][object]$Header,[Parameter(Mandatory)][string]$ObservedHead)
    $checked = Test-RepoHealthProcessEnvelope -Envelope $Envelope
    if (-not $checked.valid) { throw ('Invalid process envelope: ' + ($checked.reasons -join ',')) }
    foreach ($field in @('run_id','wave_id','step_id','phase_id','role','working_directory','repository_id','repository_path','github_repository','stable_branch','expected_input_sha','expected_output_sha_or_empty')) {
        if ([string]$Envelope.$field -ne [string]$Header.$field) { throw ('Envelope is not bound to Goal header: ' + $field) }
    }
    if ([string]$Envelope.observed_sha -ne $ObservedHead) { throw 'Envelope observed_sha differs from independently observed HEAD.' }
    if ([string]$Header.role -eq 'Supervisor' -and [string]$Envelope.audited_sha -ne $ObservedHead) { throw 'Supervisor audited_sha differs from independently observed HEAD.' }
}

function Assert-RepoHealthPostImplementerSha {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$ImplementerEnvelope,[Parameter(Mandatory)][string]$ObservedCandidateSha)
    if ([string]$ImplementerEnvelope.role -ne 'Implementer' -or [string]$ImplementerEnvelope.observed_sha -ne $ObservedCandidateSha -or $ObservedCandidateSha -notmatch '^[0-9a-f]{40}$') { throw 'Post-Implementer SHA binding failed.' }
}

function Assert-RepoHealthBranchStability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LocalCandidateSha,[Parameter(Mandatory)][string]$RemoteCandidateSha,
        [Parameter(Mandatory)][string]$PrHeadSha,[Parameter(Mandatory)][string]$SupervisorAuditedSha,
        [Parameter(Mandatory)][string]$ExpectedMergeHeadSha,[Parameter(Mandatory)][string]$PrBaseBranch,
        [Parameter(Mandatory)][string]$StableBranch,[string]$MainMovedFrom='',[string]$MainNow=''
    )
    foreach ($value in @($LocalCandidateSha,$RemoteCandidateSha,$PrHeadSha,$SupervisorAuditedSha,$ExpectedMergeHeadSha)) { Assert-RepoHealthShaOrEmpty -Value $value -Field 'branch_stability_sha' }
    if ($PrBaseBranch -ne $StableBranch) { throw 'PR base is not the stable branch.' }
    if (@($LocalCandidateSha,$RemoteCandidateSha,$PrHeadSha,$SupervisorAuditedSha,$ExpectedMergeHeadSha | Select-Object -Unique).Count -ne 1) { throw 'Candidate branch moved or audited head mismatch.' }
    if ($MainMovedFrom -and $MainNow -and $MainMovedFrom -ne $MainNow) { throw 'Stable branch moved and has not been revalidated.' }
}

function Assert-RepoHealthLaunchArguments {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments)
    foreach ($argument in $Arguments) { if ($argument -in @('--yolo','--sandbox','--config','--dangerously-bypass-approvals-and-sandbox','--dangerously-bypass-hook-trust')) { throw 'Forbidden process launch override.' } }
}

function Resolve-RepoHealthCodexHost {
    [CmdletBinding()]
    param()
    $command = Get-Command codex -ErrorAction Stop
    if ($command.CommandType -eq 'Application') { return [pscustomobject]@{file_name=$command.Source;prefix_arguments=@()} }
    if ($command.CommandType -eq 'ExternalScript') { return [pscustomobject]@{file_name=(Join-Path $PSHOME 'pwsh.exe');prefix_arguments=@('-NoProfile','-File',$command.Source)} }
    throw 'Codex command is not an external executable or script.'
}

function Enter-RepoHealthWriterLease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repository,[Parameter(Mandatory)][string]$SessionId,[string]$StateRoot='V:\src\integration-inventory\repo-health\state')
    $global = Enter-RepoHealthLock -Repository 'product-writer' -SessionId $SessionId -StateRoot $StateRoot
    try { [pscustomobject]@{Global=$global;Repository=(Enter-RepoHealthLock -Repository $Repository -SessionId $SessionId -StateRoot $StateRoot)} }
    catch { Exit-RepoHealthLock -Lock $global; throw }
}

function Exit-RepoHealthWriterLease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Lease)
    try { Exit-RepoHealthLock -Lock $Lease.Repository } finally { Exit-RepoHealthLock -Lock $Lease.Global }
}

function Write-RepoHealthProcessLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Role,[Parameter(Mandatory)][int]$ExitCode,[Parameter(Mandatory)][int]$StdOutCharacters,[Parameter(Mandatory)][int]$StdErrCharacters,[Parameter(Mandatory)][string]$Outcome,[Parameter(Mandatory)][string]$Profile,[Parameter(Mandatory)][int]$ChildProcessId)
    Write-RepoHealthJsonAtomic -Path $Path -Value ([ordered]@{schema='repo-health-process-log.v1';role=$Role;exit_code=$ExitCode;stdout_characters=$StdOutCharacters;stderr_characters=$StdErrCharacters;outcome=$Outcome;launch_profile=$Profile;child_process_id=$ChildProcessId;secrets_visible=$false;private_connection_metadata_count=0}) | Out-Null
}

function Complete-RepoHealthRunStep {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$State,[Parameter(Mandatory)][object]$Header,[Parameter(Mandatory)][object]$Envelope,[string]$InventoryRoot='V:\src\integration-inventory\repo-health')
    if ([string]$Envelope.outcome -eq 'PASS') { $State.completed_goal_ids = @($State.completed_goal_ids) + [string]$Header.goal_id }
    Save-RepoHealthManifestState -State $State -InventoryRoot $InventoryRoot | Out-Null
}

function Invoke-RepoHealthRoleProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,[Parameter(Mandatory)][string]$RunId,[Parameter(Mandatory)][string]$GoalPath,
        [Parameter(Mandatory)][ValidateSet('Architect','Implementer','Supervisor','Auditor','Mechanical')][string]$Role,
        [string]$InventoryRoot='V:\src\integration-inventory\repo-health',[string]$LogRoot='V:\src\codex-run-logs\repo-health',[string]$StateRoot='V:\src\integration-inventory\repo-health\state'
    )
    $request = Assert-RepoHealthRunStepRequest -ManifestPath $ManifestPath -RunId $RunId -GoalPath $GoalPath -Role $Role -InventoryRoot $InventoryRoot
    $header = $request.header; $profile = Get-RepoHealthRoleProfile -Role $Role
    $paths = Get-RepoHealthManifestPaths -RunId $RunId -InventoryRoot $InventoryRoot -LogRoot $LogRoot
    [System.IO.Directory]::CreateDirectory($paths.EnvelopeRoot) | Out-Null; [System.IO.Directory]::CreateDirectory($paths.LogRoot) | Out-Null
    $lease = $null; $tempResult = $null
    try {
        if ($Role -eq 'Implementer') {
            $lease = Enter-RepoHealthWriterLease -Repository ([string]$header.repository_id) -SessionId ($RunId + '-' + $header.goal_id) -StateRoot $StateRoot
            $request.state.active_writer = [string]$header.repository_id; Save-RepoHealthManifestState -State $request.state -InventoryRoot $InventoryRoot | Out-Null
        }
        $preStatus = (git -C ([string]$header.repository_path) status --porcelain=v1) -join "`n"
        $host = Resolve-RepoHealthCodexHost
        $tempResult = Join-Path ([System.IO.Path]::GetTempPath()) ('repo-health-' + $RunId + '-' + [guid]::NewGuid().ToString('N') + '.result.json')
        $psi = [System.Diagnostics.ProcessStartInfo]::new(); $psi.FileName=$host.file_name; $psi.WorkingDirectory=[string]$header.working_directory; $psi.UseShellExecute=$false; $psi.RedirectStandardInput=$true; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
        $arguments = @($host.prefix_arguments) + @('exec','--profile',$profile,'-C',[string]$header.working_directory,'--output-last-message',$tempResult,'-')
        Assert-RepoHealthLaunchArguments -Arguments $arguments
        foreach ($argument in $arguments) { [void]$psi.ArgumentList.Add([string]$argument) }
        $process=[System.Diagnostics.Process]::Start($psi); $process.StandardInput.Write($request.goal.content); $process.StandardInput.Close(); $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
        # Native interactive-TUI roles are operator-managed. The coordinator never imposes a hard deadline or kills a role process.
        $process.WaitForExit()
        $stdout=$stdoutTask.GetAwaiter().GetResult();$stderr=$stderrTask.GetAwaiter().GetResult()
        if (-not (Test-Path -LiteralPath $tempResult)) { throw 'Role process did not write a result envelope.' }
        $rawEnvelope=Get-Content -LiteralPath $tempResult -Raw; try { $envelope=$rawEnvelope | ConvertFrom-Json } catch { throw 'Role process result is not JSON.' }
        $postHead=(git -C ([string]$header.repository_path) rev-parse HEAD).Trim();$postStatus=(git -C ([string]$header.repository_path) status --porcelain=v1) -join "`n"
        if ($Role -ne 'Implementer' -and ($postHead -ne $request.observed_head -or $postStatus -ne $preStatus)) { throw 'Read-only role changed Git state.' }
        $validation=Test-RepoHealthProcessEnvelope -Envelope $envelope -RawJson $rawEnvelope
        if (-not $validation.valid) { throw ('Invalid process envelope: ' + ($validation.reasons -join ',')) }
        Assert-RepoHealthBoundEnvelope -Envelope $envelope -Header $header -ObservedHead $postHead
        $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ');$name=('{0}-{1}-{2}.json' -f $header.goal_id,$Role,$stamp);$envelopePath=Join-Path $paths.EnvelopeRoot $name
        Write-RepoHealthJsonAtomic -Path $envelopePath -Value $envelope | Out-Null
        Write-RepoHealthProcessLog -Path (Join-Path $paths.LogRoot ($name + '.log.json')) -Role $Role -ExitCode $process.ExitCode -StdOutCharacters $stdout.Length -StdErrCharacters $stderr.Length -Outcome ([string]$envelope.outcome) -Profile $profile -ChildProcessId $process.Id
        Complete-RepoHealthRunStep -State $request.state -Header $header -Envelope $envelope -InventoryRoot $InventoryRoot
        [pscustomobject]@{envelope=$envelope;envelope_path=$envelopePath;exit_code=$process.ExitCode;observed_sha=$postHead}
    }
    finally {
        if ($lease) { $request.state.active_writer=$null;Save-RepoHealthManifestState -State $request.state -InventoryRoot $InventoryRoot | Out-Null;Exit-RepoHealthWriterLease -Lease $lease }
        if ($tempResult -and (Test-Path -LiteralPath $tempResult)) { Remove-Item -LiteralPath $tempResult -Force }
    }
}

function Test-RepoHealthRoutingContract {
    [CmdletBinding()]
    param([string]$RoutingPath=(Join-Path $HOME '.codex\profile-routing.meta.json'))
    $reasons=New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $RoutingPath)) { return [pscustomobject]@{valid=$false;reasons=@('routing_metadata_missing')} }
    $routing=Get-Content -LiteralPath $RoutingPath -Raw | ConvertFrom-Json
    if ([string]$routing.routing_version -ne 'codex-routing-v2') { $reasons.Add('routing_version') }
    foreach ($role in $script:RepoHealthRoleProfiles.Keys) {
        $entry=$routing.roles.($role.ToLowerInvariant())
        if ($null -eq $entry -or [string]$entry.profile -ne $script:RepoHealthRoleProfiles[$role]) { $reasons.Add('profile_'+$role);continue }
        $expectedSandbox=if($role -eq 'Implementer'){'danger-full-access'}else{'read-only'}
        if([string]$entry.sandbox_mode -ne $expectedSandbox -or [string]$entry.approval_policy -ne 'never'){$reasons.Add('permission_'+$role)}
    }
    [pscustomobject]@{valid=($reasons.Count -eq 0);reasons=@($reasons)}
}

Export-ModuleMember -Function @(
    'Assert-RepoHealthBoundEnvelope','Assert-RepoHealthBranchStability','Assert-RepoHealthLaunchArguments','Assert-RepoHealthPostImplementerSha','Assert-RepoHealthRunStepRequest',
    'Complete-RepoHealthRunStep','Enter-RepoHealthWriterLease','Exit-RepoHealthWriterLease','Get-RepoHealthManifestPaths','Get-RepoHealthRoleProfile','Get-RepoHealthTextSha256',
    'Initialize-RepoHealthRun','Invoke-RepoHealthRoleProcess','New-RepoHealthBoundGoal','New-RepoHealthManifestState','New-RepoHealthProcessEnvelope','Read-RepoHealthBoundGoal','Read-RepoHealthManifestState',
    'Resolve-RepoHealthCodexHost','Save-RepoHealthManifestState','Test-RepoHealthProcessEnvelope','Test-RepoHealthRepositoryBinding','Test-RepoHealthRoutingContract','Test-RepoHealthRunManifest','Write-RepoHealthProcessLog'
)
