# Wave 7 Retrospective — Compressed Train Lessons

## Classification

```text
classification: retrospective
scope: W7-COMPRESSED-001 closeout and reusable governance lessons
related_waves:
  - W7B
  - W7C
  - W7D
  - W7E
related_repositories:
  - jerry-wave7-train
  - jerry-glance-dashboard
  - dev_governance_files
sensitivity_notes: durable outcomes and controls only; no raw logs, authentication state, or protected evidence
```

## Factual outcome

`W7-COMPRESSED-001` is complete. W7B delivered a minimal product correction;
W7C, W7D, and W7E completed without product deltas. The Combined Canary
validation passed, the required second owner visual review was accepted with
zero findings, and Production remained unchanged. Wave 7's retrospective is
complete; W8 and W9 have not started.

The only mandatory follow-up carried from closeout is
`CANARY_DEPLOY_VALIDATION_API_RECREATE_HARDENING=REQUIRED`. It is backlog, not
authorization for a runtime, deployment, product, W8, or W9 action.

## What worked

- Distinct Wave identities and outcomes kept a compressed train from turning
  into one undifferentiated success claim.
- Exact-head and exact-main bindings, real adjacent-implementation replay, and
  independent acceptance exposed defects that isolated green checks could not.
- Narrow owner decisions permitted a deterministic correction while preserving
  Canary isolation, Production anchors, and the stop boundaries.
- The Combined Canary packet made the accepted Wave outcomes, deployment
  identity, and human-visible semantics reviewable together.
- A second owner visual review separated technical readiness from actual
  acceptance.

## Repeated blockers and their causes

Several blockers repeated because an execution boundary had drifted while the
Goal still described an earlier state:

- ambient runtime or service context differed from the bound runtime contract;
- a broad historical Goal repeated completed context instead of pointing to the
  last accepted state and describing only the new delta;
- the authentication manifest targeted a superseded page marker rather than a
  stable, unique Combined Canary selector;
- a current-release switch did not by itself refresh a service's prior
  bind-mounted packet; and
- logical CI labels were treated too casually as evidence of usable physical
  runner capacity.

The correction is not to weaken admission. It is to bind the next bounded Goal
to durable state, state the permitted adjacent fix in advance, and prove the
current runtime topology before proceeding.

## Fail-closed benefits and costs

Fail-closed checks prevented a stale mounted packet, a stale selector, or an
unproven runner from being misreported as a valid deployment or CI result. They
also preserved the boundaries against Production mutation, unbounded auth
retries, and speculative product changes.

The cost was real: each mismatch stopped progress, consumed a narrow decision
or correction budget, and required fresh proof after the bounded repair. That
cost is acceptable only when the Goal is compact enough that completed history
is not repeatedly re-read or re-argued.

## Token and context efficiency

Full-history resume Goals create needless context growth: they repeat prior
admission, decisions, receipts, and rejected paths even when none changes the
next action. This obscures the current boundary and increases review effort.

Future resume Goals should use durable-state pointers and a compact Accepted
Delta as defined in the [Incremental Resume Goal Pattern](../patterns/incremental-resume-goal-pattern.md).
They should state the last accepted checkpoint, the one new fact, the exact
allowed change, and the next validation boundary; the full history remains
addressable rather than copied forward.

## CI runner lifecycle finding

Self-hosted CI needs repository-specific lifecycle proof. A logical label does
not prove that a physical runner is online, idle, correctly configured for the
repository, or has a separate work root available for the job. Before queuing a
gate, record a sanitized service inventory, prove online-and-idle state, and
classify queue age rather than manufacturing a retrigger with an empty commit.

The [Self-hosted CI Playbook](../playbooks/self-hosted-ci-playbook.md) now
defines this inventory, capacity, and queue-age discipline.

## Deployment bind-mount lifecycle finding

An immutable release and a correctly switched current-release symlink are
necessary but not sufficient. A long-lived container can retain a bind mount
from a prior release. Acceptance must prove the release, symlink, container
identity, bind-mount source, mounted file hashes, API-reported semantics, and
deployed/accepted build SHA as one chain.

The [Canary Runtime Binding Playbook](../playbooks/canary-runtime-binding-playbook.md)
requires that chain and makes a mismatch fail closed. The post-W7 backlog must
make validation-api recreation deterministic after a release switch, or replace
the mutable binding with an immutable content-addressed mount.

## Auth selector contract finding

Authentication automation must bind to a stable, unique, semantically owned
selector that the deployed Combined Canary page guarantees. A selector copied
from a prior layout is not a durable contract. Manifest, marker generation,
and focused parser tests must prove the same selector; any adjacent fix remains
limited to a deterministic binding defect and its declared budget.

## Mandatory post-W7 backlog

`CANARY_DEPLOY_VALIDATION_API_RECREATE_HARDENING=REQUIRED` must be handled by a
future, separately authorized Goal. It must choose one deterministic lifecycle
model:

1. force-recreate the validation API after the current-release switch; or
2. bind the validation API to an immutable content-addressed release mount.

That Goal must use the runtime-binding proof chain, preserve rollback behavior,
and keep the work separate from W8 and W9 unless a later owner decision changes
their authorization.

## Operational boundary

This retrospective records reusable governance lessons only. It does not
authorize product changes, CI runner changes, runtime changes, authentication
state handling, deployment, or the start of another Wave.
