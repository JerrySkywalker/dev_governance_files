# Jerry Series Knowledge Index

This index separates active normative sources, conditional operations, and
historical evidence.

## Harness — active normative

- `harness/README.md` / `harness/README.zh-CN.md` — bilingual Agent and human entrypoints.
- `harness/harness-specification-v1.md` — semantics for `A/B/P`, `V/E/F/G`, `L0-L5`, ledgers, transitions, and protected state.
- `harness/harness-baseline-v1.md` — empirical rationale and calibration policy.
- `harness/harness-goal-receipt-contract-v1.md` — Goal, Cycle, Gate, Stop, and Completion interfaces.
- `../../config/repo-health-harness-v1.json` — only active numeric source.
- `../../.agent/context-manifest-v1.json` — Agent context routing source.

## Decisions — active normative rationale

- `decisions/JD-0001-web-supervisor-github-governance-writes.md`
- `decisions/JD-0002-current-repository-health-train-keeps-wave-6-execution-model.md`
- `decisions/JD-0003-progress-sensitive-autonomous-execution-budgets.md`
- `decisions/JD-0004-unified-harness-control-contract.md`

Decisions explain accepted policy; they do not duplicate active parameter values.

## Playbooks — conditional operational

- `playbooks/lesson-capture-playbook.md`
- `playbooks/protected-evidence-playbook.md`
- `playbooks/self-hosted-ci-playbook.md`
- `playbooks/github-private-read-audit-playbook.md`
- `playbooks/branch-worktree-convergence-playbook.md`
- `playbooks/git-operation-marker-reconciliation-playbook.md`
- `playbooks/lightweight-plan-outcome-repository-playbook.md`
- `playbooks/canonical-git-object-audit-packet-playbook.md`

Read only the Playbook matching the current task and Harness environment/layer.

## Patterns — conditional reusable form

- `patterns/blocker-taxonomy.md`
- `patterns/recovery-goal-evidence-binding.md`
- `patterns/incremental-resume-goal-pattern.md`

The former standalone elastic-budget, validation-depth, and hyperparameter
Patterns were superseded by the unified Harness sources.

## Retrospectives — historical reference

- `retrospectives/waves-1-to-3-lessons.md`
- `retrospectives/wave-4-lessons.md`
- `retrospectives/wave-5-lessons.md`
- `retrospectives/wave-6-lessons.md`
- `retrospectives/wave-7a-lessons.md`
- `retrospectives/wave-7-lessons.md`
- `retrospectives/wave-7-end-to-end-lessons.md`
- `retrospectives/post-w7-dashboard-production-release-closeout.md`
- `retrospectives/workstation-manager-p0-5-p1a-interim-lessons.md`

Retrospectives are non-normative, not default Agent context, and never an
execution source.

## Plans — explicit binding or historical audit only

Plans remain durable history. Read only a Plan named by the current Goal or an
explicit audit. Old Plan parameters do not become current defaults.

## Update policy

Changes to active Harness semantics or frozen parameters require a versioned
governance decision, updated machine source, generated-reference check, contract
tests, and independent review. Historical evidence is preserved separately.
