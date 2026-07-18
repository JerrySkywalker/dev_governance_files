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
```

## Inventory requirements

Capture:

- local branches and exact SHAs;
- remote heads and exact SHAs;
- upstream bindings;
- open and closed PR associations;
- registered worktrees;
- stashes;
- tracked and staged state;
- nonignored untracked state;
- protected evidence roots;
- archive tags;
- Git operation markers.

## Classification

Every branch or worktree must receive one classification:

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

## Squash merge rule

When a PR was squash-merged, the final main commit does not preserve the original branch commits. Preserve the candidate history through an archive tag or other approved reference before deleting the branch.

## Worktree cleanup rule

Normal worktree removal is preferred. Forced worktree removal is not a default disposition. If normal removal reports unhandled local content, stop and classify the blocker.

## Branch deletion rule

Before deleting a branch, revalidate:

- exact SHA;
- PR state;
- worktree binding;
- ancestry or patch equivalence;
- archive preservation when unique history exists;
- remote ref has not moved since inventory.

Do not delete a branch with unresolved unique history.

## Final state

A repository is converged when:

```text
local branches = main or explicitly accepted long-lived set
remote branches = main or explicitly accepted long-lived set
registered worktrees = canonical only
open feature PRs = 0
stashes = 0 unless explicitly retained
Git operations = none
canonical worktree = clean
held_or_blocked_objects = []
```

## Receipt fields

The receipt should include:

- before and after main SHA;
- before and after branch sets;
- before and after worktree sets;
- archive tag matrix;
- branch deletions;
- worktree removals;
- evidence relocations;
- force cleanup used or not;
- product files modified or not;
- CI triggered or not;
- production action or not.
