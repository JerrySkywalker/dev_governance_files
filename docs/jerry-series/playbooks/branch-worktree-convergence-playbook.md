# Branch and Worktree Convergence Playbook

## Purpose

Converge repository branch, PR, worktree, archive, and evidence state without losing product history or local evidence.

## Standard order

```text
1. inventory
2. classify
3. preserve unique history
4. preserve unknown evidence
5. run fresh Supervisor
6. remove noncanonical worktrees normally
7. delete obsolete branches normally
8. verify final state
9. write receipt and checkpoint
10. independently revalidate live state at the milestone audit
```

## Inventory requirements

Capture the complete live set, not a sample:

- local branches and exact SHAs;
- remote heads and exact SHAs;
- gone-upstream local branches;
- local branches without upstreams;
- remote-only heads;
- upstream bindings;
- open and closed PR associations;
- registered worktrees and bound refs;
- stashes;
- tracked and staged state;
- nonignored untracked state;
- protected or opaque evidence roots;
- archive tags;
- Git operation markers;
- local, remote-tracking, and remote default-branch SHAs.

A previous receipt or checkpoint does not replace fresh live inventory.

## Classification

Every branch, remote head, PR, worktree, stash, and held evidence object must receive one classification.

Baseline classifications:

```text
RETAIN_MAIN
DELETE_MERGED
DELETE_PATCH_EQUIVALENT
ARCHIVE_THEN_DELETE
HOLD_APPROVED_EVIDENCE
HOLD_ACTIVE_WORKTREE
HOLD_UNCLEAR_UNIQUE_HISTORY
BLOCKED_UNKNOWN_DIRT
BLOCKED_PROTECTED_EVIDENCE
```

Documented retained-state extensions:

```text
RETAIN_DOCUMENTED_ACTIVE_DRAFT_PR
RETAIN_DOCUMENTED_NON_BLOCKING_EVIDENCE_WORKTREE
RETAIN_DOCUMENTED_EVIDENCE_BOUND_REF
RETAIN_DOCUMENTED_OWNER_DECISION
PRESERVED_OPAQUE_EVIDENCE_ROOT
PRESERVED_ORPHAN_GIT_METADATA
```

A retained documented object is not unresolved debt when all of the following are true:

- the exact object identity is recorded;
- an owner-approved disposition exists;
- its mutation boundary is explicit;
- it is not required for the current product contract;
- the final audit revalidates the retained state;
- it is reported separately from debt counts.

## Squash merge rule

When a PR was squash-merged, the final main commit does not preserve the original branch commits. Preserve the candidate history through an archive tag or other approved reference before deleting the branch.

## Worktree cleanup rule

Normal worktree removal is preferred. Forced worktree removal is not a default disposition. If normal removal reports unhandled local content, stop and classify the blocker.

A registered worktree may remain only when explicitly classified as a documented retained state. Do not describe it as removed or canonical. Report it separately from unresolved worktree debt.

## Branch deletion rule

Before deleting a branch, revalidate:

- exact SHA;
- PR state;
- worktree binding;
- ancestry or patch equivalence;
- archive preservation when unique history exists;
- remote ref has not moved since inventory;
- the branch is not part of an explicitly retained PR or evidence state.

Do not delete a branch with unresolved unique history.

## Remote-head rule

A zero-debt claim must classify every remote head, including remote-only heads. Do not infer remote convergence from local branch state or recent PR results.

For each remote head, record:

```text
remote_ref
exact_sha
associated_local_branch
associated_pr
unique_history
classification
final_disposition
```

## Git operation marker rule

Inventory Git operation markers through Git-resolved paths. A lone marker does not necessarily prove a coherent active operation.

Use `git-operation-marker-reconciliation-playbook.md` when Git-native status and marker state disagree.

## Final state

A repository is converged when:

```text
local branches = canonical set + explicitly retained documented set
remote branches = canonical set + explicitly retained documented set
registered worktrees = canonical set + explicitly retained documented set
active product PRs requiring action = 0
stashes = 0 unless explicitly retained
Git operations = none
canonical worktree = clean
unclassified_objects = 0
unresolved_debt = 0
```

Do not require deletion of an explicitly retained object merely to make the repository appear empty.

## Checkpoint versus live truth

A completion checkpoint is a historical claim. The final milestone audit must independently recompute:

- local and remote branch sets;
- worktrees;
- PR states;
- Git operation markers;
- accepted default-branch SHAs;
- retained-state identities.

When live state contradicts a checkpoint, stop the milestone audit, run a bounded reconciliation, and rerun the audit. Do not weaken the live audit or silently edit the prior checkpoint.

## Receipt fields

The receipt should include:

- before and after default-branch SHA;
- before and after local branch sets;
- before and after remote-head sets;
- before and after worktree sets;
- retained documented object matrix;
- archive tag matrix;
- branch deletions;
- remote-head deletions;
- worktree removals;
- evidence relocations;
- Git operation reconciliation;
- force cleanup used or not;
- product files modified or not;
- causal CI accounting;
- production action or not.

## Completion standard

```text
all live refs classified
all live worktrees classified
all PRs classified
all unique history reachable
all unknown evidence has a disposition
all retained objects explicitly documented
unclassified_objects = 0
unresolved_debt = 0
fresh Supervisor = PASS
independent milestone live audit = PASS
```
