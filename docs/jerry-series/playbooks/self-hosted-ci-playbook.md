# Self-hosted CI Playbook

## Purpose

Provide a repeatable method for using and recovering self-hosted GitHub Actions in Jerry series development.

## Context

Hosted GitHub Actions budget may be unavailable. In that mode, CI evidence must come from the intended self-hosted runner, and hosted fallback is prohibited.

## Baseline assumptions

```text
HOSTED_ACTIONS_BUDGET=EXHAUSTED
CI_EXECUTION_MODE=SELF_HOSTED_REQUIRED
HOSTED_RUNNER_FALLBACK=PROHIBITED
RUNNER_HEALTH_PREFLIGHT_REQUIRED=true
EXACT_HEAD_CHECKOUT_REQUIRED=true
SCOPED_CAUSAL_CI_ACCOUNTING_REQUIRED=true
```

## Preflight checks

Before relying on CI, verify:

- expected runner labels;
- runner is online and idle;
- runner service process has loaded the intended environment;
- network path to GitHub works from the runner process context;
- repository HTTPS read works;
- required local tools exist;
- workflow uses exact checkout binding;
- ref or tag pushes used for governance preservation will not be mistaken for product CI.

Runner visibility in GitHub is not sufficient. A runner can be online while its service process has stale proxy or environment configuration.

## Exact-head rule

For pull requests, the workflow must check out the literal PR head SHA and verify that the actual checkout SHA matches the expected SHA.

For main pushes, the workflow must verify the checkout equals the pushed main SHA.

A CI pass that is not bound to the expected SHA is not sufficient evidence for merge or milestone completion.

## Causal CI accounting

Do not use one unscoped field to describe all workflow history.

Required causal fields:

```text
CI_RUNS_TRIGGERED_BY_THIS_STEP
CI_RUNS_INTENTIONALLY_TRIGGERED_BY_CODEX
PRODUCT_CI_RUNS
AUTOMATIC_TAG_PUSH_CI_SIDE_EFFECTS
AUTOMATIC_TAG_PUSH_CI_RUN_IDS
PRIOR_AUTOMATIC_CI_RUNS_DOCUMENTED
CI_MUTATIONS_PERFORMED
CI_CANCELLED
CI_RERUN
WORKFLOW_MODIFIED
```

Classify every observed run as exactly one:

```text
PRODUCT_EXACT_HEAD_OR_MAIN_GATE
INTENTIONAL_INFRASTRUCTURE_RECOVERY_RUN
AUTOMATIC_TAG_OR_REF_PUSH_SIDE_EFFECT
PRE_EXISTING_UNRELATED_RUN
UNKNOWN_REQUIRES_OWNER_REVIEW
```

Archive-tag and preservation-ref pushes may automatically trigger workflows. Those runs are real and must be documented, even when no product CI was intentionally requested.

A truthful report may state:

```text
CI_RUNS_TRIGGERED_BY_THIS_RECOVERY=0
AUTOMATIC_TAG_PUSH_CI_SIDE_EFFECTS=4
```

It must not state a global `CI_RUNS_TRIGGERED=0` when runs exist in the audited history.

## Failure classification

Classify failures before changing code:

```text
PRODUCT_GATE_FAILURE
SELF_HOSTED_CHECKOUT_INFRASTRUCTURE
GITHUB_EGRESS_OR_PROXY
RUNNER_ENV_NOT_ACTIVATED
TOOLCHAIN_MISSING
TRANSIENT_GITHUB_OR_NETWORK
AUTOMATIC_REF_SIDE_EFFECT_NON_GATING
UNKNOWN_INFRASTRUCTURE
```

## Recovery rules

- Do not create empty commits to retrigger CI.
- Do not switch to hosted runners when fallback is prohibited.
- Do not change product code for checkout or runner infrastructure failures.
- Activate already-approved runner environment repairs before rerun.
- Rerun the unchanged head when the failure is infrastructure-only.
- If a product gate fails after checkout and setup succeed, stop and treat it as product work.
- Do not cancel or rerun automatic tag/ref side-effect runs merely to make accounting appear clean.
- Do not rewrite or delete refs to hide already-created runs.
- Replace impossible historical invariants with scoped truthful fields; do not overwrite history.

## Required evidence

A product CI receipt should include:

```text
run_id
job_id
runner_name
runner_labels
event_name
expected_checkout_sha
actual_checkout_sha
conclusion
failure_class
hosted_runner_used=false
rerun_head_unchanged=true
```

A causal accounting report should also include:

```text
run_id
triggering_ref_or_sha
trigger_cause
intentional_by_codex
product_gating
mutation_performed
classification
```

## Workflow-trigger review

Before using archive tags or preservation refs in a convergence step, inspect workflow trigger patterns read-only.

Record whether workflows match:

- all pushes;
- tag pushes;
- branch-only pushes;
- pull requests;
- manual dispatch;
- workflow chaining.

A workflow side effect does not necessarily block convergence, but it must be accounted for and must not be misrepresented as product validation.

## Completion standard

A CI-backed product step can complete only when:

- exact-head or exact-main SHA is proven;
- the intended self-hosted runner ran the product gate;
- no hosted fallback occurred;
- failure classification is resolved;
- product state is unchanged during infrastructure recovery;
- causal CI accounting is complete;
- automatic side effects are separated from intentional product CI;
- no cancellation, rerun, ref rewrite, or empty commit was used to manufacture a zero-run claim.

A no-product-delta step may complete without product CI when its contract and local validation policy explicitly permit that result. Automatic governance-side-effect runs, when present, must still be documented.
