Set-StrictMode -Version Latest

$script:RepoHealthStates = @(
    'DISCOVER',
    'CLASSIFY_BRANCHES',
    'PLAN_CONVERGENCE',
    'IMPLEMENT',
    'VERIFY_LOCAL',
    'VERIFY_CI',
    'SUPERVISOR_AUDIT',
    'MERGE_MAIN',
    'MERGE_DEV',
    'ARCHIVE',
    'DELETE_BRANCH',
    'WORKTREE_CLEANUP',
    'REPO_HEALTHY',
    'BLOCKED_ROUND_1',
    'BLOCKED_ROUND_2',
    'HUMAN_REQUIRED'
)

$script:RepoHealthHighRiskClasses = @(
    'REAL_SECRET',
    'IDENTITY_OR_SIGNING_MATERIAL',
    'MFA_OR_PHYSICAL_DEVICE',
    'PRODUCTION_MUTATION',
    'IRREVERSIBLE_DATA_OPERATION',
    'FORCE_PUSH',
    'UNIQUE_COMMITS_UNCLEAR_OWNERSHIP',
    'UNTRACKED_EVIDENCE_RISK',
    'ACTIVE_WORKTREE_UNPROVEN_OWNERSHIP',
    'ACTIVE_PROCESS_DEPENDENCY_UNCLASSIFIED'
)

function Get-RepoHealthStateNames {
    [CmdletBinding()]
    param()

    return $script:RepoHealthStates
}

function Get-RepoHealthHighRiskClasses {
    [CmdletBinding()]
    param()

    return $script:RepoHealthHighRiskClasses
}
