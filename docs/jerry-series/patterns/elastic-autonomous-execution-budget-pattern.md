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

Use independent, finite budgets to keep ordinary execution recovery moving
without treating a convenience failure as new authority. The pattern applies
after an immutable admission boundary has named the allowed mutation surface,
safety constraints, and owner gates.

## Profiles

### INTERACTIVE_DEFAULT_V1

Use for attended work where a human can review a compact stop receipt promptly.
Keep all domain counters finite, prefer one correction hypothesis at a time,
and stop before an owner gate.

### OVERNIGHT_SAFE_V1

Use for unattended work that has a wide, preapproved execution envelope and a
narrow mutation scope.

```text
MAX_AUTONOMOUS_WALL_CLOCK_HOURS=8

MAX_CONTENT_CORRECTION_CYCLES=6
MAX_ADJACENT_FIX_CYCLES=4

MAX_PACKET_METHODS=4
MAX_PACKET_PREFLIGHTS_PER_METHOD=4
MAX_PACKET_ATTEMPTS=10

MAX_AUDIT_PROCESS_ATTEMPTS=8
MAX_AUDIT_SCHEMA_REPAIRS=4
MAX_EVIDENCE_ACCESS_RECOVERIES=5

MAX_TRANSIENT_CI_RERUNS_PER_WORKFLOW=3
MAX_SAME_HEAD_SAME_SIGNATURE_RERUNS=1
MAX_RUNNER_ENVIRONMENT_CORRECTIONS=3

MAX_IDENTICAL_FAILURE_SIGNATURES=2
MAX_NO_PROGRESS_CYCLES=2

CI_WATCH_INITIAL_INTERVAL_MINUTES=5
CI_WATCH_LONG_INTERVAL_MINUTES=10
CI_WATCH_LONG_INTERVAL_AFTER_MINUTES=30
MAX_MODEL_CI_STATE_WAKEUPS_WITHOUT_CHANGE=3

AUTO_CONTINUE_AFTER_ACCEPTED_CHECKPOINT=true
STOP_BEFORE_OWNER_GATE=true
```

`MAX_TRANSIENT_CI_RERUNS_PER_WORKFLOW` covers distinct, classified transient
incidents. It does not permit repeated reruns of the same head and same failure
signature. That narrower budget is governed by
`MAX_SAME_HEAD_SAME_SIGNATURE_RERUNS`.

### PROTECTED_APPLY_V1

Use when a Goal can reach an apply or protected boundary. Keep discovery,
validation, and evidence recovery bounded, but set runtime or apply budget to
zero unless the owner supplied a separate, explicit authorization. Stop before
each protected operation and never infer permission from prior read-only
progress.

## Counting rules

Apply these rules consistently:

- An Auditor attempt counts only after the independent process starts.
- A packet attempt counts only after a final numbered packet directory begins.
- A packet-method preflight does not consume a packet attempt.
- A content correction counts only when the candidate tree changes.
- A CI rerun counts only when a run is actually queued.
- A same-head same-signature rerun consumes both the workflow rerun budget and
  the narrower signature rerun budget.
- A model CI state wakeup counts only when the model is resumed to inspect an
  unchanged CI state; shell-side watcher polls do not count as model wakeups.
- Identical no-progress failure signatures stop after two occurrences.

Record the counters separately. Do not use one ambiguous retry total for
content, packet, Auditor, CI, runner work, or CI observation.

## Reset rules

```text
new candidate tree
  -> reset packet, audit, schema, and access counters
  -> increment content-correction counter

accepted stage exact-main
  -> reset transient CI, runner, packet, audit, and no-progress counters

owner override
  -> append-only, scoped, expiring, and explicitly consumed

authority and safety boundaries
  -> never reset automatically
```

The accepted checkpoint resets operational recovery capacity, not the original
scope. A new candidate tree still requires fresh validation and an independent
audit before delivery.

An unchanged head does not reset the same-signature rerun counter merely because
runner load, timestamps, or attempt numbers changed.

## CI observation budget

CI waiting must be delegated to a finite external watcher whenever the expected
next event is only a workflow state transition. The watcher may poll GitHub, but
it must not wake the model for every unchanged response.

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
`CI_WAITING_NO_CHANGE` receipt and leave the watcher running outside the model.
Do not continue a conversation loop that repeatedly reloads full context.

The receipt should contain only:

```text
exact_head_sha
workflow_ids
current_states
runner_capacity_classification
last_state_change_at
next_wakeup_condition
watcher_deadline
```

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
  require source, test-harness, or runner-policy correction
```

A later successful sixth attempt does not erase the repeated-failure evidence.
It may prove that the product head is capable of passing, but it does not prove
the test or runner is stable.

Distinct signatures may use the broader transient rerun budget only after each
signature has its own classification and bounded correction hypothesis.

## Progress-sensitive correction budgets

A fixed one-PR or one-commit budget is often appropriate for an interactive
adjacent correction. It is not appropriate for a long unattended release when
multiple deterministic defects can be exposed sequentially inside one already
approved narrow release surface.

For such work, use an elastic but finite domain budget:

```text
allowed_surface=explicit
max_new_prs=finite
max_apply_attempts=finite
requires_verified_rollback_between_applies=true
same_failure_signature_stop=2
unrelated_scope_growth=false
```

Do not consume a new owner round trip merely because an earlier convenience
counter was exhausted when the current defect remains deterministic, in scope,
and within the currently approved elastic domain budget. Do stop at credentials,
unrelated services, unverified rollback, sensitive output, or an exhausted
explicit hard budget.

## No-progress control

A failure signature should describe the stable, sanitized failure class and
the bounded input that produced it. A new log line, timestamp, or attempt
number does not make an otherwise identical failure new progress. After two
identical signatures, stop with a compact receipt that names the next required
decision.

Repeated unchanged CI polling is also no progress. Queue age alone may change
the waiting classification, but it does not justify another model reasoning
cycle unless a configured wakeup condition occurs.

## Completion discipline

Automatic continuation is appropriate after an accepted checkpoint only while
the relevant domain counters and progress rules permit it. At a new authority
or protected boundary, stop for an owner decision. See
[JD-0003](../decisions/JD-0003-progress-sensitive-autonomous-execution-budgets.md)
for the governing top-level exits.

CI success after a flaky sequence may unblock the product step when exact-head
requirements are satisfied, but the instability must remain an explicit
follow-up and must not be rewritten as six clean product validations.

## Non-goals

This pattern does not authorize semantic product changes, cross-repository
scope growth, runtime apply, production actions, bypassing independent review,
unbounded reruns, or high-frequency model polling.
