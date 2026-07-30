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
JOB_OWNED_PROCESS_CLEANUP_REQUIRED=true
DUPLICATE_FULL_GATE_REVIEW_REQUIRED=true
CONDITION_DRIVEN_ASYNC_TESTS_REQUIRED=true
LOW_FREQUENCY_EXTERNAL_CI_WATCHER_REQUIRED=true
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
- no prior job-owned Node, Chromium, Playwright, shell, or helper process remains;
- no scheduled smoke or unrelated repository job is about to consume the same sole runner; and
- ref or tag pushes used for governance preservation will not be mistaken for product CI.

Runner visibility in GitHub is not sufficient. A runner can be online while its service process has stale proxy or environment configuration, inherited child processes, or resource pressure from an earlier job.

## Runner inventory, lifecycle, and capacity

Before queuing a repository gate, record a sanitized runner-service inventory
for that repository: the logical labels, runner registration state, service
lifecycle state, configured repository scope, and the class of dedicated work
root. Do not record host names, private paths, environment values, or service
output in the governance receipt.

Prove the intended runner is both `online` and `idle` immediately before the
job is queued. A logical label is a routing request, not proof of physical
capacity. Capacity is proven only when an online, idle runner is bound to the
repository's required tools and has a separate work root from other repository
jobs.

Classify queue age rather than assuming a matching label will start work:

```text
QUEUED_FRESH
QUEUED_WAITING_FOR_CAPACITY
QUEUED_STALE_REQUIRES_RUNNER_LIFECYCLE_REVIEW
```

Use the repository-specific lifecycle to distinguish a normal occupied runner
from a stale service, stale environment, missing work root, inherited process
tree, or missing physical capacity. Do not create an empty commit to retrigger
a queued or failed run.

## Runner process ownership and cleanup

Every job that starts Node, Chromium, Playwright, PowerShell helpers, or file-lock
children must give those processes a job-owned identity. On Windows, prefer a
Job Object or an equivalent kill-on-parent-exit process group. A PID list alone
is not sufficient because children may outlive the initiating shell.

Required job lifecycle:

```text
pre_job_inventory
  -> start job-owned process group
  -> execute tests
  -> finally terminate the complete owned process tree
  -> verify no owned process remains
  -> publish sanitized cleanup receipt
```

The cleanup receipt should include only bounded counters and classifications:

```text
owned_node_process_count_before
owned_chromium_process_count_before
cleanup_attempted
cleanup_complete
orphan_process_count_after_cleanup
runner_contamination_detected
```

Do not publish process command lines, user names, cookies, storage state, private
paths, or environment values. A job that cannot prove process-tree cleanup must
fail as runner infrastructure, not silently pass and contaminate the next job.

## Timing-sensitive test discipline

Functional correctness must not depend on a narrow fixed wall-clock delay when
the tested condition has an observable state transition.

Use condition-driven synchronization:

- DOM or IPC ready sentinels for browser controls;
- explicit child-process `READY` and stop sentinels for file locks;
- stable container identity plus bounded readiness polling for services;
- explicit completion receipts rather than sleep-and-guess ordering.

A timeout is a deadlock guard, not the expected completion time. The timeout
must exceed demonstrated loaded-runner latency and the failure receipt must
include a safe stage and elapsed time. Do not compress all timeout failures into
one generic child exit code.

Required sanitized timing fields when relevant:

```text
test_stage
elapsed_ms
condition_observed
emergency_timeout_triggered
child_exit_classification
```

A control that appears after 3.3 seconds is not a functional failure merely
because a synthetic test guessed 3.0 seconds. A lock helper that is intended to
remain held must be sentinel-controlled; its emergency timeout must not define
the test's persistence contract.

## Exact-head rule

For pull requests, the workflow must check out the literal PR head SHA and verify that the actual checkout SHA matches the expected SHA.

For main pushes, the workflow must verify the checkout equals the pushed main SHA.

A CI pass that is not bound to the expected SHA is not sufficient evidence for merge or milestone completion.

## Gate topology and duplicate work

Before making multiple workflows required, expand their command graphs and
identify duplicate expensive gates. On a sole self-hosted runner, nominally
parallel jobs are serialized, so duplicate checkout, dependency installation,
Playwright setup, and full test execution directly extend wall-clock time and
increase contamination risk.

Do not run the same complete gate, such as `npm run check`, in two required jobs
for the same head unless the duplication is explicitly justified by a distinct
environment contract. Prefer:

- one canonical full gate;
- path-sensitive focused gates for changed surfaces;
- stable required check names that return a fast, truthful
  `SKIPPED_BY_PATH_FILTER=PASS` for irrelevant changes;
- hosted runners for portable docs, static, generated, and light secret checks
  when policy and budget allow; and
- the scarce Windows runner only for Windows ACL, atomic move, PowerShell,
  browser, or other genuinely platform-specific behavior.

Scheduled smoke jobs should use a separate runner label, a hosted runner, or a
queue-aware skip rule so they do not compete with required pull-request gates.

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
RUNNER_PROCESS_CONTAMINATION
TIMING_FRAGILE_TEST
DUPLICATE_GATE_CAPACITY_WASTE
TRANSIENT_GITHUB_OR_NETWORK
AUTOMATIC_REF_SIDE_EFFECT_NON_GATING
UNKNOWN_INFRASTRUCTURE
```

A product-unrelated failure on an unchanged test is not automatically
infrastructure. Bind the classification to the changed-file set, exact failure
signature, runner inventory, process cleanup receipt, and a controlled unchanged-head
rerun.

## Rerun and repeated-failure policy

- Permit at most one unchanged-head rerun for a plausibly transient infrastructure failure.
- After the same sanitized failure signature occurs twice on the same head, stop automatic reruns and emit `REPEATED_INFRA_OR_FLAKY_FAILURE`.
- A different timestamp, attempt number, or raw log line does not create a new signature.
- Clean a proven job-owned orphan process tree before the one permitted rerun.
- Do not use a sixth successful attempt as proof that the preceding five failures were harmless.
- Do not modify unrelated product code to make an infrastructure-sensitive test disappear.

A repeated-failure receipt should contain:

```text
exact_head_sha
failure_signature
failure_count
changed_files_overlap
runner_contamination_status
cleanup_status
rerun_budget_consumed
next_required_action
```

## CI waiting and observer discipline

CI waiting must not be implemented as frequent model wakeups that repeatedly
reload full repository and conversation context. Use a shell-side or service-side
watcher that blocks outside the model and wakes the orchestrator only on a state
transition, failure, success, or hard timeout.

Recommended observation schedule:

```text
first_30_minutes: poll_every_5_minutes
30_to_120_minutes: poll_every_10_minutes
after_120_minutes_without_change: emit_one_structured_WAITING_receipt
same_failure_signature_twice: stop_reruns_and_escalate
```

A busy online runner is `WAITING_FOR_CAPACITY`, not a blocker and not a reason to
query every minute. Record queue transitions, not hundreds of unchanged PR
snapshots. The watcher must have a finite wall-clock budget and must not create
commits, reruns, or workflow mutations merely to produce activity.

## Recovery rules

- Do not create empty commits to retrigger CI.
- Do not switch to hosted runners when fallback is prohibited.
- Do not change product code for checkout or runner infrastructure failures.
- Activate already-approved runner environment repairs before rerun.
- Rerun the unchanged head only when the failure is infrastructure-only and the unchanged-head rerun budget remains.
- If a product gate fails after checkout and setup succeed, stop and treat it as product work unless changed-file and failure-signature evidence proves an unrelated runner/test defect.
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
failure_signature
hosted_runner_used=false
rerun_head_unchanged=true
job_owned_process_cleanup_complete
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
- job-owned process cleanup is proven;
- duplicate heavyweight gate execution has been reviewed;
- product state is unchanged during infrastructure recovery;
- causal CI accounting is complete;
- automatic side effects are separated from intentional product CI;
- no cancellation, unbounded rerun, ref rewrite, or empty commit was used to manufacture a pass or zero-run claim; and
- CI observation used bounded low-frequency state-transition monitoring rather than unbounded model polling.

A no-product-delta step may complete without product CI when its contract and local validation policy explicitly permit that result. Automatic governance-side-effect runs, when present, must still be documented.
