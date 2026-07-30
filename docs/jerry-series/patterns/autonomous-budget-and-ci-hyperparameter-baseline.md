# Autonomous Budget and CI Hyperparameter Baseline

## Classification

```text
classification: provisional_parameter_baseline
baseline_id: JERRY_AUTONOMY_CI_PARAMS_V1
scope: repository-health Waves, bounded multi-repository delivery, self-hosted CI, and protected release transactions
related_patterns:
  - elastic-autonomous-execution-budget-pattern.md
  - validation-depth-and-gate-selection.md
calibration_status: initial empirical baseline
change_policy: versioned, evidence-based, never changed silently inside an active Goal
sensitivity_notes: record only counters, sanitized signatures, durations, and state classifications
```

## Purpose

Provide recommended starting values for the authority, elasticity, progress, and
validation models established after Wave 7. These values are not universal safety
limits and do not create authority. They are a provisional control baseline to be
measured in later repository-health Waves and revised through explicit governance
changes.

The target is a bounded operating region with both:

```text
reliability: enough capacity to resolve sequential deterministic defects
and
efficiency: early stop on repeated no-progress, duplicate CI, and stale hypotheses
```

## Evidence basis

The initial values are derived from recurring shapes across the Jerry repositories,
not from the single worst incident.

### Ordinary repository work

Recent Manager and Proxy Control work usually converged in one to four commits or
narrow correction cycles. Workstation Manager Plan v3 used one commit; the Manager
Adapter harness used three commits and two independent-audit correction cycles.
Recent Proxy Control features and compatibility fixes were usually one to four
commits, while one older long-lived CI migration branch accumulated substantially
more and is treated as an outlier rather than a default.

### High-assurance and platform-sensitive work

Dashboard security and Windows filesystem work required wider but still finite
candidate budgets. The bounded web-auth foundation used five commits; later atomic
commit and combined-Canary corrections used four to six commits. The Windows atomic
move implementation deliberately used six internal attempts with bounded backoff,
but that micro-retry is not equivalent to six autonomous source-correction cycles.

### Protected release work

Dashboard Production PRs 75 through 87 exposed sequential defects in diagnostics,
archive identity, output protocols, readiness, recovery completion, target anchors,
and Finalize binding. The sequence demonstrates why protected work needs separate
Prepare, Apply, rollback, Finalize-preflight, and Finalize budgets. It does not
justify one generic source budget of thirteen attempts.

### CI and runner work

The self-hosted Windows runner incidents show that one classified unchanged-head
rerun may be useful after a narrow runner correction. A second identical head and
signature normally adds no evidence. Runner recovery therefore has its own budget,
while same-head same-signature reruns remain capped at one.

### Human acceptance

Technical Canary acceptance and owner-visible acceptance prove different claims.
One technical acceptance and one owner review are the default for each immutable
candidate package. A visual rejection creates a new candidate; it does not justify
repeated screenshot capture of unchanged bytes.

## Parameter scales must remain separate

A single number called `retry_count` is prohibited. Use four scales.

| Scale | Typical duration | Counts | Does not count |
| --- | --- | --- | --- |
| micro-operation | milliseconds to minutes | lock retries, readiness polls, read-only transport retries | source corrections, CI reruns |
| candidate correction | minutes to hours | changed candidate trees or declared adjacent contracts | repeated command execution on unchanged bytes |
| proof execution | minutes to hours | focused gates, canonical exact-head gates, audits, packets | watcher polls |
| protected transaction | minutes to hours | Prepare, Apply, rollback, Finalize | read-only preflight against an unchanged state |

A six-attempt filesystem lock loop may occur inside one candidate execution. It
consumes one operation invocation, not six governance correction cycles.

## Global invariant parameters

These values apply to every profile unless a stricter value is declared.

```text
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
NO_PROGRESS_WINDOW=2
IDENTICAL_FAILURE_SIGNATURE_LIFETIME=2
MODEL_CI_NO_CHANGE_WAKEUP_LIFETIME=3
DUPLICATE_CANONICAL_FULL_GATE_COUNT=0
BUDGET_BORROWING_ALLOWED=false
AUTOMATIC_AUTHORITY_EXPANSION=false
```

Interpretation:

- the first occurrence creates a diagnosis opportunity;
- one unchanged-head rerun may test one classified transient hypothesis;
- the second identical outcome ends automatic repetition;
- an external watcher may continue observing without consuming model wakeups; and
- two workflows must not execute the same canonical full command graph for the
  same exact head.

## Micro-operation defaults

These are implementation-level defaults. They must remain inside one admitted
operation and must not hide deterministic failure.

| Operation class | Total attempts or horizon | Recommended schedule | Conditions |
| --- | ---: | --- | --- |
| deterministic parser, schema, or fixture | 1 | no retry | change input or implementation before rerun |
| local filesystem transient lock or atomic replace | 6 attempts | initial, then 100/200/400/800/1600 ms | retry only allowlisted transient OS errors; revalidate invariants before every attempt |
| read-only HTTP, SSH, or API transport | 3 attempts | initial, then 2 s and 5 s | retry only classified transport/transient failures; never retry authentication or policy rejection |
| service readiness after one admitted recreation | 120 s horizon | poll every 5 s | bind all polls to the same container/process identity |
| browser login submission or activation | 1 | passive observation after submission | no automatic resubmission; challenge, MFA, bad credentials, or ambiguous flow stop |
| browser post-submit observation | 60 s default, 120 s maximum | bounded passive observation | target-specific manifest may choose a lower value |
| evidence file accessibility read | 3 attempts | immediate, 1 s, 3 s | no source mutation; classify missing, locked, malformed, or unauthorized separately |

## Profile 1 — governance and documentation capture

Use for `A1 + B2` governance-only work.

```text
PROFILE=DOCS_CAPTURE_V2
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=2

SOURCE_CORRECTION_WINDOW=2
SOURCE_CORRECTION_MAX_RENEWALS=0
SOURCE_CORRECTION_LIFETIME=3

SCHEMA_REPAIR_WINDOW=2
SCHEMA_REPAIR_LIFETIME=2
AUDIT_LAUNCH_WINDOW=2
AUDIT_LAUNCH_LIFETIME=2

TRANSIENT_CI_RERUN_LIFETIME_PER_WORKFLOW=1
RUNNER_ENVIRONMENT_CORRECTION_LIFETIME=1
NO_PROGRESS_WINDOW=2
```

Rationale:

- most documentation changes should converge in one or two edits;
- a third lifetime correction is reserved for review or index consistency;
- docs do not justify repeated self-hosted runner recovery; and
- one exact-head docs gate is sufficient when the repository defines one.

## Profile 2 — attended single-repository implementation

Use for ordinary `A2 + B2` work with prompt owner review.

```text
PROFILE=INTERACTIVE_REPOSITORY_V1
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=4

SOURCE_CORRECTION_WINDOW=3
SOURCE_CORRECTION_MAX_RENEWALS=0
SOURCE_CORRECTION_LIFETIME=3

ADJACENT_FIX_WINDOW=1
ADJACENT_FIX_MAX_RENEWALS=0
ADJACENT_FIX_LIFETIME=1

PACKET_METHOD_WINDOW=2
PACKET_PREFLIGHTS_PER_METHOD_WINDOW=3
PACKET_ATTEMPT_WINDOW=4
PACKET_ATTEMPT_LIFETIME=4

AUDIT_LAUNCH_WINDOW=2
AUDIT_LAUNCH_LIFETIME=2
AUDIT_FINDING_CORRECTION_LIFETIME=1
SCHEMA_REPAIR_LIFETIME=2
EVIDENCE_ACCESS_RECOVERY_LIFETIME=2

TRANSIENT_CI_RERUN_LIFETIME_PER_WORKFLOW=2
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
RUNNER_ENVIRONMENT_CORRECTION_LIFETIME=2
NO_PROGRESS_WINDOW=2
```

Rationale:

- three source corrections cover the common one-to-three cycle range without
  turning attended work into an unattended train;
- one adjacent fix allows a proven neighboring contract defect but prevents scope
  from spreading across repositories;
- two audit launches cover one process failure; a changed candidate requires a
  fresh audit rather than relabeling the previous verdict; and
- two transient CI reruns cover distinct classified incidents, while the same
  signature remains capped at one.

## Profile 3 — high-assurance or multi-repository Wave

Use for declared `A2/A3 + B3` work with durable checkpoints and a narrow mutation
surface.

```text
PROFILE=HIGH_ASSURANCE_WAVE_V1
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=8

SOURCE_CORRECTION_WINDOW=3
SOURCE_CORRECTION_MAX_RENEWALS=1
SOURCE_CORRECTION_LIFETIME=6

ADJACENT_FIX_WINDOW=2
ADJACENT_FIX_MAX_RENEWALS=1
ADJACENT_FIX_LIFETIME=4

PACKET_METHOD_WINDOW=3
PACKET_PREFLIGHTS_PER_METHOD_WINDOW=3
PACKET_ATTEMPT_WINDOW=4
PACKET_ATTEMPT_MAX_RENEWALS=1
PACKET_ATTEMPT_LIFETIME=8

AUDIT_LAUNCH_WINDOW=2
AUDIT_LAUNCH_MAX_RENEWALS=1
AUDIT_LAUNCH_LIFETIME=3
AUDIT_FINDING_CORRECTION_LIFETIME=2
SCHEMA_REPAIR_LIFETIME=3
EVIDENCE_ACCESS_RECOVERY_LIFETIME=3

TRANSIENT_CI_RERUN_LIFETIME_PER_WORKFLOW=2
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
RUNNER_ENVIRONMENT_CORRECTION_WINDOW=2
RUNNER_ENVIRONMENT_CORRECTION_LIFETIME=3

CI_WATCH_INITIAL_INTERVAL_MINUTES=5
CI_WATCH_LONG_INTERVAL_MINUTES=10
CI_WATCH_LONG_INTERVAL_AFTER_MINUTES=30
MODEL_CI_NO_CHANGE_WAKEUP_LIFETIME=3
NO_PROGRESS_WINDOW=2
```

Rationale:

- a window of three forces an intermediate checkpoint before the full lifetime of
  six is consumed;
- six source corrections cover the observed high-assurance upper range without
  copying the thirteen-PR protected release outlier into every Wave;
- two audit finding cycles match the observed need for an initial audit correction
  and one fresh-audit correction while still requiring a stop if the review keeps
  finding structurally new problems;
- packet capacity is larger because method, preflight, and sealed attempt failures
  are distinct; and
- three runner corrections cover process cleanup, service recovery, and one
  toolchain or workspace repair, but cannot be converted into product corrections.

## Profile 4 — compressed multi-repository train

Use only when individual Wave identities, checkpoints, and completion states remain
separate.

```text
PROFILE=COMPRESSED_TRAIN_V1
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=12
MAX_ACTIVE_WRITERS=1
MAX_PARALLEL_READ_ONLY_AUDITORS=2

PER_REPOSITORY_SOURCE_CORRECTION_WINDOW=3
PER_REPOSITORY_SOURCE_CORRECTION_LIFETIME=5
TRAIN_ADJACENT_FIX_LIFETIME=4
TRAIN_PACKET_ATTEMPT_LIFETIME=10
TRAIN_AUDIT_FINDING_CORRECTION_LIFETIME=3

MAX_CONSECUTIVE_REPOSITORIES_WITHOUT_P3_CHECKPOINT=1
MAX_NO_PRODUCT_DELTA_OUTCOMES_WITHOUT_REVIEW=3
```

Additional rules:

- repository budgets are not pooled;
- unused corrections from one repository cannot finance another;
- each repository receives its own `V2` exact-head proof;
- cross-repository `V4` proof runs only after a sealed integration packet exists;
- `NO_PRODUCT_DELTA_REQUIRED` is a valid result and consumes no source correction;
- after each repository or Wave, emit a P3 checkpoint before continuing; and
- the twelve-hour limit is observational capacity, not permission to cross an
  owner or protected boundary.

## Profile 5 — protected read-only preflight

Use for `A4 + B3` Production inspection and diagnostics.

```text
PROFILE=PROTECTED_PREFLIGHT_V2
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=4

RUNTIME_PREFLIGHT_WINDOW=3
RUNTIME_PREFLIGHT_MAX_RENEWALS=1
RUNTIME_PREFLIGHT_LIFETIME=6

SOURCE_OR_HARNESS_CORRECTION_WINDOW=2
SOURCE_OR_HARNESS_CORRECTION_LIFETIME=4

PREPARE_ATTEMPTS=0
APPLY_ATTEMPTS=0
ROLLBACK_ATTEMPTS=0
FINALIZE_ATTEMPTS=0
STOP_BEFORE_PROTECTED_MUTATION=true
```

Rationale:

- three preflights support diagnose, corrected proof, and one confirmation;
- one P3 renewal permits a second bounded stage without creating A5 authority; and
- no successful read-only result can consume or create a mutation budget.

## Profile 6 — protected transaction

Use only for explicitly admitted `A5 + B4` work.

```text
PROFILE=PROTECTED_TRANSACTION_V2
EXPLICIT_OWNER_AUTHORIZATION_REQUIRED=true
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=6

PREPARE_WINDOW=2
PREPARE_LIFETIME=4

APPLY_WINDOW=1
APPLY_MAX_RENEWALS=1
APPLY_LIFETIME=2

ACCEPTANCE_ATTEMPTS_PER_APPLY=1

ROLLBACK_WINDOW=1
ROLLBACK_LIFETIME=2

FINALIZE_PREFLIGHT_WINDOW=3
FINALIZE_PREFLIGHT_LIFETIME=6

FINALIZE_WINDOW=1
FINALIZE_MAX_RENEWALS=1
FINALIZE_LIFETIME=2

CLOSEOUT_WINDOW=2
CLOSEOUT_LIFETIME=2

FRESH_BACKUP_BEFORE_EACH_FRESH_APPLY=true
VERIFIED_ROLLBACK_BEFORE_NEXT_APPLY=true
FAILED_OR_UNVERIFIED_ROLLBACK_HARD_STOP=true
SAME_TARGET_RECREATE_WITHOUT_DRIFT=false
```

Rationale:

- Prepare is relatively recoverable and may expose sequential archive or staging
  defects before runtime mutation;
- Apply and Finalize are deliberately one-shot windows;
- the second lifetime Apply or Finalize is available only through the declared
  recovery transition, never as an immediate retry;
- rollback has capacity for the normal restoration and one explicitly authorized
  recovery continuation, but an unverified rollback always stops automatic work;
- Finalize preflight is wider because it is read-only and should absorb source or
  handoff defects before a healthy accepted target is disturbed; and
- closeout receives two attempts for receipt or metadata correction, not product or
  runtime changes.

## Validation execution budgets by proof vector

The parameter baseline constrains how often each proof should run.

| Proof | Default execution budget | Reset condition |
| --- | --- | --- |
| `V0/E0/F0/G0` edit feedback | once per changed document or schema state | input bytes change |
| `V1/E0/F0-G1` focused gate | once per changed candidate tree; one repeat only after a harness correction | candidate or harness bytes change |
| `V2/E1-E2/F2/G2` canonical repository gate | once per designated exact head, plus one classified transient rerun | new designated exact head |
| `V3/E2/F2/G2` platform gate | once per platform-sensitive exact head, plus the same CI transient rule | platform-sensitive bytes or environment classification change |
| `V4/E3/F2/G2` adjacent integration | once per sealed packet; one repeat after packet or endpoint correction | new sealed packet or changed bound implementation |
| `V5/E4/F4/G3` Canary technical acceptance | once per immutable candidate package | candidate package changes |
| `V5/E4/F4/G4` owner visual acceptance | one review per immutable candidate package | candidate package changes |
| `V6/E5/F4/G3` protected preflight | profile preflight window and lifetime | target context or source/harness changes |
| `V6/E6/F4/G4` Apply/rollback | protected transaction counters | verified rollback plus fresh backup |
| `V7/E5-E6/F4/G4` Finalize/closeout | Finalize-preflight, Finalize, and closeout counters | accepted target or finalization source changes |
| `F5` scheduled smoke | one active schedule per declared claim | schedule or claim changes |

No successful shallow gate automatically requires every deeper gate. No failed deep
gate should be repeated after unchanged inputs unless the failure is classified as
transient and the relevant rerun budget remains.

## Risk modifiers

Do not multiply all counters by a generic risk factor. Apply bounded, domain-specific
modifiers.

| Condition | Allowed adjustment | Hard maximum |
| --- | --- | ---: |
| docs-only, generated output unchanged | reduce source window by 1 | minimum 1 |
| security, ACL, atomic filesystem, or parser boundary | add 1 to source lifetime | 6 |
| each additional declared adjacent repository | add 1 to adjacent lifetime | 4 |
| sealed multi-platform proof required | add 1 packet attempt | 10 |
| self-hosted runner has known recent contamination | add 1 runner correction | 3 |
| protected runtime or credentials involved | no automatic increase | baseline remains fixed |
| same head and same signature | no increase | 1 rerun |
| Apply, rollback, or Finalize | no implicit increase | profile hard cap |

A modifier changes only the named domain and must be declared before the affected
operation begins.

## Calibration metrics

Every later Wave using this baseline should append one sanitized parameter receipt.

```text
baseline_id
profile
wave_or_goal_id
authority_class
elasticity_grade
validation_vectors_used

for_each_budget_domain:
  window_cap
  window_consumed
  renewals_consumed
  lifetime_cap
  lifetime_consumed

p0_count
p1_count
p2_count
p3_count
first_pass_focused_gate
first_pass_canonical_gate
same_head_reruns
runner_corrections
duplicate_full_gate_count
owner_interruptions_due_to_budget
owner_interruptions_due_to_authority
protected_apply_count
rollback_count
rollback_verified
finalize_count
wall_clock_minutes
completion_state
```

Do not record secrets, raw logs, private endpoints, credential identifiers, or
sensitive runtime values.

## Initial calibration targets

These are operating targets, not acceptance claims.

```text
DUPLICATE_FULL_GATE_COUNT_TARGET=0
MEDIAN_NO_PROGRESS_CYCLES_TARGET<=1
SAME_HEAD_SAME_SIGNATURE_RERUN_TARGET<=1
OWNER_INTERRUPTION_DUE_ONLY_TO_CONVENIENCE_BUDGET_TARGET<15_percent
FIRST_PASS_FOCUSED_GATE_TARGET>=90_percent
FIRST_PASS_CANONICAL_GATE_TARGET>=80_percent
PROTECTED_ROLLBACK_VERIFICATION_TARGET=100_percent
UNVERIFIED_PROTECTED_CONTINUATION_TARGET=0
```

Visual owner rejection and `NO_PRODUCT_DELTA_REQUIRED` are recorded separately and
are not counted as implementation reliability failures.

## Retuning policy

The baseline should be reviewed after each Wave but changed only with enough
comparable evidence.

### Initial observation period

Use `JERRY_AUTONOMY_CI_PARAMS_V1` for at least:

```text
6 completed repository-health Waves
or
12 completed comparable Goals
```

A safety defect may reduce a parameter immediately. Increasing a parameter should
normally wait for the observation period.

### Increase rule

Increase one domain by exactly one unit only when all are true:

1. at least two of the last three comparable runs reached 80 percent or more of the
   domain lifetime cap;
2. the cap caused an owner interruption or incomplete but still in-scope work;
3. the final attempts were P1 or P2 progress, not P0 repetition;
4. no authority, sensitivity, writer, rollback, or source-binding invariant was
   violated; and
5. the increase does not exceed the domain hard maximum.

### Decrease rule

Decrease one domain by one unit when either condition holds:

- four consecutive comparable runs consumed no more than half the lifetime cap and
  completed without convenience-budget interruption; or
- the current value repeatedly enabled duplicate gates, P0 loops, stale hypotheses,
  or avoidable runner contention.

### Frozen parameters

The following parameters do not increase automatically from empirical convenience
pressure:

```text
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
APPLY_WINDOW=1
FINALIZE_WINDOW=1
FAILED_OR_UNVERIFIED_ROLLBACK_HARD_STOP=true
AUTOMATIC_AUTHORITY_EXPANSION=false
BUDGET_BORROWING_ALLOWED=false
```

A change to a frozen parameter requires an explicit governance decision and a new
baseline version.

## Versioning and adoption

Each Goal must record the exact baseline ID it used. A later baseline applies only
to newly admitted work unless an owner-approved resume instruction explicitly
adopts it.

Recommended evolution:

```text
JERRY_AUTONOMY_CI_PARAMS_V1
  -> collect receipts
  -> compare reliability and efficiency
  -> publish calibrated deltas
  -> JERRY_AUTONOMY_CI_PARAMS_V2
```

Do not rewrite historical receipts after a parameter change.