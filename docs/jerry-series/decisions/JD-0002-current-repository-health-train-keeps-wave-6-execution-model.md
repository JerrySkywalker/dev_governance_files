# JD-0002: Current repository-health train keeps the Wave 6 execution model

Status: Accepted  
Scope: Jerry repository-health train, remaining Waves through M9  
Date: 2026-07-21

## Context

The Lightweight Plan and Outcome Repository Playbook defines a reusable future convention for product-local or task-group Plan/Outcome repositories. The current repository-health train predates that convention and already has a proven execution mechanism from Wave 6.

The generic placement guidance could be misread as requiring the remaining health Waves to create a new task-group repository, migrate `integration-inventory`, publish every local Outcome remotely, or adopt the full future Template lifecycle before continuing.

That is not the intended disposition.

## Decision

Until `M9_GLOBAL_GOVERNANCE_CLOSED` is achieved, the repository-health train shall continue using the proven Wave 6 execution model:

```text
GitHub-hosted Wave orchestrator in dev_governance_files
+ local compact reports and checkpoints under integration-inventory
+ long-running checkpointed Codex execution
+ structured manual flag handoff for blockers and completion
+ web-supervisor verification of live remote repositories
```

For Waves 7 through 9:

1. The Wave-specific orchestrator and governance Plan may remain in `dev_governance_files` because the active task is itself a governance and repository-health program.
2. The complete lightweight Plan/Outcome task-group repository lifecycle is not a required execution mechanism.
3. A new task-group Plan/Outcome repository is not a prerequisite for admission, completion, audit, or milestone declaration.
4. Remote publication of local `outcome.md`, `outcome.json`, checkpoint, validation-root, or artifact content is not a completion dependency.
5. Local files may gradually adopt the names `plan.md`, `goal.md`, `outcome.md`, and `outcome.json` when useful, but the existing compact report/checkpoint model remains valid.
6. `V:\src\integration-inventory` shall not be migrated, converted into a new remote repository, or reorganized as part of Waves 7 through 9 unless a separate owner decision explicitly changes this policy.
7. The future GitHub Template repository and SkyBridge Plan/Outcome transport integration remain post-health-train follow-up work.
8. The owner may continue to provide Codex blocker or completion flags manually for web-supervisor review.

## Precedence

For the active repository-health train, this decision and the `Current repository-health train disposition` section of the Lightweight Plan and Outcome Repository Playbook take precedence over the Playbook's generic task-group repository lifecycle.

The reusable parts of that Playbook still apply where they do not alter the execution mechanism, including:

- Plan immutability;
- narrow append-only owner overrides;
- blocker classification;
- evidence status such as `ACCEPTED`, `REJECTED`, and `SUPERSEDED`;
- honest limits on remote audit coverage;
- compact Outcome design;
- separation of product delivery from coordination records.

## Required Wave 7 planning treatment

Detailed Wave 7 planning must:

- start from the completed M6 state;
- use a Wave-specific durable orchestrator when long-running execution is appropriate;
- preserve local checkpointed resume;
- avoid making the future Template repository or a new evidence-publishing system part of the critical path;
- stop only for genuine owner decisions or unsafe conditions;
- retain structured final flags for manual handoff and remote verification.

## Post-M9 follow-up

After M9, representative health-train examples may be extracted into the future GitHub Template repository. Raw historical local evidence does not need to be migrated wholesale.

The decision to build the Template repository or connect it to SkyBridge must be made as a separate development plan after the health train is closed.

## Non-goals

This decision does not:

- weaken repository-health completion criteria;
- reduce exact-SHA, branch, PR, worktree, or final-audit requirements;
- claim that structured flags are complete remote evidence;
- authorize product, device, service, or production mutations;
- prescribe the detailed Wave 7 dependency graph;
- modify or supersede completed Wave 6 evidence.