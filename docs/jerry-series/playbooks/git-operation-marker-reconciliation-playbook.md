# Git Operation Marker Reconciliation Playbook

## Purpose

Distinguish a coherent active Git operation from stale or orphan Git metadata, then reconcile the state without losing evidence or rewriting product history.

This playbook applies when admission or final audit discovers markers such as:

```text
REBASE_HEAD
MERGE_HEAD
CHERRY_PICK_HEAD
REVERT_HEAD
BISECT_LOG
rebase-merge/
rebase-apply/
```

## Core rule

```text
A marker is evidence of an operation state, not sufficient proof of a coherent active operation.
```

Use Git-native status and operation metadata together. Do not infer an active operation from a single file existence check.

## Classification

Every discovered marker state must receive exactly one classification:

```text
ACTIVE_COHERENT_OPERATION
ORPHAN_GIT_OPERATION_METADATA
NO_ACTIVE_OPERATION_ALREADY_CLEAR
BLOCKED_AMBIGUOUS_OPERATION_STATE
BLOCKED_UNRELATED_WORKTREE_DIRT
BLOCKED_REF_DRIFT
BLOCKED_PROTECTED_OR_OPAQUE_EVIDENCE
```

## Evidence-first inventory

Resolve the repository-specific Git paths rather than assuming `.git` is a directory:

```text
git rev-parse --git-dir
git rev-parse --git-common-dir
git rev-parse --git-path REBASE_HEAD
```

Record without printing file contents:

- current branch and HEAD;
- accepted local default-branch SHA;
- remote-tracking default-branch SHA;
- remote default-branch SHA from a read-only query;
- `git status` operation message;
- operation directory existence;
- other operation marker existence;
- staged/tracked and nonignored untracked state;
- registered worktrees;
- protected or opaque evidence roots by exact root only.

Do not read, hash, parse, size-query, or print the contents of an operation marker unless a separate authorization explicitly requires it.

## Coherent active-operation test

Classify as `ACTIVE_COHERENT_OPERATION` only when Git-native state is consistent, for example:

- `git status` reports the operation in progress; and/or
- the matching operation directory exists, such as `rebase-merge` or `rebase-apply`; and
- related markers do not contradict one another; and
- the operation can be handled by the standard Git command for that operation.

For a coherent active operation, use a separately authorized product or repository recovery. The decision to continue, skip, abort, or preserve changes is an owner decision.

## Orphan-marker test

Classify a marker as `ORPHAN_GIT_OPERATION_METADATA` only when all of the following are proven:

```text
marker_exists=true
Git_status_reports_operation=false
matching_operation_directory_exists=false
other_operation_markers_exist=false
canonical_worktree_clean=true
accepted_local_remote_refs_agree=true
Git_native_abort_or_status_says_no_operation_in_progress=true
```

Do not classify an operation as orphan merely because an abort command failed. The complete state matrix must be coherent.

## Orphan metadata disposition

Preferred disposition:

```text
OPAQUE_SAME_VOLUME_GIT_METADATA_RELOCATION
```

Procedure:

1. Bind the exact Git-resolved source path.
2. Bind an exact destination outside product repositories and registered worktrees.
3. Verify the destination does not exist.
4. Persist owner authorization and the classification matrix.
5. Move the exact marker as an opaque same-volume object.
6. Do not copy, compress, parse, hash, size-query, or print it.
7. Verify only source absence and destination presence.
8. Re-run Git-native status and operation-marker checks.
9. Verify accepted refs and canonical worktree state remain unchanged.
10. Persist a receipt and fresh Supervisor report.

Unrecorded manual deletion is not the default disposition.

## Prohibited shortcuts

Do not default to:

- repeated `abort`, `continue`, or `skip` attempts after Git denies the operation exists;
- `reset --hard`;
- `clean`;
- manual marker editing;
- deleting the marker without preservation;
- moving unrelated Git metadata;
- product commits intended only to clear metadata;
- pushing or rewriting remote refs.

## Post-reconciliation checks

Require:

```text
active_git_operation=false
operation_marker_source_absent=true
orphan_marker_preserved_when_relocated=true
canonical_worktree_clean=true
accepted_default_branch_sha_unchanged=true
product_files_modified=false
local_refs_mutated=false
github_mutations=0
ci_triggered=false
production_action=false
```

## Receipt fields

A reconciliation receipt should include:

- repository and accepted default-branch SHA;
- Git-resolved marker source path;
- classification matrix;
- Git-native status result;
- matching operation-directory state;
- other marker state;
- chosen disposition;
- opaque destination when used;
- content read/hash/size/parse flags;
- before/after ref SHAs;
- product, GitHub, CI, and production mutation flags.

## Non-goals

This playbook does not decide whether valid in-progress product work should be continued or aborted. That requires a separate owner-authorized repository work scope.
