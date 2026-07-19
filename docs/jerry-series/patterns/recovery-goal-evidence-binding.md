# Recovery Goal Evidence Binding

## Classification

```text
classification: pattern
scope: blocker recovery Goals
related_waves:
  - Wave 4
```

## Problem

A recovery Goal can block itself when it requires reports that would only have been produced after the phase where the original blocker occurred.

This creates a false admission dependency:

```text
blocked before report generation
        ↓
recovery requires the absent report
        ↓
recovery cannot start
```

The recovery must bind to the last proven state, not to the intended final artifact set of the parent step.

## Core rule

```text
Bind admission to the last proven checkpoint and the exact blocker evidence.
Do not require artifacts that belong to an unexecuted later phase.
```

## Evidence classes

Every evidence path in a recovery Goal must be classified as exactly one:

```text
REQUIRED_LAST_PROVEN
OPTIONAL_IF_PRESENT
EXPECTED_ABSENT_AFTER_EARLY_BLOCKER
SUPERSEDED_BY_EXPLICIT_RECOVERY
NOT_RELEVANT_TO_THIS_RECOVERY
```

### REQUIRED_LAST_PROVEN

Evidence that proves the workflow reached the recovery boundary, for example:

- prior wave milestone checkpoint;
- parent-step admission report;
- exact blocker report;
- completed prerequisite recovery checkpoint;
- governing playbook.

### OPTIONAL_IF_PRESENT

Reports that may have been generated before the blocker but are not required to authorize the bounded recovery.

Read them for context when present. Do not fabricate or restore them when absent.

### EXPECTED_ABSENT_AFTER_EARLY_BLOCKER

Artifacts that normally appear later in the parent step and are expected to be absent because the step stopped early.

Their absence must be recorded as expected, not treated as a new blocker.

### SUPERSEDED_BY_EXPLICIT_RECOVERY

Prior evidence whose narrow assertion has been replaced by a later owner-approved recovery checkpoint.

Keep the historical evidence. Do not overwrite it. The parent rerun should read both the original blocker and the superseding recovery receipt.

### NOT_RELEVANT_TO_THIS_RECOVERY

Artifacts outside the exact blocker scope. Do not add them to admission merely because they belong to the same wave.

## Stage-aware admission schema

A recovery Goal should declare:

```text
parent_wave
parent_step
blocked_phase
last_proven_phase
blocker_code
blocker_object
required_last_proven_evidence
optional_evidence
expected_absent_evidence
superseding_evidence
mutation_scope
completion_boundary
```

## Single-blocker rule

A recovery Goal should normally resolve one blocker class and stop.

Examples:

```text
opaque root relocation only
local-main fast-forward only
tracked placeholder restoration only
orphan Git metadata reconciliation only
CI side-effect disposition only
```

Do not combine the recovery with the rest of the parent product step unless the mutation and evidence boundaries are genuinely identical.

After recovery:

1. write a checkpoint;
2. release locks;
3. rerun the parent step from a fresh inventory;
4. require a fresh Supervisor.

## Truthful invariant rule

Do not bind a recovery to an invariant that has become historically impossible.

Bad:

```text
CI_RUNS_TRIGGERED=0
```

when prior automatic runs already exist.

Better:

```text
CI_RUNS_TRIGGERED_BY_THIS_RECOVERY=0
PRIOR_AUTOMATIC_CI_RUNS_DOCUMENTED=4
```

A recovery corrects the disposition or accounting. It does not rewrite history.

## File-name and schema drift

When evidence exists under a different but proven filename:

- prefer a non-destructive alias or an explicit superseding binding;
- preserve the original evidence;
- verify content equality when creating an alias;
- do not rename or overwrite historical evidence without a specific reason.

## Runtime-capacity drift

A Goal must not treat a preferred concurrency level as a product admission requirement.

When child-agent capacity is lower than expected:

- use deterministic staggered batches;
- preserve identical Auditor scopes;
- record batch membership and maximum observed capacity;
- do not launch external Codex processes to simulate missing native slots.

## Recovery completion receipt

A recovery checkpoint should include:

```text
recovery_complete=true
parent_step_complete=false
blocker_resolved=true
product_scope_unchanged=true
product_files_modified=<true|false>
local_git_ref_mutations=<count>
github_mutations=<count>
ci_runs_triggered_by_this_recovery=<count>
production_action=false
parent_step_ready_to_rerun=true
next_step_not_started=true
```

## Non-goals

This pattern does not weaken parent-step completion criteria. It only makes recovery admission match the state that actually exists.
