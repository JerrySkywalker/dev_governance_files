# Jerry Repository-Health Harness Specification V1

## Status

```text
MODEL_ID=JERRY_HARNESS_MODEL_V1
NORMATIVE=true
NUMERIC_SOURCE=config/repo-health-harness-v1.json
```

This document owns Harness semantics and state transitions. It does not own
Profile numbers.

## 1. Complete instance

```text
Harness Instance
  = <model_id, baseline_id, profile>
  + <A,B,P>
  + L
  + <V,E,F,G>
  + budget ledgers
  + admitted scope
  + durable receipt state
```

A flat `retry_count` is prohibited.

## 2. Control vector

### Authority `A`

| Code | Meaning |
| --- | --- |
| `A0` | observe only |
| `A1` | governance or metadata write |
| `A2` | declared repository source write |
| `A3` | declared multi-repository or isolated-runtime work |
| `A4` | protected runtime read-only |
| `A5` | protected runtime mutation |
| `OWNER` | credentials, identity, policy, or unsafe override |

Authority never increases because time elapsed, a Gate passed, a budget remains,
or a checkpoint was reached. `A4 -> A5` always requires explicit admission.

### Elasticity `B`

| Code | Meaning |
| --- | --- |
| `B0` | no autonomous continuation |
| `B1` | one-shot |
| `B2` | fixed bounded iteration |
| `B3` | checkpoint-renewable bounded iteration |
| `B4` | protected transactional elasticity |

A `B4` transaction may contain locally one-shot Apply or Finalize windows.

### Progress `P`

| Code | Meaning | Effect |
| --- | --- | --- |
| `P_INIT` | admitted, no cycle classified yet | consumes no no-progress budget |
| `P0` | no new reviewable fact | consumes no-progress budget |
| `P1` | new diagnostic fact | permits one bounded hypothesis |
| `P2` | new candidate or corrected binding | consumes correction budget and invalidates affected proof |
| `P3` | accepted checkpoint | may replenish declared windows, never lifetime caps |

New timestamps, attempt numbers, queue age, and raw lines mapping to the same
signature are not progress.

## 3. Proof vector

```text
Gate = <V,E,F,G>
```

### `V` — claim depth

`V0` static/governance; `V1` focused behavior; `V2` repository coherence;
`V3` platform behavior; `V4` real adjacent integration; `V5` deployed and
owner-visible acceptance; `V6` protected transaction and rollback; `V7`
Finalize, evidence binding, and closeout.

### `E` — environment

`E0` local portable; `E1` hosted portable CI; `E2` self-hosted platform CI;
`E3` composed integration lab; `E4` Canary/isolated runtime; `E5` protected
read-only; `E6` protected mutation.

Use the least privileged environment that can prove the claim.

### `F` — cadence

`F0` per edit; `F1` per candidate; `F2` once per final exact head; `F3` once per
accepted exact main; `F4` per release stage; `F5` scheduled/observational.

### `G` — criticality

`G0` advisory; `G1` candidate-blocking; `G2` merge/exact-head blocking; `G3`
protected-entry blocking; `G4` owner acceptance, Finalize, or closeout blocking.

## 4. Operational layers

| Layer | Entry | Exit |
| --- | --- | --- |
| `L0` edit feedback | changed input | fastest applicable Gate passes or candidate changes |
| `L1` candidate acceptance | candidate exists | focused claim accepted |
| `L2` exact-head acceptance | designated final head | canonical repository/platform/integration proof accepted |
| `L3` deployed acceptance | immutable package | technical and, when required, owner acceptance |
| `L4` protected transaction | explicit A4/A5 admission | accepted target or verified recovery |
| `L5` Finalize/closeout | accepted target | durable transaction and governance settlement |

Layers may be omitted when inapplicable. A failed layer returns to the narrowest
earlier layer that can correct the failure. A deeper pass does not imply an
omitted claim.

### 4.1 Development / production scope separation

An ordinary-development writer lease is a `DEVELOPMENT_TRAIN` lease. Its
ownership may include source code, tests, CI, Git/PR operations, documentation,
release preparation, release build/qualification, and immutable artifact
custody. It must exclude Stage0 publication, A4/A5 admission, production or
protected transaction execution, rollback, device mutation, and every
Owner-only production boundary.

A Goal that declares development work and any present, future, or conditional
protected operation is classified `MIXED_DEVELOPMENT_PRODUCTION_SCOPE` and
must return `REJECT_GOAL_BEFORE_WRITER_ACQUISITION`. “Conditional later A5” is
still mixed scope. The required topology is:

```text
DEVELOPMENT TRAIN
  -> canonical terminal release
  -> fresh protected admission
  -> separate production transaction
```

An ordinary-development allow-list must also exclude bare protected labels such
as `production`, `protected`, `Stage0`, `A4`, and `A5`; an incomplete label is
not a way to evade the pre-acquisition classifier.

The ordinary-development writer cannot acquire the separate production
transaction. The boundary is not a budget replenishment or a continuation.

## 5. Budget ledger

Every admitted domain has:

```text
window_cap
window_consumed
maximum_renewals
renewals_consumed
lifetime_cap
lifetime_consumed
unit
scope
reset_event
hard_stop_event
```

The active baseline explicitly defines zero-valued prohibited domains. Missing
fields must not be interpreted as permission.

### Counting

- source correction: candidate source bytes change;
- adjacent correction: declared neighboring contract changes;
- packet attempt: a final numbered packet begins;
- audit launch: an independent process starts;
- CI rerun: a new workflow run is queued;
- runner correction: runner state/configuration changes;
- Apply: protected mutation begins;
- rollback: restoration mutation begins;
- Finalize: transaction commit mutation begins;
- external watcher polls do not count as model wakeups.

Lifetime counters never decrease.

## 6. Replenishment

Only a declared `P3` event may replenish an eligible window. It never resets:

- authority;
- owner gates;
- lifetime caps;
- protected mutation counts;
- same-head same-signature history;
- sensitivity boundaries.

A verified rollback may reopen one declared Apply window only when budget
remains and a fresh backup is created where required.

## 7. No borrowing

Unused capacity in one domain cannot finance another. Examples:

- source corrections cannot become CI reruns;
- packet attempts cannot become Apply attempts;
- runner recovery cannot become product changes;
- preflight cannot become Finalize;
- wall-clock cannot expand scope.

## 8. Protected state machine

```text
ADMITTED_A5
  -> PREFLIGHTED
  -> PREPARED
  -> APPLIED_PENDING_ACCEPTANCE
  -> ACCEPTED
  -> FINALIZED
  -> CLOSED
```

Failure rules:

```text
preflight failure
  -> source/harness correction
  -> repeat read-only proof

prepare failure before mutation
  -> prepare correction
  -> no Apply consumed

Apply failure
  -> ROLLBACK_REQUIRED
  -> ROLLBACK_VERIFIED
  -> fresh backup
  -> next Apply only if lifetime remains

Finalize-preflight failure
  -> accepted target may remain pending Finalize
  -> source/harness correction
  -> no Apply or Finalize consumed
```

Failed or unverified rollback is a hard stop.

## 9. Evidence reuse

Evidence is reusable only while every bound fact remains unchanged. Exact-head
proof is invalid after head movement; platform proof is invalid after runner
contract change; adjacent proof is invalid after either implementation changes;
runtime evidence requires unchanged image, container, config, mount, route, and
rendered state; protected receipts remain bound to their plan domain and
transaction state.

## 10. Failure and stop semantics

Top-level dispositions:

```text
COMPLETE
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

Budget exhaustion alone normally produces `OWNER_DECISION_REQUIRED`.
`UNSAFE_BLOCKER` is reserved for safety, sensitivity, rollback, writer,
authority, or source-binding violations.

## 11. Precedence

1. this Specification's hard safety/state rules;
2. current Goal authority and scope;
3. Goal-bound baseline/profile;
4. valid declared overrides;
5. latest durable Receipt;
6. matching Playbooks;
7. Decisions;
8. historical evidence.
