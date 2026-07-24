# Pre-W7B Dashboard Hardening Train

## 1. Identity and purpose

| Field | Value |
| --- | --- |
| Train | `PRE-W7B-DASHBOARD-HARDENING` |
| Amendment | `W7V-R02-PRE-W7B-DASHBOARD-HARDENING` |
| Overall milestone | `M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE` |
| Product repository | `jerry-glance-dashboard` |
| Governance repository | `dev_governance_files` |
| Local evidence root | `V:\src\integration-inventory\repo-health` |
| W7B state | `W7B_STARTED=false` |

This amendment inserts a named, checkpointed hardening interlude after completed
Wave 7V and before the existing Wave 7B. It does not add a Wave, rename W7B,
change the W7B milestone, or authorize W7B-S01.

The train establishes:

1. a repository-local, fail-closed browser-authentication test tool;
2. a versioned Dashboard UI geometry contract;
3. an accepted production-shaped Canary preview; and
4. production-only UI harmonization prepared and validated under owner control.

The four product changes are intentionally separate pull requests. Authentication,
contract creation, preview acceptance, and production harmonization must remain
reviewable and reversible as distinct boundaries.

## 2. Authority and one-writer boundary

The root Implementer is the sole intentional writer. It may perform normal
branches, commits, pushes, pull requests, permitted CI reruns, normal merges,
exact-main validation, checkpoint writes, safe evidence generation, and normal
branch retirement within this plan.

Fresh acceptance reviews use independently launched read-only Auditor or
Supervisor processes. Same-process subagents may assist with bounded read-only
analysis, but are not the independent acceptance boundary.

The following remain owner-controlled:

- Authelia identity, group, policy, and configuration changes;
- Windows Credential Manager provisioning through the UI;
- any production deployment or infrastructure mutation;
- the G2 and G3 visual/design decisions;
- the G4 apply decision and final production acceptance; and
- authorization to begin W7B.

The Implementer must not use SSH, change OpenResty or Authelia, create the
dedicated identity, handle a credential value, deploy production, or start W7B.

## 3. Wave 7V closure binding

The interlude is admitted only from the final Wave 7V closure, not from earlier
superseded or append-only in-progress entries.

| Evidence | SHA-256 |
| --- | --- |
| `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-closure-evidence-20260724T061617Z.json` | `e61178ef3c7a54f0952d56c8047f517358245212fdb83bc1b76863bc92640974` |
| `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-logs/s06-final-normalization-validation-20260724T062040Z.txt` | `ab9cbc4c689a8cc5efc690afc0f0dc170b94256cccbdefb3ee51d452e8e025e6` |
| `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-checkpoint.json` | `5845d381a74546a5b79d71e70c3e40ca30383d441942a5fe2221909447768c4b` |
| `V:/src/integration-inventory/repo-health/w7v-dual-dashboard-report.md` | `618155e9d71eb6d384561af545a9789aafd370c186c99e6ab9bbd19d161c3f6e` |

The bound closure proves:

```text
W7V_FORMAL_CONFORMANCE=PASS
W7V_OVERALL_STATUS=COMPLETE
DASHBOARD_EXACT_MAIN=c3f0e309ec26238d5d61972b5024d76d478c8adc
W7B_STARTED=false
```

The report is append-only chronology; its latest final-closure section is the
current disposition. Earlier pending sections and earlier Dashboard SHAs are
historical and do not override the final closure receipt.

## 4. Entry and completion gates

### 4.1 Train entry

All of these must be true before the first Dashboard branch:

```text
GOVERNANCE_PLAN_MERGED=true
GOVERNANCE_EXACT_MAIN_PASS=true
W7V_FORMAL_CONFORMANCE=PASS
W7V_OVERALL_STATUS=COMPLETE
DASHBOARD_MAIN_SHA=c3f0e309ec26238d5d61972b5024d76d478c8adc
W7B_STARTED=false
```

Dashboard main drift before the first product branch requires a fresh Architect
or owner decision. Unknown dirt, an unresolved writer lock, an unsafe Git
operation marker, or an unclassified protected-evidence root blocks admission.
Approved protected evidence is preserved opaquely and is not enumerated merely
to make admission pass.

### 4.2 W7B entry

The existing W7B now has the additional explicit entry gate:

```text
M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=true
```

That milestone may be set only after the fresh final read-only audit passes. Its
achievement returns control to the W7B authorization boundary; it does not start
W7B.

## 5. Ordered phase model

| Order | Product PR | Phase | Milestone or gate |
| --- | --- | --- | --- |
| 1 | PR A | Authentication automation | G1 then `M_DASH_AUTH_AUTOMATION_READY` |
| 2 | PR B | UI contract v1 | G2 then `M_DASH_UI_CONTRACT_V1_READY` |
| 3 | PR C1 | Production-shaped Canary preview | G3 acceptance |
| 4 | PR C2 | Production-only harmonization | G4 then `M_DASH_PRODUCTION_UI_HARMONIZED` |

Every PR starts from the exact main produced by its predecessor. No phase may be
combined with another product PR, and no later branch may start before the
preceding exact-main and owner gate are complete.

## 6. Phase A — authentication automation

### 6.1 Repository-local architecture

Create `tools/web-auth` inside `jerry-glance-dashboard`. It is not a standalone
repository and must not become a daemon, service, scheduled task, watcher, or
persistent helper.

The tool consists of:

- a PowerShell command entrypoint and Windows secret broker;
- a Node/Playwright provider engine;
- secret-free target manifests;
- an Authelia provider adapter;
- an explicit future Authentik adapter interface;
- a finite safe-status schema; and
- unit and synthetic-fixture integration tests.

The conceptual commands are `preflight`, `validate`, `acquire`, `refresh`, and
`run`.

### 6.2 Secret and login invariants

- Credential values are never accepted through argv.
- Credential values are never copied to child-process environment variables.
- Credential material crosses from broker to provider only by redirected stdin
  or an anonymous pipe.
- Managed buffers are cleared on a best-effort basis after the one submission.
- No command automatically retries a password.
- `acquire` permits at most one form submission.
- `refresh` validates first and permits at most one acquisition attempt.
- `run` gives the business test only a storage-state pathname.
- Credentials, identities, cookies, storage-state contents, and raw auth errors
  are never printed or retained as evidence.
- Unexpected flows fail closed.

The primary backend is
`WINDOWS_CREDENTIAL_MANAGER_GENERIC_CREDENTIAL_CURRENT_USER`, addressed through
a fixed non-secret alias and the Windows Credential API. The optional fallback
is `WINDOWS_DPAPI_CURRENT_USER_ENCRYPTED_LOCAL_FILE`, stored outside the
repository under a dedicated owner-only `%LOCALAPPDATA%` location. Machine-scope
DPAPI is rejected.

### 6.3 Provider and target contract

Each adapter implements:

```text
detectLoginPage
detectUnexpectedChallenge
fillAndSubmitOnce
validateFinalOrigin
classifySafeFailure
```

Required fail-closed classifications are:

```text
MFA_REQUIRED
CAPTCHA_PRESENT
REGULATION_LOCKOUT
LOGIN_FORM_UNRECOGNIZED
FINAL_ORIGIN_MISMATCH
BAD_CREDENTIALS_OR_ACCESS_DENIED
NETWORK_OR_TLS_FAILURE
```

Canary and production are separate targets. Canary uses a dedicated credential
alias, permits acquisition, accepts only the exact Canary HTTPS origin, and uses
its own ignored state path. Production is owner-managed, validation-only, has no
automated credential reference, and cannot use the Canary identity or state.

### 6.4 Atomic state policy

An acquired state is written to a temporary file beside the destination, given
an owner-only ACL, and validated in a fresh browser context at the exact allowed
origin. Login trace, video, HAR, and screenshots remain disabled. The final file
is replaced on the same volume only after validation. Failure preserves the old
state and removes the unsuccessful temporary state safely.

State and temporary files are never artifacts. Git ignores state and fallback
ciphertext patterns. CI artifact publication uses positive allowlists and must
prove that state, trace, video, HAR, and login screenshots cannot be uploaded.

### 6.5 Safe status

Output contains only:

```text
target_id
provider
command
status
classification
login_submissions
state_replaced
owner_action_required
sensitive_output=false
```

Existing capture, state-check, and authenticated-smoke commands may become thin
compatibility wrappers. Dashboard assertions—including Canary identity, exact
SHA, business cards, layout, post-auth screenshots, and network-origin audit—
remain outside `tools/web-auth`.

### 6.6 Required proof

Tests cover parser rejection of password arguments, environment isolation,
single submission, zero retry, safe classifications, exact-origin mismatch,
failed-state preservation, atomic success, Canary/production state separation,
adapter extensibility, and disabled login artifacts.

After exact-head CI and an independent read-only security review, PR A merges
normally, exact main is validated, and the branch is retired normally.

## 7. Owner gate G1 — identity and policy

After PR A reaches exact main, the owner creates and provisions the dedicated
non-personal, non-admin Canary E2E identity, its Canary-only group and sequential
subject-bound one-factor policy, and the current-user generic credential through
the Windows UI. Production is excluded; regulation and existing MFA remain.

The Implementer performs at most one post-gate acquisition after a preflight and
records only safe Booleans and classifications.

`M_DASH_AUTH_AUTOMATION_READY` requires:

```text
AUTH_TOOL_EXACT_MAIN_PASS=true
DEDICATED_IDENTITY_OWNER_ACTION_COMPLETE=true
LOGIN_SUBMISSIONS_LESS_THAN_OR_EQUAL_TO_ONE=true
CANARY_FINAL_ORIGIN_VALID=true
PRODUCTION_ORIGIN_DENIED_TO_CANARY_IDENTITY=true
CREDENTIAL_DISCLOSED=false
STORAGE_STATE_UPLOADED=false
```

Extraction to a standalone testkit remains deferred until the stated
multi-service, stability, independent-versioning, or Authentik trigger occurs.

## 8. Phase B — Dashboard UI contract v1

PR B creates the JSON contract, JSON Schema, legacy allowlist, design document,
deterministic common-CSS renderer, AST linter, fixtures, and geometry tests.

Required baseline geometry tokens:

| Token | Value |
| --- | --- |
| `section_gap` | `12px` |
| `grid_gap` | `8px` |
| `standard_card_padding` | `12px` |
| `compact_card_padding` | `10px` |
| `standard_card_radius` | `8px` |
| `packet_radius` | `10px` |
| `alert_radius` | `12px` |
| `neutral_border_width` | `1px` |
| `semantic_left_accent_width` | `4px` |
| `content_max_width` | `1360px` |
| `mobile_breakpoint` | `600px` |
| `tablet_breakpoint` | `900px` |

Named component tokens preserve the accepted W7V 4px micro-gap, 2px alert
border, and pill/meter radius. They are not anonymous exceptions.

The vocabulary is `jd-card`, `jd-card--compact`, `jd-card--positive`,
`jd-card--primary`, `jd-card--warning`, `jd-grid`, `jd-stack`, `jd-status`,
`jd-kv`, `jd-identifier-row`, `jd-alert`, and `jd-pill`.

The renderer injects identical marker-delimited common CSS into the managed
single-file Glance templates. There is no runtime include, external stylesheet,
or second deployable configuration. The same renderer serves production source,
generated configuration, W7V Canary, local preview fixtures, and
production-shaped previews. Parity checks reject manual drift.

The AST linter rejects unapproved raw geometry declarations and negative
margins. Every exact legacy exception declares an ID, file, selector, property,
value, count, rationale, decision owner, and expiry/review trigger. Wildcards,
changed counts, and unused entries fail.

Computed-style and bounding geometry tests run at 1600, 1366, and 390 pixels and
cover token values, card geometry, borders, equal heights, axes, rhythm,
breakpoints, long English/Chinese labels, SHA wrapping, no horizontal overflow,
and English, Chinese, and Settings layouts.

PR B may emit behavior-neutral contract CSS into production output, but it does
not apply the harmonizing selectors/classes. It also updates the Dashboard
`AGENTS.md` contract for generated sources, geometry tokens, exceptions,
single-file deployment, and PR separation.

After exact-head CI and fresh read-only UI/security review, PR B merges normally,
exact main is validated, and the branch is retired normally.

## 9. Owner gate G2 — UI contract acceptance

The owner receives the three-viewport fixture-only Canary preview and computed
style report, and accepts the tokens, component vocabulary, responsive behavior,
wrapping, exception mechanism, and explicit `CANARY` / `NOT PRODUCTION`
identity. One bounded correction round is available.

Acceptance sets `M_DASH_UI_CONTRACT_V1_READY=true`.

## 10. Phase C1 — production-shaped Canary preview

PR C1 is preview-only and fixture-backed. It changes no rendered production
behavior and uses no production credentials, tokens, or live production data.

The finite component mapping is:

- native calendar, weather, and bookmarks: native Glance standard-card adapter;
- Dashboard title/state: `jd-stack`, `jd-status`, and `jd-pill`;
- Codex: compact positive card plus `jd-alert` fallback;
- SkyBridge and Quant: primary cards with compact nested cards and `jd-kv`;
- Fleet: compact positive card plus `jd-identifier-row`;
- Pipelines: compact primary card plus `jd-status`;
- Operations: compact primary card plus `jd-alert`; and
- Settings: standard primary card plus stack, key/value, and pill primitives.

Every owned production geometry declaration receives exactly one disposition:

```text
CONFORM_TO_UI_CONTRACT
PRESERVE_SEMANTIC_EXCEPTION
REMOVE_LEGACY_WORKAROUND
OWNER_DESIGN_DECISION_REQUIRED
```

Three-pixel accents, random card radii/gaps/padding, and fixed grids conform.
Codex negative margins and compensating width are removed. Pill/progress radius
uses its named token. The 24rem depth/bottom alignment is initially preserved
pending owner review. Duplicate SkyBridge/Quant inner titles require an owner
decision. Unowned Glance internals remain outside the authored contract unless
an exact tested adapter selector covers them.

All three viewports run computed-style, bounding-box, wrapping, overflow,
network-origin, and supplemental screenshot checks. After exact-head CI and
fresh read-only review, PR C1 merges normally, exact main is validated, and the
branch is retired normally.

## 11. Owner gate G3 — production-shaped preview

The owner decides:

- whether duplicate SkyBridge/Quant inner titles remain;
- whether 24rem panel-depth/bottom alignment remains a semantic exception; and
- whether the complete three-viewport preview is accepted.

One bounded correction round is available. No production harmonization begins
until the decisions and acceptance are recorded safely.

## 12. Phase C2 — production-only harmonization

PR C2 contains only the accepted production UI harmonization, generated
artifacts, tests, and related documentation. It excludes authentication,
credentials, Authelia, OpenResty, unrelated deployment scripts, data changes,
and business behavior changes.

The final linter rejects all remaining unreviewed legacy geometry. Source and
generated output remain identical; translations, secret scanners, exact SHA
reporting, anonymous behavior, validation-only owner-authenticated production,
three-viewport geometry, network origins, upload rules, and the current
single-file artifact all pass.

PR C2 requires self-hosted exact-head CI, a fresh read-only UI Auditor, and a
fresh read-only security/artifact Auditor. It merges normally, receives
self-hosted exact-main CI, and is retired normally.

The code-ready state does not complete the milestone.

## 13. Owner gate G4 — production deployment

The owner controls the existing manifested config-only transaction. The
Implementer provides the accepted main SHA, artifact digest, pre-deploy receipt,
mount identity, prior known-good digest, rollback procedure, and anonymous plus
authenticated validation checklist.

The permitted envelope is one owner-controlled apply and one automatic rollback
to the prior known-good artifact on failed validation. A second apply requires a
fresh owner decision.

Post-deployment proof covers the intended anonymous boundary, validation-only
owner authentication at the exact production origin, Canary identity exclusion,
English/Chinese/Settings rendering, key cards, deployed digest, viewport
overflow, and absence of retained credentials, cookies, or state.

Only accepted deploy and rollback evidence sets
`M_DASH_PRODUCTION_UI_HARMONIZED=true`.

## 14. Exact-state proof, PR, and branch contract

### 14.1 Stage G governance repository proof

Stage G uses
`EXACT_HEAD_PROOF_CLASS=GOVERNANCE_REPOSITORY_NO_CI_PROOF` and
`GOVERNANCE_EXACT_MAIN_PROOF_CLASS=GOVERNANCE_REPOSITORY_NO_CI_PROOF`.
This proof class applies only to `dev_governance_files`, and only while an
independent live capability check proves all of:

```text
GOVERNANCE_TRACKED_WORKFLOW_COUNT=0
GOVERNANCE_ATTACHED_RUNNER_COUNT=0
GOVERNANCE_STATUS_CHECK_COUNT=0
GOVERNANCE_NO_CI_CAPABILITY_PROVEN=true
```

This is a bounded repository-capability proof, not a CI waiver. Exact-head proof
still requires an open and mergeable normal PR bound to its base and head SHAs;
the authorized file/commit budget; deterministic JSON, structural, master-plan,
W7V/W7B, prohibited-secret, and diff validation; a clean worktree; no writer
lock or active Git operation; and a separately launched read-only exact-head
Auditor with zero findings.

After normal merge, exact-main proof requires local `main`, cached
`origin/main`, and live remote `main` to equal the merge SHA; the complete
deterministic validation to pass again; and a fresh separately launched
read-only exact-main Auditor to pass before branch retirement.

The proof class never permits:

- GitHub-hosted or other hosted-runner fallback;
- skipped deterministic validation;
- a same-process audit substitute;
- local output that is not bound to the exact commit;
- a dirty worktree or active Git operation;
- force push, history rewrite, or direct unreviewed merge; or
- adding a workflow, attaching/registering a runner, or changing branch
  protection as an implicit part of this amendment.

Future governance-repository CI is a separate infrastructure decision and is not
authorized by this train.

### 14.2 Product repository CI

All Phase A through Phase C product CI remains self-hosted and exact-SHA bound.
Hosted-runner fallback is prohibited. An unchanged-head infrastructure rerun is
allowed only after explicit infrastructure classification; empty trigger
commits are not.

Each product branch follows:

```text
admit -> implement -> local validate -> independent read-only review
-> push -> normal PR -> self-hosted exact-head CI -> normal merge
-> self-hosted exact-main validation -> remote delete -> local git branch -d
```

Force push, history rewrite, force deletion, synthetic combined phase PRs, and
archive tags invented for routine retirement are prohibited.

## 15. Checkpoint and safe evidence

After governance exact main, the root Implementer maintains:

- `pre-w7b-dashboard-hardening-checkpoint.json`;
- `pre-w7b-dashboard-hardening-report.md`; and
- `pre-w7b-dashboard-hardening-logs/`.

The checkpoint schema is `pre-w7b-dashboard-hardening-checkpoint.v1`. It is
atomically replaced after irreversible boundaries and contains only safe
metadata, hashes, milestone/PR/gate states, correction consumption, invariant
Booleans, mutation Booleans, blocker/next-action data, and resume instructions.

It never contains personal identity details, usernames, passwords, credential
values, cookies, tokens, storage-state contents, credential-database contents,
private keys, secret-bearing command lines, or raw authentication error bodies.

Authentication state, login artifacts, and credential material never enter
governance evidence or GitHub artifacts.

## 16. Correction budgets

- Governance: one planned coherent implementation commit and at most one bounded
  corrective docs/schema commit.
- Each product PR: at most two planned coherent commits, two corrective product
  commits, and one extra test/harness-only corrective commit.
- G2 and G3: one bounded correction round each; a second rejection requires
  Architect and owner review.
- Authentication: one submission per invocation and no password retry.
- Production: one apply and one automatic rollback; no second apply without
  owner authorization.

## 17. Blocker envelopes

Every stop records `BLOCKER_CODE`, `BLOCKED_STEP`, `BLOCKED_PHASE`, and
`BLOCKER_TEXT`.

- `PREW7B_DASH_HARDENING_ADMISSION_BLOCKED`: missing/mismatched W7V proof,
  W7B started, initial Dashboard drift, writer lock, unsafe Git state, or
  unresolved dirt.
- `PREW7B_DASH_HARDENING_OWNER_ACTION_REQUIRED`: identity/policy/credential
  provisioning, MFA/CAPTCHA/regulation lockout, visual acceptance, or production
  deployment.
- `PREW7B_DASH_HARDENING_OWNER_DECISION_REQUIRED`: amendment or semantic-slot
  conflict, scope expansion, new geometry token, semantic exception/title/depth
  decision, or exhausted correction budget.
- `PREW7B_DASH_HARDENING_UNSAFE_BLOCKER`: personal admin credential, plaintext
  or committed credential, state upload, Authelia bypass, global MFA weakening,
  permanent admin session, indefinite retry, credential URL, hosted runner,
  force push, unauthorized infrastructure or production mutation, or W7B start.

## 18. Final audit and success

A fresh independently launched read-only Supervisor/Auditor validates the exact
governance and Dashboard mains, four distinct merged product PRs, exact-head and
exact-main self-hosted checks, four owner gates, normal branch retirement,
auth/security invariants, UI parity, deployment/rollback proof, and
`W7B_STARTED=false`.

Only `FINAL_READ_ONLY_AUDIT=PASS` sets:

```text
M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=true
READY_FOR_W7B_AUTHORIZATION_REVIEW
```

W7B remains `PLANNED_NOT_STARTED` until a later explicit authorization.

## 19. Non-goals

This train does not:

- add a new Wave;
- start W7B;
- weaken authentication or global MFA;
- create or use a personal administrator identity;
- deploy infrastructure through Codex;
- create a standalone auth repository or persistent auth service;
- extract `jerry-web-auth-testkit` before its trigger;
- redesign business data or unrelated Dashboard behavior;
- update the repository registry or dependency graph solely for stale Dashboard
  metadata; or
- retain credential or authentication-state evidence.
