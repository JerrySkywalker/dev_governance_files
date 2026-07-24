# Repository-Health Master Wave Plan

Plan ID: repo-health-master-wave-plan
Schema: repo-health-master-wave-plan.v1
Version: 1.6
Status: ACTIVE

The machine-readable canonical plan is config/repo-health-master-wave-plan.json. Wave 0 persists governance and inventory, safely converges only proven-safe worktrees, and adds the deterministic coordinator. Its milestone is M0_FOUNDATION_READY.

## Active versioned amendment

`W1-R01-MAIN-DEV-POLICY-V2` activates [Main/Dev Policy V2](governance/main-dev-policy-v2.md) and its machine-readable source at `policy/main-dev-policy-v2.json`. It supersedes the active branch-policy interpretation while preserving `config/branch-lifecycle-policy.json` as the historical V1 policy and leaving all Wave 1 receipts untouched.

The current amendment is
`W7V-R02-PRE-W7B-DASHBOARD-HARDENING`, version `1.6`. It preserves all earlier
amendments and records the final Wave 7V closure before inserting the named
`PRE-W7B-DASHBOARD-HARDENING` interlude. It does not add a Wave or change the
existing W7B identifier, steps, visual channel, dependency direction, or
milestone.

Wave 7V is `COMPLETED`. Its final closure is bound to:

- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-closure-evidence-20260724T061617Z.json`, SHA-256 `e61178ef3c7a54f0952d56c8047f517358245212fdb83bc1b76863bc92640974`;
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-normalization-validation-20260724T062040Z.txt`, SHA-256 `ab9cbc4c689a8cc5efc690afc0f0dc170b94256cccbdefb3ee51d452e8e025e6`;
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-checkpoint.json`, SHA-256 `5845d381a74546a5b79d71e70c3e40ca30383d441942a5fe2221909447768c4b`; and
- `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-report.md`, SHA-256 `618155e9d71eb6d384561af545a9789aafd370c186c99e6ab9bbd19d161c3f6e`.

The final facts are
`W7V_FORMAL_CONFORMANCE=PASS`, `W7V_OVERALL_STATUS=COMPLETE`,
`DASHBOARD_EXACT_MAIN=c3f0e309ec26238d5d61972b5024d76d478c8adc`, and
`W7B_STARTED=false`.

## Pre-W7B Dashboard hardening interlude

The interlude is defined by:

- `docs/jerry-series/plans/pre-w7b-dashboard-hardening-train.md`; and
- `docs/jerry-series/plans/pre-w7b-dashboard-hardening-execution-orchestrator.md`.

Its overall milestone is
`M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE`. The existing W7B remains
`PLANNED_NOT_STARTED` and now requires that milestone as an explicit entry gate
in addition to its preserved dependency on W7V.

The train has three sequential phase milestones:

1. `M_DASH_AUTH_AUTOMATION_READY`;
2. `M_DASH_UI_CONTRACT_V1_READY`; and
3. `M_DASH_PRODUCTION_UI_HARMONIZED`.

It requires four separate Dashboard product pull requests:

1. repository-local authentication automation;
2. Dashboard UI contract v1;
3. production-shaped fixture-backed Canary preview; and
4. accepted production-only UI harmonization.

It also requires four owner gates:

1. dedicated non-personal Canary E2E identity, exact-Canary policy, and local
   credential provisioning;
2. UI contract and three-viewport fixture-preview acceptance;
3. production-shaped preview, duplicate-title, and panel-depth decisions; and
4. owner-controlled production deployment, validation, and rollback proof.

One root Implementer is the only writer. Every PR uses a short-lived branch,
normal push and merge, self-hosted exact-head and exact-main proof, fresh
independent read-only review, and normal remote plus local branch retirement.
No force push, hosted-runner fallback, cross-phase combined PR, or automatic
empty-commit rerun is permitted.

The governance change permits one planned commit and one bounded corrective
docs/schema commit. Each product PR permits at most two planned commits, two
corrective product commits, and one test/harness-only corrective commit. G2 and
G3 permit one bounded correction round each. Authentication permits one login
submission per invocation and no automatic password retry. Production permits
one owner apply and one automatic rollback; another apply requires a fresh owner
decision.

The Implementer may prepare deployment inputs but may not deploy production,
modify Authelia or OpenResty, create the dedicated identity, access credential
values, or retain authentication state as evidence. Governance and CI evidence
must not contain credentials, personal identity details, cookies, tokens,
storage-state contents, raw authentication errors, secret-bearing command lines,
or private keys.

The interlude returns to the W7B authorization boundary only after all three
phase milestones, all four owner gates, four distinct merged PRs, self-hosted
exact-head/exact-main proof, rollback evidence, and a fresh final read-only audit
set `M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=true`. It does not start W7B.

Wave 1 remains `COMPLETED`: `M1_UPSTREAM_CONTRACTS_CONVERGED` is achieved by the recorded Agent, Hub, and Access exact-main evidence. Wave 2 remains `PLANNED` and explicitly `not_started`; this amendment does not authorize or start W2-S01.

The planned train proceeds through upstream identity (W1), Gateway (W2), consumers (W3), proxy and SkyBridge control plane (W4), workstation source (W5), independent products (W6), chain groups W7A through W7E, product milestones (W8), and global governance (W9). Deferred Wave P is outside the current source-health critical path.

Every repository-health action applies the REPO-A through REPO-G template. AGENTS.md is the sole canonical filename and must be updated before or together with the first repository write. Branch policy permits main, a justified optional dev, and short-lived task branches with finite classifications.

Wave 0 forbids product source and branch-ref mutation, permanent deletion, production mutation, secret exposure, and private connection metadata. The known Agent evidence location remains preserved in place and is excluded from reporting contents.
