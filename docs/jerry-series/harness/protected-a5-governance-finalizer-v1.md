# Protected A5 Governance Finalizer v1

Status: active, narrowly scoped protected-governance settlement mechanism.

`PROTECTED_A5_GOVERNANCE_FINALIZER_V1` is the canonical source implementation
for releasing a terminal protected-A5 Writer Lease v1 after fresh explicit
Owner authorization. It is an L5 governance settlement operation. It is not an
Apply, promotion, rollback, Stage0 publication, device mutation, transaction
executor, force unlock, raw delete, general lock reclamation, or Writer Lease
v2 implementation.

The public entry point is:

```text
tools/repo-health/Invoke-ProtectedA5GovernanceFinalizer.ps1
```

## Separation from ordinary development

The two v1 paths are disjoint:

```text
ordinary DEVELOPMENT_TRAIN lease
  -> WriterLeaseV1Settlement

PROTECTED_TRANSACTION_V2 / A5 / L4-L5 lease
  -> ProtectedA5GovernanceFinalizer
```

The finalizer requires exact `PROTECTED_TRANSACTION_V2`, `A5`, `B4`, L4 or L5
current state, L5 maximum scope, and non-empty protected and Owner-only
boundaries in the lease-bound frozen Goal. Ordinary development is rejected.
`Assert-Wlv1OrdinaryDevelopmentGoal` remains unchanged and continues to reject
protected or production-attached leases.

## Supported terminal class

Version 1 supports exactly:

```text
terminal_result=FAILED_BEFORE_CONFIG
terminal_failure_code=OWNER_ABORTED_PREPARED
```

This pair has a safe exact evidence contract: terminal state, exact live/prestate
binding, no unresolved configuration mutation, rollback-packet validation where
relevant, no unresolved rollback, reconciliation PASS, and independent
Supervisor PASS.

`ROLLED_BACK_RC2` and `COMMITTED_RC3` were evaluated but remain unsupported in
v1. They require separate exact rollback-receipt/live-prestate and accepted-
target/final-protected-verification contracts respectively. Unsupported terminal
classes fail closed; they must not be approximated with the
`FAILED_BEFORE_CONFIG` packet.

## Typed authorization and evidence

The Owner authorization schema is
`protected-a5-governance-finalization-authorization.v1`. It is strict,
additional-field closed, valid for at most 30 minutes, and binds:

- the canonical task-root active lease path and exact lease SHA-256;
- the exact Goal, run, Goal metadata SHA-256, and budget metadata SHA-256;
- the transaction ID and supported terminal result/failure pair;
- a typed `protected-a5-finalization-evidence.v1` packet and its SHA-256;
- the exact reconciliation and independent-verifier paths and SHA-256 values.

The authorization scope is exactly
`PROTECTED_A5_GOVERNANCE_FINALIZE`. It grants no other protected authority.

The typed evidence packet is the machine-readable bridge for predecessor
receipts that were not originally designed for finalizer parsing. It references
and hashes those immutable receipts; it never rewrites, backdates, or replaces
them. The finalizer re-hashes the referenced files and requires:

```text
transaction_terminal=true
reconciliation_status=PASS
final_supervisor_status=PASS
fresh_transaction_evidence=true
live_prestate_status=EXACT
configuration_mutation_status=NONE_UNRESOLVED
rollback_packet_status=VALIDATED_WHERE_RELEVANT
rollback_status=NOT_REQUIRED
no_unresolved_protected_mutation=true
no_contradictory_later_transaction_evidence=true
no_fabricated_historical_receipt=true
unresolved_rollback=false
conflicting_evidence=false
```

The machine-readable schemas are under `tools/repo-health/schemas/`:

- `protected-a5-finalization-authorization.schema.json`;
- `protected-a5-finalization-evidence.schema.json`;
- `protected-a5-finalization-receipt.schema.json`.

## Canonical finalization transaction

The finalizer accepts only
`<task-root>/.coord-local/leases/taskroot-writer.active.json`. Every admission
file must be a regular non-reparse file beneath its exact task-root namespace.
JSON is strict UTF-8 with duplicate, unknown, missing, and incorrectly cased
fields rejected.

After initial admission, the finalizer acquires a permanent-path exclusive file
lock, re-reads and compares the SHA-256 of the lease, Goal, budget,
authorization, typed evidence, reconciliation receipt, and verifier receipt,
then:

1. moves the exact active lease without overwrite to
   `.coord-local/leases/history/protected-a5/leases/<lease-sha>.writer-lease.v1.json`;
2. proves the active marker absent and historical bytes unchanged;
3. creates an immutable
   `protected-a5-governance-finalization-receipt.v1` under
   `.coord-local/leases/history/protected-a5/finalizations/`;
4. independently re-reads the historical lease and receipt before returning
   `PROTECTED_A5_GOVERNANCE_RELEASED`.

The receipt always records `production_transaction_mutated=false`. The finalizer
does not touch the protected transaction journal, rollback packet, remote
runtime, or historical lease bytes.

If a process stops after the lease is archived but before receipt creation, an
exact retry classifies the state as `RECOVERY_PENDING`. With still-current exact
Owner authorization and unchanged evidence, it completes only the immutable
receipt. A complete exact repeat returns `FINALIZATION_ALREADY_COMPLETE` after
history and receipt validation; it never restores or deletes an active marker.

## Invocation

Observation and finalization both require the exact authorization packet:

```powershell
pwsh -NoLogo -NoProfile -File .\tools\repo-health\Invoke-ProtectedA5GovernanceFinalizer.ps1 `
  -Mode Observe `
  -TaskRoot <synthetic-or-owner-authorized-task-root> `
  -LeasePath <task-root>\.coord-local\leases\taskroot-writer.active.json `
  -ExpectedLeaseSha256 <exact-lowercase-sha256> `
  -AuthorizationPath <task-root>\.coord-local\authorizations\<fresh-owner-authorization>.json

pwsh -NoLogo -NoProfile -File .\tools\repo-health\Invoke-ProtectedA5GovernanceFinalizer.ps1 `
  -Mode Finalize `
  -TaskRoot <owner-authorized-task-root> `
  -LeasePath <task-root>\.coord-local\leases\taskroot-writer.active.json `
  -ExpectedLeaseSha256 <exact-lowercase-sha256> `
  -AuthorizationPath <task-root>\.coord-local\authorizations\<fresh-owner-authorization>.json
```

The second command is a template for a separately admitted protected L5 Goal.
A source-development Goal must not run it against a retained real lease.

## Regression suite

```powershell
pwsh -NoLogo -NoProfile -File .\tests\repo-health\Test-ProtectedA5GovernanceFinalizer.ps1
```

The sanitized 059 model retains only the public transaction ID, retained lease
digest, terminal classification, and PASS classifications. Tests use fresh
synthetic task roots and synthetic lease bytes. They prove the model is
finalizable only with a matching synthetic Owner authorization; they never use
the retained lease as a mutable fixture.
