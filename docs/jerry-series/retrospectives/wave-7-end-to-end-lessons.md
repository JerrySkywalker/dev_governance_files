# Wave 7 End-to-End Retrospective — From Cross-Repository E2E to Production Finalize

## Classification

```text
classification: retrospective
scope: W7A, W7V, W7B-W7E, Post-W7 Dashboard interludes, and the final Production release
related_waves:
  - W7A
  - W7V
  - W7B
  - W7C
  - W7D
  - W7E
  - Post-W7 Dashboard
related_repositories:
  - jerry-telemetry-agent
  - jerry-telemetry-hub
  - jerry-message-gateway
  - jerry-devops-android
  - jerry-glance-dashboard
  - jerry-wave7-train
  - dev_governance_files
sensitivity_notes: public PRs, sanitized statuses, durable rules, and accepted hashes only; no credentials, storage state, raw Production payloads, or protected evidence
```

## Purpose

Wave 7 was not one implementation task. It was a sequence of increasingly deep
proof boundaries:

```text
cross-repository message semantics
  -> authenticated visual-validation infrastructure
  -> compressed product train
  -> production-shaped parity
  -> owner-visible UI hardening
  -> immutable Production release
  -> transactional Finalize and closeout
```

This retrospective consolidates the reusable experience from the whole chain.
It supplements, but does not replace:

- `wave-7a-lessons.md` for the Codex usage message chain;
- `wave-7-lessons.md` for the compressed W7B-through-W7E train;
- `post-w7-dashboard-production-release-closeout.md` for final release facts;
- `self-hosted-ci-playbook.md` for runner operations; and
- `elastic-autonomous-execution-budget-pattern.md` for execution budgets.

## Final disposition

```text
WAVE7_AND_POST_W7_DASHBOARD_WORK=COMPLETE
DASHBOARD_EXACT_MAIN=abd19347d162405770c3aa343234e301e0de29c5
COORDINATION_EXACT_MAIN=9debc773b663e3c3756b7fe120ee5ba57c9bead0
GOVERNANCE_EXACT_MAIN=e08dfe5d74dd8a6fad25d57703156a7a420ba96b
RUNNING_GLANCE_VERSION=v0.8.5
CONFIG_TRANSACTION_STATUS=applied
RELEASE_JOURNAL_STATUS=applied_accepted
W8_ENTRY_GATE=READY
W8_STARTED=false
W9_STARTED=false
```

Wave 7 is complete. The following lessons are historical and reusable. They do
not reopen Wave 7 or authorize W8.

## Audit basis

The end-to-end review used these durable sources:

- Wave 7A exact-chain retrospective;
- compressed Wave 7 retrospective;
- Post-W7 Production closeout;
- Dashboard PRs #75 through #87;
- Coordination PR #45 and issue #42;
- Governance PRs #21 and #22;
- the self-hosted CI playbook;
- the incremental resume pattern; and
- the elastic autonomous execution budget pattern.

The audit asks two questions for every lesson:

1. Did the lesson arise from a real accepted or rejected execution path?
2. Does the durable rule distinguish product correctness, execution
   infrastructure, authority, and evidence rather than collapsing them into one
   status?

## Executive findings

The most important Wave 7 findings are:

1. **Independent green repositories do not prove an integration chain.** The
   primary proof must execute real adjacent implementations.
2. **Technical acceptance and owner acceptance are different gates.** A
   technically correct dashboard may still fail product intent or visual
   acceptance.
3. **Validation depth must match the current delta and risk boundary.** A docs
   change, a Windows lock harness, a cross-repository contract, a Canary, and a
   Production Finalize must not all invoke the same gate graph.
4. **Elastic budgets are operational, not authoritative.** They prevent routine
   owner round trips inside a narrow approved surface, while credentials,
   unrelated services, unverified rollback, and sensitive output remain hard
   stops.
5. **A blocker should identify the current execution frontier.** Repeated stops
   were useful when each exposed a new boundary; repeated identical failures or
   unchanged CI polls were no progress.
6. **Self-hosted CI is a stateful shared system.** Runner process ownership,
   cleanup, queue topology, duplicate gates, and timing-sensitive tests are part
   of the trust boundary.
7. **Long-running Goals must resume from durable pointers and a compact delta.**
   Replaying the full chronology wastes context and obscures the next decision.
8. **Production release logic is a state machine, not a shell script.** Inspect,
   Prepare, Apply, Accept, Finalize, Recover, and Closeout need explicit states,
   anchors, and idempotent transitions.
9. **Prior-state anchors and target-state anchors must be separate.** Reusing one
   generic expected-image or expected-Compose variable across Prepare, Finalize,
   and rollback caused deterministic defects.
10. **Rollback is a product capability.** It must restore image, Compose,
    configuration, mounted content, health, route, and transaction markers, not
    merely restart a container.
11. **Artifact formats require semantic verification.** Docker image ID, OCI
    config digest, manifest digest, and registry digest are distinct identities.
12. **Read-only preflight should precede protected mutation.** A Finalize defect
    discovered by preflight should not cause an otherwise healthy target to be
    rolled back while waiting for a source correction.
13. **Evidence is valid only for the state it binds.** Screenshots and acceptance
    receipts can be reused only while container identity and all accepted
    anchors remain unchanged.
14. **CI hardening and product closeout are separate decisions.** A known flaky
    runner must be recorded and repaired, but an unrelated merge-ready product
    correction should not be held indefinitely by an already classified
    infrastructure backlog.
15. **Closeout is a real stage.** Exact mains, issue state, branch retirement,
    lease release, Keeper stop, rollback retention, and knowledge capture are
    part of completion.

## 1. Real adjacent implementations are the primary integration proof

Wave 7A showed that Agent, Hub, Gateway, and Android could each have local green
checks while the exact Hub-to-Gateway request still lacked the expected-node
binding. The accepted milestone executed the real upstream normalizer and read
model through the real downstream parser and acknowledgement path.

Reusable rule:

```text
unit fixtures explain one component;
real adjacent implementations prove a contract edge;
end-to-end execution proves the chain.
```

Handwritten fixtures remain valuable for focused negative cases and fault
injection. They must not be the only evidence for cross-repository
compatibility.

## 2. Evidence path legitimacy is part of correctness

A command may produce the expected output through an unauthorized acquisition
or bootstrap path. Wave 7A rejected a technically passing Android result because
the Wrapper downloaded a distribution through an unapproved path. The result
was replayed using a verified local source.

Reusable rule:

```text
expected output
+ authorized tool/bootstrap path
+ exact source binding
+ accepted evidence disposition
= admissible result
```

A later passing command does not retroactively rehabilitate an earlier unsafe
attempt. Each attempt needs an explicit disposition such as accepted, rejected,
superseded, preserved, or informational-only.

## 3. Human-visible validation is a first-class system boundary

W7A established the need for a durable visual channel. W7V then created an
isolated authenticated Canary Dashboard, screenshot packets, and owner review.
The later Production-shaped Canary passed technical parity but was rejected by
the owner for visual rhythm and intent. That rejection was valid even though
all automated checks were green.

Reusable rule:

```text
technical correctness != owner-visible product acceptance
```

For human-facing cross-repository systems, the acceptance chain should include:

- exact source and deployment identity;
- authenticated desktop and mobile screenshots;
- semantic UI assertions;
- a stable public or owner-accessible validation channel; and
- an explicit human decision.

## 4. Stable selectors are owned contracts

Authentication and browser automation initially bound to selectors inherited
from an earlier layout. UI evolution made those selectors stale even though the
page remained functionally correct.

A durable selector must be:

- unique;
- semantically owned by the page contract;
- emitted by generation or source in a testable way;
- referenced consistently by the auth manifest, browser validation, and focused
  tests; and
- changed only with the corresponding contract update.

A selector that merely happens to exist is not an automation contract.

## 5. Authentication state needs a lifecycle, not a one-time capture

The Production owner session exposed a distinction between:

```text
an already authenticated long-lived browser context
```

and:

```text
a persisted storage state that a new independent context can reuse
```

A Keeper reporting that its original browser still sees the Dashboard was not
sufficient. The corrected lifecycle required independent-context validation,
atomic state replacement, and the official repository validator.

Reusable rule:

- owner-managed authentication acquisition remains an owner action;
- automation may validate and persist only within the approved contract;
- Keeper health must mean portable state is valid, not merely that one browser
  process remains logged in; and
- no credential, cookie, storage state, or identity detail enters governance
  evidence.

## 6. Resume from a durable checkpoint and one accepted delta

Long-running Wave 7 Goals accumulated many accepted states, rejected attempts,
PRs, and rollback receipts. Repeating all of that history in every resume Goal
made the current mutation and owner boundary harder to review.

The preferred resume block is:

```text
LAST_ACCEPTED_CHECKPOINT=<durable pointer>
CURRENT_DELTA=<one new fact>
ALLOWED_MUTATION=<smallest declared surface>
UNCHANGED_BOUNDARIES=<explicit non-goals>
REQUIRED_PROOF=<next boundary>
HARD_STOP=<first new decision>
```

Completed history should remain addressable through durable files and exact
mains rather than copied into every prompt.

## 7. Elastic budgets must be finite, domain-separated, and progress-sensitive

Early last-mile Goals often allowed one PR, one correction commit, or one Apply.
That was safe for attended work, but it caused repeated owner round trips when
real Production execution exposed a sequence of deterministic defects inside
one already-approved release surface.

The correction is not an unbounded budget. Use independent finite counters:

```text
source correction cycles
adjacent-fix PRs
CI reruns by failure signature
runner-environment corrections
read-only preflights
Prepare attempts
Apply attempts
verified rollbacks
audit attempts
model wakeups
```

Rules:

- consuming one domain budget must not silently consume or enlarge another;
- an accepted exact-main checkpoint may reset operational recovery counters;
- authority, credentials, unrelated services, and sensitive-data boundaries
  never reset automatically;
- a new Apply requires a fresh backup and, after a failed Apply, a fully verified
  rollback;
- a read-only preflight failure does not consume an Apply attempt; and
- identical failures are not new progress merely because attempt numbers change.

## 8. Hard stops must remain immutable

Elastic execution is allowed only inside a declared surface. The following
remain hard stops:

- credentials or identity acquisition;
- Production authentication policy changes;
- unrelated service mutation;
- backup or archive integrity failure;
- inability to prove either a complete old state or a complete target state;
- failed rollback that cannot restore a proven state;
- sensitive output;
- writer conflict; and
- exhausted explicit hard budget.

The distinction is:

```text
elastic convenience budget != new authority
```

## 9. A blocker is useful only when it names the current frontier

Wave 7 stopped repeatedly, but the stops were not all equivalent. The execution
frontier moved through:

```text
auth portability
  -> safe Prepare diagnostics
  -> OCI archive semantics
  -> Windows lock determinism
  -> output protocol grammar
  -> Apply readiness
  -> interrupted recovery
  -> Finalize target anchors
  -> acceptance receipt binding
```

That sequence represents progress because each blocker appeared after the
previous boundary was crossed.

By contrast, these are no progress:

- repeated identical CI failure signatures on one unchanged head;
- repeated owner-authorization stops caused only by an obsolete convenience
  counter;
- repeated high-frequency reads of an unchanged queued workflow; and
- recreating an already correct runtime on every recovery attempt.

Blocker receipts should therefore include the accepted checkpoint, the new
frontier, the stable failure signature, state-changed status, and the exact
next decision.

## 10. Validation depth must match the delta

Wave 7 used several fundamentally different proof depths:

```text
static/document proof
focused deterministic proof
repository full gate
platform-specific runner proof
cross-repository adjacent proof
Canary/runtime proof
Production preflight
protected Apply
Finalize and closeout proof
```

These are not interchangeable. A deeper gate is not automatically a reason to
repeat every lower gate, and a full repository CI pass does not prove a live
Production transaction.

The reusable selection rules are captured in
`validation-depth-and-gate-selection.md`.

Key defaults:

- run focused tests during implementation;
- run one canonical exact-head full repository gate for the final candidate;
- use platform-specific gates only for behavior that actually depends on that
  platform;
- require real adjacent-implementation replay for contract edges;
- require runtime binding and owner-visible evidence for Canary/UI acceptance;
- require read-only preflight, backup, rollback, and explicit authorization for
  Production; and
- require post-Finalize proof and durable closeout before declaring completion.

## 11. CI is an execution environment, not one universal validation level

The term `CI` was often used as though it meant one fixed depth. In practice:

- CI can run lightweight static checks;
- CI can run a full repository gate;
- self-hosted CI can prove Windows-specific behavior;
- CI cannot by itself prove an authenticated Production state unless the
  protected runtime contract explicitly allows that action; and
- a Production preflight can be deeper than a repository CI job while still
  remaining read-only.

The validation claim must name the gate that ran, its exact source binding, its
platform, and what it does not prove.

## 12. One sole runner turns nominal parallelism into serial contention

Dashboard CI had multiple jobs plus Jerry CI and scheduled smoke, all targeting
the same Windows runner labels. Several jobs repeated checkout, dependency
installation, Playwright setup, and the complete `npm run check` graph.

Consequences included:

- long queue times;
- repeated heavyweight gates;
- higher orphan-process and resource-pressure risk;
- timing-sensitive failures unrelated to the PR diff; and
- a supervising model that appeared stuck while repeatedly polling unchanged
  state.

Reusable topology rule:

- one canonical complete gate per exact head;
- path-sensitive focused gates with stable required contexts;
- portable docs/static checks on other capacity when policy permits;
- Windows runner reserved for Windows-specific behavior;
- scheduled smoke isolated from PR gates; and
- low-frequency external observation rather than model polling.

## 13. Test process ownership and timing are part of the CI trust boundary

The Post-W7 incident showed orphaned Node and Chromium descendants after a
parent process timed out. Fixed three-second UI detection and fixed emergency
lock timeouts made scheduler latency look like product failure.

Required design:

```text
job-owned process group
  -> explicit ready sentinel
  -> bounded condition polling
  -> explicit stop sentinel
  -> recursive finally cleanup
  -> zero-orphan proof
```

Timeouts are deadlock guards, not expected completion times. Failures should
retain sanitized `stage`, `elapsed_ms`, `condition_observed`, and child exit
classification.

## 14. Same-signature reruns need a hard limit

For one exact head and one sanitized failure signature:

```text
first failure:
  classify
  perform one proven infrastructure cleanup if applicable
  permit one unchanged-head rerun

second identical failure:
  stop automatic reruns
  emit REPEATED_INFRA_OR_FLAKY_FAILURE
  require a test-harness, runner-policy, or source correction
```

A sixth successful run proves only that the head can pass under some conditions.
It does not prove that the previous failures were harmless or that the gate is
stable.

## 15. Model time must not be used as a CI polling loop

The long PR #87 wait produced hundreds of unchanged status reads and model
wakeups. That consumed context without producing evidence or progress.

A finite external watcher should:

- poll every five minutes initially;
- move to ten-minute polling after the initial window;
- wake the model only on a state transition, new failure signature, success, or
  hard timeout; and
- emit one structured waiting receipt after repeated no-change wakeups.

The watcher must not create commits, rerun workflows, cancel jobs, or mutate
branch protection.

## 16. Production release must be modeled as an explicit transaction state machine

The successful release required separate stages:

```text
Inspect
DiagnosePrepare
Prepare
Apply
Acceptance
InspectFinalize
Finalize
Closeout
```

Recovery required explicit interrupted-state inspection and supported
transitions such as target adoption or old-state recovery.

Each stage needs:

- exact input anchors;
- allowed states;
- idempotency rules;
- mutation classification;
- bounded sanitized output;
- next-state proof; and
- rollback behavior.

A long shell function without explicit state semantics is difficult to resume
safely after interruption.

## 17. Prior anchors and target anchors must never be conflated

Several Finalize defects came from using preparation or rollback anchors while
validating the target state. The final model separated:

```text
prior anchors:
  old image
  old Compose
  prior config pair
  prior mounted config

target anchors:
  target image and immutable repo digest
  candidate Compose
  approved config pair
  approved mounted config
  final mount identity
```

The stage must select the correct anchor set before performing runtime
validation, and it must repeat the same proof after acquiring the transaction
lock.

## 18. Artifact identity is a graph, not one digest string

The OCI archive incident exposed a false assumption that the OCI config digest
must equal Docker's local image ID. The accepted verifier instead proved the
actual descriptor graph and source binding.

Reusable rules:

- Docker image ID, registry repo digest, OCI index digest, manifest digest, and
  config digest are distinct identities;
- validate each descriptor against the bytes it references;
- validate size, digest, platform, member type, and path safety;
- bind `docker image save` to an exact source image before and after save; and
- test against retained real archive shapes, not only synthetic fixtures.

## 19. Production output is an allowlisted protocol

Release controllers rejected legitimate digit-bearing keys, while Docker
Compose progress leaked into a line-oriented protocol. Both failures show that
machine output needs a versioned allowlist.

A protected wrapper should:

- allow only known keys;
- validate each value by key;
- reject duplicates and unknown keys;
- suppress or capture noisy subprocess output;
- emit one sanitized diagnostic envelope on failure; and
- test the actual wrapper-to-engine command path.

A syntactically valid generic key is not automatically an authorized field.

## 20. Rollback must restore both runtime and transaction truth

A rollback is not complete when the page happens to be healthy. It must prove:

- old image;
- old Compose;
- old config pair;
- old mounted config;
- health;
- route;
- config transaction status; and
- outer release journal.

Wave 7 exposed a recovery livelock in which an already correct old runtime was
recreated, immediately checked before readiness, and never allowed to complete
its transaction markers.

Reusable correction:

- detect an already exact healthy runtime;
- use a no-recreate completion fast path;
- when recreation is required, recreate once and poll readiness on the same
  container identity;
- complete inner transaction state before outer journal state; and
- make recovery idempotent.

## 21. Read-only preflight prevents unnecessary rollback

Before the final successful release, missing Finalize knowledge was discovered
only after Apply or during Finalize, causing automatic rollback of an otherwise
healthy target.

The corrected design added a non-mutating Finalize preflight that validates the
same prerequisites as Finalize without:

- changing transaction state;
- creating acceptance receipts;
- deleting staged configuration; or
- triggering rollback.

A healthy target in `pending_acceptance` may remain in that state while an
in-scope Finalize-tool correction is reviewed, provided its anchors, health,
route, Keeper, and lease remain valid.

## 22. Real two-engine tests are required for composed transactions

Some tests replaced the config engine with a stub that simply wrote the desired
status. That fixture proved outer control flow but could not reveal an anchor or
receipt mismatch between the outer release engine and the real config engine.

For composed transactions, the primary test should run both real engines.
External systems such as Docker, Compose, curl, and isolated filesystem metadata
may be faked, but the interface boundary under test must remain real.

This principle is the transaction equivalent of the W7A adjacent-implementation
rule.

## 23. Acceptance receipts must bind the correct plan domain

The final PR #87 defect came from computing a config acceptance receipt with the
outer release plan ID instead of the inner config transaction plan ID.

Reusable rule:

- every receipt names its schema and plan domain;
- nested transactions use their own plan IDs;
- the outer receipt may incorporate the verified inner receipt hash;
- wrappers must pass explicit plan IDs rather than infer one generic plan; and
- regression tests should inspect the exact command or environment value passed
  across the boundary.

## 24. Evidence reuse requires unchanged-state proof

Screenshots captured before a rollback are diagnostic evidence, not final online
evidence. Screenshots captured in a healthy target state may be reused after a
source-only Finalize fix only when all of these remain unchanged:

- container identity;
- image ID and immutable digest;
- config pair;
- mounted config;
- target Compose;
- rendered state; and
- screenshot index and acceptance record.

Evidence should name the state it proves. It must not float independently of
runtime anchors.

## 25. Single-writer leases and owner-controlled authentication remained effective

Despite many resumes, the run retained one product writer, one release lease,
and owner-controlled Production authentication. Reboot recovery used same-run
lease takeover rather than creating a second writer.

These controls prevented:

- concurrent repository mutation;
- two release transactions acting on Production;
- automated credential acquisition;
- accidental auth-state disclosure; and
- closeout before the protected runtime was settled.

## 26. Product completion and CI hardening must be sequenced deliberately

The runner instability was real, but PR #87 had a merge-ready, exact-head green
state and a Production target waiting in `pending_acceptance`. Restarting a CI
redesign at that point would have created a new head and delayed Finalize.

The accepted sequence was:

```text
complete the protected release
  -> close the train
  -> capture CI lessons in governance
  -> execute CI hardening as a separate authorized interlude
```

This avoids both extremes:

- ignoring infrastructure debt; and
- allowing unrelated infrastructure redesign to block a safe product closeout.

## 27. Closeout is not clerical cleanup

Wave 7 completed only after:

- target Finalize;
- post-Finalize runtime proof;
- Coordination closeout;
- Governance closeout;
- issue #42 closure;
- branch retirement;
- Keeper stop request;
- writer lease release;
- rollback retention; and
- lesson capture.

A successful Apply without durable closeout remains an incomplete train.

## Validation-depth summary

| Depth | Main question | Typical Wave 7 example | Canonical evidence |
| --- | --- | --- | --- |
| D0 static | Is the document or contract internally valid? | Governance closeout | parse, links, scope, secret scan |
| D1 focused | Does the changed unit or binding behave correctly? | receipt hash calculation | focused deterministic test |
| D2 repository | Is the final repository candidate coherent? | exact-head Dashboard gate | one canonical full repository gate |
| D3 platform | Does platform-specific behavior hold? | Windows ACL and atomic move | clean self-hosted Windows proof |
| D4 adjacent integration | Do real neighboring implementations agree? | Agent-Hub-Gateway-Android | real adjacent replay |
| D5 Canary/runtime | Is the deployed candidate bound and visible? | W7V and Production-shaped Canary | runtime anchors, screenshots, owner review |
| D6 protected mutation | Can the target be applied and rolled back safely? | Glance v0.8.5 release | backup, preflight, Apply, rollback proof |
| D7 finalization | Is the accepted target durably committed and closed? | config `applied`, journal `applied_accepted` | Finalize, post-proof, closeout |

The deepest applicable proof should run once for the accepted candidate. Lower
proofs should be selected by changed surface rather than repeated mechanically.

## Recommended defaults for future Waves

### Goal structure

- use durable-state pointers and one Accepted Delta;
- declare exact mutation surface and non-goals;
- separate operational budgets by domain;
- identify the validation depth before implementation;
- name hard stops that cannot be reset automatically; and
- emit compact completion or stop receipts.

### Validation structure

- focused tests during implementation;
- one exact-head repository gate for the final candidate;
- platform gates only for platform-specific behavior;
- real adjacent implementations for contract edges;
- runtime and owner-visible proof for human-facing deployment;
- read-only preflight before protected mutation and Finalize;
- post-Finalize state binding before closeout.

### CI structure

- one canonical complete gate per exact head;
- path-sensitive required contexts;
- owned process trees and zero-orphan receipts;
- sentinel-based asynchronous tests;
- one unchanged-head rerun per signature;
- low-frequency external watchers;
- scheduled smoke isolated from scarce required capacity.

### Release structure

- explicit state machine;
- separate prior and target anchors;
- immutable image binding;
- real archive semantics;
- non-mutating preflights;
- idempotent recovery;
- verified rollback between Apply attempts;
- receipts bound to their own plan domains.

## Remaining separately authorized backlog

Wave 7 completion does not itself execute these items:

```text
POST_W7_CI_HARDENING=REQUIRED
CANARY_DEPLOY_VALIDATION_API_RECREATE_HARDENING=REQUIRED
MASTER_WAVE_PLAN_CLOSEOUT_RECONCILIATION=REQUIRED_BEFORE_W8_AUTHORIZATION
```

The CI-hardening scope should include duplicate-gate elimination, path-sensitive
gates, process cleanup, condition-driven tests, rerun limits, external watchers,
and scheduled-smoke isolation.

The Canary lifecycle backlog should choose deterministic recreation or an
immutable content-addressed mount.

The master plan should record the completed Post-W7 prerequisite chain while
preserving `W8_AUTHORIZED=false` until a separate owner decision.

## Operational boundary

This retrospective is governance knowledge only. It does not authorize:

- W8 or W9;
- CI workflow or runner mutation;
- Production contact;
- authentication acquisition;
- product source changes;
- deployment; or
- cleanup of retained rollback evidence.
