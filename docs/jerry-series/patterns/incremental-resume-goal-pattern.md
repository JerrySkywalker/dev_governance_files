# Incremental Resume Goal Pattern

## Classification

```text
classification: pattern
context_class: CONDITIONAL_OPERATIONAL
scope: resuming bounded Goals after an accepted checkpoint
```

## Core rule

Resume from durable pointers plus one compact Accepted Delta. Do not copy full
history into each prompt.

## Required Harness binding

```text
HARNESS_MODEL_ID=<model>
HARNESS_BASELINE_ID=<baseline>
HARNESS_PROFILE=<profile>
CURRENT_CONTROL_VECTOR=<A,B,P>
CURRENT_LAYER=<L>
BUDGET_STATE_REF=<durable pointer>
NEXT_PROOF_VECTOR=<V,E,F,G>
```

The current baseline and Profile are immutable for the active Goal unless an
owner-approved resume explicitly adopts a newer version.

## Compact Accepted Delta

```text
LAST_ACCEPTED_CHECKPOINT=<durable pointer>
CURRENT_DELTA=<one new fact>
ALLOWED_MUTATION=<smallest authorized surface or NONE>
UNCHANGED_BOUNDARIES=<explicit non-goals>
NEXT_PROOF_VECTOR=<V,E,F,G>
HARD_STOP=<first condition requiring a new decision>
```

Pointers do not replace revalidation of drift-prone facts.

## Adjacent repair

An adjacent repair is allowed only when:

1. the primary failure is deterministically classified;
2. the defect lies on a declared direct contract edge;
3. the current adjacent-correction ledger has capacity;
4. no repository, policy, protected, identity, or runtime boundary expands; and
5. the next proof distinguishes the repair from the primary candidate.

Otherwise stop with an evidence pointer and owner decision.

## Layer-aware resume

| Current state | Normal resume |
| --- | --- |
| `L0/L1` candidate defect | change candidate, consume correction ledger, rerun focused proof |
| `L2` deterministic Gate failure | return to `L1`, create a new exact head, rerun one canonical `L2` Gate |
| `L3` owner rejection | return to `L1`, build a new immutable package, repeat technical and owner acceptance |
| `L4` read-only preflight failure | correct source/harness; no Apply consumed |
| `L4` Apply failure | rollback, verify, fresh backup, reopen Apply only if ledger remains |
| `L5` Finalize-preflight failure | retain accepted target when safe; correct Finalize source/harness |

## Stop conditions

Stop on source or durable-pointer drift, scope expansion, writer conflict,
exhausted applicable lifetime, ambiguous proof, unverified rollback, sensitive
output, or any owner/protected boundary not explicitly admitted.

The stop Receipt follows
`../harness/harness-goal-receipt-contract-v1.md`.
