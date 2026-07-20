# Wave 6 Lessons

## Classification

```text
classification: retrospective
related_wave: Wave 6
milestone: M6_REPOSITORY_HEALTH_TRAIN_COMPLETE
related_repositories:
  - codex-ntfy-notifier
  - wearos-healthprobe-preflight
  - wearos-healthprobe-app
external_not_owned:
  - hithesis
```

## Scope

Wave 6 tested a broader execution model than earlier waves. One GitHub-hosted orchestrator directed a durable local Codex run across multiple repository steps, used a local checkpoint for resume, paused only for explicit owner decisions or unsafe conditions, skipped a third-party repository without modifying it, and completed with an independent all-repository audit.

The wave proved that a multi-step repository-health train can be executed through one owner-visible invocation while preserving repository-level write isolation and exact completion gates.

## Outcome

```text
W6_COMPLETE=true
M6_REPOSITORY_HEALTH_TRAIN_COMPLETE=true
W6_S01_COMPLETE=true
W6_S02_COMPLETE=true
W6_S03_COMPLETE=true
W6_S04_COMPLETE=true
W6_S05_COMPLETE=true
W6_S06_COMPLETE=true
unclassified_object_count=0
unresolved_repository_health_debt=0
force_push=false
history_rewrite=false
device_mutation=false
windows_service_mutation=false
production_action=false
```

The notifier repository required a real product correction and a normal pull-request delivery. The preflight and Wear OS app repositories completed through formal source-convergence and contract-validation outcomes without manufacturing unnecessary product changes. The downloaded `hithesis` repository was recorded as `SKIPPED_EXTERNAL_NOT_OWNED` and did not block the milestone.

## Durable lessons

### 1. A GitHub-hosted plan can coordinate a long-running multi-step Wave

Wave 6 used one stable orchestrator file plus one local durable checkpoint:

```text
GitHub-hosted orchestrator
        +
local checkpoint and evidence
        =
restartable multi-repository execution
```

A terminal, network, quota, HAPI, or machine interruption need not invalidate completed phases. A resumed executor must re-read the checkpoint, revalidate the recorded live state, and continue from the last proven phase.

Reusable rule:

```text
ONE_WAVE
ONE_DURABLE_ORCHESTRATOR
ONE_LOCAL_RESUME_CHECKPOINT
NO_ACKNOWLEDGEMENT_BETWEEN_ORDINARY_SUCCESSFUL_STEPS
```

### 2. Stable policy and runtime state have different homes

The GitHub-hosted plan should contain stable policy:

- step ordering and dependencies;
- repository ownership and scope;
- allowed and prohibited mutations;
- validation and delivery gates;
- blocker classes;
- milestone conditions.

The local checkpoint should contain runtime facts:

- current step and phase;
- accepted local and remote state;
- active locks;
- performed mutations;
- current blocker;
- consumed owner overrides;
- accepted and rejected evidence;
- next action.

Do not rewrite the stable governance plan for every runtime exception.

### 3. Runtime owner overrides should be narrow, append-only, and consumable once

Wave 6 required two owner decisions:

- one additional bounded corrective commit for a test-helper defect;
- a no-signing validation restart after an inadmissible Android build attempt.

Both decisions were valid runtime dispositions and did not require a governance-plan pull request.

A runtime override should record:

```text
override identity
blocked step and phase
exact scope
one-time or reusable status
newly authorized operation
operations still prohibited
consumed status
expiry boundary
governance plan modified = false
```

An override must not silently propagate to later steps.

### 4. Blocker classes should reflect the required authority, not merely the inconvenience

A corrective-commit budget prevented unbounded iterative repair, but exhausting a small numerical budget did not itself make the repository unsafe. It required owner authority to extend the budget.

Future blocker classification should prefer:

```text
OWNER_DECISION_REQUIRED
```

for a bounded scope or budget extension when the proposed change is already understood and remains inside the established safety boundary.

Use:

```text
UNSAFE_BLOCKER
```

when the continuation itself would create an unclassified safety risk, such as secret exposure, unknown filesystem mutation, force/history rewrite, unclassified unique history, or evidence that cannot be bound to an exact source state.

### 5. Final audits must inspect helper and integration boundaries, not only primary product logic

The notifier product accepted a custom Codex directory, but its test helper initially failed to propagate the same directory into the child process. The primary script was correct while the validation path could still fall back to the real user directory.

Reusable rule:

```text
When a safety parameter defines an isolation boundary,
verify that every wrapper, helper, subprocess, template, and test invocation
propagates the same parameter end to end.
```

A final audit should trace the complete invocation chain rather than inspect only the target implementation.

### 6. Non-access evidence must be designed before execution

The first Wear OS app validation invoked an Android assembly target whose task graph included debug-signing operations. Because pre-run signing state and isolation were not captured, the run could not support a claim that no signing key was accessed.

The safe response was not to infer safety from the aftermath. The result was rejected as acceptance evidence and replaced with a fresh validation using:

- isolated Gradle, Android, and Java user homes;
- a tracked-config signing audit;
- an explicit task-graph guard;
- a forbidden-task denylist;
- source-validation targets that did not assemble, package, sign, install, deploy, or publish.

Reusable sequence:

```text
prevent
-> bind isolated roots
-> inspect the planned task graph
-> execute under a guard
-> verify the guarded result
```

Do not use:

```text
execute first
-> inspect afterwards
-> claim that a sensitive resource was not accessed
```

This rule also applies to credentials, user configuration, production databases, device state, deployment keys, and external services.

### 7. Evidence status is a first-class state

A failed or unsafe validation attempt must not be deleted from the history and must not remain eligible for acceptance accidentally.

Minimum evidence states are:

```text
ACCEPTED
REJECTED
SUPERSEDED
INFORMATIONAL_ONLY
LOCAL_ONLY
```

Every rejected or superseded item should record:

- the reason;
- the source state to which it was bound;
- whether any product mutation occurred;
- the replacement evidence when one exists.

A later successful attempt does not rewrite the facts of an earlier attempt.

### 8. Formal no-product-delta outcomes are essential

Wave 6 did not create product commits merely to make every step appear active. A repository may complete through:

```text
NO_PRODUCT_DELTA_REQUIRED
```

when:

- the current product already satisfies the intended contract;
- source-validatable gates pass;
- local and remote canonical state is converged;
- retained or deferred evidence is explicit;
- a fresh final audit passes.

This reduces noise and keeps product history meaningful.

### 9. Provider contracts must be frozen before consumer validation

The Wear OS preflight repository was treated as a provider of probe and readiness semantics. Its exact accepted contract was frozen before the app consumer was evaluated.

Reusable dependency rule:

```text
provider source convergence
-> exact contract freeze
-> consumer compatibility audit
```

Do not let a downstream consumer define or silently reinterpret an unfrozen upstream contract during the same write phase.

### 10. External repositories should be excluded at the ownership boundary

A downloaded third-party repository is not repository-health debt merely because it exists under the local source root.

The correct disposition is explicit:

```text
SKIPPED_EXTERNAL_NOT_OWNED
product writes = 0
Git ref mutations = 0
milestone blocking = false
```

Do not modify, clean, normalize, fork, archive, or delete an external repository as part of an owner-controlled health train without separate authority.

### 11. Completion flags and remote repository inspection are useful but not a complete evidence transport layer

During Wave 6, the web supervisor reviewed:

- the structured final flags returned by Codex;
- current remote repositories, branches, pull requests, and exact commits.

The web supervisor could not directly inspect all local Markdown reports, JSON checkpoints, validation roots, or local-only artifacts under `integration-inventory`.

Therefore the current audit should be described accurately as:

```text
remote product-state verification
+
structured local outcome claims
```

It is not yet a complete remote audit of every local evidence file.

The remaining repository-health waves may continue this proven lightweight model. A heavier evidence-publishing subsystem must not interrupt the active health train.

### 12. Plan and Outcome should become a lightweight reusable repository convention

Future development should not begin with a universal execution database or a large centralized ledger. A smaller convention is sufficient:

```text
plan.md
goal.md
outcome.md
outcome.json
optional blocker / override / artifact notes
```

The convention can later be published as:

- a development guideline in `dev_governance_files`;
- a GitHub Template repository;
- a small SkyBridge-compatible status interface.

The template should be proven on real tasks before adding databases, complex event streams, large artifact stores, or a dedicated web application.

### 13. Plan and Outcome placement depends on task scope

Use product-repository placement when:

- one product repository is involved;
- the plan is strongly coupled to that product version;
- the outcome remains useful to future product maintainers;
- the record is small and contains no private local evidence.

Use a separate task-group Plan/Outcome repository when:

- multiple repositories or agents are involved;
- there is a dependency graph or integration milestone;
- one product repository is not the natural owner of the plan;
- blockers and owner overrides must be coordinated centrally.

Do not place every runtime record into `dev_governance_files`. That repository remains the stable cross-project governance layer.

### 14. SkyBridge should provide transport and control, not become the evidence source of truth

A future integration should use:

```text
GitHub repository = durable Plan and Outcome source of truth
SkyBridge = distribution, launch, monitoring, notification, and decision transport
Codex = local executor
web ChatGPT = architect, supervisor, and governance writer
```

SkyBridge should initially consume a small status contract containing:

- run identifier;
- plan repository and commit;
- current step and phase;
- status;
- blocker summary;
- outcome path;
- last update time.

SkyBridge should not need to parse or own the full Goal format.

### 15. Wave completion and governance metadata closeout are distinct gates

A local Wave checkpoint can prove the product and repository-health milestone while the remote master plan still records the Wave as planned.

Future Waves should explicitly close this gap:

```text
local milestone completion
-> web supervisor remote verification
-> docs-only governance closeout
-> next-Wave planning
```

Do not start the next Wave merely because the executor printed success when the durable governance status still needs reconciliation.

### 16. Do not let workflow infrastructure replace the product objective

The purpose of the repository-health train is to converge and audit repositories. A new harness, ledger, template system, or SkyBridge integration should not become a prerequisite in the middle of the train unless the current work cannot proceed safely without it.

Reusable rule:

```text
finish the active critical path with the lightest proven mechanism;
extract the reusable convention afterwards.
```

## Operational consequences for Wave 7 planning

Before Wave 7 starts:

- reconcile Wave 6 completion into the master governance plan;
- perform a detailed dependency and topology review rather than relying on the existing coarse W7 step names;
- continue the W6 long-running-orchestrator pattern only after the W7 graph is frozen;
- keep one writer per repository and explicit provider/consumer contract ordering;
- retain compact local reports and checkpoints;
- continue structured flag handoff for owner-visible blockers and final completion;
- optionally standardize local outputs to `plan.md`, `goal.md`, `outcome.md`, and `outcome.json` without introducing a new remote execution platform;
- keep Plan/Outcome template development and SkyBridge automation outside the active W7 critical path unless separately scheduled.

Wave 7 must remain not started until its dependency directions, repository scopes, evidence classes, and production/device boundaries are reviewed in detail.

## Non-goals

This retrospective does not:

- publish or replace raw local Wave 6 evidence;
- claim that the web supervisor inspected files that remained local-only;
- authorize migration of the existing `integration-inventory` directory;
- create a centralized execution-ledger product;
- create the future Plan/Outcome Template repository;
- authorize SkyBridge product changes;
- authorize Wave 7 execution;
- expose credentials, signing material, private runtime payloads, device data, or protected evidence.

## Sensitivity notes

Only reusable governance facts are recorded here. Private repository payloads, exact local evidence contents, credentials, signing material, local validation roots, and device/runtime data remain outside this public governance repository.
