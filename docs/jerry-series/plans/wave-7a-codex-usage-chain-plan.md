# Wave 7A Codex Usage Chain Plan

## Classification

```text
classification: execution plan
wave: W7A
name: CODEX_USAGE_SAFE_MESSAGE_CHAIN
status: READY_NOT_STARTED
milestone: M7A_CODEX_USAGE_CHAIN_GREEN
execution_model: Wave 6 durable orchestrator + local checkpoint
```

## Purpose

Wave 7A closes the current Codex usage path across four owner-controlled repositories:

```text
jerry-telemetry-agent
  codex.usage.snapshot
        ->
jerry-telemetry-hub
  GET /v1/codex/usage/summary
        ->
jerry-message-gateway
  codex.usage.summary.v1 subject-scoped message
        ->
jerry-devops-android
  bounded debug-canary preview and idempotent acknowledgement
```

The accepted product meaning is:

```text
W7A_CHAIN_SEMANTICS=SAFE_USAGE_CHANGE_MESSAGE
```

Wave 7A proves that a safe Codex usage snapshot can become a bounded Android inbox message through the current exact source contracts. It does not implement a full Android usage dashboard and does not make Message Gateway a telemetry query API.

## Starting source baseline

The initial accepted remote baseline at plan creation is:

```text
jerry-telemetry-agent
  main=e2eefd1630d6231ea5fe7388c3caf1394576c8f6

jerry-telemetry-hub
  main=8960abd64f1736de5a31788f8a65e31c76ed6971

jerry-message-gateway
  main=6ee6b1bc9ae3045a42d94df943ce77331178c3ec

jerry-devops-android
  main=c856e4f8ee476002b3a17858a1873fe945322ef6
```

These SHAs are admission expectations, not permission to overwrite local work. The executor must revalidate local and remote state. When a repository has moved safely on `main` before W7A begins, the executor may rebind the baseline only after proving that the new state is canonical, clean, owner-controlled, compatible with this plan, and contains no ambiguous unique work. Otherwise it must stop with a structured owner decision or unsafe blocker.

## Existing implementation state

### Agent

Already implemented:

- backend usage collection;
- safe `codex.usage.snapshot` normalization;
- four-window limit support;
- token, identity and raw-response omission;
- signed Hub upload support;
- generic local Agent-to-Hub E2E.

Unproven at Wave admission:

- exact current Agent Codex normalizer output ingested by exact current Hub in one cross-repository test.

### Hub

Already implemented:

- signed telemetry ingest;
- authenticated Codex usage latest, summary, glance and node overview models;
- four-window preservation;
- missing, stale and degraded semantics;
- read authentication and redaction tests.

Unproven at Wave admission:

- exact current Agent output compatibility in a cross-repository test;
- exact current Hub summary compatibility with exact current Gateway in a real local Hub process.

### Gateway

Already implemented:

- disabled-by-default, loopback-only, one-shot Hub usage source;
- strict safe-summary parsing;
- expected-node binding;
- semantic deduplication;
- subject-scoped message ingest and outbox;
- Android pull and idempotent acknowledgement;
- fake-Hub smoke coverage.

Unproven at Wave admission:

- direct consumption of the exact current Hub implementation;
- current four-window Hub response through the exact Gateway adapter;
- exact Gateway response consumed by Android parser tests.

### Android

Already implemented:

- debug-only Message Gateway canary;
- bounded title, body preview, source and status display;
- message ID retained only for acknowledgement;
- sensitive text rejection;
- release canary disabled and release base URL empty;
- local tests and release-safety checks.

Unproven at Wave admission:

- exact current Gateway JSON parsed through an Android test seam;
- physical phone proof, which remains outside W7A.

## Scope and expected outcomes

The default expected product outcome for every repository is:

```text
NO_PRODUCT_DELTA_REQUIRED
```

A minimal product delta is permitted only when exact cross-repository validation reveals a real incompatibility or when Android lacks any safe way to test the complete current Gateway response. A testability-only Android change must be limited to extracting a pure internal parser seam without changing UI, network behavior, persistence, release behavior or accepted fields.

The provider-to-consumer correction order is:

```text
Agent -> Hub -> Gateway -> Android
```

Do not add a downstream compatibility workaround that conceals an upstream contract defect.

## W7A-S01 — Agent to Hub exact integration

### Objective

Prove that the exact Agent implementation generates a safe Codex usage event that the exact Hub accepts and converts to the expected safe read model.

### Required execution shape

Use an owned isolated validation root with:

- exact source copies;
- a synthetic backend-usage payload;
- the real Agent normalizer and event/batch builder;
- a temporary loopback Hub process;
- a temporary SQLite database;
- in-memory generated HMAC and read credentials;
- no production endpoints or credentials.

Do not directly hand-write the Hub event or summary as the primary acceptance path.

### Required scenarios

Positive:

- default 5-hour window;
- default weekly window;
- additional 5-hour window;
- additional weekly window;
- partial and null metrics;
- exhausted and active status;
- reset fields and window labels;
- actual collector identity.

Negative and safety:

- raw token-like fields;
- email, account ID and user ID;
- nested unknown values;
- auth-path markers;
- malformed and negative metrics;
- bad HMAC;
- wrong node;
- missing and bad read authorization;
- stale event;
- backend-error/degraded event.

### Acceptance

```text
AGENT_USAGE_EVENT_GENERATED_BY_REAL_CODE=true
HUB_REAL_INGEST_PASS=true
HUB_FOUR_WINDOW_SUMMARY_PASS=true
AGENT_HUB_COLLECTOR_IDENTITY_RECONCILED=true
RAW_BACKEND_DATA_EXPOSED=false
```

## W7A-S02 — Hub to Gateway exact integration

### Objective

Run the exact Gateway one-shot source against the exact temporary Hub populated through S01.

### Required execution shape

Use:

- the S01-compatible actual Hub process and safe database state;
- a generated runtime-only read bearer;
- the exact expected node ID;
- an exact Gateway source copy;
- a temporary Gateway SQLite database or equivalent owned test store;
- loopback only;
- one explicit source invocation only.

### Required scenarios

Hub and parser states:

- four-window `ok`;
- degraded;
- stale;
- missing;
- one or all limits exhausted;
- wrong node;
- `safe_response=false`;
- limits count mismatch;
- invalid enums, timestamps and metrics;
- unknown additive fields;
- redirect, unauthorized, server failure, timeout and connection refusal.

Semantic deduplication:

- identical response is duplicate;
- `updated_at`-only change is duplicate;
- reset timestamp/countdown-only change is duplicate;
- limit ordering-only change is duplicate;
- material percent, status or exhausted/recovered transition emits a new message.

### Message acceptance

The emitted message must remain bounded and subject-scoped:

```text
schema_version=1
message_type=codex.usage.summary.v1
source=telemetry-hub
subject=Codex usage update
recipient=subject:<runtime-subject>
```

It must not expose the bearer, raw Hub body, raw metrics, account identity, user identity or source credential material.

### Acceptance

```text
ACTUAL_HUB_GATEWAY_READ_PASS=true
FOUR_WINDOW_GATEWAY_PARSE_PASS=true
SEMANTIC_DEDUP_PASS=true
SUBJECT_OUTBOX_PASS=true
GATEWAY_EXTERNAL_NETWORK=false
```

## W7A-S03 — Gateway to Android exact contract

### Objective

Prove that the exact Gateway Android response generated from the W7A message is accepted safely by the exact Android contract and acknowledgement path.

### Gateway API checks

Verify the exact allowlisted response keys:

```text
message_id
created_at
title
body_preview
priority
status
source
cursor
```

Verify the absence of recipient keys, subjects, credentials, Hub payloads, raw metrics, internal route state, provider state and database state.

Verify acknowledgement:

- first acknowledgement succeeds;
- repeated acknowledgement is idempotent;
- subsequent pending pull excludes the message;
- foreign or absent message ID returns safe not-found behavior.

### Android parser checks

The acceptance fixture must be captured from the actual Gateway response in the owned validation root. Prefer an existing test seam. When no safe complete-response seam exists, permit one minimal Android testability change that extracts a pure internal parser.

Verify:

- the actual response parses;
- additive unknown fields are ignored;
- title, preview, source and status remain bounded;
- credential-like or structured payload fragments are rejected;
- message ID is not displayed and is used only for acknowledgement;
- no message content is persisted;
- release canary remains disabled;
- release base URL remains empty.

### Android Gradle boundary

Accepted Gradle evidence is limited to explicitly no-signing tasks such as:

```text
:mobile-app:testDebugUnitTest
```

Use an isolated Gradle, Android and Java home plus a task-graph guard. Reject any task graph containing assemble, bundle, package, sign, validateSigning, install, connected, device, deploy, publish, APK or AAB tasks.

### Acceptance

```text
GATEWAY_ANDROID_RESPONSE_ALLOWLIST_PASS=true
ANDROID_ACTUAL_GATEWAY_FIXTURE_PARSE_PASS=true
ANDROID_SAFE_PREVIEW_PASS=true
ACK_IDEMPOTENT_PASS=true
ANDROID_RELEASE_BEHAVIOR_UNCHANGED=true
SIGNING_TASK_EXECUTED=false
```

## W7A-S04 — Full-chain audit

### Objective

Prove the complete local chain in one exact-SHA validation run:

```text
synthetic backend payload
-> Agent real normalizer
-> Agent real signed batch
-> Hub real ingest and read model
-> Gateway real one-shot source
-> Gateway real subject outbox and Android API
-> Android exact parser contract
-> idempotent acknowledgement
```

### Required audit state

Record:

- initial and final SHA for all four repositories;
- local/remote parity and clean worktree state;
- product outcome for each repository;
- all accepted validation commands;
- accepted, rejected and superseded evidence;
- temporary process and port cleanup;
- filesystem mutation scope;
- Git, GitHub, CI and PR accounting;
- all prohibited operations remaining false.

Use two fresh direct native read-only Auditors and one fresh final Supervisor. No recursive descendants and no external Codex processes.

## Evidence paths

Use the current repository-health local evidence model:

```text
V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-report.md
V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-checkpoint.json
```

Detailed failure logs may be placed under:

```text
V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-logs\
```

Owned validation roots belong under:

```text
V:\src\.codex-validation\w7a-*
```

Remote publication of local reports or artifacts is not a completion dependency.

## Automatic recovery budget

The same top-level W7A Goal may automatically perform bounded recovery for:

- process-scoped Node, npm, Java, Gradle and PowerShell rebinding;
- owned validation-root creation and cleanup;
- dependency installation inside owned validation copies;
- dynamic loopback-port selection;
- temporary process startup, shutdown and stale owned-process cleanup;
- workflow syntax or test-harness correction;
- safe fetch and prune;
- normal feature branch, pull request, merge and merged-ref retirement;
- exact-head and exact-main CI waiting;
- one test/harness-only corrective commit beyond the ordinary product-correction budget.

Product corrections are limited to two corrective commits per affected repository. One additional test/harness-only corrective commit is permitted. Further product correction requires an owner decision. An execution path whose safety cannot be demonstrated is an unsafe blocker.

## Top-level exits

The executor must continue through ordinary successful phases and stop only with exactly one of:

```text
W7A_COMPLETE
M7A_CODEX_USAGE_CHAIN_GREEN=true
```

or:

```text
W7A_OWNER_DECISION_REQUIRED
```

or:

```text
W7A_UNSAFE_BLOCKER
```

Do not create owner-visible suffix steps.

## Prohibited operations

Wave 7A does not authorize:

- reading real `%USERPROFILE%\.codex\auth.json` or another real Codex auth file;
- calling the real ChatGPT/Codex backend;
- contacting production LAX Agent, Beijing Hub or a production Gateway;
- using real Hub, Gateway, Access or Android credentials;
- production polling, scheduler or daemon enablement;
- production deployment or database mutation;
- external notification delivery;
- real Authentik login;
- APK/AAB assembly, packaging or signing;
- signing-key inspection or access;
- physical phone, watch, ADB, installation or sideloading;
- Windows service, Scheduled Task, persistent PATH or registry mutation;
- force push, history rewrite or destructive branch deletion.

## Milestone contract

The success block must include:

```text
W7A_COMPLETE
M7A_CODEX_USAGE_CHAIN_GREEN=true
W7A_CHAIN_SEMANTICS=SAFE_USAGE_CHANGE_MESSAGE

AGENT_HUB_CONTRACT_COMPATIBLE=true
HUB_GATEWAY_CONTRACT_COMPATIBLE=true
GATEWAY_ANDROID_CONTRACT_COMPATIBLE=true
FULL_LOCAL_CHAIN_E2E_PASS=true
FOUR_WINDOW_CHAIN_PASS=true
SEMANTIC_DEDUP_PASS=true
ACK_IDEMPOTENT_PASS=true

AGENT_PRODUCT_OUTCOME=<actual>
HUB_PRODUCT_OUTCOME=<actual>
GATEWAY_PRODUCT_OUTCOME=<actual>
ANDROID_PRODUCT_OUTCOME=<actual>

REAL_CODEX_AUTH_READ=false
REAL_CHATGPT_REQUEST=false
PRODUCTION_HUB_REQUEST=false
PRODUCTION_GATEWAY_ACTION=false
PHYSICAL_DEVICE_ACTION=false
SIGNING_TASK_EXECUTED=false
PRODUCTION_ACTION=false

W7B_NOT_STARTED
READY_FOR_W7B
```

Wave 7B must not start inside the W7A Goal.