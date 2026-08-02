# CLH v0.2.1 Template provenance and independent-audit lessons

```text
classification: retrospective
scope: coordination-loop-harness v0.2.0 publication through v0.2.1 Goal 3 acceptance
active_defaults: false
execution_source: false
```

## Context

The v0.2.0 publication Gates passed, but the first real private Template consumer
showed that a `workflow_dispatch` event snapshot did not contain canonical
`repository.template_repository` metadata. The workflow had treated that event
snapshot as authoritative provenance. The release tag was already public and
immutable, and the active Goal admitted no tracked source correction.

The safe response was an authority-bound stop, not no-progress. A short elapsed time
or an otherwise healthy release could not create correction authority. The defect was
fixed by a patch release rather than moving or relabeling the published v0.2.0 tag.

## Lessons

### Repository provenance is a live triple binding

An event payload is context, not canonical repository metadata. A derived-repository
bootstrap must query the target repository through the canonical REST metadata path,
compare the returned Template source with the declared dispatch input, and also bind
the checked-out tree to the exact Template commit tree. API failure, absent metadata,
source mismatch, or tree mismatch must all fail closed. Copying the same tree into a
non-Template repository must not pass.

### Published tags preserve history

Once v0.2.0 was public, its tag and Release identity remained fixed. The history was
kept accurate with a Known Issue and an explicit v0.2.1 patch Release. The original
failed smoke evidence remained a failure; the later successful consumer proved the
repair but did not rewrite the earlier result.

### Real Template consumption needs two observations

The corrected private Template consumer proved canonical REST provenance, exact tree
binding, rendered files, Template lock, bootstrap branch creation, and an unmerged
Draft PR. A second dispatch then proved the established repeat contract by failing
closed before creating competing state. The Draft PR and private visibility remained
unchanged.

### Zero correction budget is a safety boundary

`semantic_correction=0` correctly forced an owner decision when the published
workflow required tracked repair. The stop at roughly 25.984 minutes was an authority
boundary with a new diagnostic fact, not a no-progress loop. Wall-clock and unused
budgets in other domains could not finance that source change.

### Independent audit admission is part of the proof method

Starting an independent process consumes `audit_launch`, even when response-schema
admission fails before model execution. The original schema used constructs that were
valid general JSON Schema but outside the installed Codex structured-output subset;
an ephemeral session then made same-session recovery impossible.

The replacement Train first reproduced the missing-`type` rejection without starting
an Auditor, moved to an explicit-type closed schema, ran positive and negative
fixtures, rendered the same profile/sandbox/start message through a no-model
preflight, and removed ephemeral mode. A named primary Auditor then completed all
product and integrity Gates with zero findings. Its technical exact-main audit was
PASS, while formal clean audit remained false under the documented existing Codex
control-plane exception.

Named primary and contingency launches keep the exception narrow. A contingency is
only for a new deterministic pre-product-read admission defect after a `P2` packet
correction; a repeated signature stops. Later success does not erase the original
schema failure or its consumed launch.

## Train efficiency

The compressed Train reduced owner round trips by carrying accepted P3 checkpoints
forward and reusing exact-head, exact-main, release, and smoke evidence only after
their bindings were revalidated. It ran no duplicate canonical full Gate. Rerun and
correction history remained domain-specific instead of being flattened into one
retry count.

## Non-goals

This Retrospective does not define current budgets, create audit authority, authorize
tag movement, permit smoke publication or merge, or replace the active Harness,
Goal/Receipt Contract, condition-matched Playbooks, or machine-readable Profile.
