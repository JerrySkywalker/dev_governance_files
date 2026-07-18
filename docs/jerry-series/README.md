# Jerry Series Governance Knowledge

This directory stores durable governance knowledge for the Jerry series development workflow.

It is intended for cross-repository lessons, architectural decisions, execution playbooks, audit patterns, and wave retrospectives. It should not store raw logs, credentials, protected evidence contents, private runtime payloads, or machine-local evidence trees.

## Operating model

- ChatGPT web acts as supervisor, architect, and governance documentation writer.
- Local Codex acts as implementer, subsystem architect, local verifier, and evidence/worktree operator.
- GitHub stores durable governance memory and reviewable docs-only changes.
- Product repository code changes, local Git operations, CI recovery, worktree cleanup, archive tags, and protected evidence handling remain local-Codex responsibilities.

## Directory map

```text
principles/      Stable cross-wave rules.
playbooks/       Repeatable operational procedures.
retrospectives/  Wave and incident lessons.
decisions/       Jerry Decisions (JD) for durable governance choices.
patterns/        Goal, blocker, Supervisor, and evidence templates.
```

## Capture rule

When a conversation produces reusable design experience, capture it as one of:

- a principle when it is stable and general;
- a playbook when it is executable procedure;
- a retrospective when it records what happened and what changed;
- a decision when it changes authority, responsibility, or workflow;
- a pattern when it should be reused in future Goals.

Do not rely on chat history as the only memory for Jerry series development.
