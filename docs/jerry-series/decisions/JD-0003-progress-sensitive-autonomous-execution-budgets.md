# JD-0003: Progress-sensitive autonomous execution budgets

- Status: Accepted
- Scope: Jerry-series checkpointed execution Goals
- Date: 2026-07-30
- Implemented by: JD-0004 and `JERRY_HARNESS_MODEL_V1`

## Context

Long-running bounded Goals encounter tooling, packet, validation, CI, and
release interruptions after their product and safety boundaries are admitted.
Stopping for every operational interruption is inefficient; treating those
interruptions as unlimited authority is unsafe.

## Decision

```text
WIDE_OVERALL_EXECUTION_ENVELOPE=true
NARROW_MUTATION_SCOPE=true
BUDGETS_ARE_DOMAIN_SEPARATED=true
BUDGETS_ARE_PROGRESS_SENSITIVE=true
CHECKPOINTS_MAY_REPLENISH_ELIGIBLE_WINDOWS=true
LIFETIME_CAPS_NEVER_RESET=true
AUTHORITY_BOUNDARIES_NEVER_AUTO_EXPAND=true
```

Autonomous continuation is permitted only while the relevant domain ledger has
capacity and a reviewable `P1`, `P2`, or `P3` event supports the next bounded
hypothesis. Repeated identical outcomes consume the no-progress budget.

## Durable principles

- authority and operational capacity are separate;
- one domain cannot borrow from another;
- a checkpoint may replenish a window, never a lifetime cap;
- a same-head same-signature history is not reset by time or a checkpoint;
- failed protected mutation requires verified rollback before another Apply;
- owner-only credentials, identity, policy, and unsafe override remain owner-only.

## Top-level exits

```text
COMPLETE
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

Budget exhaustion normally means `OWNER_DECISION_REQUIRED`. Use
`UNSAFE_BLOCKER` only when continuation would violate safety, sensitivity,
rollback, writer, authority, or source-binding invariants.

## Normative implementation

Current semantics:
`../harness/harness-specification-v1.md`

Current numeric baseline:
`../../../config/repo-health-harness-v1.json`

Goal and Receipt fields:
`../harness/harness-goal-receipt-contract-v1.md`

This Decision records why the model exists; it is not a second numeric source.
