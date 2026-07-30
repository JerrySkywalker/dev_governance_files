# Harness Hyperparameter Baseline V1

## Status

```text
BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
STATUS=PROVISIONAL
NUMERIC_SOURCE=config/repo-health-harness-v1.json
```

This file explains the numbers. The JSON file is authoritative.

## Evidence basis

The baseline uses recurring development shapes, not the single worst incident.

- ordinary Manager and Proxy Control work commonly converged in one to three
  candidate corrections;
- security, Windows ACL, atomic move, and composed Canary work required four to
  six bounded candidate states;
- Production PRs #75-#87 showed that Prepare, Apply, rollback,
  Finalize-preflight, and Finalize require separate ledgers;
- self-hosted runner incidents support one classified unchanged-head rerun, not
  repeated same-signature execution;
- one technical acceptance and one owner review are appropriate per immutable
  package.

## Separate scales

| Scale | Examples |
| --- | --- |
| micro-operation | lock retry, readiness polling, read-only transport |
| candidate correction | changed source tree or declared adjacent contract |
| proof execution | focused Gate, exact-head Gate, audit, sealed packet |
| protected transaction | Prepare, Apply, rollback, Finalize |

Six lock attempts inside one atomic operation count as one admitted operation,
not six source-correction cycles.

## Recommended profiles

| Profile | Principal source budget | Special limits |
| --- | --- | --- |
| `DOCS_CAPTURE_V2` | window 2, lifetime 3 | one CI transient; runner lifetime 1 |
| `INTERACTIVE_REPOSITORY_V1` | 3/3 | adjacent 1; audit finding 1; runner 2 |
| `HIGH_ASSURANCE_WAVE_V1` | window 3, one renewal, lifetime 6 | adjacent 4; packet 8; runner 3 |
| `COMPRESSED_TRAIN_V1` | per repository window 3, lifetime 5 | one writer; train packet 10 |
| `PROTECTED_PREFLIGHT_V2` | source/harness 2/4 | runtime preflight 3/6; mutation domains zero |
| `PROTECTED_TRANSACTION_V2` | source/harness 2/4 | Apply 1/2; Finalize 1/2; rollback verification mandatory |

Notation `3/6` means a window of three and a lifetime of six, not six immediate
attempts.

## Why these values

### Ordinary source correction: 3

The expected shape is initial candidate, one deterministic correction, and one
final convergence correction. A lower value interrupts normal review; a larger
default hides design instability.

### High-assurance source correction: 3 + 3

The first window forces a durable checkpoint. A second window is available only
after `P3`; lifetime still caps the Goal at six.

### Same-head same-signature rerun: 1

The first failure creates a diagnostic opportunity. One rerun tests a specific
transient hypothesis. A second identical failure adds no evidence.

### Runner correction: 2 or 3

Typical repairs are process cleanup, service recovery, and—only in
high-assurance work—one toolchain/workspace correction.

### Prepare: 2/4

Prepare is comparatively recoverable and may reveal sequential archive,
manifest, staging, or output-protocol defects before runtime mutation.

### Apply and Finalize: one-shot windows

Both use window 1. A second lifetime attempt exists only through the declared
recovery transition, with verified rollback and fresh backup where applicable.

### Finalize preflight: 3/6

Read-only proof should absorb target-context, receipt-binding, and plan-domain
defects before a healthy accepted target is disturbed.

## Frozen parameters

The following do not increase automatically:

```text
same-head same-signature rerun lifetime = 1
Apply window = 1
Finalize window = 1
failed or unverified rollback = hard stop
automatic authority expansion = false
budget borrowing = false
duplicate canonical full Gate = 0
```

## Calibration

Each later Wave emits a sanitized consumption Receipt. Review V1 after at least
six completed Waves or twelve comparable Goals.

Targets:

- duplicate full Gate count: 0;
- median no-progress cycles: at most 1;
- convenience-budget-only owner interruption: below 15%;
- first-pass focused Gate: at least 90%;
- first-pass canonical Gate: at least 80%;
- protected rollback verification: 100%;
- unverified protected continuation: 0.

Increase one domain by one unit only when two of the last three comparable runs
use at least 80%, the cap interrupts still-in-scope `P1/P2` work, no safety
invariant is violated, and the hard maximum remains. Decrease after four
underused runs or when a value enables duplicate Gates, `P0` loops, stale
hypotheses, or avoidable contention.
