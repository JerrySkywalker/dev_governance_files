# Elastic Autonomous Execution Budget Pattern

## Classification

```text
classification: pattern
scope: bounded autonomous continuation after an admitted checkpoint
related_repositories:
  - dev_governance_files
sensitivity_notes: record only durable counters and sanitized classifications
```

## Purpose

Permit routine recovery and deterministic correction to continue without repeated
owner round trips, while preventing operational retries from becoming new
authority.

The pattern applies only after an immutable admission boundary has declared:

- the allowed repositories, files, services, and runtime surfaces;
- the protected and owner-controlled boundaries;
- the required proof classes;
- the rollback contract; and
- the completion or stop state.

The pattern is not “more retries.” It is a three-layer control system:

```text
immutable authority envelope
  + finite domain budget ledger
  + progress-sensitive replenishment state machine
```

## Core invariants

```text
AUTHORITY_NEVER_EXPANDS_AUTOMATICALLY=true
BUDGET_DOMAINS_NEVER_BORROW_FROM_EACH_OTHER=true
CHECKPOINT_REPLENISHMENT_HAS_A_LIFETIME_CAP=true
IDENTICAL_FAILURE_IS_NOT_PROGRESS=true
PROTECTED_RETRY_REQUIRES_VERIFIED_ROLLBACK=true
OWNER_ONLY_ACTIONS_REMAIN_OWNER_ONLY=true
```

A budget controls how admitted work continues. It never answers whether the work
was authorized in the first place.

## Layer 1 — authority classes

Every autonomous Goal must declare exactly one current authority class. A later
stage may move to a higher class only through an explicit owner decision or a
previously admitted transition written into the Goal.

| Class | Authority | Typical operations | Automatic expansion |
| --- | --- | --- | --- |
| A0 | observe only | inspect repositories, CI, runtime, evidence metadata | never |
| A1 | governance or metadata write | plans, receipts, retrospectives, closeout | never |
| A2 | declared repository source write | focused implementation and tests in named repositories | never |
| A3 | declared multi-repository or isolated-runtime work | adjacent integration, package creation, Canary | never |
| A4 | protected runtime read-only | Production inspect, diagnostics, preflight | never |
| A5 | protected runtime mutation | Prepare, Apply, Recover, Finalize | never |
| OWNER | owner-only | credential acquisition, identity, policy choice, unsafe override | not autonomous |

### Authority transition rules

```text
A0 -> A1/A2/A3/A4/A5 requires declared admission
A2 -> A3 requires declared cross-repository or runtime scope
A4 -> A5 requires explicit protected-mutation authorization
ANY -> OWNER requires owner action
```

Success, elapsed time, a green CI run, a completed audit, or an exhausted
convenience counter cannot raise the authority class.

## Layer 2 — elasticity grades

The elasticity grade describes how operational budgets behave inside the current
authority class.

| Grade | Meaning | Normal use |
| --- | --- | --- |
| B0 | no autonomous continuation | unsafe, owner-only, or unresolved authority boundary |
| B1 | one-shot | unique protected or irreversible action |
| B2 | fixed bounded iteration | attended, focused correction |
| B3 | checkpoint-renewable iteration | long-running narrow work with durable checkpoints |
| B4 | protected transactional elasticity | protected work with separate preflight, Apply, rollback, and Finalize budgets |

### B0 — hard stop

Use when the next action could:

- acquire or expose credentials or identity material;
- change authentication or authorization policy;
- touch an unrelated service or repository;
- proceed without a complete old-state or target-state proof;
- continue after an unverified rollback;
- publish sensitive output;
- violate a one-writer or transaction lease; or
- exceed an explicit lifetime hard cap.

B0 produces `OWNER_DECISION_REQUIRED` or `UNSAFE_BLOCKER`. It is not replenished.

### B1 — one-shot

Use when one admitted action is intentionally unique. Examples include one
explicit owner-approved Production Apply or one irreversible publication step.

A failed B1 action does not automatically become B2. A new attempt requires the
Goal's declared recovery transition and, for protected work, verified rollback
plus a fresh backup.

### B2 — fixed bounded iteration

Use for attended work where a compact stop receipt can be reviewed promptly.
Counters have a finite window and no automatic checkpoint renewal.

Typical uses:

- focused source correction;
- one adjacent deterministic repair;
- packet or schema repair;
- one classified CI rerun; and
- evidence access recovery.

### B3 — checkpoint-renewable iteration

Use for unattended or long-running work with a wide execution envelope but a
narrow mutation surface.

A declared accepted checkpoint may replenish selected transient windows. It does
not reset:

- authority class;
- safety boundaries;
- owner gates;
- lifetime caps;
- protected mutation counts; or
- a same-head same-signature failure history.

### B4 — protected transactional elasticity

Use only inside A5 with explicit protected-mutation authorization.

B4 separates:

```text
read_only_preflight
prepare
apply
acceptance
rollback
finalize_preflight
finalize
closeout
```

The budgets are independent. A read-only preflight failure does not consume an
Apply. An Apply failure does not authorize another Apply until rollback is
verified and the contract requires a fresh backup or explicitly safe continuation.

## Layer 3 — progress states

Autonomous continuation depends on reviewable progress, not activity.

| State | Meaning | Examples | Budget effect |
| --- | --- | --- | --- |
| P0 | no new fact | same signature, timestamp-only change, unchanged CI poll | consumes no-progress budget |
| P1 | new diagnostic fact | new safe failure stage, runner inventory, archive shape | permits one bounded hypothesis |
| P2 | new candidate state | changed tree, corrected binding, new sealed packet | consumes correction budget; requires fresh proof |
| P3 | accepted checkpoint | exact-main accepted, audit complete, rollback verified | may replenish declared transient windows |

### Progress rules

Progress must be monotonic and reviewable. Valid progress events include:

- a different candidate tree;
- a successful focused preflight;
- a sealed evidence packet;
- a completed independent audit;
- a verified runner cleanup;
- a verified rollback;
- an accepted exact-main checkpoint; or
- a newly accepted runtime or transaction state.

The following are not progress:

- a new attempt number;
- a new timestamp;
- queue age changing without a state transition;
- a raw log line that maps to the same sanitized signature;
- rerunning an unchanged head without a bounded hypothesis; or
- recreating an already exact healthy runtime.

## Budget ledger schema

Every counter must declare more than a single maximum:

```text
budget_domain
window_cap
window_consumed
maximum_renewals
renewals_consumed
lifetime_cap
lifetime_consumed
reset_event
hard_stop_event
```

Example:

```text
source_correction:
  window_cap=3
  maximum_renewals=2
  lifetime_cap=9
  reset_event=ACCEPTED_EXACT_MAIN
  hard_stop_event=LIFETIME_CAP_EXHAUSTED
```

A checkpoint can restore the window, but the lifetime counter continues. This
prevents repeated resets from creating an unbounded run.

## Mandatory budget domains

Every Goal that allows autonomous continuation must explicitly classify the
applicable domains. Use zero where a domain is prohibited.

| Domain | Controls | Never authorizes |
| --- | --- | --- |
| authority | repositories, paths, services, owner gates | scope expansion |
| semantic correction | in-scope candidate changes | product-policy or desired-state change |
| adjacent correction | declared neighboring contract fixes | a new repository or interface |
| evidence packet | methods, preflights, sealed attempts | candidate changes for easier evidence |
| auditor process | independent content reviews | converting runtime failure into PASS |
| schema and access | output contract and evidence accessibility | source-state changes |
| CI transient | actually queued no-change reruns | hiding deterministic failure |
| runner environment | narrow service or toolchain recovery | product edits or hosted fallback |
| runtime preflight | read-only runtime inspection | protected mutation |
| Prepare | backup and candidate staging | Apply |
| Apply | protected mutation attempts | unrelated runtime work |
| rollback | restoration attempts | accepting an unproven state |
| Finalize | transaction commit attempts | changing accepted product semantics |
| observer | model wakeups and state reads | CI mutation |
| wall clock | total autonomous duration | authority extension |
| no progress | repeated identical outcomes | additional retries without a hypothesis |

Budgets are recorded separately. There is no generic `retry_count`.

## No borrowing rule

One budget domain cannot finance another.

Examples:

- unused packet attempts cannot become Apply attempts;
- unused source corrections cannot become CI reruns;
- unused preflights cannot become Finalize mutations;
- unused runner corrections cannot become product fixes; and
- unused wall-clock time cannot expand scope.

If the correct domain is exhausted, stop or use an explicit scoped owner
override. Do not relabel the operation.

## Default profiles

Profiles instantiate the authority and elasticity model. They are defaults, not
implicit permission.

### DOCS_CAPTURE_V1

```text
AUTHORITY_CLASS=A1
ELASTICITY_GRADE=B2
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=2
SOURCE_CORRECTION_WINDOW=3
SOURCE_CORRECTION_MAX_RENEWALS=0
SOURCE_CORRECTION_LIFETIME=3
AUDIT_ATTEMPT_WINDOW=2
AUDIT_ATTEMPT_LIFETIME=2
PROTECTED_RUNTIME_CONTACT=false
```

Use for governance-only lesson capture, plans, and closeout documents.

### INTERACTIVE_DEFAULT_V2

```text
AUTHORITY_CLASS=A2_OR_DECLARED_A3
ELASTICITY_GRADE=B2
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=4

SOURCE_CORRECTION_WINDOW=3
SOURCE_CORRECTION_MAX_RENEWALS=0
SOURCE_CORRECTION_LIFETIME=3

ADJACENT_FIX_WINDOW=2
ADJACENT_FIX_LIFETIME=2

PACKET_METHOD_WINDOW=3
PACKET_ATTEMPT_WINDOW=6
AUDIT_ATTEMPT_WINDOW=4
SCHEMA_REPAIR_WINDOW=2

TRANSIENT_CI_RERUN_WINDOW=2
SAME_HEAD_SAME_SIGNATURE_RERUN_WINDOW=1
RUNNER_ENVIRONMENT_CORRECTION_WINDOW=2

NO_PROGRESS_WINDOW=2
STOP_BEFORE_OWNER_GATE=true
```

Use for attended source work with prompt owner review.

### OVERNIGHT_SAFE_V2

```text
AUTHORITY_CLASS=DECLARED_A2_OR_A3
ELASTICITY_GRADE=B3
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=8

SOURCE_CORRECTION_WINDOW=3
SOURCE_CORRECTION_MAX_RENEWALS=1
SOURCE_CORRECTION_LIFETIME=6

ADJACENT_FIX_WINDOW=2
ADJACENT_FIX_MAX_RENEWALS=1
ADJACENT_FIX_LIFETIME=4

PACKET_METHOD_WINDOW=4
PACKET_PREFLIGHTS_PER_METHOD_WINDOW=4
PACKET_ATTEMPT_WINDOW=6
PACKET_ATTEMPT_MAX_RENEWALS=1
PACKET_ATTEMPT_LIFETIME=10

AUDIT_ATTEMPT_WINDOW=4
AUDIT_ATTEMPT_MAX_RENEWALS=1
AUDIT_ATTEMPT_LIFETIME=8
SCHEMA_REPAIR_LIFETIME=4
EVIDENCE_ACCESS_RECOVERY_LIFETIME=5

TRANSIENT_CI_RERUN_LIFETIME_PER_WORKFLOW=3
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
RUNNER_ENVIRONMENT_CORRECTION_LIFETIME=3

IDENTICAL_FAILURE_SIGNATURE_LIFETIME=2
NO_PROGRESS_WINDOW=2

CI_WATCH_INITIAL_INTERVAL_MINUTES=5
CI_WATCH_LONG_INTERVAL_MINUTES=10
CI_WATCH_LONG_INTERVAL_AFTER_MINUTES=30
MODEL_CI_NO_CHANGE_WAKEUP_LIFETIME=3

AUTO_CONTINUE_AFTER_ACCEPTED_CHECKPOINT=true
STOP_BEFORE_OWNER_GATE=true
```

Use only when the mutation surface and completion checkpoints are explicit.

### PROTECTED_PREFLIGHT_V1

```text
AUTHORITY_CLASS=A4
ELASTICITY_GRADE=B3
RUNTIME_PREFLIGHT_WINDOW=3
RUNTIME_PREFLIGHT_LIFETIME=6
PREPARE_ATTEMPTS=0
APPLY_ATTEMPTS=0
ROLLBACK_ATTEMPTS=0
FINALIZE_ATTEMPTS=0
STOP_BEFORE_PROTECTED_MUTATION=true
```

Use for Production inspect and non-mutating diagnostics. A successful A4 result
does not imply A5 authority.

### PROTECTED_TRANSACTION_V1

```text
AUTHORITY_CLASS=A5
ELASTICITY_GRADE=B4
EXPLICIT_OWNER_AUTHORIZATION_REQUIRED=true

PREPARE_WINDOW=2
PREPARE_LIFETIME=4
APPLY_WINDOW=1
APPLY_MAX_RENEWALS=1
APPLY_LIFETIME=2
ROLLBACK_WINDOW=1
ROLLBACK_LIFETIME=2
FINALIZE_PREFLIGHT_WINDOW=3
FINALIZE_PREFLIGHT_LIFETIME=6
FINALIZE_WINDOW=1
FINALIZE_MAX_RENEWALS=1
FINALIZE_LIFETIME=2

FRESH_BACKUP_BEFORE_EACH_FRESH_APPLY=true
VERIFIED_ROLLBACK_BEFORE_NEXT_APPLY=true
FAILED_ROLLBACK_HARD_STOP=true
STOP_BEFORE_OWNER_CREDENTIAL_OR_POLICY_GATE=true
```

The exact numeric values may be reduced for a narrower transaction. They must not
be increased implicitly after execution begins.

## Counting rules

Apply these rules consistently:

- A source correction counts only when candidate source bytes change.
- An adjacent correction counts when a declared neighboring contract changes.
- An Auditor attempt counts only after an independent process starts.
- A packet attempt counts only after a final numbered packet directory begins.
- A packet-method preflight does not consume a packet attempt.
- A CI rerun counts only when a new workflow run is actually queued.
- A same-head same-signature rerun consumes both transient-CI and signature
  budgets.
- A runner correction counts only when runner state or configuration changes.
- A runtime preflight does not consume Prepare, Apply, rollback, or Finalize.
- An Apply counts only when protected mutation begins.
- A rollback counts only when restoration mutation begins.
- A Finalize preflight does not consume Finalize.
- A model wakeup counts only when the model resumes to inspect unchanged state;
  external watcher polls do not count.
- The lifetime counter never decreases.

## Replenishment rules

Only a declared P3 event may replenish a transient window.

```text
new candidate tree
  -> increment source or adjacent correction lifetime counter
  -> reset focused proof for the affected candidate
  -> do not replenish CI or protected mutation automatically

accepted stage exact-main
  -> may replenish packet, audit, schema, runner, and transient-CI windows
  -> do not reset lifetime counters
  -> do not reset authority or safety boundaries

verified rollback
  -> may reopen one declared fresh Apply window
  -> requires a fresh backup when the contract says so

owner override
  -> append-only
  -> exact domain and purpose
  -> explicit expiry or consumption
  -> never silent
```

An unchanged head does not reset the same-signature counter merely because load,
timestamps, or attempt numbers changed.

## Protected transaction state machine

```text
ADMITTED_A5
  -> PREFLIGHTED
  -> PREPARED
  -> APPLIED_PENDING_ACCEPTANCE
  -> ACCEPTED
  -> FINALIZED
  -> CLOSED
```

Failure transitions:

```text
PREFLIGHT_FAILURE
  -> source/harness correction within budget
  -> repeat preflight

PREPARE_FAILURE_BEFORE_MUTATION
  -> prepare correction within budget
  -> no Apply consumed

APPLY_FAILURE
  -> ROLLBACK_REQUIRED
  -> ROLLBACK_VERIFIED
  -> fresh backup
  -> next Apply only if budget remains

FINALIZE_PREFLIGHT_FAILURE
  -> target may remain accepted and pending Finalize
  -> source/harness correction within budget
  -> no Apply or Finalize consumed

FINALIZE_FAILURE_AFTER_MUTATION
  -> follow declared recovery state machine
  -> never improvise acceptance or rollback semantics
```

## CI observation budget

CI waiting must be delegated to a finite external watcher whenever the expected
next event is only a workflow state transition.

Recommended schedule:

```text
0_to_30_minutes:
  watcher_poll_interval=5m

30_minutes_and_later:
  watcher_poll_interval=10m

model_wakeup_conditions:
  - queued_to_in_progress
  - in_progress_to_success
  - in_progress_to_failure
  - new_failure_signature
  - hard_timeout
```

After three model wakeups with no meaningful state change, emit one structured
`CI_WAITING_NO_CHANGE` receipt and leave the watcher outside the model.

The watcher must not create commits, rerun workflows, cancel jobs, mutate branch
protection, or alter product state.

## Repeated CI failure control

For one exact head and one sanitized failure signature:

```text
first_failure:
  classify
  perform one proven infrastructure cleanup when applicable
  permit at most one unchanged-head rerun

second_identical_failure:
  stop automatic reruns
  emit REPEATED_INFRA_OR_FLAKY_FAILURE
  require source, harness, runner-policy, or workflow correction
```

A later successful attempt does not erase the instability history.

## Required stop receipt

When a budget stops execution, emit:

```text
last_accepted_checkpoint
current_authority_class
current_elasticity_grade
budget_domain
window_consumed
window_cap
renewals_consumed
maximum_renewals
lifetime_consumed
lifetime_cap
progress_state
failure_signature
state_changed
next_required_decision
```

Budget exhaustion alone is normally `OWNER_DECISION_REQUIRED`, not
`UNSAFE_BLOCKER`. Use `UNSAFE_BLOCKER` when continuation would violate a safety,
sensitivity, rollback, writer, or source-binding invariant.

## Completion discipline

Automatic continuation is appropriate only while:

- the authority envelope remains unchanged;
- the relevant domain window and lifetime caps remain;
- the failure has a bounded corrective hypothesis;
- reviewable progress continues;
- required proof is renewed for every new candidate; and
- no owner or protected boundary has been reached.

A passing result after several flaky attempts may unblock the exact product step
when all required proof is satisfied, but the instability remains a separate
follow-up. It must not be rewritten as several clean validations.

## Non-goals

This pattern does not authorize semantic product changes, cross-repository scope
growth, runtime Apply, Production contact, credential acquisition, bypassing
independent review, unbounded checkpoint resets, unbounded reruns, or
high-frequency model polling.