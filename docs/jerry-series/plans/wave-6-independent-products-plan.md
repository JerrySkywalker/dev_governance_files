# Wave 6 Independent Products Plan

## Classification

```text
classification: plan
related_wave: Wave 6
milestone: M6_REPOSITORY_HEALTH_TRAIN_COMPLETE
status: PLANNED_NOT_STARTED
```

## Purpose

Wave 6 converges independent owner-controlled product repositories after the main DevOps source chains and workstation source pair have been stabilized.

The wave is repository-health work only. It does not perform production deployment, device enrollment, service installation, package-manager mutation, or runtime activation.

## Governance model inherited from Wave 5

Each owner-controlled repository normally receives one owner-visible convergence Goal with internal phases:

```text
admission
live inventory
contract and product audit
minimal implementation or formal no-op
local validation
runner and workflow convergence
exact-head delivery
merge and exact merged-branch gate
main migration and exact-main gate
obsolete-ref retirement
final live audit
```

Only these top-level exits are expected:

```text
COMPLETE
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

Routine bounded recovery remains internal when it is already authorized.

## Ownership boundary

Wave 6 includes only repositories that are owner-controlled canonical development repositories.

`hithesis` is a downloaded third-party repository used as an external dependency/reference. It is not owned, maintained, or governed by this repository-health train.

Required disposition:

```text
W6-S04 status = SKIPPED_EXTERNAL_NOT_OWNED
product writes = prohibited
branch or worktree cleanup = prohibited
milestone blocking = false
```

The original step identifier is preserved for historical plan stability; later steps are not renumbered.

## Step plan

### W6-S01 — `codex-ntfy-notifier` repository convergence

Scope:

- complete local and remote branch, PR, worktree, stash, and Git-operation inventory;
- classify every unique commit and retained object;
- audit the notifier contract and current product intent;
- validate configuration, packaging, and notification-safety boundaries;
- implement only exact required deltas;
- converge CI to exact-SHA evidence;
- converge the canonical branch to `main` unless live policy proves another owner-approved state;
- retire obsolete refs only after full ancestry and worktree proof;
- perform no production notification delivery unless a separate product goal explicitly authorizes it.

Expected completion:

```text
codex_ntfy_notifier_source_converged=true
open_feature_pr_count=0
unclassified_refs=0
production_notification_action=false
```

### W6-S02 — `wearos-healthprobe-preflight` repository convergence

Scope:

- treat the preflight repository as the provider of probe contracts and readiness evidence;
- inventory all refs, PRs, worktrees, generated artifacts, and test evidence;
- audit API/schema, health classification, privacy, and device-independent validation;
- separate source validation from physical-device evidence;
- converge the provider contract before modifying the app consumer;
- preserve explicit deferred items when a physical device or external service is required.

Expected completion:

```text
wearos_preflight_source_converged=true
preflight_contract_frozen=true
physical_device_action=false
```

Dependency:

```text
W6-S02 must complete before W6-S03 product writes begin.
```

### W6-S03 — `wearos-healthprobe-app` repository convergence

Scope:

- bind to the exact frozen W6-S02 preflight contract;
- audit Android/WearOS build configuration, application contract, permissions, privacy, and release safety;
- distinguish emulator/local build evidence from physical-watch evidence;
- implement only consumer deltas required by the exact preflight contract;
- converge branches, PRs, worktrees, CI, and canonical `main`;
- retain a documented deferred state when real watch validation remains outstanding;
- perform no device enrollment, sideload, signing, Play publication, or production activation without separate authorization.

Expected completion:

```text
wearos_app_source_converged=true
preflight_app_contract_compatible=true
physical_watch_validation=<COMPLETE|DOCUMENTED_DEFERRED>
production_release_action=false
```

### W6-S04 — `hithesis` external repository disposition

Status:

```text
SKIPPED_EXTERNAL_NOT_OWNED
```

Reason:

- the repository belongs to another maintainer;
- the local copy is downloaded for use, not an owner-controlled development repository;
- this health train has no authority to rewrite its branches, worktrees, history, CI, or documentation.

Required treatment:

- record it as an external dependency/reference in inventory;
- exclude it from canonical repository counts;
- do not modify, clean, commit, push, fork, archive, or delete it;
- do not treat its branches or worktrees as owner repository debt;
- do not block the Wave 6 milestone solely because it remains present locally.

### W6-S05 — remaining owner-controlled canonical repository review

Purpose:

Recompute the live canonical repository registry after W6-S01 through W6-S03.

Scope:

- enumerate all owner-controlled repositories still classified as independent products;
- explicitly exclude external, vendor, downloaded, generated, archived, quarantine, evidence-only, and non-repository objects;
- identify any owner-controlled canonical repository omitted from the named plan;
- for each discovered repository choose exactly one disposition:

```text
ALREADY_CONVERGED_NO_PRODUCT_DELTA
CONVERGENCE_REQUIRED_IN_W6_S05
DEFER_TO_LATER_NAMED_WAVE
EXCLUDE_NONCANONICAL_WITH_REASON
OWNER_DECISION_REQUIRED
```

Any required repository convergence is performed inside one W6-S05 top-level Goal with a compact per-repository matrix. Do not create ad hoc W6-S05A/B/C identifiers.

Expected completion:

```text
remaining_owner_controlled_repositories_classified=true
unclassified_canonical_repository_count=0
external_repositories_excluded_explicitly=true
```

### W6-S06 — all-owner-repository health audit

This is a read-only independent milestone audit.

Recompute live state for every owner-controlled canonical repository covered by Waves 0 through 6:

- canonical branch and exact SHA;
- local/remote parity;
- default branch;
- full local and remote branch set;
- open PRs;
- worktrees;
- stashes;
- Git operation markers;
- unique history reachability;
- exact CI evidence or approved local proof class;
- retained documented objects;
- deferred product evidence;
- production/runtime mutation accounting.

Exclude `hithesis` and any other object classified as external-not-owned from canonical convergence assertions.

Milestone decision:

```text
M6_REPOSITORY_HEALTH_TRAIN_COMPLETE=true
```

only when:

```text
all owner-controlled canonical repositories classified
all required source convergence complete
all feature branches merged, retained with explicit disposition, or retired
all open PRs classified
all worktrees classified
unclassified_objects=0
unresolved_repository_health_debt=0
external_not_owned_objects do not block
production_action=false
fresh independent Supervisor=PASS
```

## Sequencing

```text
W6-S01
-> W6-S02
-> W6-S03
-> W6-S04 SKIPPED_EXTERNAL_NOT_OWNED
-> W6-S05
-> W6-S06
```

W6-S01 and W6-S02 may be audited in parallel only when write scopes remain disjoint and both retain one writer per repository. W6-S03 must wait for the exact W6-S02 contract.

## Evidence model

Each active repository step should normally emit:

```text
<step>-report.md
<step>-checkpoint.json
<step>-logs/ only for bounded failure detail
```

The Wave 6 final audit emits one milestone report and one milestone checkpoint.

## Non-goals

Wave 6 does not:

- modify third-party repositories;
- perform production deployment;
- send production notifications;
- enroll or mutate physical devices;
- install Windows services;
- use force push or history rewrite;
- create activity-only commits or PRs;
- weaken exact-SHA or live-state audit requirements.
