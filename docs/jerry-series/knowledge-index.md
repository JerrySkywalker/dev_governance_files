# Jerry Series Knowledge Index

This index lists durable governance knowledge captured from Jerry series development.

## Decisions

- `decisions/JD-0001-web-supervisor-github-governance-writes.md` — Defines the authority split between ChatGPT web and local Codex.
- `decisions/JD-0002-current-repository-health-train-keeps-wave-6-execution-model.md` — Makes the Wave 6 execution model mandatory for the remaining repository-health Waves through M9 instead of requiring the generic Plan/Outcome task-group repository lifecycle.

## Playbooks

- `playbooks/lesson-capture-playbook.md` — How to capture future lessons into this repository.
- `playbooks/protected-evidence-playbook.md` — How to handle unknown or protected evidence, retained evidence worktrees, and post-relocation metadata side effects without losing evidence.
- `playbooks/self-hosted-ci-playbook.md` — How to preflight and recover self-hosted GitHub Actions failures with exact-SHA and causal CI accounting.
- `playbooks/github-private-read-audit-playbook.md` — How to perform authenticated private GitHub reads without credential exposure or mutation.
- `playbooks/branch-worktree-convergence-playbook.md` — How to converge complete live local/remote branch, PR, worktree, archive, and retained-state inventories safely.
- `playbooks/git-operation-marker-reconciliation-playbook.md` — How to distinguish coherent active Git operations from orphan markers and preserve stale metadata safely.
- `playbooks/lightweight-plan-outcome-repository-playbook.md` — Lightweight GitHub conventions for concrete Plans, Goals, Outcomes, blockers, overrides, and SkyBridge status.

## Retrospectives

- `retrospectives/waves-1-to-3-lessons.md` — Lessons from the upstream, Gateway, and consumer waves.
- `retrospectives/wave-4-lessons.md` — Lessons from control-plane topology, no-op product convergence, live-state revalidation, evidence dispositions, and final audit recovery.
- `retrospectives/wave-5-lessons.md` — Lessons from workstation source convergence, single-goal execution, automatic recovery budgets, private cross-repository CI, and complete branch retirement.
- `retrospectives/wave-6-lessons.md` — Lessons from long-running Wave orchestration, runtime overrides, evidence replacement, safe validation, lightweight Plan/Outcome repositories, and SkyBridge boundaries.
- `retrospectives/wave-7a-lessons.md` — Lessons from exact cross-repository E2E, provider-contract repair, Gradle supply-chain proof, task-graph semantic classification, evidence disposition, and the need for a durable authenticated visual-validation channel.

## Plans

- `plans/wave-6-independent-products-plan.md` — Revised six-step Wave 6 plan for owner-controlled independent products, with `hithesis` explicitly skipped as external and not owner-controlled.
- `plans/wave-6-execution-orchestrator.md` — Durable one-invocation Wave 6 state machine for sequential autonomous execution, checkpointed resume, bounded recovery, external-repository skip handling, and final M6 audit.
- `plans/wave-7a-codex-usage-chain-plan.md` — Detailed exact-SHA plan for the Agent → Hub → Gateway → Android safe Codex usage change-message chain.
- `plans/wave-7a-execution-orchestrator.md` — Durable one-invocation W7A state machine for exact cross-repository integration, bounded correction, no-signing Android validation, and final M7A audit.
- `plans/wave-7v-dual-dashboard-visual-validation-plan.md` — Inserts a production/canary dual Glance Dashboard, safe Wave visual packets, 1Panel/Authelia owner gate, cloud Playwright screenshots, and human visual acceptance between W7A and W7B.
- `plans/wave-7v-execution-orchestrator.md` — Durable one-invocation W7V state machine for topology admission, Dashboard source work, local screenshots, isolated Beijing canary deployment, owner-controlled public routing, authenticated cloud Playwright validation, and final visual acceptance.
- `plans/pre-w7b-dashboard-hardening-train.md` — Defines the four-PR, four-owner-gate Dashboard authentication and UI hardening interlude required after completed W7V and before W7B authorization.
- `plans/pre-w7b-dashboard-hardening-execution-orchestrator.md` — Checkpointed one-writer state machine for governance-first delivery, repository-local auth automation, UI contract and previews, owner-controlled production confirmation, and final read-only acceptance.

## Patterns

- `patterns/blocker-taxonomy.md` — Standard blocker classes and expected dispositions.
- `patterns/recovery-goal-evidence-binding.md` — How recovery Goals bind to the last proven stage without requiring artifacts that could not yet exist.

## Non-goals

This knowledge base does not replace product repository documentation, release notes, or raw evidence receipts. It records reusable governance knowledge only.

## Update policy

Small docs-only additions may be performed from ChatGPT web through a pull request in `dev_governance_files`. Product code, local evidence, local Git state, CI recovery, protected evidence operations, server deployment, 1Panel owner actions, and Playwright authenticated state remain local-Codex or owner-controlled work.
