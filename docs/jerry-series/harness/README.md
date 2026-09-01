# Jerry Repository-Health Harness

[简体中文](README.zh-CN.md)

This is the only entrypoint for active Harness work.

## Active identifiers

```text
MODEL_ID=JERRY_HARNESS_MODEL_V1
BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
CONTEXT_MANIFEST_ID=JERRY_AGENT_CONTEXT_V1
STATUS=PROVISIONAL
```

## Read order

| Task | Required context |
| --- | --- |
| explain the Harness | this README + relevant Specification sections |
| create or resume a Goal | this README + Goal/Receipt Contract + selected Profile slice |
| audit execution | Specification + baseline JSON + Goal + Receipts + matching Playbook |
| retune parameters | Specification + Baseline rationale + receipts + explicit historical evidence |
| self-hosted CI | selected Profile + `../playbooks/self-hosted-ci-playbook.md` |
| historical analysis | explicitly named Retrospective sections only |

## Harness model

```text
Harness Instance
  = Version selectors
  + Control vector <A,B,P>
  + Operational layer L
  + Proof vector <V,E,F,G>
  + Domain budget ledger
  + Goal scope
  + Current receipt state
```

### Control vector

- `A`: authority — what may be touched.
- `B`: elasticity — how admitted work may continue.
- `P`: progress — whether a reviewable state change occurred.

### Proof vector

- `V`: proof depth — what claim is established.
- `E`: environment — where the claim is established.
- `F`: cadence — when and how often it runs.
- `G`: criticality — what failure blocks.

### Operational layers

| Layer | Purpose | Typical vector |
| --- | --- | --- |
| `L0` | edit feedback | `V0/V1,E0,F0,G0` |
| `L1` | candidate acceptance | `V1` plus focused `V3/V4`, `F1,G1` |
| `L2` | exact-head repository acceptance | `V2` plus applicable `V3/V4`, `F2,G2` |
| `L3` | deployed candidate and owner acceptance | `V5,E4,F4,G3/G4` |
| `L4` | protected preflight and transaction | `V6,E5/E6,F4,G3/G4` |
| `L5` | Finalize and closeout | `V7,E5/E6,F4,G4` |

## Profiles

| Profile | Control start | Layer range |
| --- | --- | --- |
| `DOCS_CAPTURE_V2` | `A1,B2,P_INIT` | `L0-L2` |
| `INTERACTIVE_REPOSITORY_V1` | `A2,B2,P_INIT` | `L0-L2` |
| `HIGH_ASSURANCE_WAVE_V1` | `A2/A3,B3,P_INIT` | `L0-L3` |
| `COMPRESSED_TRAIN_V1` | `A3,B3,P_INIT` | `L1-L3` |
| `PROTECTED_PREFLIGHT_V2` | `A4,B3,P_INIT` | read-only `L4` |
| `PROTECTED_TRANSACTION_V2` | `A5,B4,P_INIT` | `L4-L5` |

Profiles load defaults. They never create authority.

## Sixteen parameter families

1. authority class;
2. elasticity grade;
3. progress state;
4. Profile;
5. proof depth;
6. execution environment;
7. cadence;
8. criticality;
9. operational layer;
10. domain budget ledger;
11. micro-operation retry;
12. time and observation;
13. concurrency and Gate topology;
14. transition and replenishment;
15. safety and frozen invariants;
16. calibration and retuning.

## Hard invariants

```text
AUTHORITY_NEVER_EXPANDS_AUTOMATICALLY=true
BUDGET_DOMAINS_NEVER_BORROW=true
SAME_HEAD_SAME_SIGNATURE_RERUN_LIFETIME=1
DUPLICATE_CANONICAL_FULL_GATE_COUNT=0
FAILED_OR_UNVERIFIED_ROLLBACK_HARD_STOP=true
```

## Sources of truth

- Semantics: [`harness-specification-v1.md`](harness-specification-v1.md)
- Numbers: [`../../../config/repo-health-harness-v1.json`](../../../config/repo-health-harness-v1.json)
- Rationale: [`harness-baseline-v1.md`](harness-baseline-v1.md)
- Interface: [`harness-goal-receipt-contract-v1.md`](harness-goal-receipt-contract-v1.md)

## Active compatibility mechanisms

- [`WRITER_LEASE_V1_INTERIM_SETTLEMENT`](writer-lease-v1-interim-settlement.md)
  is the temporary, fail-closed compatibility path for expired ordinary-development
  Writer Lease v1 records. It excludes production and does not replace Writer
  Lease v2 ([issue #30](https://github.com/JerrySkywalker/dev_governance_files/issues/30)).
- [`PROTECTED_A5_GOVERNANCE_FINALIZER_V1`](protected-a5-governance-finalizer-v1.md)
  is the separate Owner-authorized L5 settlement path for an exactly proven
  terminal protected-A5 Writer Lease v1. Version 1 supports only
  `FAILED_BEFORE_CONFIG` / `OWNER_ABORTED_PREPARED` and performs no production
  transaction mutation.
- [`PROTECTED_A5_LEGACY_LEASE_COMPATIBILITY_V1`](protected-a5-legacy-lease-compatibility-v1.md)
  is the explicit compatibility adapter for a proven historical protected-A5
  Writer Lease v1 whose metadata layout predates canonical task-root metadata.
  It preserves the lease bytes, derives narrowly typed companion metadata,
  imports predecessor receipts by exact SHA-256, and requires Owner auth v2.

Retrospectives explain origins but do not provide active defaults.
