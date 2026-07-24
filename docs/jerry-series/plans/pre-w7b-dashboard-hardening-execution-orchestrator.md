# Pre-W7B Dashboard Hardening Execution Orchestrator

## Identity

```text
TRAIN_ID=PRE-W7B-DASHBOARD-HARDENING
AMENDMENT_ID=W7V-R02-PRE-W7B-DASHBOARD-HARDENING
ROLE=implementer
PROFILE=jerry-implementer
GOVERNANCE_REPOSITORY=V:\src\dev_governance_files
DASHBOARD_REPOSITORY=V:\src\jerry-glance-dashboard
EVIDENCE_ROOT=V:\src\integration-inventory\repo-health
INITIAL_DASHBOARD_MAIN=c3f0e309ec26238d5d61972b5024d76d478c8adc
W7B_STARTED=false
```

This is the durable one-writer, checkpointed state machine for the hardening
interlude between completed W7V and the existing W7B.

## Authoritative inputs

1. `pre-w7b-dashboard-hardening-train.md`;
2. `config/repo-health-master-wave-plan.json`;
3. `docs/repo-health-master-wave-plan.md`;
4. the final W7V closure receipt and normalization receipt bound in the train;
5. repository `AGENTS.md` files, with the later explicit Goal controlling where
   it intentionally widens an older repository-local restriction; and
6. the safe checkpoint after it exists.

If checkpoint text conflicts with live repository state, live state wins. If an
old report section conflicts with the hash-bound final W7V closure, the latest
final closure wins. Owner decisions are immutable and append-only once recorded.

## Roles and permission model

The root Implementer is the only product, governance, evidence, Git, and GitHub
writer. It holds the repository writer lease before each write phase and
releases it at a safe boundary.

Built-in subagents may perform bounded read-only exploration, test review,
security review preparation, and log classification. They do not mutate files,
Git, GitHub, credentials, authentication state, or infrastructure and do not
serve as the independent final acceptance boundary.

Independent acceptance requires separately launched read-only Codex processes:

- a governance exact-head Auditor/Supervisor;
- a Phase A security Auditor;
- a Phase B UI/security Auditor;
- a Phase C1 UI Auditor;
- Phase C2 UI and security/artifact Auditors; and
- a fresh final exact-main Supervisor/Auditor.

## Durable state

After Stage G exact main, maintain:

```text
V:\src\integration-inventory\repo-health\
  pre-w7b-dashboard-hardening-checkpoint.json
  pre-w7b-dashboard-hardening-report.md
  pre-w7b-dashboard-hardening-logs\
```

Checkpoint schema:

```text
pre-w7b-dashboard-hardening-checkpoint.v1
```

Use same-directory temporary creation, flush, and atomic replacement. Update
after branch creation, commit, push, PR creation, exact-head acceptance, merge,
exact-main acceptance, branch retirement, owner receipt, and blocker
classification. A transient write failure preserves the prior checkpoint and
blocks further irreversible work.

Safe checkpoint sections:

- train/schema/status/current phase;
- immutable owner decisions;
- W7V evidence paths and SHA-256 values;
- `W7B_STARTED=false`;
- admitted governance and Dashboard SHAs;
- per-milestone and per-owner-gate state;
- per-PR branch/head/check/merge/main state;
- correction budgets consumed;
- safe evidence path and disposition records;
- security and mutation Booleans;
- blocker envelope or next action; and
- exact resume instructions.

Never persist personal identity details, usernames, passwords, credential
values, storage-state contents, cookies, tokens, credential database contents,
private keys, raw authentication errors, secret-bearing command lines, or
private connection metadata.

## Global state machine

```text
STAGE_G_ADMISSION
  -> STAGE_G_IMPLEMENT
  -> STAGE_G_REVIEW
  -> STAGE_G_PR_EXACT_HEAD
  -> STAGE_G_MERGE_EXACT_MAIN
  -> CHECKPOINT_INITIALIZE
  -> PHASE_A_ADMISSION
  -> PHASE_A_IMPLEMENT
  -> PHASE_A_REVIEW_AND_PR
  -> PHASE_A_EXACT_MAIN
  -> OWNER_GATE_G1
  -> PHASE_B_ADMISSION
  -> PHASE_B_IMPLEMENT
  -> PHASE_B_REVIEW_AND_PR
  -> PHASE_B_EXACT_MAIN
  -> OWNER_GATE_G2
  -> PHASE_C1_ADMISSION
  -> PHASE_C1_IMPLEMENT
  -> PHASE_C1_REVIEW_AND_PR
  -> PHASE_C1_EXACT_MAIN
  -> OWNER_GATE_G3
  -> PHASE_C2_ADMISSION
  -> PHASE_C2_IMPLEMENT
  -> PHASE_C2_REVIEW_AND_PR
  -> PHASE_C2_EXACT_MAIN
  -> OWNER_GATE_G4
  -> FINAL_READ_ONLY_AUDIT
  -> COMPLETE_AT_W7B_AUTHORIZATION_BOUNDARY
```

No transition skips an owner gate or combines product PRs.

## Admission before every repository write

Record and verify:

```text
cwd
repository_root
origin_identity
current_branch
HEAD
local_origin_main
live_remote_main
clean_or_classified_status
worktrees
stashes
writer_lock
merge_marker
rebase_marker
cherry_pick_marker
revert_marker
bisect_marker
allowed_write_boundary
upstream_read_only_boundaries
```

Use per-command `safe.directory` only if ownership requires it. Never change
global Git configuration for admission.

Unknown dirt, an existing writer lease, ref drift, or an active unsafe Git
operation blocks mutation. Approved evidence is existence/classification-only
unless a separate authorization permits descendants. Do not inspect or enumerate
`.claude/` descendants to make Dashboard admission pass.

## Stage G — governance first

### G.1 Admission

Require:

```text
governance_main=88e9cff2203926618eb2ac9ba2017d2a646ed91d
master_plan_version=1.5
amendment_id_free=true
W7V_FORMAL_CONFORMANCE=PASS
W7V_OVERALL_STATUS=COMPLETE
dashboard_exact_main=c3f0e309ec26238d5d61972b5024d76d478c8adc
W7B_STARTED=false
```

If version `1.5` or the reserved amendment slot has drifted, re-admit the live
structure and stop for owner decision when the semantic slot conflicts.

### G.2 Write boundary

Only these governance files are in scope:

```text
docs/jerry-series/plans/pre-w7b-dashboard-hardening-train.md
docs/jerry-series/plans/pre-w7b-dashboard-hardening-execution-orchestrator.md
docs/jerry-series/knowledge-index.md
config/repo-health-master-wave-plan.json
docs/repo-health-master-wave-plan.md
```

Do not update the registry, dependency graph, product repository, CI
infrastructure, or older W7V plan merely because current metadata is stale. A
mandatory scope expansion requires owner decision.

### G.3 Validation

At minimum:

- parse the canonical JSON;
- verify unique amendment, wave, and step identifiers;
- verify plan version `1.6`;
- verify W7V is completed and bound to final closure evidence;
- verify W7V immediately precedes W7B;
- verify W7B retains its identifier, name, steps, milestone, and visual channel;
- verify W7B still depends on W7V and also gates on the hardening milestone;
- verify three ordered phase milestones, four product PRs, and four owner gates;
- verify all referenced governance documents exist;
- verify `W7B_STARTED=false`;
- scan for prohibited credential/state material;
- run `git diff --check`; and
- distinguish pre-existing harness drift from introduced failures.

### G.4 Review and delivery

Use one planned coherent commit. Obtain a fresh independent read-only exact-head
governance review. Push normally, open a normal PR, require exact-head
self-hosted CI, merge normally, validate exact main, delete the remote branch
normally, and delete the local branch with `git branch -d`.

If the repository lacks an in-scope self-hosted exact-head CI path, do not count
local tests, Copilot review, or a hosted runner as CI. Stop with
`PREW7B_DASH_HARDENING_OWNER_DECISION_REQUIRED` before adding workflow or runner
scope.

No Dashboard branch starts until:

```text
GOVERNANCE_PLAN_MERGED=true
GOVERNANCE_EXACT_MAIN_PASS=true
W7B_STARTED=false
```

## Checkpoint initialization

After governance exact main, create the checkpoint, report, and log directory.
Bind:

- governance exact-main SHA and PR/check proof;
- Dashboard admitted SHA;
- the four W7V evidence paths/hashes from the train;
- protected-evidence disposition without descendant data;
- all milestones and owner gates initially false/pending;
- correction budgets at zero;
- all prohibited mutation/security Booleans false;
- `current_phase=PHASE_A_ADMISSION`; and
- safe resume instructions.

## Product PR lifecycle

Each product PR uses a fresh branch from the preceding exact main:

1. re-admit live state and acquire the Dashboard writer lease;
2. create the phase branch;
3. implement only the phase write boundary;
4. run phase-focused tests and the full repository gate;
5. obtain the required independent read-only review;
6. commit within budget and push normally;
7. open a normal PR;
8. wait for exact-head self-hosted CI;
9. classify failures as product, infrastructure, or external;
10. correct within budget or stop;
11. merge normally only after exact-head acceptance;
12. validate local and self-hosted exact main;
13. retire remote and local branches normally; and
14. atomically checkpoint the irreversible boundary.

Do not use force push, force delete, empty trigger commits, or hosted runners.

## Phase A orchestrator

### A.1 Write boundary

Limit changes to the repository-local auth tool, its target manifests, provider
adapters, synthetic fixtures, tests, thin compatibility wrappers, ignore/scanner
rules, positive artifact allowlists, and related documentation/CI protections.

Dashboard business assertions stay outside `tools/web-auth`. Do not create a new
repository or persistent process.

### A.2 Command contract

```text
auth preflight
auth validate
auth acquire
auth refresh
auth run
```

`preflight` performs no login. `validate` uses a fresh context and exact HTTPS
origin. `acquire` submits once at most. `refresh` validates first and acquires
once at most. `run` passes only a state pathname to the business test.

The parser has no password option. The broker does not print credentials and
does not place them in argv or environment. Provider stdin/anonymous-pipe input
is finite and consumed for the single submission.

### A.3 Provider contract

Implement and test:

```text
detectLoginPage
detectUnexpectedChallenge
fillAndSubmitOnce
validateFinalOrigin
classifySafeFailure
```

Safe classifications are finite. Unknown or changed flows fail closed.

### A.4 State transaction

Create the temporary state beside the final state, apply owner-only ACL, keep
trace/video/HAR/login screenshots disabled, validate in a fresh context, and
replace only on exact-origin success. Failure preserves the prior state and
removes only the unsuccessful temporary state.

### A.5 Review gates

Before merge prove all required parser, environment, single-submission,
classification, origin, atomicity, target separation, adapter, and artifact-mode
tests. Require independent security review and self-hosted exact-head CI.

After normal merge and exact-main validation, retire the branch and stop at G1.

## Owner gate G1

Output:

```text
BLOCKER_CODE=PREW7B_DASH_HARDENING_OWNER_ACTION_REQUIRED
BLOCKED_STEP=OWNER_GATE_G1
BLOCKED_PHASE=PHASE_A
BLOCKER_TEXT=Dedicated Canary E2E identity, subject-bound policy, and current-user generic credential must be created by the owner.
```

Do not perform the identity, Authelia, or credential action. After the owner
confirms completion, re-admit, run `preflight`, then permit at most one
acquisition. Stop immediately for MFA, CAPTCHA, regulation lockout, unknown
form, origin mismatch, access denial, or network/TLS failure. Record only the
safe status schema and Booleans.

Set `M_DASH_AUTH_AUTOMATION_READY=true` only when every Phase A/G1 condition in
the train is true.

## Phase B orchestrator

### B.1 Write boundary

Create:

```text
ui/dashboard-ui-contract.v1.json
ui/schema/dashboard-ui-contract.v1.schema.json
ui/dashboard-ui-contract-legacy-allowlist.v1.json
docs/design/dashboard-ui-contract-v1.md
```

Add the renderer, generated markers/parity checks, AST linter, preview fixtures,
computed-style/geometry tests, and the explicit `AGENTS.md` rules. Do not change
production card selectors/classes in Phase B.

### B.2 Deterministic generation

One renderer consumes the contract and emits marker-delimited common CSS into
every managed single-file template. Generated files are never hand-edited.
Parity is byte-deterministic after normalized line endings.

### B.3 Linter

Parse authored and generated CSS structurally. Reject raw unapproved gap,
padding, radius, semantic border width, breakpoint, and negative-margin
geometry. Match allowlist entries by exact file/selector/property/value/count.
Reject wildcard, unused, expired, and count-changed entries.

### B.4 Geometry validation

Run 1600, 1366, and 390 viewport assertions for English, Chinese, and Settings.
Use computed styles and bounding boxes as primary acceptance; screenshots are
supplemental. Assert wrapping, columns at 900/600, axes, heights, rhythm, borders,
and no horizontal overflow.

After exact-head CI and independent UI/security review, merge normally, validate
exact main, retire the branch, and stop at G2.

## Owner gate G2

Present the fixture-only Canary preview and computed-style report. The owner
accepts or rejects the tokens, vocabulary, responsiveness, wrapping, exception
mechanism, and Canary identity.

One bounded correction round is allowed. A second rejection stops for Architect
and owner review. On acceptance, record a safe receipt and set
`M_DASH_UI_CONTRACT_V1_READY=true`.

## Phase C1 orchestrator

### C1.1 Preview only

Start from Phase B exact main. Build the complete fixture-backed,
production-shaped Canary preview using the finite mapping in the train. Do not
change production-rendered behavior.

### C1.2 Geometry inventory

Inventory every owned production geometry declaration and assign one exact
disposition. Reject missing or multiple dispositions. Initial classifications
follow the train; duplicate inner titles and the 24rem depth/bottom alignment
remain explicit owner decisions.

### C1.3 Validation and delivery

Run three-viewport computed styles, boxes, wrapping, overflow, expected
network-origin, and screenshot checks. Require exact-head self-hosted CI and
fresh independent review. Merge normally, validate exact main, retire the branch,
and stop at G3.

## Owner gate G3

The owner decides duplicate inner titles, 24rem depth alignment, and overall
preview acceptance. Record the exact decisions safely. One bounded correction
round is allowed; a second rejection requires Architect and owner review.

No Phase C2 branch starts without accepted G3 decisions.

## Phase C2 orchestrator

### C2.1 Production-only boundary

Apply only the accepted selectors/classes, semantic exceptions, generated
artifacts, tests, and directly related documentation. Remove obsolete allowlist
entries. Do not include auth, credential, Authelia, OpenResty, unrelated deploy,
data, or business behavior changes.

### C2.2 Pre-merge proof

Require:

- source/generated parity;
- translation/key checks;
- secret scanners;
- exact Dashboard SHA reporting;
- anonymous boundary;
- validation-only owner production state;
- three-viewport computed geometry;
- axes, equal heights, rhythm, wrapping, overflow;
- expected browser network origins;
- state/login artifacts absent from upload rules; and
- current single-file deployment artifact.

Obtain separate independent UI and security/artifact audits plus self-hosted
exact-head CI. Merge normally, validate with self-hosted exact-main CI, and
retire the branch normally.

Record code-ready state but keep
`M_DASH_PRODUCTION_UI_HARMONIZED=false` until G4.

## Owner gate G4

Prepare, but do not execute, the production handoff:

```text
accepted_main_sha
generated_artifact_sha256
predeploy_receipt
expected_mount_identity
prior_known_good_sha256
rollback_procedure
anonymous_validation_checklist
authenticated_validation_checklist
```

The owner performs one config-only apply. One automatic rollback is permitted if
validation fails. No second apply occurs without a new owner decision.

After owner completion, validate the safe post-deploy conditions without
retaining credentials, cookies, or state. Record owner acceptance and rollback
proof, then set `M_DASH_PRODUCTION_UI_HARMONIZED=true`.

## Final independent audit

Launch fresh read-only processes against exact main and require proof of:

- governance exact main and final amendment;
- four separate merged product PRs;
- all exact-head and exact-main checks on self-hosted runners;
- all four owner gates;
- no hosted fallback, force push, or abnormal branch retirement;
- repository-local non-daemon auth tooling;
- no standalone auth repository;
- no personal administrator credential;
- at most one login submission;
- no credential argv/env/history leakage;
- no state upload or evidence retention;
- contract-as-source-of-truth UI generation;
- production parity with accepted preview;
- deploy and rollback proof; and
- `W7B_STARTED=false`.

Only a fresh `PASS` may set the overall milestone. Corrections require a fresh
Implementer phase followed by a fresh read-only audit and remain within budget.

## Failure classification and reruns

For every failed check, bind the exact head and classify:

```text
PRODUCT_REGRESSION
CI_INFRASTRUCTURE
EXTERNAL_DEPENDENCY
OWNER_ACTION
UNSAFE
```

An unchanged-head rerun is permitted only for proven CI infrastructure failure.
No empty commit is used to trigger CI. Hosted fallback is unsafe.

## Correction accounting

Track independently:

```text
governance_planned_commits <= 1
governance_corrective_commits <= 1
each_product_planned_commits <= 2
each_product_corrective_commits <= 2
each_product_test_only_corrective_commits <= 1
G2_correction_rounds <= 1
G3_correction_rounds <= 1
login_submissions_per_invocation <= 1
production_apply_attempts <= 1
automatic_rollbacks <= 1
```

Exhaustion produces owner-decision output before another mutation.

## Stop output

Every stop emits:

```text
BLOCKER_CODE=
BLOCKED_STEP=
BLOCKED_PHASE=
BLOCKER_TEXT=
```

Use only the four blocker codes defined in the train. The stop persists the safe
checkpoint when it exists, releases the writer lease, performs no later phase,
and provides exact resume instructions.

## Absolute prohibitions

- W7B start;
- force push or forced branch deletion;
- hosted-runner fallback;
- credential argv, environment, URL, log, history, commit, or artifact exposure;
- storage-state content read, commit, upload, or evidence retention;
- personal administrator credential or permanent administrator session;
- Authelia bypass or global MFA weakening;
- infinite retry or automatic password retry;
- standalone auth repository, daemon, service, scheduled task, or watcher;
- Implementer production deployment;
- unauthorized SSH, OpenResty, Authelia, runner, or network mutation; and
- cross-phase combined product PR.

## Success output

```text
PRE_W7B_DASHBOARD_HARDENING_COMPLETE
W7V_FORMAL_CONFORMANCE=PASS
W7V_OVERALL_STATUS=COMPLETE
M_DASH_AUTH_AUTOMATION_READY=true
M_DASH_UI_CONTRACT_V1_READY=true
M_DASH_PRODUCTION_UI_HARMONIZED=true
M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=true
GOVERNANCE_PLAN_EXACT_MAIN_PASS=true
PRODUCT_PRS_MERGED=4
SELF_HOSTED_EXACT_HEAD_PASS=true
SELF_HOSTED_EXACT_MAIN_PASS=true
OWNER_GATES_COMPLETE=4
AUTH_LOGIN_MAX_SUBMISSIONS_PER_INVOCATION=1
PERSONAL_ADMIN_CREDENTIAL_USED=false
PLAINTEXT_REPOSITORY_CREDENTIAL=false
STORAGE_STATE_UPLOADED=false
AUTH_TOOL_STANDALONE_REPOSITORY_CREATED=false
AUTH_TOOL_DAEMON_CREATED=false
PRODUCTION_DEPLOYMENT_OWNER_CONTROLLED=true
ROLLBACK_PROOF_RETAINED=true
FINAL_READ_ONLY_AUDIT=PASS
W7B_STARTED=false
READY_FOR_W7B_AUTHORIZATION_REVIEW
```
