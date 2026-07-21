# Wave 7A Execution Orchestrator

## Goal identity

```text
GOAL_ID=COMPLETE-WAVE-7A-CODEX-USAGE-SAFE-MESSAGE-CHAIN
WAVE=W7A
MILESTONE=M7A_CODEX_USAGE_CHAIN_GREEN
EXECUTION_MODEL=ONE_VISIBLE_CODEX_TUI_WITH_DURABLE_LOCAL_CHECKPOINT
```

## Authority

This orchestrator implements:

```text
docs/jerry-series/plans/wave-7a-codex-usage-chain-plan.md
```

It also inherits:

- `docs/jerry-series/decisions/JD-0002-current-repository-health-train-keeps-wave-6-execution-model.md`;
- `docs/jerry-series/retrospectives/wave-5-lessons.md`;
- `docs/jerry-series/retrospectives/wave-6-lessons.md`;
- every applicable playbook, policy, `AGENTS.md` and repository instruction.

When instructions conflict, the narrowest active repository safety rule wins. No instruction may expand production, device, credential, signing or destructive Git authority.

## Durable local state

Use:

```text
CHECKPOINT=V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-checkpoint.json
REPORT=V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-report.md
LOG_ROOT=V:\src\integration-inventory\repo-health\w7a-codex-usage-chain-logs
VALIDATION_ROOT=V:\src\.codex-validation
```

The checkpoint is the resumable materialized state. It is not live truth. Every resume must independently revalidate repository identity, exact SHA, worktree state, locks, processes, ports, PRs and the last accepted evidence before continuing.

## Execution sequence

Run continuously:

```text
ADMISSION
-> W7A-S01 Agent to Hub exact integration
-> W7A-S02 Hub to Gateway exact integration
-> W7A-S03 Gateway to Android exact contract
-> W7A-S04 full-chain live audit
```

Do not ask for acknowledgement after an ordinary successful phase. Do not invent W7A-S01A, recovery suffixes or separate owner-visible substeps.

Wave 7B must not start inside this orchestrator.

## Coordination model

- One product writer at a time.
- Native direct read-only subagents may inspect in parallel or deterministic staggered batches.
- No recursive descendants.
- No external Codex process, `codex exec`, SSH auditor or detached role process.
- Final W7A-S04 uses two fresh direct native read-only Auditors and one fresh Supervisor.
- Product Git operations are performed by Codex, not the owner.

## Admission

### Governance synchronization

Safely synchronize:

```text
V:\src\dev_governance_files
```

to remote `main`. Do not discard local governance dirt, unique commits or divergence. Stop with `W7A_OWNER_DECISION_REQUIRED` when safe fast-forward synchronization is not possible.

Read this orchestrator and the authoritative plan from the synchronized governance checkout.

### Repository inventory

Inspect:

```text
V:\src\jerry-telemetry-agent
V:\src\jerry-telemetry-hub
V:\src\jerry-message-gateway
V:\src\jerry-devops-android
```

For each repository, record:

- repository identity and remote URL;
- default branch;
- local and remote `main` SHA;
- upstream binding;
- clean/dirty status;
- all local branches, remote heads and worktrees;
- open PRs;
- stashes and operation markers;
- unique local or remote history;
- applicable `AGENTS.md` and repository instructions.

Initial expected remote SHAs are:

```text
Agent=e2eefd1630d6231ea5fe7388c3caf1394576c8f6
Hub=8960abd64f1736de5a31788f8a65e31c76ed6971
Gateway=6ee6b1bc9ae3045a42d94df943ce77331178c3ec
Android=c856e4f8ee476002b3a17858a1873fe945322ef6
```

A newer canonical `main` may be rebound only after complete proof that it is safe and compatible. Never reset to these historical expectations merely to match the plan.

### Chain semantics

Record:

```text
W7A_CHAIN_SEMANTICS=SAFE_USAGE_CHANGE_MESSAGE
FULL_ANDROID_USAGE_DASHBOARD=false
PRODUCTION_POLLING=false
PHYSICAL_PHONE_VALIDATION=false
```

### Toolchain and safety preflight

Preflight before product writes:

- Node/npm toolchains required by Agent, Hub and Gateway;
- Java/Gradle required by Android;
- isolated Gradle/Android/Java homes;
- PowerShell and dynamic loopback-port support;
- repository permissions and CI availability;
- available local disk for validation copies;
- no owned process or listener collision from an earlier attempt.

Only process-scoped toolchain rebinding is permitted.

## W7A-S01 — Agent to Hub

### Validation root

Create a fresh exact root such as:

```text
V:\src\.codex-validation\w7a-s01-agent-hub-<agent-short>-<hub-short>-<attempt>
```

It must be absent or conclusively empty before use. Use exact source copies. Do not mutate product checkouts for validation setup.

### Required implementation path

Construct a synthetic backend-usage input and invoke the real Agent Codex normalizer plus real event/batch path. Send the resulting signed batch to a temporary exact Hub process using:

- a temporary SQLite database;
- generated HMAC material in memory;
- generated read authorization in memory;
- a loopback dynamic port;
- no `.env` or production credential inheritance.

The primary acceptance path must not hand-write the final Hub event or summary.

### Required validation

Prove four-window preservation and all plan scenarios. Compare the actual collector identity and record any safe naming normalization. Verify bad HMAC, wrong node, read-auth failures, stale and degraded behavior, and forbidden-field omission.

### Product disposition

When compatible, record `NO_PRODUCT_DELTA_REQUIRED` for Agent and Hub.

When incompatible, identify the owning provider, create one normal feature branch in that repository, implement the smallest coherent correction, run repository validation, create a PR, prove exact-head CI, merge normally, prove exact-main state, retire the merged ref safely, update the W7A baseline and rerun S01.

Do not continue S02 on a superseded S01 source state.

## W7A-S02 — Hub to Gateway

### Validation root

Create a fresh exact root such as:

```text
V:\src\.codex-validation\w7a-s02-hub-gateway-<hub-short>-<gateway-short>-<attempt>
```

The Hub state must be generated through the accepted S01 real Agent path or a deterministic replay of the accepted exact S01 event. A hand-written fake Hub response is insufficient as the primary proof.

### Required implementation path

Run the exact Gateway one-shot source directly against the exact temporary Hub:

```text
GET /v1/codex/usage/summary
```

Use a generated runtime-only read bearer, exact expected node ID, a temporary Gateway store and loopback only.

### Required validation

Prove:

- four-window parsing;
- all status and parser-defense scenarios;
- redirect and unavailable handling;
- semantic deduplication;
- bounded message creation;
- subject-scoped outbox isolation;
- no raw Hub response, account identity, user identity or credential leakage.

The semantic fingerprint must treat timestamp, reset countdown and ordering-only changes according to the plan and emit on material state transitions.

### Product disposition

Apply the same provider-first correction process. A downstream Gateway workaround must not conceal an invalid Hub contract.

## W7A-S03 — Gateway to Android

### Validation root

Create a fresh exact root such as:

```text
V:\src\.codex-validation\w7a-s03-gateway-android-<gateway-short>-<android-short>-<attempt>
```

Capture the actual safe Gateway `/v1/android/messages` response produced by the accepted S02 message. Store it only inside the owned validation root.

### Gateway validation

Verify the exact response allowlist and the absence of recipient, credential, Hub payload, raw metric, internal route, provider and database state.

Verify first acknowledgement, repeated acknowledgement, subsequent pull and safe not-found behavior.

### Android validation

Use the actual captured Gateway response as input to the exact Android parser contract.

Prefer an existing test seam. When none exists, a minimal testability-only Android change may extract a pure internal parser. Such a change must not alter UI, runtime network behavior, storage, release behavior, accepted fields or security boundaries.

### No-signing Gradle policy

Use fresh isolated:

```text
GRADLE_USER_HOME
ANDROID_USER_HOME
user.home
```

under the validation root. Use `--no-daemon` and a task-graph guard. The accepted task graph must contain no case-insensitive match for:

```text
assemble
bundle
package
sign
signingReport
validateSigning
install
uninstall
connected
device
deploy
publish
upload
apk
aab
```

Use only an explicitly no-signing target such as `:mobile-app:testDebugUnitTest` after a guarded dry run.

Do not inspect real `.android`, `.gradle`, `.jks`, `.keystore` or signing material.

### Product disposition

The default is `NO_PRODUCT_DELTA_REQUIRED`. `MINIMAL_TESTABILITY_DELTA_IMPLEMENTED` is allowed only for the pure parser seam described above.

## W7A-S04 — Full-chain audit

### Integrated rerun

Perform a fresh integrated run from synthetic backend input through Android parser and acknowledgement using the final accepted SHAs.

Do not merely combine earlier flags. Prove the complete chain again in one bound validation run or a deterministic chain of accepted exact-state subruns whose inputs and outputs are hash-bound.

### Fresh audits

Auditor A reviews:

- data mapping and enum compatibility;
- redaction and forbidden fields;
- four-window behavior;
- semantic deduplication;
- Android safe preview and acknowledgement.

Auditor B reviews:

- exact SHAs and repository state;
- local/remote parity;
- PR, CI, branch and worktree accounting;
- validation roots, processes, listener closure and filesystem scope;
- evidence acceptance, rejection and supersession;
- all prohibited operations.

The fresh Supervisor independently recomputes the milestone. A prior checkpoint is not sufficient.

## Evidence model

Maintain one compact report and checkpoint. The checkpoint must include:

- `status` and `current_step`;
- authoritative governance commit and plan paths;
- repository baseline and final SHAs;
- `phases` map;
- active locks;
- validation roots and attempt dispositions;
- product outcomes;
- accepted/rejected/superseded evidence;
- blockers and consumed owner overrides;
- mutation and non-mutation accounting;
- final milestone fields.

Do not create one owner-visible evidence file per internal gate.

## Automatic recovery

Remain inside the same top-level Goal for ordinary recovery:

- process-only toolchain correction;
- clean owned validation copies;
- dynamic port conflicts;
- stale owned child processes;
- dependency caches and installs inside validation copies;
- local test-harness defects;
- workflow syntax/context defects;
- repository-scoped runner recovery when required;
- safe fetch/prune;
- normal feature branch/PR/merge/retirement;
- exact-SHA CI waiting.

Corrective budgets:

```text
product corrective commits per affected repo: 2
additional test/harness-only corrective commits per affected repo: 1
```

A planned coherent implementation commit does not consume the corrective budget. Further corrections require `W7A_OWNER_DECISION_REQUIRED`.

## Owner decision conditions

Use `W7A_OWNER_DECISION_REQUIRED` for:

- ambiguous product semantics;
- baseline with legitimate unique local or remote work;
- a bounded correction budget extension;
- a choice between multiple reasonable provider contracts;
- credential, branch policy or production authorization;
- an Android change larger than the permitted pure parser seam.

## Unsafe blocker conditions

Use `W7A_UNSAFE_BLOCKER` for:

- secret exposure;
- unknown or unowned mutation;
- force/history rewrite requirement;
- unclassified unique history;
- concurrent ref drift that prevents exact binding;
- inability to prove no signing or device task in accepted Android validation;
- inability to bind evidence to exact source state;
- a required execution path whose safety cannot be demonstrated.

A structured blocker must include:

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

## Absolute prohibitions

Never perform:

- real Codex auth-file read;
- real ChatGPT backend request;
- production LAX or Beijing request;
- production Hub/Gateway/Android credential use;
- production scheduler, daemon or deployment activation;
- external notification delivery;
- real Authentik login;
- Android assemble, package, signing, install, ADB or device action;
- signing-key inspection;
- production database mutation;
- Windows service, Scheduled Task, persistent PATH or registry mutation;
- force push, history rewrite, `git branch -D` or admin merge.

## Final exits

Success output must be only the plan-defined W7A success block beginning:

```text
W7A_COMPLETE
M7A_CODEX_USAGE_CHAIN_GREEN=true
```

A blocked run must output only the complete structured owner-decision or unsafe-blocker block.

Do not start W7B.