# Jerry Series Knowledge Index

This index lists durable governance knowledge captured from Jerry series development.

## Decisions

- `decisions/JD-0001-web-supervisor-github-governance-writes.md` — Defines the authority split between ChatGPT web and local Codex.

## Playbooks

- `playbooks/lesson-capture-playbook.md` — How to capture future lessons into this repository.
- `playbooks/protected-evidence-playbook.md` — How to handle unknown or protected evidence, retained evidence worktrees, and post-relocation metadata side effects without losing evidence.
- `playbooks/self-hosted-ci-playbook.md` — How to preflight and recover self-hosted GitHub Actions failures with exact-SHA and causal CI accounting.
- `playbooks/github-private-read-audit-playbook.md` — How to perform authenticated private GitHub reads without credential exposure or mutation.
- `playbooks/branch-worktree-convergence-playbook.md` — How to converge complete live local/remote branch, PR, worktree, archive, and retained-state inventories safely.
- `playbooks/git-operation-marker-reconciliation-playbook.md` — How to distinguish coherent active Git operations from orphan markers and preserve stale metadata safely.

## Retrospectives

- `retrospectives/waves-1-to-3-lessons.md` — Lessons from the upstream, Gateway, and consumer waves.
- `retrospectives/wave-4-lessons.md` — Lessons from control-plane topology, no-op product convergence, live-state revalidation, evidence dispositions, and final audit recovery.
- `retrospectives/wave-5-lessons.md` — Lessons from workstation source convergence, single-goal execution, automatic recovery budgets, private cross-repository CI, and complete branch retirement.

## Plans

- `plans/wave-6-independent-products-plan.md` — Revised six-step Wave 6 plan for owner-controlled independent products, with `hithesis` explicitly skipped as external and not owner-controlled.
- `plans/wave-6-execution-orchestrator.md` — Durable one-invocation Wave 6 state machine for sequential autonomous execution, checkpointed resume, bounded recovery, external-repository skip handling, and final M6 audit.

## Patterns

- `patterns/blocker-taxonomy.md` — Standard blocker classes and expected dispositions.
- `patterns/recovery-goal-evidence-binding.md` — How recovery Goals bind to the last proven stage without requiring artifacts that could not yet exist.

## Non-goals

This knowledge base does not replace product repository documentation, release notes, or raw evidence receipts. It records reusable governance knowledge only.

## Update policy

Small docs-only additions may be performed from ChatGPT web through a pull request in `dev_governance_files`. Product code, local evidence, local Git state, CI recovery, and protected evidence operations remain local-Codex work.
