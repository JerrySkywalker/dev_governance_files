# Repository-Health Master Wave Plan

Plan ID: repo-health-master-wave-plan
Schema: repo-health-master-wave-plan.v1
Version: 1.1
Status: ACTIVE

The machine-readable canonical plan is config/repo-health-master-wave-plan.json. Wave 0 persists governance and inventory, safely converges only proven-safe worktrees, and adds the deterministic coordinator. Its milestone is M0_FOUNDATION_READY.

## Active versioned amendment

`W1-R01-MAIN-DEV-POLICY-V2` activates [Main/Dev Policy V2](governance/main-dev-policy-v2.md) and its machine-readable source at `policy/main-dev-policy-v2.json`. It supersedes the active branch-policy interpretation while preserving `config/branch-lifecycle-policy.json` as the historical V1 policy and leaving all Wave 1 receipts untouched.

Wave 1 is `COMPLETED`: `M1_UPSTREAM_CONTRACTS_CONVERGED` is achieved by the recorded Agent, Hub, and Access exact-main evidence. Wave 2 remains `PLANNED` and explicitly `not_started`; this amendment does not authorize or start W2-S01.

The planned train proceeds through upstream identity (W1), Gateway (W2), consumers (W3), proxy and SkyBridge control plane (W4), workstation source (W5), independent products (W6), chain groups W7A through W7E, product milestones (W8), and global governance (W9). Deferred Wave P is outside the current source-health critical path.

Every repository-health action applies the REPO-A through REPO-G template. AGENTS.md is the sole canonical filename and must be updated before or together with the first repository write. Branch policy permits main, a justified optional dev, and short-lived task branches with finite classifications.

Wave 0 forbids product source and branch-ref mutation, permanent deletion, production mutation, secret exposure, and private connection metadata. The known Agent evidence location remains preserved in place and is excluded from reporting contents.
