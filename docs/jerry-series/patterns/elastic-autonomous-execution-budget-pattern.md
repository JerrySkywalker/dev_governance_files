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
MAX_RUNNER_ENVIRONMENT_CORRECTIONS=3

MAX_IDENTICAL_FAILURE_SIGNATURES=2
MAX_NO_PROGRESS_CYCLES=2

AUTO_CONTINUE_AFTER_ACCEPTED_CHECKPOINT=true
STOP_BEFORE_OWNER_GATE=true
```

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
- Identical no-progress failure signatures stop after two occurrences.

Record the counters separately. Do not use one ambiguous retry total for
content, packet, Auditor, CI, or runner work.

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

## No-progress control

A failure signature should describe the stable, sanitized failure class and
the bounded input that produced it. A new log line, timestamp, or attempt
number does not make an otherwise identical failure new progress. After two
identical signatures, stop with a compact receipt that names the next required
decision.

## Completion discipline

Automatic continuation is appropriate after an accepted checkpoint only while
the relevant domain counters and progress rules permit it. At a new authority
or protected boundary, stop for an owner decision. See
[JD-0003](../decisions/JD-0003-progress-sensitive-autonomous-execution-budgets.md)
for the governing top-level exits.

## Non-goals

This pattern does not authorize semantic product changes, cross-repository
scope growth, runtime apply, production actions, or bypassing independent
review.
