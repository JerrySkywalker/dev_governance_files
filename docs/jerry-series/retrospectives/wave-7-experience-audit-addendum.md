# Wave 7 Experience Audit Addendum — Graduated Budgets and Proof Architecture

## Classification

```text
classification: retrospective addendum
scope: second-pass audit of W7A, W7V, W7B-W7E, Post-W7 Dashboard work, Production release, Finalize, and closeout
related_repositories:
  - jerry-telemetry-agent
  - jerry-telemetry-hub
  - jerry-message-gateway
  - jerry-devops-android
  - jerry-glance-dashboard
  - jerry-wave7-train
  - dev_governance_files
sensitivity_notes: durable rules, public pull requests, sanitized statuses, and accepted hashes only
```

## Purpose

The first end-to-end retrospective correctly captured the principal incidents and
controls, but two abstractions remained too flat for future Waves:

1. elastic execution budgets were described mainly as domain counters and retry
   limits; and
2. CI and validation were described mainly as one depth ladder.

Wave 7 showed that neither concern is one-dimensional. This addendum records a
second-pass audit and replaces those simplified readings with reusable control
models.

This document supplements:

- `wave-7a-lessons.md`;
- `wave-7-lessons.md`;
- `wave-7-end-to-end-lessons.md`;
- `post-w7-dashboard-production-release-closeout.md`;
- `elastic-autonomous-execution-budget-pattern.md`; and
- `validation-depth-and-gate-selection.md`.

It does not reopen Wave 7 or authorize W8.

## Audit basis

The audit re-read the accepted chain rather than relying only on the final
summary:

- W7A Agent → Hub → Gateway → Android exact-chain work;
- W7V authenticated Canary and human visual validation;
- W7B-through-W7E compressed train closeout;
- Post-W7 production-shaped parity and UI hardening;
- Dashboard Production release PRs #75 through #87;
- Coordination closeout PR #45 and issue #42;
- governance closeout and knowledge-capture PRs;
- self-hosted runner failure and recovery evidence; and
- existing resume, blocker, evidence, CI, and autonomous-budget patterns.

The review used four questions:

```text
1. What claim was actually proved?
2. What authority was actually exercised?
3. What operational recovery was safe without new authority?
4. Which state transition made the next action legitimate?
```

## Wave 7 was a proof-system development program

The visible product outcome was a working Dashboard release, but the reusable
engineering result was broader:

```text
real adjacent contracts
  -> durable human-visible acceptance
  -> exact-source and exact-runtime binding
  -> bounded autonomous correction
  -> stateful self-hosted CI discipline
  -> protected transactional release
  -> idempotent recovery and Finalize
  -> durable governance closeout
```

The dominant failures were not random bugs. Most were mismatches between two
proof domains:

- a fixture and a real adjacent implementation;
- a technically green page and owner-visible product intent;
- an old runtime anchor and a target runtime anchor;
- a repository check and a platform-specific claim;
- a passing command and an unauthorized bootstrap path;
- an inner transaction receipt and an outer plan identifier;
- a logical runner label and usable physical capacity;
- a healthy runtime and a committed transaction state; or
- an accepted checkpoint and a Goal that still described an older frontier.

The central Wave 7 lesson is therefore:

```text
most late-stage failures are proof-binding failures before they are coding failures.
```

## Phase-by-phase experience

### W7A — real adjacent implementations

W7A established that independent repository green checks are insufficient for a
chain. The primary compatibility proof must preserve the real edge under test.
Fixtures may replace transport, external services, or fault injection, but they
must not replace both sides of the contract being accepted.

W7A also established that evidence legitimacy includes the tool and acquisition
path. A technically passing Android test was rejected because the Wrapper used an
unauthorized distribution path. Correct output through an unapproved bootstrap is
not admissible evidence.

Reusable controls:

- exact upstream and downstream source states;
- real adjacent producer and consumer;
- explicit attempt disposition;
- semantic task classification rather than lexical bans;
- supervised long-running child processes; and
- safe replay after a corrected acquisition path.

### W7V — technical correctness and owner acceptance

W7V made human-visible validation a first-class system boundary. It created an
isolated authenticated Canary, stable validation packets, desktop and mobile
screenshots, and an explicit owner decision.

The later Production-shaped Canary proved why this distinction matters: the
candidate could be technically correct and still be rejected for visual rhythm,
information hierarchy, or product intent.

Reusable controls:

- stable semantically owned selectors;
- independent-context authentication-state validation;
- exact deployment, container, mount, and packet identity;
- screenshot matrices bound to runtime anchors; and
- separate technical and owner-acceptance statuses.

### W7B-W7E — compressed execution without semantic collapse

The compressed train succeeded because the Waves retained distinct identities,
outcomes, and stop boundaries. W7C, W7D, and W7E could complete with no product
delta without being rewritten as missing work.

Reusable controls:

- exact-head and exact-main bindings;
- one accepted outcome per Wave;
- explicit `NO_PRODUCT_DELTA_REQUIRED` where appropriate;
- Combined Canary evidence across the accepted chain;
- independent acceptance after local validation; and
- a second owner visual review before closeout.

Compression is safe only when execution is compressed while proof identities
remain separate.

### Post-W7 parity and UI hardening — deterministic generation over runtime repair

The parity and UI interludes showed that browser-time DOM rewriting, inherited
selectors, and layout assumptions are weak contracts. Deterministic generation,
stable names, explicit markers, geometry checks, and immutable packages are more
reliable than one-shot runtime repair.

Reusable controls:

- generated semantics instead of timing-sensitive DOM mutation;
- stable route and page identities;
- source/generated parity checks;
- package manifests with exact hashes;
- Production-byte-equivalence assertions; and
- owner-visible preview before Production handoff.

### Production release PRs #75-#87 — release logic as a composed transaction

The Production release exposed a sequence of deterministic defects inside one
narrow, already authorized release surface:

```text
missing safe diagnostics
  -> OCI archive-shape assumptions
  -> output-key grammar mismatch
  -> interrupted-state classification
  -> target-versus-prior anchor confusion
  -> recovery readiness and idempotency
  -> Apply readiness polling
  -> subprocess output leakage
  -> complete Finalize target context
  -> inner receipt plan-domain binding
```

This sequence is the strongest evidence that one-PR, one-commit, or one-Apply
convenience limits are not a sufficient execution model for protected last-mile
work. The correct response is not unlimited authority. It is a finite,
transaction-aware budget model inside an immutable authority envelope.

Reusable controls:

- Inspect, Diagnose, Prepare, Apply, Accept, InspectFinalize, Finalize, Recover,
  and Closeout as explicit states;
- separate prior and target anchors;
- immutable image and real OCI graph verification;
- allowlisted output envelopes;
- same-container readiness polling;
- no-recreate recovery fast paths;
- idempotent rollback completion;
- real two-engine tests; and
- receipts bound to their own plan domains.

### Self-hosted CI incident — CI as a stateful execution system

The runner incident proved that CI trust includes physical runner state, process
ownership, queue topology, test synchronization, and observer discipline.

The same exact head failed repeatedly before passing unchanged after orphan
process cleanup. At the same time, multiple workflows repeated the same full
command graph on one Windows runner, while scheduled smoke competed for the same
capacity.

Reusable controls:

- repository-specific online-and-idle proof;
- job-owned process trees and recursive cleanup;
- sentinels and condition polling instead of narrow sleeps;
- one canonical full exact-head gate;
- path-sensitive focused gates;
- one unchanged-head rerun per sanitized signature;
- external low-frequency state-transition watching; and
- scheduled work isolated from required scarce capacity.

### Closeout — completion is a state transition, not a narrative claim

Wave 7 completed only after runtime Finalize, post-Finalize proof, coordination
and governance closeout, issue closure, branch retirement, lease release, Keeper
stop, retained rollback proof, and knowledge capture.

A successful Apply is not a complete release. A successful merge is not a
complete train. Completion requires the accepted state to be durably bound and
all execution ownership to be settled.

## Refined abstraction 1 — elastic budgets are a three-layer control system

The earlier wording could be read as “allow more retries.” Wave 7 supports a
stricter model:

```text
Layer 1: immutable authority envelope
Layer 2: finite operational budget ledger
Layer 3: progress and replenishment state machine
```

### Layer 1 — immutable authority envelope

The authority envelope answers what may be touched. It cannot be expanded by
success, elapsed time, repeated failures, or checkpoint replenishment.

Recommended authority classes:

| Class | Meaning | Typical Wave 7 example |
| --- | --- | --- |
| A0 | Observe only | repository and runtime inspection |
| A1 | Governance or metadata write | lesson capture and closeout documents |
| A2 | Declared repository source write | focused Dashboard correction |
| A3 | Declared multi-repository or isolated-runtime work | W7A chain or Canary |
| A4 | Protected runtime read-only | Production Inspect or Finalize preflight |
| A5 | Protected runtime mutation | Prepare, Apply, Recover, Finalize |
| OWNER | Never autonomous | credential acquisition, identity or policy decision |

Moving from A2 to A3, or from A4 to A5, is a new authority decision. No retry
budget can perform that transition.

### Layer 2 — operational elasticity grade

The elasticity grade answers how the admitted work may continue:

| Grade | Behavior | Use |
| --- | --- | --- |
| B0 | no autonomous continuation | owner-only or unsafe boundary |
| B1 | one-shot | unique protected or irreversible operation |
| B2 | fixed bounded iteration | attended focused correction |
| B3 | checkpoint-renewable iteration | long-running, narrow, non-protected work |
| B4 | transactional elasticity | protected work with separate preflight, Apply, rollback, and Finalize budgets |

B3 and B4 are not infinite. Every domain requires:

```text
window_cap
maximum_renewals
lifetime_cap
reset_event
hard_stop_event
```

A checkpoint may replenish a window while the lifetime cap continues to count.
This prevents “reset after every checkpoint” from becoming an unbounded loop.

### Layer 3 — progress state

Only reviewable state changes justify continued autonomy:

| State | Meaning | Effect |
| --- | --- | --- |
| P0 | no new fact | consumes no-progress budget |
| P1 | new diagnostic fact | may justify a bounded hypothesis |
| P2 | new candidate or corrected binding | consumes correction budget and requires fresh proof |
| P3 | accepted checkpoint | may replenish declared transient windows |

A new timestamp, attempt number, queue age, or raw log line is not progress. An
accepted exact-main, sealed packet, completed independent audit, verified
rollback, or accepted runtime state is progress.

### Protected transaction invariant

For A5/B4 work:

```text
failed Apply
  -> rollback required
  -> rollback verified
  -> fresh backup and fresh Apply budget
```

A read-only preflight failure does not consume an Apply. An Apply budget cannot
be borrowed from a source-correction or CI-rerun budget. A failed rollback is a
hard stop.

The normative details are recorded in the revised
`elastic-autonomous-execution-budget-pattern.md`.

## Refined abstraction 2 — CI and validation are a vector, not a ladder

The earlier D0-D7 model remains useful for the claim being proved, but it is not
sufficient as a CI taxonomy. Wave 7 requires four independent axes:

```text
Gate = <proof depth, execution environment, cadence, criticality>
```

### Axis 1 — proof depth

This answers what the evidence proves:

| Code | Claim |
| --- | --- |
| V0 | static and governance consistency |
| V1 | focused deterministic behavior |
| V2 | repository candidate coherence |
| V3 | platform-specific behavior |
| V4 | real adjacent-implementation integration |
| V5 | deployed runtime and owner-visible acceptance |
| V6 | protected transaction and rollback safety |
| V7 | Finalize, evidence binding, and closeout |

### Axis 2 — execution environment

This answers where the proof is obtained:

| Code | Environment |
| --- | --- |
| E0 | local portable |
| E1 | hosted portable CI |
| E2 | self-hosted platform CI |
| E3 | composed integration lab |
| E4 | Canary or isolated runtime |
| E5 | protected runtime read-only |
| E6 | protected runtime mutation |

### Axis 3 — cadence

This answers how often the gate should run:

| Code | Cadence |
| --- | --- |
| F0 | per edit or tight implementation loop |
| F1 | per candidate correction |
| F2 | once per final exact head |
| F3 | once per accepted exact main |
| F4 | once per release transaction or stage |
| F5 | scheduled or observational |

### Axis 4 — criticality

This answers what the result blocks:

| Code | Criticality |
| --- | --- |
| G0 | advisory |
| G1 | candidate acceptance |
| G2 | merge or exact-head acceptance |
| G3 | protected-entry gate |
| G4 | owner acceptance, Finalize, or closeout |

Examples:

```text
focused parser loop        = <V1,E0,F0,G0>
canonical repository gate  = <V2,E1-or-E2,F2,G2>
Windows atomic-move proof  = <V3,E2,F2,G2>
Agent-to-Android chain      = <V4,E3,F2,G2>
Canary visual acceptance   = <V5,E4,F4,G4>
Production preflight       = <V6,E5,F4,G3>
Production Apply           = <V6,E6,F4,G4>
Finalize and closeout      = <V7,E5-or-E6,F4,G4>
scheduled smoke            = <declared V,E,F5,G0-or-G1>
```

This prevents four recurrent errors:

1. calling every automated job “CI” without naming its claim;
2. running portable checks on a scarce platform runner;
3. repeating one full graph in several required contexts; and
4. treating scheduled smoke or a repository gate as Production evidence.

The normative vector and selection rules are recorded in the revised
`validation-depth-and-gate-selection.md`.

## Refined blocker interpretation

A useful blocker is a frontier receipt, not merely a stop message.

Required fields:

```text
last_accepted_checkpoint
current_authority_class
current_budget_grade
proof_vector
new_frontier
failure_signature
state_changed
budget_consumed
budget_remaining
next_required_decision
```

The Wave 7 Production sequence contained many blockers, but most represented
progress because the frontier moved. Repeated identical CI signatures and
unchanged polling did not.

## Refined Goal defaults for future Waves

A future long-running Goal should declare:

```text
LAST_ACCEPTED_CHECKPOINT=<durable pointer>
ACCEPTED_DELTA=<one new fact>
AUTHORITY_CLASS=<A0-A5 or OWNER>
ELASTICITY_GRADE=<B0-B4>
MUTATION_SURFACES=<exact paths/services/repositories>
BUDGET_LEDGER=<domain window, renewals, lifetime cap>
PROGRESS_EVENTS=<P1-P3 definitions>
VALIDATION_VECTOR=<V,E,F,G>
HARD_STOPS=<immutable list>
COMPLETION_STATE=<durable target>
```

The Goal should not copy the full historical chronology. It should point to the
accepted history and describe only the new delta.

## Final audit conclusions

The Wave 7 experience can be condensed into ten durable principles:

1. real adjacent implementations prove interfaces;
2. admissible evidence includes its acquisition path;
3. technical acceptance and human acceptance are separate;
4. deterministic generated contracts outperform timing-sensitive repair;
5. authority never expands through retries;
6. operational elasticity needs window, renewal, and lifetime caps;
7. CI must declare claim, environment, cadence, and criticality;
8. protected release logic is a composed state machine;
9. rollback and Finalize are product capabilities; and
10. closeout is part of the delivered state.

The two most important meta-rules are:

```text
fail closed at authority boundaries;
continue elastically inside a narrow admitted surface only while reviewable progress exists.
```

and:

```text
run the smallest gate that can reject the current edit quickly;
run the deepest applicable proof once for the accepted state.
```

## Operational boundary

This addendum records governance knowledge only. It does not authorize product,
workflow, runner, runtime, credential, authentication, Production, W8, or W9
changes.