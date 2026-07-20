# Lightweight Plan and Outcome Repository Playbook

## Classification

```text
classification: playbook
scope: agent-assisted development planning, execution handoff, and outcome review
originating_waves:
  - Wave 5
  - Wave 6
```

## Purpose

Provide a lightweight, reusable convention for hosting an executable development Plan and its Outcome in GitHub without building a large centralized execution platform.

The convention supports:

- a single-repository feature or repair;
- a multi-repository task group;
- a long-running Codex orchestrator;
- human owner decisions and resume;
- remote web-supervisor review;
- later SkyBridge monitoring and transport.

The convention deliberately remains smaller than a general workflow engine, event database, artifact platform, or universal execution ledger.

## Core rule

```text
Governance defines how work should be organized.
A task repository records one concrete task group.
Product repositories contain product source and durable product-specific assets.
SkyBridge transports state and decisions.
```

Do not make the record-keeping system larger than the product work it supports.

## Storage layers

### Governance layer

Repository example:

```text
dev_governance_files
```

Store:

- stable cross-project principles;
- Plan/Outcome conventions;
- blocker and override rules;
- reusable playbooks and patterns;
- retrospectives;
- template design guidance.

Do not store:

- every concrete Goal;
- every local checkpoint;
- raw local logs;
- private runtime evidence;
- high-frequency project status;
- product-specific execution history that has no cross-project value.

### Task-group Plan/Outcome layer

Use a separate repository created from a future template when a task spans multiple repositories, agents, or integration gates.

Examples:

```text
skybridge-feature-train
observatory-milestone-12
repository-health-train
wearos-healthprobe-program
```

Store:

- the concrete task-group Plan;
- the executable Goal or orchestrator;
- compact Outcome files;
- blocker and override records when needed;
- artifact references;
- integration and final audit results.

A task-group repository is scoped to one program, milestone family, or coherent development train. It is not a universal ledger for every future task.

### Product layer

Store in the product repository:

- source code;
- tests;
- CI workflows;
- product contracts and schemas;
- durable validation scripts;
- architecture decisions;
- product-specific plans and outcomes that remain useful to maintainers.

Do not use a product repository as a dump for raw agent transcripts, local machine evidence, or unrelated cross-repository coordination.

## Choosing the placement mode

### Mode A: product-repository placement

Use this mode when all or most of the following are true:

- one product repository is involved;
- the Plan is strongly coupled to that product version;
- the Outcome is useful to future maintainers;
- the record is small;
- there is no sensitive local evidence;
- cross-repository coordination is minimal.

Recommended path:

```text
docs/runs/<run-id>/
  plan.md
  goal.md
  outcome.md
  outcome.json
```

Suitable examples:

- a schema migration inside one repository;
- a focused refactor;
- a release-readiness audit;
- a bounded feature train;
- a product-specific incident repair.

### Mode B: separate task-group repository

Use this mode when any of the following are material:

- several product repositories are involved;
- several agents or worktrees operate in parallel;
- the work has a provider/consumer or other dependency graph;
- integration results do not belong naturally to one product repository;
- blockers and owner overrides require central coordination;
- a long-running orchestrator needs a durable GitHub entry point.

Recommended structure:

```text
README.md
AGENTS.md
plan/
  overview.md
  goal.md
  repository-matrix.md
runs/
  <run-id>/
    outcome.md
    outcome.json
    blocker.md        # optional
    override.md       # optional
    artifacts.md      # optional
final/
  outcome.md
  outcome.json
```

Do not create one repository per tiny Codex invocation. The unit is a coherent task group.

## Minimum run bundle

The preferred minimum is four files.

### `plan.md`

Human-readable intent and boundaries:

- objective;
- scope and repositories;
- dependency ordering;
- allowed mutations;
- prohibited mutations;
- validation strategy;
- delivery strategy;
- completion criteria;
- blocker conditions;
- expected outputs.

### `goal.md`

The concrete executable prompt passed to the local executor.

The Goal should identify:

- authoritative Plan and repository refs;
- exact working root;
- checkpoint and outcome paths;
- execution order;
- automatic recovery budget;
- owner-decision boundaries;
- safety prohibitions;
- final output contract.

For a long-running task, the same short resume prompt should be able to reload the durable Goal and checkpoint.

### `outcome.md`

Human-readable result:

- what was done;
- what changed;
- what did not change;
- product and repository results;
- validation performed;
- blockers encountered;
- owner overrides applied;
- rejected or superseded evidence;
- deferred items;
- final conclusion;
- next step.

### `outcome.json`

Small machine-readable status for CI, SkyBridge, and later review.

Minimum fields:

```json
{
  "schema": "agent-plan-outcome.v1",
  "run_id": "...",
  "status": "planned|running|blocked|complete|failed",
  "plan_ref": {
    "repository": "...",
    "commit": "...",
    "path": "..."
  },
  "current_step": "...",
  "current_phase": "...",
  "repositories": [],
  "initial_shas": {},
  "final_shas": {},
  "product_outcomes": {},
  "validations": [],
  "blockers": [],
  "overrides": [],
  "artifacts": [],
  "production_action": false,
  "next_step": null
}
```

Do not introduce a large schema family before repeated real tasks prove it necessary.

## Plan immutability and runtime overrides

Once execution begins, preserve the exact Plan and Goal that authorized the run.

Do not silently edit the original Goal to make a blocker appear preauthorized.

When the owner authorizes a narrow exception, append an override record containing:

```text
override id
run and step
blocked phase
exact authorization
remaining prohibitions
one-time status
consumed status
expiry boundary
```

Small projects may store overrides in `override.md` or in the `overrides` array of `outcome.json`. A larger task group may use one file per decision.

A runtime override should not require a change to `dev_governance_files` unless it reveals a reusable governance defect.

## Blocker handling

Top-level blocker classes should remain small:

```text
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

Use `OWNER_DECISION_REQUIRED` for:

- a real product-direction choice;
- a bounded scope or budget extension;
- credential-policy selection;
- branch-policy changes;
- a production, signing, device, or deployment authorization;
- multiple reasonable dispositions for unique work.

Use `UNSAFE_BLOCKER` for:

- secret exposure;
- unknown or unowned mutation;
- force or history rewrite requirement;
- unclassified unique history;
- concurrent ref drift;
- inability to bind evidence to exact source state;
- an execution path whose safety cannot be demonstrated.

A blocker record should include:

```text
blocked step and phase
blocker text
exact affected scope
current safe state
options
recommended option
mutations already completed
mutations not performed
resume instruction
```

## Evidence and artifact handling

Outcome records should distinguish:

```text
ACCEPTED
REJECTED
SUPERSEDED
INFORMATIONAL_ONLY
LOCAL_ONLY
```

Do not delete a rejected validation attempt merely because a later attempt passed. Do not let rejected evidence remain eligible for acceptance.

Keep small, safe evidence in Git when it materially supports review:

- summaries;
- compact JSON;
- task graphs;
- small diffs;
- validation result tables;
- artifact hashes and references.

Do not commit:

- secrets or credentials;
- signing material;
- private device data;
- raw production payloads;
- large generated logs without a clear need;
- local user configuration;
- protected evidence descendants.

When an artifact remains local-only, state that fact honestly. Do not claim that a remote reviewer inspected it.

## Remote review model

A complete web-supervisor review should compare as many of these sources as are available:

```text
stable governance rule
locked Plan / Goal
Outcome claims
published compact evidence
live product repository state
```

When local reports or artifacts are not published, describe the review accurately as remote repository verification plus structured local outcome claims.

Do not overstate remote audit coverage.

## GitHub lifecycle

For a separate task-group repository, the preferred lightweight lifecycle is:

```text
create from template
-> write Plan and Goal
-> review/freeze Plan
-> execute locally
-> update Outcome at meaningful boundaries
-> review product repositories and Outcome
-> merge or close the task-group record
```

Meaningful update boundaries include:

- a step completed;
- a genuine blocker;
- an owner override consumed;
- a long-running session stopping;
- final audit completed.

Do not require a commit for every command or internal phase.

Product changes still use product-repository branches and pull requests. The task-group repository records coordination and results; it does not replace product delivery history.

## SkyBridge interface

SkyBridge should remain a transport and control plane rather than the durable source of truth.

A minimal status interface may contain:

```json
{
  "schema": "agent-run-status.v1",
  "run_id": "...",
  "status": "running|blocked|complete",
  "plan_ref": {
    "repository": "...",
    "commit": "...",
    "path": "plan/goal.md"
  },
  "current_step": "...",
  "current_phase": "...",
  "blocker_summary": null,
  "outcome_path": "runs/.../outcome.json",
  "last_updated_at": "..."
}
```

Initial SkyBridge capabilities should be read-oriented:

- display current task, step, phase, and exact Plan ref;
- surface blocker summaries;
- notify the owner;
- link to the GitHub Plan and Outcome.

Later capabilities may include:

- pulling a frozen Plan;
- launching or resuming a local Codex session;
- publishing sanitized Outcome updates;
- returning a narrow owner decision to the local executor.

SkyBridge should not need to understand the full internal Goal grammar.

## Current repository-health train disposition

The active repository-health train should continue using the proven Wave 6 model:

```text
GitHub-hosted orchestrator
local compact report/checkpoint
long-running Codex execution
manual structured flag handoff
web remote-repository verification
```

Do not migrate the current `integration-inventory` tree or build the future Template repository in the middle of the health train.

For remaining Waves, local outputs may gradually standardize around:

```text
plan.md
goal.md
outcome.md
outcome.json
```

without making remote publishing a new completion dependency.

After the health train completes, representative examples may be extracted into a future GitHub Template repository. Raw historical local evidence does not need to be migrated wholesale.

## Future Template repository

A future template should remain small:

```text
README.md
AGENTS.md
plan/plan.md
plan/goal.md
outcome/outcome.md
outcome/outcome.json
templates/blocker.md
templates/override.md
scripts/New-Run.ps1
scripts/Test-RunBundle.ps1
scripts/Close-Run.ps1
.github/workflows/validate-plan-outcome.yml
```

The first release should include:

- one single-repository example;
- one multi-repository task-group example;
- simple file and JSON validation;
- secret scanning;
- no database;
- no mandatory external artifact service;
- no custom web UI.

Prove the convention on real development before adding heavier infrastructure.

## Anti-patterns

Avoid:

- one centralized repository containing every task forever without clear scope;
- raw Codex transcript dumping;
- replacing product PRs with Outcome files;
- editing the original Plan after execution without an explicit override;
- treating final flags as complete evidence by themselves;
- making local-only evidence appear remotely audited;
- building a workflow platform before the lightweight convention is proven;
- placing all project-specific execution records in `dev_governance_files`;
- coupling SkyBridge to one executor or one Goal syntax.

## Non-goals

This playbook does not:

- mandate a new repository for every task;
- require migration of existing local evidence;
- define a universal event database;
- replace GitHub Issues, pull requests, CI, or product documentation;
- authorize automatic production or device actions;
- authorize SkyBridge implementation work;
- prescribe the detailed Wave 7 plan.
