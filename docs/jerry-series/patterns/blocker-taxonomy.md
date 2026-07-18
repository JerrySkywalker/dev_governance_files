# Blocker Taxonomy

## Purpose

Provide standard blocker names and expected dispositions for Jerry series governance and execution work.

## Product decision blockers

```text
HUMAN_PRODUCT_DECISION_REQUIRED
```

Use when the next action depends on product intent, not technical feasibility.

Expected disposition:

- obtain explicit owner decision;
- record accepted and rejected alternatives;
- do not let technical analysis substitute for product decision.

## Evidence blockers

```text
BLOCKED_UNKNOWN_DIRT
BLOCKED_PROTECTED_EVIDENCE
WORKTREE_REMOVE_FILENAME_TOO_LONG
PROTECTED_ROOT_COVERAGE_INCOMPLETE
```

Expected disposition:

- preserve or relocate evidence opaquely;
- avoid descendant inspection unless authorized;
- rerun Supervisor after disposition;
- resume cleanup only after receipt.

## Remote verification blockers

```text
ANONYMOUS_PRIVATE_GITHUB_404
EXISTING_GITHUB_AUTH_UNAVAILABLE
REMOTE_STATE_DRIFT
ARCHIVE_TAG_DRIFT
```

Expected disposition:

- distinguish anonymous 404 from missing private resource;
- request explicit authenticated-read authorization when needed;
- do not mutate GitHub during read audit;
- stop on real remote drift.

## CI blockers

```text
SELF_HOSTED_CHECKOUT_INFRASTRUCTURE
GITHUB_EGRESS_OR_PROXY
RUNNER_ENV_NOT_ACTIVATED
PRODUCT_GATE_FAILURE
```

Expected disposition:

- infrastructure failures: fix runner or network without changing product code;
- product gate failures: stop and treat as product work;
- do not create empty commits for CI retries;
- do not use hosted fallback when prohibited.

## Governance blockers

```text
WAVE_NOT_AUTHORIZED
CROSS_WAVE_DISCOVERY_PROHIBITED
PRODUCT_WRITER_CONFLICT
SUPERVISOR_REPORT_INVALID
GOAL_BINDING_INCONSISTENT
```

Expected disposition:

- stop before mutation;
- correct the Goal or authorization boundary;
- preserve prior evidence;
- do not infer permission from convenience.

## Completion blockers

A step is not complete when:

- a required receipt is missing;
- a required checkpoint is missing;
- a Supervisor PASS is chat-only;
- exact-head or exact-main evidence is missing;
- branch or worktree debt remains unclassified;
- private remote verification was attempted anonymously and failed.

## Reporting format

Use exact finite fields:

```text
BLOCKER_CODE=<code>
BLOCKER_PATH=<path when applicable>
BLOCKER_HEAD=<sha when applicable>
BLOCKER_TEXT=<specific reason>
AVAILABLE_OPTIONS=<finite options>
RECOMMENDED_OPTION=<one option>
STATE_CHANGED=false|true
NEXT_AUTHORIZATION_REQUIRED=<specific authorization>
```
