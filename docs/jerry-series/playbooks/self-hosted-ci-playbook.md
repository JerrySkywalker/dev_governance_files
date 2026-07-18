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
```

## Preflight checks

Before relying on CI, verify:

- expected runner labels;
- runner is online and idle;
- runner service process has loaded the intended environment;
- network path to GitHub works from the runner process context;
- repository HTTPS read works;
- required local tools exist;
- workflow uses exact checkout binding.

Runner visibility in GitHub is not sufficient. A runner can be online while its service process has stale proxy or environment configuration.

## Exact-head rule

For pull requests, the workflow must check out the literal PR head SHA and verify that the actual checkout SHA matches the expected SHA.

For main pushes, the workflow must verify the checkout equals the pushed main SHA.

A CI pass that is not bound to the expected SHA is not sufficient evidence for merge or milestone completion.

## Failure classification

Classify failures before changing code:

```text
PRODUCT_GATE_FAILURE
SELF_HOSTED_CHECKOUT_INFRASTRUCTURE
GITHUB_EGRESS_OR_PROXY
RUNNER_ENV_NOT_ACTIVATED
TOOLCHAIN_MISSING
TRANSIENT_GITHUB_OR_NETWORK
UNKNOWN_INFRASTRUCTURE
```

## Recovery rules

- Do not create empty commits to retrigger CI.
- Do not switch to hosted runners when fallback is prohibited.
- Do not change product code for checkout or runner infrastructure failures.
- Activate already-approved runner environment repairs before rerun.
- Rerun the unchanged head when the failure is infrastructure-only.
- If a product gate fails after checkout and setup succeed, stop and treat it as product work.

## Required evidence

A CI receipt should include:

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

## Completion standard

A CI-backed step can complete only when:

- exact-head or exact-main SHA is proven;
- the intended self-hosted runner ran the job;
- no hosted fallback occurred;
- failure classification is resolved;
- product state is unchanged during infrastructure recovery.
