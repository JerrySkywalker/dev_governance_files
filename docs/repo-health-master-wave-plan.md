# Repository-Health Master Wave Plan

Plan ID: repo-health-master-wave-plan
Schema: repo-health-master-wave-plan.v1
Version: 1.7
Status: ACTIVE

The machine-readable canonical plan is config/repo-health-master-wave-plan.json. Wave 0 persists governance and inventory, safely converges only proven-safe worktrees, and adds the deterministic coordinator. Its milestone is M0_FOUNDATION_READY.

## Active versioned amendment

`W1-R01-MAIN-DEV-POLICY-V2` activates [Main/Dev Policy V2](governance/main-dev-policy-v2.md) and its machine-readable source at `policy/main-dev-policy-v2.json`. It supersedes the active branch-policy interpretation while preserving `config/branch-lifecycle-policy.json` as the historical V1 policy and leaving all Wave 1 receipts untouched.

The current amendment is
`W7V-R03-PHASE-A-CLOSEOUT-AND-COMPRESSED-WAVE7-TRAIN`, version `1.7`. It
preserves all earlier amendments, closes Pre-W7B Phase A, moves the
owner-deferred Dashboard UI work after W7E, and authorizes materialization of
the `W7-COMPRESSED-001` run bundle. It does not start W7B or authorize W8/W9.

Wave 7V is `COMPLETED`. Its final closure is bound to:

- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-closure-evidence-20260724T061617Z.json`, SHA-256 `e61178ef3c7a54f0952d56c8047f517358245212fdb83bc1b76863bc92640974`;
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-normalization-validation-20260724T062040Z.txt`, SHA-256 `ab9cbc4c689a8cc5efc690afc0f0dc170b94256cccbdefb3ee51d452e8e025e6`;
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-checkpoint.json`, SHA-256 `5845d381a74546a5b79d71e70c3e40ca30383d441942a5fe2221909447768c4b`; and
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-report.md`, SHA-256 `618155e9d71eb6d384561af545a9789aafd370c186c99e6ab9bbd19d161c3f6e`.

The Wave 7V closure facts remain
`W7V_FORMAL_CONFORMANCE=PASS`, `W7V_OVERALL_STATUS=COMPLETE`,
`DASHBOARD_EXACT_MAIN=c3f0e309ec26238d5d61972b5024d76d478c8adc`, and
`W7B_STARTED=false`.

## Pre-W7B Phase A closeout

The original interlude remains documented by:

- `docs/jerry-series/plans/pre-w7b-dashboard-hardening-train.md`; and
- `docs/jerry-series/plans/pre-w7b-dashboard-hardening-execution-orchestrator.md`.

The accepted current facts are:

```text
M_DASH_AUTH_AUTOMATION_READY=true
PHASE_A_COMPLETE=true
G1_COMPLETE=true
DASHBOARD_EXACT_MAIN=88b9b8e41b992887f832c5c31e230f373700ab5c
PHASE_B_STATUS=DEFERRED_BY_OWNER
PHASE_C_STATUS=DEFERRED_BY_OWNER
M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=false
```

Phases B and C move to `POST_WAVE7_DASHBOARD_UI_HARDENING`, positioned after
W7E and before any later W8 decision. They are not execution-authorized and no
longer block W7B.

## W7B admission

W7B remains `PLANNED_NOT_STARTED`. It may start only when a fresh live
admission proves:

```text
W7V_OVERALL_STATUS=COMPLETE
M_DASH_AUTH_AUTOMATION_READY=true
W7B_OWNER_AUTHORIZATION=true
W7B_STARTED=false
```

Materializing this governance package and run bundle is not W7B owner
authorization.

## Compressed W7B-through-W7E train

The governance contract is
`docs/jerry-series/plans/wave-7-compressed-train-governance.md`. The compact
durable mailbox is the private repository
`JerrySkywalker/jerry-wave7-train`, run `W7-COMPRESSED-001`.

One continuous checkpointed root Implementer will execute W7B, W7C, W7D, and
W7E only after a later W7B authorization. Each Wave keeps a distinct identity,
outcome, real adjacent-implementation replay, fresh independent audit, and safe
Canary packet. `NO_PRODUCT_DELTA_REQUIRED` is the default. A deterministic
defect is the only basis for a product PR, and a changed product requires
exact-head plus exact-main proof.

The run uses an owner-designated validation machine; it does not require every
development laptop to be initialized. Multi-machine initialization remains
backlog. Production authentication is validation-only, and automated
Production credential acquisition is prohibited. The completed web-auth helper
is Canary-only.

After W7E, the run performs combined Canary visual acceptance, records a Wave 7
retrospective, and stops. W8 and W9 remain planned but not authorized.

One root Implementer is the only writer. Governance and coordination repository
changes use normal PR/merge flows as applicable, exact-SHA validation, fresh
separately launched read-only exact-head and exact-main audits, clean
worktrees, and normal branch retirement. GitHub issue comments are notification
only and never executable authorization.

Wave 1 remains `COMPLETED`: `M1_UPSTREAM_CONTRACTS_CONVERGED` is achieved by the recorded Agent, Hub, and Access exact-main evidence. Wave 2 remains `PLANNED` and explicitly `not_started`; this amendment does not authorize or start W2-S01.

The planned train proceeds through upstream identity (W1), Gateway (W2), consumers (W3), proxy and SkyBridge control plane (W4), workstation source (W5), independent products (W6), chain groups W7A through W7E, product milestones (W8), and global governance (W9). Deferred Wave P is outside the current source-health critical path.

Every repository-health action applies the REPO-A through REPO-G template. AGENTS.md is the sole canonical filename and must be updated before or together with the first repository write. Branch policy permits main, a justified optional dev, and short-lived task branches with finite classifications.

Wave 0 forbids product source and branch-ref mutation, permanent deletion, production mutation, secret exposure, and private connection metadata. The known Agent evidence location remains preserved in place and is excluded from reporting contents.
