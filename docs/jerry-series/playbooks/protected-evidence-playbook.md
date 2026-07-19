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

Do not default to force cleanup, recursive deletion, content hashing, size inspection, compression, descendant enumeration, or broad recursive restore for unknown or protected evidence.

## Standard dispositions

Every evidence object should receive exactly one disposition:

```text
RETAIN_AND_REPLAN
RETAIN_DOCUMENTED_NON_BLOCKING_WORKTREE
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
9. Revalidate Git path/status metadata without reading relocated content.
10. Persist a receipt.
11. Resume normal non-force cleanup only after metadata side effects are resolved.

## Retained registered evidence worktree

Use `RETAIN_DOCUMENTED_NON_BLOCKING_WORKTREE` when removing or relocating a registered worktree would risk destroying unclassified tracked or opaque evidence and the owner elects to preserve it in place.

The receipt must bind:

- exact worktree path;
- exact shallow dirty-path identities and statuses;
- bound branch or detached HEAD state;
- retain-in-place decision;
- prohibition on removal, cleanup, bound-ref deletion, and content inspection;
- reason the worktree is not required for current product convergence;
- explicit exclusion from unresolved debt.

A retained worktree remains a real registered worktree. Report it separately from canonical worktrees and unresolved worktree debt. Do not claim it was removed or cleaned.

## Post-relocation tracked-metadata reconciliation

Opaque relocation can expose tracked deletion entries for placeholders or anchors that were inside the moved root, for example:

```text
D .agent/.gitkeep
```

This is a metadata side effect. It does not authorize restoring the opaque contents.

Safe sequence:

1. Confirm the opaque source root remains absent.
2. Confirm the opaque destination remains present.
3. Use path/status-only Git checks to identify exact tracked metadata deletions.
4. Verify no additional tracked dirt exists.
5. Persist an exact restore plan.
6. Restore only the exact tracked placeholder from the index or HEAD.
7. Do not recursively restore the opaque root.
8. Verify the placeholder deletion is cleared.
9. Verify the relocated opaque contents remain outside the worktree.
10. Resume normal non-force worktree removal.

Typical exact restore semantics:

```text
git restore --worktree -- <exact-tracked-placeholder>
```

A path-scoped `checkout -- <exact-path>` fallback is allowed only when it does not switch branches and the Goal explicitly permits it.

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

When tracked metadata was reconciled, also state:

```text
restored_opaque_contents=false
exact_tracked_metadata_paths=<list>
additional_tracked_dirt=false
opaque_destination_preserved=true
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
- exact root is outside repositories and registered worktrees after relocation;
- receipt says no content was lost;
- no cleanup operation references children.

Do not list child names unless a prior explicit authorization covers that specific act.

## Git metadata as protected evidence

A stale Git operation marker may itself be preserved as opaque metadata when Git-native state proves it is orphaned. Use `git-operation-marker-reconciliation-playbook.md`; do not apply generic file deletion without the marker-coherence checks in that playbook.

## Completion standard

Cleanup may proceed only when:

```text
all unique history is reachable
all unknown evidence has a disposition
all protected roots are preserved
all tracked metadata side effects are reconciled
normal non-force worktree removal is possible
product state remains unchanged
```

A documented retained evidence worktree may remain when its owner-approved disposition is explicit and final audit reports it separately from unresolved debt.
