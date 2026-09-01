# Protected A5 Legacy Lease Compatibility v1

Status: active compatibility adapter for narrowly proven historical protected
Writer Lease v1 records.

`PROTECTED_A5_LEGACY_LEASE_COMPATIBILITY_V1` does not rewrite a lease, reclaim a
lock, infer authority from age, reconstruct historical metadata, contact a
protected runtime, or implement Writer Lease v2. It converts accepted immutable
predecessor evidence into an explicit task-root-local admission bridge for the
existing Protected A5 finalization transaction.

The public preparation entry point is:

```text
tools/repo-health/Invoke-ProtectedA5LegacyCompatibility.ps1
```

## Disjoint state machines

```text
modern protected lease
  -> modern lease parser
  -> canonical frozen Goal and budget
  -> Owner authorization v1
  -> existing archive/lock/receipt transaction

legacy protected lease
  -> legacy-shape parser
  -> accepted typed provenance
  -> exact predecessor-receipt import
  -> DERIVED_COMPATIBILITY_METADATA companions
  -> immutable compatibility packet
  -> Owner authorization v2
  -> existing archive/lock/receipt transaction
```

An omitted legacy argument always selects the unchanged modern path. An explicit
legacy argument requires a JSON-null `budget_state_ref`, an absolute historical
`goal_ref` literal, and auth v2. Modern-shaped leases fail the legacy parser;
legacy-shaped leases fail the modern parser.

## Preparation inputs and provenance

The preparer accepts a strict
`protected-a5-legacy-compatibility-preparation.v1` manifest. The manifest binds
the exact lease digest and literal legacy fields, a typed
`protected-a5-legacy-governance-provenance.v1` packet, three immutable
predecessor governance records, and the reconciliation and verifier source
receipts. Every supplied source must be a regular non-reparse file whose bytes
match its expected SHA-256.

The provenance packet is itself derived evidence. It must say
`DERIVED_COMPATIBILITY_METADATA`, reference exact predecessor hashes, and prove
the supported protected shape: `PROTECTED_TRANSACTION_V2`, `A5`, `B4`, current
L4 or L5, maximum L5, and present protected/Owner-only boundaries. It never
claims that the companion records existed during the historical transaction.

The legacy `goal_ref` is bound as an immutable literal. Neither the preparer nor
the finalizer follows that absolute path.

## Observe and Prepare

`Observe` performs no write. `Prepare` revalidates every input under an
exclusive preparation lock and then creates without overwrite:

- `protected-a5-legacy-goal-companion.v1`;
- `protected-a5-legacy-budget-companion.v1`;
- canonical byte-identical reconciliation and verifier copies under
  `.coord-local/receipts/protected-a5-legacy/`;
- `protected-a5-legacy-lease-compatibility.v1`.

All outputs are re-read, re-hashed, and marked read-only. Existing destinations,
reparse ancestors, source drift, and byte inequality fail closed. The external
receipts are never moved, modified, or deleted.

```powershell
pwsh -NoLogo -NoProfile -File .\tools\repo-health\Invoke-ProtectedA5LegacyCompatibility.ps1 `
  -Mode Observe `
  -TaskRoot <synthetic-or-separately-authorized-task-root> `
  -LeasePath <task-root>\.coord-local\leases\taskroot-writer.active.json `
  -ExpectedLeaseSha256 <exact-lowercase-sha256> `
  -PreparationManifestPath <strict-preparation-manifest>
```

Changing `-Mode` to `Prepare` writes only the compatibility artifacts described
above. It does not mutate the active lease or run finalization.

## Finalizer admission

The finalizer consumes only the canonical imported receipt paths. Arbitrary
external receipt paths remain rejected. Owner auth v2 binds the compatibility
path and digest, companion Goal/budget hashes, canonical receipt hashes,
terminal evidence, transaction, and exact lease digest. Auth v1 remains
unchanged for modern leases.

Initial admission and immediate locked revalidation compare the lease,
compatibility packet, companions, imported receipts, typed evidence, and
authorization. The mature archive, exclusive lock, immutable settlement
receipt, idempotent repeat, and archive-before-receipt recovery semantics are
shared unchanged after admission.

## Regression suite

```powershell
pwsh -NoLogo -NoProfile -File .\tests\repo-health\Test-ProtectedA5LegacyCompatibility.ps1
```

The 059 fixture reproduces only the legacy JSON shape. It contains neither the
real retained lease bytes nor production evidence, and no test uses the real
task root.
