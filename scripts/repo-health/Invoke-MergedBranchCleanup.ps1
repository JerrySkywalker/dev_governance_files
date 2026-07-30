[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[^/]+/[^/]+$')]
    [string]$Repository,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Token,

    [switch]$Apply,

    [string[]]$PreserveBranches = @(
        'main',
        'governance/ssh-key-store'
    )
)

$ErrorActionPreference = 'Stop'
$apiRoot = 'https://api.github.com'
$headers = @{
    Accept                 = 'application/vnd.github+json'
    Authorization          = "Bearer $Token"
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent'           = 'Jerry-Repository-Health'
}

function Get-GitHubPagedItems {
    param([Parameter(Mandatory)][string]$Path)

    $items = [System.Collections.Generic.List[object]]::new()
    for ($page = 1; ; $page++) {
        $separator = if ($Path.Contains('?')) { '&' } else { '?' }
        $uri = "$apiRoot$Path${separator}per_page=100&page=$page"
        $response = @(Invoke-RestMethod -Method Get -Uri $uri -Headers $headers)
        foreach ($item in $response) { $items.Add($item) }
        if ($response.Count -lt 100) { break }
    }

    foreach ($item in $items) {
        Write-Output -InputObject $item
    }
}

function ConvertTo-RefPath {
    param([Parameter(Mandatory)][string]$BranchName)

    return (($BranchName -split '/') | ForEach-Object {
        [uri]::EscapeDataString($_)
    }) -join '/'
}

$repositoryState = Invoke-RestMethod -Method Get -Uri "$apiRoot/repos/$Repository" -Headers $headers
$defaultBranch = [string]$repositoryState.default_branch
$preserve = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$null = $preserve.Add($defaultBranch)
foreach ($branchName in $PreserveBranches) { $null = $preserve.Add($branchName) }

$branches = @(Get-GitHubPagedItems -Path "/repos/$Repository/branches")
$closedPullRequests = @(Get-GitHubPagedItems -Path "/repos/$Repository/pulls?state=closed&sort=updated&direction=desc")
$openPullRequests = @(Get-GitHubPagedItems -Path "/repos/$Repository/pulls?state=open&sort=updated&direction=desc")

if ($branches.Count -lt 1) { throw 'Branch inventory is empty' }
if ($closedPullRequests.Count -lt 1) { throw 'Closed pull-request inventory is empty' }

$mergedHeads = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($pullRequest in $closedPullRequests) {
    if ($null -ne $pullRequest.merged_at -and
        [string]$pullRequest.head.repo.full_name -eq $Repository) {
        $null = $mergedHeads.Add([string]$pullRequest.head.ref)
    }
}

if ($mergedHeads.Count -lt 1) { throw 'No merged same-repository PR heads were discovered' }

$openHeads = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($pullRequest in $openPullRequests) {
    if ([string]$pullRequest.head.repo.full_name -eq $Repository) {
        $null = $openHeads.Add([string]$pullRequest.head.ref)
    }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($branch in ($branches | Sort-Object name)) {
    $name = [string]$branch.name
    $classification = if ($name -eq $defaultBranch) {
        'HOLD_DEFAULT'
    }
    elseif ($preserve.Contains($name)) {
        'HOLD_PRESERVED'
    }
    elseif ([bool]$branch.protected) {
        'HOLD_PROTECTED'
    }
    elseif ($openHeads.Contains($name)) {
        'HOLD_OPEN_PR'
    }
    elseif ($mergedHeads.Contains($name)) {
        'DELETE_MERGED_PR_HEAD'
    }
    else {
        'HOLD_UNMERGED_OR_UNCLASSIFIED'
    }

    $deleted = $false
    if ($Apply -and $classification -eq 'DELETE_MERGED_PR_HEAD') {
        $refPath = ConvertTo-RefPath -BranchName $name
        Invoke-RestMethod -Method Delete -Uri "$apiRoot/repos/$Repository/git/refs/heads/$refPath" -Headers $headers
        $deleted = $true
    }

    $results.Add([pscustomobject]@{
        branch         = $name
        classification = $classification
        deleted        = $deleted
        protected      = [bool]$branch.protected
        sha            = [string]$branch.commit.sha
    })
}

if ($results.Count -ne $branches.Count) {
    throw "Branch classification mismatch: branches=$($branches.Count) results=$($results.Count)"
}

$results | Sort-Object classification, branch | Format-Table -AutoSize

$deleteCandidates = @($results | Where-Object classification -eq 'DELETE_MERGED_PR_HEAD')
$deletedCount = @($results | Where-Object deleted).Count
$heldUnclassified = @($results | Where-Object classification -eq 'HOLD_UNMERGED_OR_UNCLASSIFIED')

"BRANCH_CLEANUP_MODE=$(if ($Apply) { 'APPLY' } else { 'DRY_RUN' })"
"BRANCH_COUNT=$($branches.Count)"
"CLOSED_PR_COUNT=$($closedPullRequests.Count)"
"MERGED_HEAD_COUNT=$($mergedHeads.Count)"
"OPEN_PR_HEAD_COUNT=$($openHeads.Count)"
"DELETE_CANDIDATE_COUNT=$($deleteCandidates.Count)"
"DELETED_COUNT=$deletedCount"
"HOLD_UNMERGED_OR_UNCLASSIFIED_COUNT=$($heldUnclassified.Count)"

if ($Apply -and $deletedCount -ne $deleteCandidates.Count) {
    throw "Branch cleanup incomplete: expected=$($deleteCandidates.Count) deleted=$deletedCount"
}
