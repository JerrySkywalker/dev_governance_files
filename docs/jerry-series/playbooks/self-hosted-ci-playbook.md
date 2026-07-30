# Self-hosted CI Playbook

## Classification

```text
context_class: CONDITIONAL_OPERATIONAL
applies_when: execution_environment=E2
numeric_source: config/repo-health-harness-v1.json
```

This Playbook defines how to obtain trustworthy self-hosted CI evidence. It does
not create runner, workflow, product, or hosted-fallback authority.

## Preflight

Before queuing a Gate, verify:

- intended repository-specific labels;
- runner registration, online, and idle state;
- service process has the intended environment;
- repository read and required toolchain availability;
- exact-head checkout assertion;
- suitable isolated work root;
- no prior job-owned Node, Chromium, Playwright, shell, or helper process;
- scheduled work is not competing for the same sole capacity;
- the command graph proves a distinct claim.

A label is a routing request, not physical-capacity proof.

## Process ownership

Any job starting descendants must use a job-owned process group or equivalent
kill-on-parent-exit mechanism.

```text
pre_job_inventory
  -> job-owned process group
  -> tests
  -> finally terminate complete owned tree
  -> zero-orphan verification
  -> sanitized cleanup Receipt
```

Do not publish command lines, usernames, cookies, storage state, private paths,
or environment values.

## Timing discipline

Prefer observable conditions:

- DOM or IPC ready sentinels;
- explicit child `READY` and stop sentinels;
- stable container identity and bounded readiness polling;
- completion Receipts.

A timeout is a deadlock guard, not the expected completion time. Preserve safe
stage, elapsed time, condition-observed, and exit classification.

## Gate topology

For one exact head:

- one canonical complete repository Gate;
- distinct focused or platform-specific Gates;
- truthful path-filtered PASS for irrelevant surfaces;
- portable work on non-scarce capacity when policy permits;
- Windows runner reserved for genuinely Windows-dependent behavior;
- scheduled smoke isolated from required PR capacity.

Duplicate command graphs with the same exact source, environment contract, and
claim are prohibited.

## Exact binding and causal accounting

A valid Receipt records expected and actual checkout SHA, event, runner class,
claim, failure class, and whether the run was product-gating, recovery, an
automatic ref side effect, unrelated, or unknown.

Do not report global zero CI when automatic tag/ref runs exist.

## Failure classification

Classify before changing code:

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

A platform failure is corrected at `V3/E2`, not by unrelated `V1` product edits.

## Rerun and observer policy

The exact numeric limits come from the selected Harness Profile. Global frozen
rules still require:

```text
same head + same sanitized signature -> at most one rerun
second identical signature -> stop automatic reruns
duplicate canonical full Gate -> zero
```

A proven runner correction may precede the one rerun. A later pass does not erase
instability history.

Use an external finite watcher for queued/running state. Wake the model only on a
state transition, new signature, success, or hard timeout. The watcher must not
commit, rerun, cancel, modify branch protection, or mutate product state.

## Recovery boundaries

- no empty commits to retrigger;
- no hosted fallback when prohibited;
- no product changes for checkout/runner defects;
- no ref rewrite to hide side-effect runs;
- no repeated unchanged-head execution after the signature budget is exhausted;
- no claim that several flaky attempts were several clean validations.

## Completion

An E2-backed step completes only when exact source, intended runner, resolved
failure classification, zero-orphan cleanup, unique Gate topology, causal
accounting, and the selected Profile's budgets are all proven.
