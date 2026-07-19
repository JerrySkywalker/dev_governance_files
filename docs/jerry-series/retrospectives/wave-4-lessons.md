# Wave 4 Lessons

## Classification

```text
classification: retrospective
related_wave: Wave 4
milestone: M4_CONTROL_PLANE_CONVERGED
related_repositories:
  - jerry-proxy-edge
  - jerry-proxy-control
  - jerry-proxy-client
  - skybridge-agent-hub
```

## Scope

Wave 4 converged the Proxy and SkyBridge control-plane source chain:

```text
Edge -> Control -> Client -> SkyBridge
```

The wave completed with all four product contracts converged, the planned writer order followed, no production action, and no required product delta in any of the four product steps.

The durable value of the wave was not new code. It was proof that the existing source, contracts, history, local worktrees, remote refs, pull requests, CI accounting, and evidence dispositions formed a trustworthy control-plane baseline.

## Outcome

```text
W4_COMPLETE=true
M4_CONTROL_PLANE_CONVERGED=true
writer_order=Edge -> Control -> Client -> SkyBridge
product_delta=NO_PRODUCT_DELTA_REQUIRED for every product repository
production_action=false
```

Retained and preserved objects were allowed when explicitly classified. They were reported separately from unresolved debt.

## Durable lessons

### 1. A checkpoint is a historical claim, not live truth

A completion checkpoint records what a step proved at its completion boundary. It must not replace a fresh live inventory at the final milestone audit.

Wave 4 final audit independently recomputed:

- local branches and exact SHAs;
- remote heads and exact SHAs;
- upstream bindings;
- registered worktrees;
- pull-request state;
- Git operation markers;
- local, remote-tracking, and remote default-branch SHAs.

This revalidation found state that earlier checkpoints had not fully represented. The correct response was a bounded recovery followed by a new audit, not retroactive weakening of the audit.

Reusable rule:

```text
Final milestone audit must recompute live state. It must not merely restate prior receipts.
```

### 2. Existing objects and unresolved debt are different concepts

A repository may be converged while retaining explicitly approved objects, for example:

```text
RETAIN_DOCUMENTED_ACTIVE_DRAFT_PR
RETAIN_DOCUMENTED_NON_BLOCKING_EVIDENCE_WORKTREE
PRESERVED_OPAQUE_EVIDENCE_ROOT
PRESERVED_ORPHAN_GIT_METADATA
```

The completion condition is:

```text
unclassified_objects = 0
unresolved_debt = 0
```

It is not necessarily:

```text
all_noncanonical_objects_deleted = true
```

Every retained object needs an owner-approved disposition, exact identity, operational boundary, and final audit treatment.

### 3. Opaque relocation can create tracked-metadata side effects

Moving an ignored or opaque directory out of a worktree can expose tracked placeholder deletions such as:

```text
D .agent/.gitkeep
```

That does not authorize restoring the opaque contents. The safe sequence is:

1. relocate the exact opaque root;
2. verify source absence and destination presence;
3. revalidate Git status using path/status-only checks;
4. restore only the exact tracked placeholder from the index or HEAD;
5. verify the opaque contents remain outside the worktree;
6. resume normal non-force worktree removal.

Broad recursive restore, force cleanup, or moving the opaque root back is not an acceptable shortcut.

### 4. A Git operation marker can be orphan metadata

The presence of a marker such as `REBASE_HEAD` does not by itself prove a coherent active rebase.

A valid active operation requires consistent evidence from Git status and the corresponding operation directories or related markers. When Git reports that no operation is in progress, the worktree is clean, the accepted refs agree, and only a lone marker remains, classify it as orphan Git metadata.

The safe disposition is evidence-first opaque preservation of the exact marker, not repeated abort attempts, reset, clean, or unrecorded manual deletion.

### 5. CI accounting must describe causality

Archive-tag or ref pushes may automatically trigger workflows. A global assertion such as:

```text
CI_RUNS_TRIGGERED=0
```

becomes false even when Codex did not intentionally request a product CI run.

Use scoped causal accounting:

```text
CI_RUNS_TRIGGERED_BY_THIS_STEP
CI_RUNS_INTENTIONALLY_TRIGGERED_BY_CODEX
PRODUCT_CI_RUNS
AUTOMATIC_TAG_PUSH_CI_SIDE_EFFECTS
AUTOMATIC_TAG_PUSH_CI_RUN_IDS
CI_MUTATIONS_PERFORMED
```

Do not cancel, rerun, rewrite refs, or create empty commits to make the accounting appear clean. Record what happened truthfully.

### 6. Recovery Goals must bind to the last proven stage

A recovery Goal must not require artifacts that would only have been generated after the phase where the blocker occurred.

Admission evidence should be classified as:

```text
REQUIRED_LAST_PROVEN
OPTIONAL_IF_PRESENT
EXPECTED_ABSENT_AFTER_EARLY_BLOCKER
SUPERSEDED_BY_EXPLICIT_RECOVERY
```

A recovery should resolve one blocker class, write its evidence, stop, and allow the parent step to rerun from a fresh inventory.

### 7. Parallelism is an optimization, not an admission invariant

When native child-agent capacity is lower than the number of repositories, use deterministic staggered batches rather than external Codex processes or a full-wave restart.

Required properties:

- identical Auditor scope;
- no descendants;
- recorded batch membership;
- all Auditor batches complete before the final Supervisor;
- no reduction in final evidence requirements.

### 8. No-op is a formal product outcome

A product step may complete as `NO_PRODUCT_DELTA_REQUIRED` when contract analysis, upstream/downstream compatibility, accepted SHA verification, state convergence, and a fresh Supervisor all pass.

No-op does not mean that no work occurred. It means the audit proved the existing product state already satisfied the intended contract.

Do not create meaningless commits, pull requests, or CI runs merely to manufacture visible activity.

### 9. Full remote-head inventory is mandatory

Branch convergence must include the complete live set of:

- local branches;
- remote heads;
- gone-upstream local branches;
- local branches without upstreams;
- remote-only heads;
- worktree-bound refs;
- active and retained pull-request branches.

Sampling recent branches or trusting a prior count is insufficient for a zero-debt claim.

### 10. A final audit may reopen recovery without reopening completed product work

When a final audit finds drift or incomplete classification, the already completed contract steps do not automatically become invalid.

Use a bounded reconciliation for the discovered state, preserve the accepted product SHAs, and rerun the final audit. This keeps the milestone honest without restarting the entire wave.

## Operational consequences for Wave 5

Wave 5 must inherit the following rules:

```text
live inventory before trusting checkpoints
full local and remote branch classification
explicit retained-state model
stage-aware recovery evidence binding
causal CI accounting
no-op product outcome allowed
Git operation marker coherence checks
no real executor or workstation apply
```

The Workstation repositories currently use `master` as their default branch while the old Wave 5 plan names `main/dev`. Wave 5 must resolve that policy explicitly before branch mutation. It must not silently assume that a branch name in a planning document already exists in the repositories.

## Non-goals

This retrospective does not:

- replace raw Wave 4 evidence receipts;
- expose protected evidence descendants;
- authorize cleanup of retained objects;
- authorize production deployment;
- authorize Wave 5 real execution;
- prescribe product implementation changes.

## Sensitivity notes

Only reusable governance facts are recorded here. Raw local payloads, credentials, protected contents, and private runtime data remain outside this repository.
