# WRITER_LEASE_V1_INTERIM_SETTLEMENT

Status: active, temporary compatibility mechanism.

This is the canonical fail-closed settlement path for an **expired** legacy
ordinary-development Writer Lease v1 record. It is not Writer Lease v2, does
not add heartbeats, epochs, fencing, Windows Job Objects, per-resource
ownership, force acquisition, or a general delete operation.

Writer Lease v2 remains the permanent target in
[issue #30](https://github.com/JerrySkywalker/dev_governance_files/issues/30).
This interim mechanism exists only so an expired ordinary-development v1 lease
cannot become an indefinite zombie because v1 had no canonical settlement
operation.

## Hard boundary

The only supported active path is:

```text
<task-root>/.coord-local/leases/taskroot-writer.active.json
```

The supported record schema is exactly `jpc.taskroot-writer-lease.v1`. The
operation never treats `codex resume`, `holder_session`, or any logical Codex
session identifier as ownership or liveness proof.

`Settle` uses the host's current UTC time; callers cannot inject a future time.
The read-only admission API accepts an injected timestamp only to make the
sanitized regression fixture deterministic.

Settlement is accepted only when every check below passes:

1. The active record, task root, and every used ancestor are contained and
   non-reparse; the active record is a regular file.
2. The lease, Goal, budget state, and authorization records parse as strict,
   exact-property JSON schemas.
3. Raw lease bytes are read and SHA-256 pinned before admission; `Settle`
   requires that exact caller-supplied SHA again immediately before retirement.
4. `hard_stop_utc` is strictly before current UTC.
5. The Goal and budget references bind to each other and identify only
   `INTERACTIVE_REPOSITORY_V1`, `A2`, `B2`, and `L0`–`L2` ordinary development.
6. Any protected/production profile, A4/A5 class, L4/L5 layer, protected or
   Owner-only boundary, service attachment, or production-like lease scope is
   rejected as `SETTLEMENT_REJECTED_PRODUCTION_ATTACHED`.
7. An explicit `pid:<n>` holder is rejected while that process is live. An
   opaque holder is only *not demonstrably live*; it is never mapped through
   a logical session resume.
8. The task-root Git worktree must be clean and have no `index.lock`.
9. A current, bounded Owner or coordinator authorization must bind the exact
   source-relative active path and lease SHA.

Any absent, malformed, changed, unexpired, live, protected, or ambiguous input
fails closed. In particular, an active/unexpired v1 lease is never reclaimed,
and production is excluded entirely.

## Canonical records and transaction

There is no `DeleteLease`, `ForceAcquire`, `IgnoreLease`, `ReclaimAnyway`, or
public raw-delete command. A successful settlement:

1. atomically moves the exact SHA-pinned active file to
   `.coord-local/leases/history/leases/<sha256>.writer-lease.v1.json` without
   overwrite;
2. verifies that no active marker remains and that the historical bytes still
   hash to the admitted SHA;
3. creates the immutable terminal receipt at
   `.coord-local/leases/history/settlements/<sha256>.settlement.json`; and
4. independently re-reads the terminal receipt and historical bytes before
   returning `SETTLEMENT_PASS`.

If a terminal receipt and matching historical file already exist, a second
`Settle` is a no-write `SETTLEMENT_ALREADY_SETTLED` observation. A failed move
or history check never reports successful settlement.

The terminal receipt is intentionally written after the atomic move and
post-move byte proof. This is the safer representation: it cannot falsely
claim a completed retirement if the process crashes before the active marker
has moved.

## Normal ordinary-development returns

`Invoke-WriterLeaseV1OrdinaryDevelopmentCoordinator` is the canonical outer
coordinator wrapper for a v1 ordinary-development implementer. For `PASS`,
`BLOCKED`, `HOLD`, `WAITING_EXTERNAL_CI`, and `READY_FOR_OWNER`, its outermost
`finally` performs:

```text
terminal normal-return receipt
-> canonical move to normal-return history
-> independent ACTIVE_LEASE=false check
```

The receipt is immutable and records `TERMINAL_NORMAL_RETURN_RECORDED`; it
does not pre-claim a completed release. A failed release is surfaced as
`NORMAL_RETURN_RELEASE_FAILED=<classifier>`. An abnormal exit has no normal
outcome, so this path does not fabricate a clean release; expired settlement
remains the fallback. Production attachment is checked before either receipt
or move and is never released by this path.

## Invocation

The read-only observation command is:

```powershell
pwsh -NoProfile -File .\tools\repo-health\Invoke-WriterLeaseV1Settlement.ps1 `
  -Mode Observe `
  -TaskRoot <task-root> `
  -LeasePath <task-root>\.coord-local\leases\taskroot-writer.active.json
```

The mutating settlement command additionally requires the observed exact SHA
and an approved authorization record below `<task-root>\.coord-local\authorizations`:

```powershell
pwsh -NoProfile -File .\tools\repo-health\Invoke-WriterLeaseV1Settlement.ps1 `
  -Mode Settle `
  -TaskRoot <task-root> `
  -LeasePath <task-root>\.coord-local\leases\taskroot-writer.active.json `
  -ExpectedLeaseSha256 <64-lowercase-hex> `
  -AuthorizationPath <task-root>\.coord-local\authorizations\<approved>.json
```

The authorization schema is exactly
`writer-lease-v1-settlement-authorization.v1`, with a current
`EXPIRED_ORDINARY_DEVELOPMENT_V1_SETTLEMENT` scope, source-relative active
path, exact SHA, `OWNER` or `COORDINATOR` issuer, and bounded UTC validity.
Its presence is mandatory because v1 has no stronger authorization proof.

## Regression fixture and validation

`tests/repo-health/fixtures/writer-lease-v1/054d-ordinary-development/` is a
sanitized structural fixture. It has no real logical session, machine path,
or secret. The focused suite proves both:

```text
before simulated expiry => SETTLEMENT_REJECTED_NOT_EXPIRED
after simulated expiry  => SETTLEMENT_ACCEPTED
```

Run it with:

```powershell
pwsh -NoProfile -File .\tests\repo-health\Test-WriterLeaseV1Settlement.ps1
```
