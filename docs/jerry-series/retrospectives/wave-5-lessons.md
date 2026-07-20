# Wave 5 Lessons

## Classification

```text
classification: retrospective
related_wave: Wave 5
milestone: M5_WORKSTATION_SOURCE_CONVERGED
related_repositories:
  - workstation-manager
  - jerry-workstation-config
```

## Scope

Wave 5 converged the workstation source pair without enabling real workstation mutation:

```text
workstation-manager -> jerry-workstation-config
```

The final state used one canonical `main` branch per repository, no long-lived `dev`, no open product pull requests, exact-main CI evidence, compatible Manager and Config contracts, and an explicit deferred production backlog.

The wave did not install software, apply workstation state, enable a real executor, install Windows services, launch Sandbox or Hyper-V workloads, or perform production activation.

## Outcome

```text
W5_COMPLETE=true
M5_WORKSTATION_SOURCE_CONVERGED=true
manager_source_converged=true
config_source_converged=true
manager_config_compatible=true
production_install_deferred=true
real_executor_enabled=false
workstation_apply_enabled=false
production_action=false
```

## Durable lessons

### 1. One repository should normally have one owner-visible convergence Goal

Wave 5 initially exposed too many internal phases as separate owner-visible steps. The product work, runner recovery, exact-head delivery, merge, branch migration, and branch retirement were logically one repository convergence operation with ordered internal gates.

Reusable rule:

```text
ONE_REPOSITORY
ONE_TOP_LEVEL_GOAL
ONE_COMPACT_REPORT
ONE_FINAL_CHECKPOINT
```

Internal phases remain checkpointed and resumable, but should not become new owner-facing step identifiers unless the owner must make a genuine product or policy decision.

### 2. Admission must preflight infrastructure before product writes

The first full preflight should validate all of the following before implementation begins:

- local and remote Git state;
- pull-request base and head;
- complete branch and worktree inventory;
- required toolchains;
- repository permissions;
- self-hosted runner availability;
- private cross-repository checkout requirements;
- workflow syntax and context legality;
- branch-protection and default-branch migration constraints;
- generated-output boundaries.

Toolchain, runner, credential, and workflow-context defects discovered after product commits create avoidable recovery loops.

### 3. Safe automatic recovery needs an explicit budget

A repository Goal should preauthorize bounded recovery for ordinary infrastructure problems, including:

```text
process-scoped toolchain rebinding
owned validation-root creation and cleanup
owned runner distribution reconciliation
repository-scoped runner registration and restart
workflow syntax and context correction
exact-ref fetch and reconciliation
CI queue waiting on a single runner
safe merged-branch pruning
```

These recoveries remain inside the same top-level Goal and must be followed by fresh validation.

Automatic recovery must still stop for:

- ambiguous product intent;
- unclassified unique commits;
- unknown or unowned filesystem mutation;
- secret exposure;
- force push or history rewrite;
- branch-protection policy changes;
- real execution, workstation apply, service mutation, or production work.

### 4. Full branch inventory is required before the first retirement mutation

Wave 5 retired the current pull-request feature branches, but the final audit later found older merged MG2-MG8 refs. They contained no unique history and were safely retired, but the late discovery caused an unnecessary closeout blocker.

Reusable rule:

```text
Before deleting any obsolete branch, enumerate and classify every local branch,
every remote head, every remote-tracking ref, every worktree-bound ref, and every
open PR head/base.
```

Do not inventory only the branches already named in the current Goal.

### 5. Final audit must remain live and independent

The final milestone audit correctly recomputed live state instead of trusting completion checkpoints. It found the historical refs without reopening completed product work.

The correct recovery pattern was:

```text
preserve accepted product SHAs
retire only the newly discovered merged refs
rerun the complete final audit
declare the milestone only after a fresh Supervisor PASS
```

### 6. Exact-head, merge, main migration, and cleanup can be one ordered transaction

The safe sequence remains:

```text
exact-head CI
-> normal merge
-> exact merged-branch CI
-> create exact main
-> exact-main CI
-> change default branch
-> switch local canonical checkout
-> retire obsolete refs
```

These are separate gates, not necessarily separate owner-visible Goals.

### 7. Self-hosted CI must be repository-scoped and causally accounted

Wave 5 used repository-scoped, normal-user, non-persistent runners. They were CI infrastructure, not Windows services or production runtimes.

The durable rules are:

- bind workflows to exact runner labels;
- prove expected and actual checkout SHAs;
- distinguish automatic branch-push runs from manual CI mutations;
- do not use hosted fallback silently;
- do not install a runner as a service unless separately authorized;
- record offline state as an infrastructure fact, not a source-convergence failure after evidence is complete.

### 8. Private cross-repository CI access needs a least-privilege model

Config validation required read access to private Manager source. The selected model was a repository-specific read-only credential retained only for CI, with no personal credential reuse and no write capability.

Reusable rule:

```text
private producer source
-> immutable commit reference
-> repository-specific read-only credential
-> persist-credentials=false
-> no credential material in Git or evidence
```

A GitHub App becomes preferable when several repositories need the same controlled cross-repository access pattern.

### 9. GitHub context legality must be statically audited before push

A workflow failed before job creation because a runner-only context was referenced at job-level environment scope. The corrected pattern binds runner temporary paths inside a runner-executed step and exports later-step values through the job environment file.

Reusable rule:

```text
Do not reference runner context where the workflow schema does not expose it.
Bind RUNNER_TEMP inside a step.
Export derived paths for later steps through GITHUB_ENV.
```

Workflow changes require a static context audit before the first push.

### 10. Unlocatable external temporary residue is not automatically product debt

A failed probe created an external temporary object but did not retain its exact path. The safe disposition was not speculative deletion. The object was left unmodified and classified as non-blocking after proving it was outside product and runner roots.

Reusable rule:

```text
unknown exact path -> no deletion claim
outside owned product/runtime roots -> preserve uncertainty
product and runner state independently proven -> do not block unrelated recovery
```

### 11. Evidence should be compact

The preferred repository-level evidence model is:

```text
<step>-report.md
<step>-checkpoint.json
<step>-logs/ only when detailed failure output is required
```

The checkpoint should contain an internal `phases` map. Creating one JSON document per internal gate increases coordination cost without improving final trust.

### 12. Owner-visible blockers should be rare and meaningful

The default top-level exits should be:

```text
COMPLETE
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

Routine toolchain, runner, workflow, queueing, and owned-root recovery should remain internal. An owner-visible blocker should represent a real change in authority, product direction, retained history, credential policy, or safety boundary.

## Operational consequences for Wave 6

Wave 6 inherits these rules:

```text
one owner-visible Goal per repository
complete admission preflight
full local and remote branch inventory
preauthorized bounded automatic recovery
compact report plus checkpoint
exact-SHA CI evidence
no production or runtime mutation
final independent live audit
```

`hithesis` is not an owner-controlled product repository. It must be classified as an external downloaded dependency and skipped rather than modified, cleaned, or counted as unresolved canonical-repository debt.

## Non-goals

This retrospective does not:

- replace raw Wave 5 evidence;
- expose credential values or runner credentials;
- authorize production installation;
- authorize real executor enablement;
- authorize workstation apply;
- authorize Wave 6 product changes.

## Sensitivity notes

Only reusable governance facts are recorded. Local paths, secret values, private keys, registration tokens, protected runtime references, and raw private-repository evidence remain outside this public repository.
