# Jerry Series Knowledge Index

This index lists durable governance knowledge captured from Jerry series development.

## Decisions

- `decisions/JD-0001-web-supervisor-github-governance-writes.md` — Defines the authority split between ChatGPT web and local Codex.

## Playbooks

- `playbooks/lesson-capture-playbook.md` — How to capture future lessons into this repository.
- `playbooks/protected-evidence-playbook.md` — How to handle unknown or protected evidence without losing it.
- `playbooks/self-hosted-ci-playbook.md` — How to preflight and recover self-hosted GitHub Actions failures.
- `playbooks/github-private-read-audit-playbook.md` — How to perform authenticated private GitHub reads without credential exposure or mutation.
- `playbooks/branch-worktree-convergence-playbook.md` — How to converge branches, PRs, worktrees, and archive tags safely.

## Retrospectives

- `retrospectives/waves-1-to-3-lessons.md` — Lessons from the upstream, Gateway, and consumer waves.

## Patterns

- `patterns/blocker-taxonomy.md` — Standard blocker classes and expected dispositions.

## Non-goals

This knowledge base does not replace product repository documentation, release notes, or raw evidence receipts. It records reusable governance knowledge only.

## Update policy

Small docs-only additions may be performed from ChatGPT web through a pull request in `dev_governance_files`. Product code, local evidence, local Git state, CI recovery, and protected evidence operations remain local-Codex work.
