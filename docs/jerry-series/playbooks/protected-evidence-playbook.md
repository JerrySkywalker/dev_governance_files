# Protected Evidence Playbook

## Purpose

Preserve unknown or protected evidence while allowing repository health work to continue.

This playbook applies when worktree cleanup, branch convergence, CI recovery, or audit work discovers a file or directory whose contents are not approved for inspection or deletion.

## Core rule

```text
Evidence before cleanup.
```

Never use faster destructive cleanup to avoid an evidence decision.

## Prohibited defaults

Do not default to force cleanup, recursive deletion, content hashing, size inspection, compression, or descendant enumeration for unknown or protected evidence.

## Standard dispositions

Every evidence object should receive exactly one disposition:

```text
RETAIN_AND_REPLAN
OPAQUE_SAME_VOLUME_FILE_RELOCATION
OPAQUE_SAME_VOLUME_DIRECTORY_RELOCATION
BOUNDED_DIRECT_DELETION_AFTER_EXPLICIT_AUTHORIZATION
PROTECTED_ROOT_EXISTENCE_ONLY
SNAPSHOT_REQUIRED
```

## Opaque relocation procedure

Use this when an unknown file or directory blocks normal cleanup but should not be inspected.

1. Bind the exact source path.
2. Bind the exact destination path outside product repositories and registered worktrees.
3. Verify the source root exists without enumerating descendants.
4. Verify the destination does not exist.
5. Persist owner authorization.
6. Run a fresh Supervisor check.
7. Move as an opaque object using same-volume rename semantics.
8. Verify only source absence and destination presence.
9. Persist a receipt.
10. Resume normal non-force cleanup.

## Supervisor requirements

The Supervisor report should state:

```text
outcome=PASS
content_read=false
hash_computed=false
size_queried=false
descendant_enumeration=false
copy_performed=false
compression_performed=false
deletion_without_preservation=false
product_state_unchanged=true
```

When the Supervisor cannot truthfully assert a condition, stop and correct the Goal. Do not weaken the report.

## Windows long-path residue

If normal worktree removal removes Git registration but leaves a physical directory because of a filename-too-long error:

1. Treat the leftover directory as unregistered filesystem evidence.
2. Do not enumerate descendants.
3. Prefer a shorter same-volume opaque destination.
4. Use extended-length literal paths when required.
5. Move the root as a directory object.
6. Prune only proven stale Git administrative metadata.

## Protected root handling

For protected roots, verify only:

- exact root exists;
- exact root is outside repositories and registered worktrees;
- receipt says no content was lost;
- no cleanup operation references children.

Do not list child names unless a prior explicit authorization covers that specific act.

## Completion standard

Cleanup may proceed only when:

```text
all unique history is reachable
all unknown evidence has a disposition
all protected roots are preserved
normal non-force worktree removal is possible
product state remains unchanged
```
