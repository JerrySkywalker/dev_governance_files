# Wave 6 Execution Orchestrator

## Classification

```text
classification: executable governance plan
related_wave: Wave 6
milestone: M6_REPOSITORY_HEALTH_TRAIN_COMPLETE
status: PLANNED_NOT_STARTED
```

## Purpose

This document is the durable entrypoint for running Wave 6 as one checkpointed
Codex session. It turns the six stable Wave 6 steps into an ordered state
machine that can continue without owner interaction between ordinary steps.

The authoritative scope remains:

- `wave-6-independent-products-plan.md`;
- the repository-health master wave plan;
- applicable Jerry-series playbooks and blocker taxonomy.

When this file and the broader plan differ, stop with
`W6_OWNER_DECISION_REQUIRED`; do not silently broaden product or mutation scope.

## Single invocation contract

The visible interactive Codex TUI root is the Wave 6 coordinator.

Execute in this order:

```text
W6-S01 codex-ntfy-notifier
-> W6-S02 wearos-healthprobe-preflight
-> W6-S03 wearos-healthprobe-app
-> W6-S04 hithesis SKIPPED_EXTERNAL_NOT_OWNED
-> W6-S05 remaining owner-controlled canonical repository review
-> W6-S06 all-owner-repository final health audit
```

Do not wait for owner acknowledgement after an ordinary successful step.

Stop only for:

```text
W6_COMPLETE
W6_OWNER_DECISION_REQUIRED
W6_UNSAFE_BLOCKER
```

Do not invent owner-visible suffix steps such as `W6-S01A` or recovery step
identifiers. Internal phases belong in the durable checkpoint.

## Durable state

Workspace root:

```text
V:\src
```

Required prior milestone:

```text
V:\src\integration-inventory\repo-health\w5-workstation-closeout-checkpoint.json
```

Wave 6 orchestrator checkpoint:

```text
V:\src\integration-inventory\repo-health\w6-execution-orchestrator-checkpoint.json
```

Wave 6 final outputs:

```text
V:\src\integration-inventory\repo-health\w6-repository-health-train-report.md
V:\src\integration-inventory\repo-health\w6-repository-health-train-checkpoint.json
```

On first execution create the orchestrator checkpoint atomically with:

```text
schema=w6-execution-orchestrator.v1
W6_STARTED=true
W6_COMPLETE=false
current_step=W6-S01
current_phase=admission
completed_steps=[]
owner_decision_required=false
unsafe_blocker=false
production_action=false
```

After each material phase atomically update:

```text
current_step
current_phase
accepted_repository
accepted_branch
accepted_SHA
completed_phases
completed_steps
active_locks
automatic_recoveries
mutation_accounting
CI_accounting
next_action
```

A checkpoint is historical evidence, not permission to skip fresh live-state
revalidation after a restart.

## Role and write model

Use:

- one product writer at a time;
- direct native read-only auditors where useful;
- two final read-only Auditors and one fresh Supervisor per active repository;
- deterministic staggered Auditor batches when capacity is limited.

Do not use:

- recursive subagents;
- `codex exec`;
- external or detached Codex role processes;
- SSH-based audits;
- simultaneous product writers in one repository;
- hosted CI as an undeclared fallback.

## Universal repository protocol

For W6-S01, W6-S02, W6-S03, and each owner-controlled repository requiring work
inside W6-S05, run one owner-visible repository convergence operation with these
internal phases:

```text
admission
live_inventory
product_and_contract_audit
delta_decision
implementation_or_formal_noop
local_validation
runner_and_workflow_convergence
exact_head_delivery
merge_and_exact_main
obsolete_ref_retirement
final_live_audit
```

### Admission

Before the first product write, establish:

- exact local and remote identity;
- repository ownership and permission;
- all applicable `AGENTS.md` instructions;
- worktree cleanliness or exact dirt classification;
- absence or classification of Git operations;
- complete branches, remote heads, PRs, worktrees, stashes and tags;
- toolchain availability;
- runner and workflow state;
- private cross-repository checkout needs;
- branch protection, rulesets and default-branch constraints;
- generated-output roots and secret boundaries.

### Complete live inventory

Enumerate and classify every:

- local branch and SHA;
- remote head and SHA;
- remote-tracking ref;
- upstream and gone-upstream branch;
- local branch without upstream;
- open and relevant closed PR;
- worktree and bound ref;
- stash;
- tag/release;
- tracked, staged and nonignored untracked object;
- Git operation marker;
- retained or deferred evidence object;
- CI workflow and repository runner.

Do not inventory only branches named in the current plan. Unknown classification
is prohibited.

### Product outcome

Classify exactly:

```text
NO_PRODUCT_DELTA_REQUIRED
MINIMAL_PRODUCT_DELTA_REQUIRED
OWNER_DECISION_REQUIRED
UNSAFE
```

Do not create activity-only commits or PRs.

### Validation and output boundaries

Use owned external validation roots below:

```text
V:\src\.codex-validation\w6-*
```

Do not pollute product worktrees. Do not fabricate device, credential,
production, network or runtime evidence.

### CI

When CI is required:

- prefer repository-scoped self-hosted Windows runners;
- use exact repository labels and no hosted fallback;
- handle registration tokens only in process memory;
- use detached normal-user runner processes;
- install no Windows service, Scheduled Task or startup persistence;
- verify expected checkout SHA equals actual checkout SHA;
- bind `RUNNER_TEMP` inside a runner-executed step;
- export later-step paths through `GITHUB_ENV`;
- perform no production or user-runtime mutation.

### Delivery

When changes are required:

```text
short-lived branch
-> normal non-force push
-> one PR
-> exact-head CI
-> fresh Supervisor
-> normal merge commit
-> exact-main CI
-> local canonical convergence
-> complete obsolete-ref retirement
```

Do not force push, rewrite history, use admin merge, create empty commits or
manually dispatch/rerun/cancel CI.

When no product or CI delta is required, record a formal no-op outcome and use
the strongest approved exact-main local or CI proof available.

### Ref convergence

Immediately before the first deletion, repeat the complete branch/ref/worktree
inventory. Delete only refs that are fully reachable from canonical `main`,
have zero unique commits, have no worktree or PR dependency, and have not moved.

Use only normal remote deletion and lowercase `git branch -d`.

A long-lived `dev` requires a genuine product need and owner decision.

## Automatic recovery budget

Continue inside the same Wave 6 run for ordinary bounded recovery:

- process-scoped toolchain/environment correction;
- owned validation-root creation and bounded cleanup;
- safe fetch/prune/upstream/origin-HEAD reconciliation;
- official repository-scoped runner provisioning or restart;
- in-memory runner registration-token use;
- workflow label, syntax and context correction;
- exact-SHA checkout correction;
- sequential CI queue waiting;
- transient read-only GitHub/network retry;
- safe merged-branch pruning;
- atomic checkpoint regeneration.

Every corrective change requires fresh validation. Maximum two non-empty
corrective commits per active repository unless the owner explicitly authorizes
more.

## Mandatory owner or unsafe stops

Use `W6_OWNER_DECISION_REQUIRED` only for a genuine authority or product-policy
choice, including:

- ambiguous intended behavior;
- multiple reasonable dispositions for unique commits;
- a genuine need for long-lived `dev`;
- credential-policy selection;
- branch-protection/ruleset policy change;
- production notification, device, signing or deployment authorization;
- removal of an intentional product capability.

Use `W6_UNSAFE_BLOCKER` for:

- secret or credential exposure;
- unknown or unowned filesystem mutation;
- required force push or history rewrite;
- concurrent remote ref drift;
- unclassified unique history at deletion time;
- exhausted corrective budget;
- inability to bind evidence to exact SHAs.

Every blocker output must include:

```text
BLOCKED_STEP
BLOCKED_PHASE
BLOCKER_TEXT
EXACT_AFFECTED_SCOPE
CURRENT_SAFE_STATE
OPTIONS
RECOMMENDED_OPTION
MUTATIONS_ALREADY_COMPLETED
MUTATIONS_NOT_PERFORMED
CHECKPOINT_PATH
RESUME_INSTRUCTION
```

## W6-S01 — codex-ntfy-notifier

Repository:

```text
V:\src\codex-ntfy-notifier
JerrySkywalker/codex-ntfy-notifier
```

Expected initial remote baseline:

```text
default_branch=main
initial_main_SHA=092d17999b790a3d8d7ec7493615092117ec80e7
visibility=public
```

Audit notifier hooks, templates, install/test/backup/repair scripts, markdown
serialization, path independence, error handling, logs, HTTP authorization,
DPAPI boundaries, secret exclusion, documentation and CI.

Absolute boundaries:

```text
real %USERPROFILE%\.codex modification = prohibited
existing DPAPI material read = prohibited
real ntfy credential request = prohibited
real external ntfy request = prohibited
production notification = prohibited
Codex global-config mutation = prohibited
```

Static analysis, synthetic profile roots and loopback-only mock endpoints are
allowed when fully contained in the validation root.

Outputs:

```text
w6-s01-codex-ntfy-notifier-report.md
w6-s01-codex-ntfy-notifier-checkpoint.json
```

Completion requires source convergence on `main`, no open feature PR, no
unclassified refs/worktrees, offline validation, intact secret/DPAPI boundaries
and no production notification action.

Proceed automatically to W6-S02.

## W6-S02 — wearos-healthprobe-preflight

Repository:

```text
V:\src\wearos-healthprobe-preflight
JerrySkywalker/wearos-healthprobe-preflight
```

Current remote metadata at orchestrator publication:

```text
default_branch=master
visibility=private
open_PR_count=0
```

Revalidate live state before mutation.

Treat this repository as the provider of probe contracts and readiness evidence.
Audit API/schema, health states, error semantics, privacy/redaction,
device-independent tests, evidence generation, packaging, CI and the consumer
boundary.

Separate source-validatable facts from physical-device or external-service
evidence. Perform no device mutation, enrollment, sideload or production access.

Freeze an exact accepted provider contract containing:

```text
provider_repository
provider_canonical_SHA
schema_version
API surface
health states
error semantics
privacy boundary
required app behavior
deferred physical evidence
```

Converge canonical branch to `main` when safe and retire obsolete refs after
exact proof.

Outputs:

```text
w6-s02-wearos-healthprobe-preflight-report.md
w6-s02-wearos-healthprobe-preflight-checkpoint.json
```

Do not begin W6-S03 product writes until W6-S02 has completed and the exact
contract is recorded in the orchestrator checkpoint.

## W6-S03 — wearos-healthprobe-app

Repository:

```text
V:\src\wearos-healthprobe-app
JerrySkywalker/wearos-healthprobe-app
```

Current remote metadata at orchestrator publication:

```text
default_branch=main
visibility=private
open_PR_count=0
```

Bind to the exact frozen W6-S02 contract. Audit project structure, build and
dependencies, schema compatibility, permissions, networking, privacy,
foreground/background behavior, debug/release separation, signing boundaries,
CI, artifacts and branch/worktree state.

Do not enroll or mutate a watch, sideload, access signing keys, publish to Play
or perform production activation.

Physical-watch evidence must be either:

```text
COMPLETE
DOCUMENTED_DEFERRED
```

A documented physical-watch deferral does not block source convergence when all
source-validatable gates pass.

Outputs:

```text
w6-s03-wearos-healthprobe-app-report.md
w6-s03-wearos-healthprobe-app-checkpoint.json
```

Proceed automatically to W6-S04.

## W6-S04 — hithesis skip

Object:

```text
V:\src\hithesis
```

Disposition:

```text
SKIPPED_EXTERNAL_NOT_OWNED
```

This is a downloaded third-party repository/reference. Perform only bounded
read-only identity confirmation when safe.

Do not modify, clean, fetch, pull, push, switch/create/delete branches, alter
remotes, fork, commit, archive or delete it. Do not count its branch/worktree
state as owner repository debt.

Record in the orchestrator checkpoint:

```text
W6_S04_COMPLETE=true
W6_S04_DISPOSITION=SKIPPED_EXTERNAL_NOT_OWNED
PRODUCT_WRITES=0
GIT_REF_MUTATIONS=0
MILESTONE_BLOCKING=false
```

Proceed automatically to W6-S05.

## W6-S05 — remaining canonical repository review

Recompute the live `V:\src` object and repository registry.

Distinguish owner-controlled canonical repositories from external/downloaded,
vendor, generated, archived, quarantine, evidence-only, non-repository and
later-wave objects.

For every owner-controlled repository not already fully covered by a named
Wave 6 active step, assign:

```text
ALREADY_CONVERGED_NO_PRODUCT_DELTA
CONVERGENCE_REQUIRED_IN_W6_S05
DEFER_TO_LATER_NAMED_WAVE
EXCLUDE_NONCANONICAL_WITH_REASON
OWNER_DECISION_REQUIRED
```

Process required repositories sequentially inside this single W6-S05 step with
a compact per-repository matrix. Do not create W6-S05A/B identifiers. Do not
pull later-wave or deferred production work into Wave 6 merely because it exists
locally.

Outputs:

```text
w6-s05-remaining-canonical-repositories-report.md
w6-s05-remaining-canonical-repositories-checkpoint.json
```

Proceed automatically to W6-S06.

## W6-S06 — final all-owner-repository audit

This step is read-only except for final evidence files.

Recompute live state for every owner-controlled canonical repository covered by
Waves 0 through 6:

- canonical branch and SHA;
- default branch and local/remote parity;
- complete local and remote ref sets;
- open PRs, worktrees and stashes;
- Git operation markers;
- unique-history reachability;
- exact CI or approved local proof;
- retained and deferred objects;
- production/runtime mutation accounting.

Exclude `hithesis` and every object classified external-not-owned,
vendor/downloaded, generated/evidence-only or deferred to a later wave.

Use deterministic read-only Auditor batches, then one fresh final Supervisor.

Declare:

```text
M6_REPOSITORY_HEALTH_TRAIN_COMPLETE=true
```

only when:

```text
all owner-controlled canonical repositories classified
all required source convergence complete
all feature branches merged, explicitly retained, or retired
all PRs and worktrees classified
all unique history reachable
unclassified_objects=0
unresolved_repository_health_debt=0
external_not_owned objects are non-blocking
production_action=false
fresh final Supervisor=PASS
```

Final outputs:

```text
w6-repository-health-train-report.md
w6-repository-health-train-checkpoint.json
```

The final checkpoint must record all six stable steps complete, including W6-S04
as skipped external-not-owned, and must leave Wave 7 not started.

## Final success output

On success output exactly:

```text
W6_COMPLETE
M6_REPOSITORY_HEALTH_TRAIN_COMPLETE=true

W6_S01_COMPLETE=true
CODEX_NTFY_NOTIFIER_SOURCE_CONVERGED=true

W6_S02_COMPLETE=true
WEAROS_PREFLIGHT_SOURCE_CONVERGED=true
PREFLIGHT_CONTRACT_FROZEN=true

W6_S03_COMPLETE=true
WEAROS_APP_SOURCE_CONVERGED=true
PREFLIGHT_APP_CONTRACT_COMPATIBLE=true

W6_S04_COMPLETE=true
HITHESIS_DISPOSITION=SKIPPED_EXTERNAL_NOT_OWNED
HITHESIS_MILESTONE_BLOCKING=false

W6_S05_COMPLETE=true
REMAINING_OWNER_CONTROLLED_REPOSITORIES_CLASSIFIED=true

W6_S06_COMPLETE=true
UNCLASSIFIED_OBJECT_COUNT=0
UNRESOLVED_REPOSITORY_HEALTH_DEBT=0

FORCE_PUSH_PERFORMED=false
HISTORY_REWRITE=false
DEVICE_MUTATION=false
WINDOWS_SERVICE_MUTATION=false
PRODUCTION_ACTION=false

W7_NOT_STARTED
READY_FOR_NEXT_WAVE
```
