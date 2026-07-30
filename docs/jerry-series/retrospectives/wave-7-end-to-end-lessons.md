# Wave 7 End-to-End Retrospective

## Classification

```text
classification: retrospective
context_class: HISTORICAL_REFERENCE
normative: false
active_defaults: false
execution_from_code_blocks: prohibited
scope: W7A through Post-W7 Production Finalize and closeout
```

This document explains the evidence behind the unified Harness. Active semantics
and numbers live under `../harness/` and `../../../config/`.

## Final disposition

```text
WAVE7_AND_POST_W7_DASHBOARD_WORK=COMPLETE
RUNNING_GLANCE_VERSION=v0.8.5
CONFIG_TRANSACTION_STATUS=applied
RELEASE_JOURNAL_STATUS=applied_accepted
W8_ENTRY_GATE=READY
W8_STARTED=false
W9_STARTED=false
```

These facts do not reopen Wave 7 or authorize later work.

## Wave 7 as a proof-system program

The visible result was a Dashboard release. The reusable result was:

```text
real adjacent contracts
  -> human-visible acceptance
  -> exact source/runtime binding
  -> bounded autonomous correction
  -> stateful self-hosted CI
  -> protected transactional release
  -> idempotent recovery and Finalize
  -> durable closeout
```

Most late failures were proof-binding failures before they were coding failures:
fixture versus real implementation, technical pass versus owner intent, old
anchor versus target anchor, repository Gate versus platform claim, passing
output versus unauthorized acquisition path, inner Receipt versus outer plan,
logical runner label versus physical capacity, or healthy runtime versus
committed transaction state.

## Phase lessons

### W7A — real adjacent implementations

Independent green repositories did not prove Agent → Hub → Gateway → Android.
The accepted proof kept the real producer and consumer on each accepted edge.
Fixtures remained appropriate for external transport and negative cases, not as
both sides of the contract.

A technically passing Android test was rejected when its Wrapper used an
unapproved acquisition path. Correct output, authorized tool path, exact source,
and explicit evidence disposition were all required.

### W7V — technical and owner acceptance

Authenticated Canary, portable authentication-state validation, stable
selectors, exact runtime anchors, desktop/mobile screenshots, and explicit owner
review became separate first-class controls. A technically green candidate could
still be rejected for product intent or visual hierarchy.

### W7B-W7E — compressed execution without semantic collapse

Execution could be compressed only because Wave identities, outcomes,
checkpoints, and stop boundaries remained separate. `NO_PRODUCT_DELTA_REQUIRED`
was a valid result rather than missing work.

### Post-W7 UI — deterministic generation

Browser-time DOM rewriting and inherited selectors were weaker than generated
semantics, stable names, explicit markers, source/generated parity, immutable
packages, and owner-visible preview.

### Production PRs #75-#87 — composed transaction

The release exposed sequential defects in diagnostics, OCI semantics, output
protocols, interrupted state, prior/target anchors, readiness, recovery
idempotency, Finalize context, and nested plan-domain binding.

The lesson was not “allow thirteen retries.” It was to separate Inspect,
Prepare, Apply, acceptance, rollback, Finalize-preflight, Finalize, and closeout
inside an immutable authority envelope.

### Self-hosted CI incident

Runner trust included physical capacity, process ownership, cleanup, queue
topology, timing synchronization, duplicate Gates, and observer discipline.
The same exact head passing after orphan cleanup justified one classified rerun,
not unlimited repetition.

### Closeout

Completion required Finalize, post-Finalize proof, coordination/governance
settlement, issue closure, branch retirement, lease release, Keeper stop,
rollback retention, and lesson capture.

## Refined Harness abstractions

### Control vector

```text
<A,B,P>
```

`A` separates authority; `B` separates fixed, renewable, and transactional
elasticity; `P_INIT/P0-P3` separates admission, no progress, diagnosis,
candidate change, and accepted checkpoint.

### Proof vector

```text
<V,E,F,G>
```

Proof depth, environment, cadence, and criticality are independent. “CI” alone
does not state a claim.

### Operational layer

```text
L0 edit
L1 candidate
L2 exact head
L3 deployed acceptance
L4 protected transaction
L5 Finalize/closeout
```

### Budget principle

Window renewal never resets lifetime, authority, owner gates, protected counts,
or same-signature history. Unused budget in one domain cannot fund another.

## Durable release lessons

- prior and target anchors are distinct;
- image identity is a descriptor graph, not one generic SHA;
- protected output is an allowlisted protocol;
- rollback restores runtime and transaction truth;
- already-correct runtime needs an idempotent no-recreate path;
- read-only Finalize preflight prevents unnecessary rollback;
- composed transactions need real engines on the boundary under test;
- nested Receipts use their own plan domains;
- evidence reuse requires unchanged anchors;
- one writer and owner-controlled authentication remain mandatory;
- product closeout and later CI redesign are separate decisions.

## Normative extraction

The accepted rules were extracted to:

- `../harness/harness-specification-v1.md`;
- `../harness/harness-baseline-v1.md`;
- `../harness/harness-goal-receipt-contract-v1.md`;
- `../../../config/repo-health-harness-v1.json`;
- `../decisions/JD-0004-unified-harness-control-contract.md`.

This retrospective must not be used as an active parameter source.
