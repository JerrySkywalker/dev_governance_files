# Validation Depth and Gate Selection Pattern

## Classification

```text
classification: pattern
scope: selecting focused tests, CI gates, integration proof, runtime validation, protected release evidence, and closeout proof
related_waves:
  - Wave 7
related_repositories:
  - dev_governance_files
  - product repositories
  - coordination repositories
sensitivity_notes: durable rules and sanitized evidence classes only
```

## Purpose

Choose the smallest gate that can reject the current edit quickly, then run the
deepest applicable proof once for the final accepted state.

The pattern prevents:

- **under-validation**, where a fixture or repository CI pass is reported as real
  integration, runtime, or Production proof;
- **over-validation**, where every edit repeats every historical gate and consumes
  scarce platform or runtime capacity; and
- **category collapse**, where the word `CI` is used without stating what was
  proved, where it ran, how often it should run, or what it blocks.

## Core correction — a gate is a vector, not one depth number

Wave 7 showed that CI and validation require four independent axes:

```text
Gate = <proof depth, execution environment, cadence, criticality>
```

A complete receipt must name all four.

```text
proof_depth
execution_environment
cadence
criticality
exact_source_binding
changed_surface
claim_proved
claim_not_proved
```

`CI` describes an automation location and orchestration mechanism. It is not a
proof claim by itself.

## Axis 1 — proof depth

Proof depth answers: **what claim does this evidence establish?**

Older Wave 7 documents used `D0-D7`. New receipts should use `V0-V7`; the older
codes remain direct aliases for historical interpretation.

### V0 — static and governance consistency

Use for:

- Markdown and policy text;
- JSON and schema-only governance updates;
- knowledge-index changes;
- metadata-only closeout; and
- generated metadata with no product behavior.

Typical proof:

- parse and schema checks;
- Markdown link checks;
- exact-SHA formatting;
- scope and forbidden-marker checks;
- lightweight secret scan; and
- `git diff --check`.

V0 does not prove product behavior, platform behavior, integration, runtime
state, or Production safety.

### V1 — focused deterministic behavior

Use for:

- one parser, wrapper, selector, receipt, or binding;
- one deterministic regression;
- one negative case;
- isolated configuration generation; or
- direct correction of an observed defect.

Typical proof:

- directly affected tests;
- exact source binding;
- syntax checks;
- sanitized output assertions;
- repeated serial proof when process or timing semantics changed; and
- focused failure-path coverage.

V1 is the normal implementation loop. It should be fast enough to run after each
candidate correction.

### V2 — repository candidate coherence

Use for:

- the final pull-request candidate;
- changes spanning several repository-local components;
- repository policy and generated-output coherence; or
- branch-protection required checks.

Typical proof:

- one canonical complete repository gate;
- exact-head checkout assertion;
- repository secret, syntax, generation, and contract checks;
- causal CI accounting; and
- fresh exact-main proof when policy requires it.

Rules:

- run the complete graph once for the final exact head;
- do not duplicate the same graph in several required contexts without a distinct
  environment claim;
- use truthful path-sensitive fast PASS contexts for irrelevant surfaces; and
- do not use repeated unchanged-head reruns as a stability substitute.

V2 does not prove a neighboring repository contract or a deployed runtime.

### V3 — platform-specific behavior

Use only when correctness depends on a specific platform, runner, filesystem,
process model, or managed browser environment.

Examples:

- Windows ACL and atomic move behavior;
- PowerShell process and filesystem semantics;
- browser behavior tied to the managed Windows runner;
- container or filesystem semantics unavailable in portable tests; and
- platform-specific packaging.

Typical proof:

- intended platform and exact head;
- clean runner preflight;
- job-owned child-process lifecycle;
- recursive cleanup and zero-orphan receipt;
- condition-driven synchronization;
- safe stage and elapsed-time diagnostics; and
- changed-file overlap classification.

Portable V0-V2 work should not consume scarce V3 capacity merely because the
repository also contains platform-specific code.

### V4 — real adjacent-implementation integration

Use when one real component consumes another component's real output or contract.

Examples:

- Agent → Hub;
- Hub → Gateway;
- Gateway → Android;
- release controller → remote release engine; and
- outer release engine → config transaction engine.

Typical proof:

- real upstream producer or read model;
- real downstream parser, controller, or engine;
- exact source states for both sides;
- explicit semantic assertions;
- bounded negative cases; and
- idempotency where applicable.

Fixtures may replace external transport, isolated filesystems, Docker, or fault
injection. They must not replace the contract edge being accepted.

### V5 — deployed runtime and owner-visible acceptance

Use when the candidate is deployed into Canary, staging, or another isolated
runtime, or when human-visible acceptance is required.

Typical proof:

- exact deployed source, package, image, or digest;
- service and container identity;
- mount and generated-artifact hashes;
- route and health;
- authenticated browser rendering where applicable;
- desktop and mobile screenshots;
- semantic UI assertions; and
- explicit owner acceptance.

V5 separates technical runtime correctness from owner-visible product acceptance.
A technically green candidate may still be rejected.

### V6 — protected transaction and rollback safety

Use for:

- Production Prepare or Apply;
- protected runtime mutation;
- identity- or credential-adjacent operations;
- interrupted-state recovery; and
- operations whose failure requires rollback.

Required before protected mutation:

- separate explicit authorization;
- exact prior-state proof;
- immutable target binding;
- fresh backup namespace;
- archive and manifest integrity;
- read-only diagnostic or preflight;
- rollback availability;
- one writer and one transaction lease; and
- bounded allowlisted output.

Required after mutation:

- exact target image or artifact;
- target configuration and mounted content;
- target Compose or equivalent declaration;
- stable runtime identity;
- readiness, health, route, and log gates;
- transaction status; and
- supported automatic rollback on failure.

A read-only preflight failure does not consume an Apply.

### V7 — Finalize, evidence binding, and closeout

Use after the target has passed acceptance but is not yet durably committed or
the train is not yet closed.

Typical proof:

- Finalize preflight;
- inner transaction committed;
- outer journal committed;
- receipts bound to the correct plan domains;
- screenshot and runtime anchors unchanged;
- post-Finalize runtime proof;
- coordination and governance closeout;
- issue closure;
- branch retirement;
- lease release; and
- retained rollback proof.

Apply or screenshots without V7 proof do not complete a protected release train.

## Axis 2 — execution environment

Execution environment answers: **where is the claim obtained?**

| Code | Environment | Typical use |
| --- | --- | --- |
| E0 | local portable | fast V0-V2 implementation loops |
| E1 | hosted portable CI | portable static and repository checks |
| E2 | self-hosted platform CI | Windows, special filesystem, managed browser |
| E3 | composed integration lab | V4 real adjacent implementations |
| E4 | Canary or isolated runtime | V5 deployed and visual proof |
| E5 | protected runtime read-only | Inspect, Diagnose, preflight |
| E6 | protected runtime mutation | Prepare, Apply, Recover, Finalize |

Environment selection rules:

- use the least privileged environment that can prove the claim;
- do not run portable work on a scarce self-hosted runner without a specific
  platform reason;
- do not treat a self-hosted label as proof that a usable physical runner exists;
- do not treat E5 as E6 authorization; and
- do not substitute E1 or E2 repository CI for E4-E6 runtime proof.

## Axis 3 — cadence

Cadence answers: **when and how often should the gate run?**

| Code | Cadence | Rule |
| --- | --- | --- |
| F0 | per edit | fastest implementation feedback |
| F1 | per candidate correction | after a bounded source or binding change |
| F2 | once per final exact head | canonical PR candidate proof |
| F3 | once per accepted exact main | post-merge or convergence proof |
| F4 | once per release transaction or stage | Canary, Prepare, Apply, Finalize, closeout |
| F5 | scheduled or observational | smoke, drift, or periodic health |

Cadence is not criticality. A scheduled F5 smoke job is not automatically a
required exact-head gate. A V2 full gate should normally be F2, not F0.

## Axis 4 — criticality

Criticality answers: **what does failure block?**

| Code | Criticality | Effect |
| --- | --- | --- |
| G0 | advisory | records information; does not block candidate acceptance |
| G1 | candidate acceptance | blocks promoting the current candidate |
| G2 | merge or exact-head acceptance | required repository or integration proof |
| G3 | protected-entry gate | blocks protected runtime contact or mutation |
| G4 | owner acceptance, Finalize, or closeout | blocks durable completion |

Criticality must be declared, not inferred from the name of a workflow or job.

## Canonical gate vectors

The following vectors are defaults, not universal commands.

| Gate | Vector | Meaning |
| --- | --- | --- |
| docs edit loop | `<V0,E0,F0,G0>` | local consistency feedback |
| focused implementation loop | `<V1,E0,F0,G0>` | direct regression feedback |
| candidate focused gate | `<V1,E0-or-E1,F1,G1>` | accepts one candidate correction |
| canonical repository gate | `<V2,E1-or-E2,F2,G2>` | final exact-head coherence |
| Windows-specific gate | `<V3,E2,F2,G2>` | exact-head platform proof |
| real adjacent replay | `<V4,E3,F2,G2>` | contract-edge acceptance |
| Canary technical gate | `<V5,E4,F4,G3>` | deployed runtime readiness |
| Canary owner review | `<V5,E4,F4,G4>` | human-visible acceptance |
| Production inspect | `<V6,E5,F4,G3>` | protected read-only readiness |
| Production Apply | `<V6,E6,F4,G4>` | protected mutation and rollback contract |
| Finalize and closeout | `<V7,E5-or-E6,F4,G4>` | durable commit and train completion |
| scheduled smoke | `<declared V,declared E,F5,G0-or-G1>` | observation; not exact-head proof unless explicitly bound |

## Selection procedure

### Step 1 — classify the changed surface

Choose one or more:

```text
documentation
local_logic
repository_composition
platform_behavior
cross_repository_contract
runtime_binding
protected_mutation
transaction_finalization
```

### Step 2 — identify the next acceptance boundary

The file size does not determine the required proof. A one-line wrapper change
may require V4 and V7 when it changes the binding between two real transaction
engines and Finalize.

### Step 3 — choose the implementation-loop vector

Use the cheapest fast gate that can reject a bad edit:

- V0/E0/F0 for docs;
- V1/E0/F0 for local logic;
- V3/E2/F1 only when the edit genuinely depends on the platform; and
- V4/E3/F1 when the defect crosses a real contract edge.

Implementation-loop gates are not final acceptance merely because they pass many
times.

### Step 4 — choose the final-candidate vector

Require the deepest applicable claim once for the accepted state:

- V2/F2 for a repository PR;
- V3/E2/F2 for platform behavior;
- V4/E3/F2 for real contract edges;
- V5/E4/F4 for deployed and owner-visible acceptance;
- V6/E5-or-E6/F4 for protected transaction work; and
- V7/F4/G4 for Finalize and closeout.

### Step 5 — assign criticality explicitly

State whether the gate is advisory, candidate-blocking, merge-blocking,
protected-entry, or completion-blocking. Do not infer this from “CI”, “smoke”,
“release”, or a workflow title.

### Step 6 — remove duplicate command graphs

Expand the command graph of every required job. Two jobs are duplicate when they
have the same:

```text
exact source
execution environment contract
command graph
claim proved
```

Choose one canonical owner for the full graph. Retain only distinct focused or
environment-specific checks in the other contexts.

### Step 7 — record what was not proved

Example:

```text
PROOF_DEPTH=V2
EXECUTION_ENVIRONMENT=E1
CADENCE=F2
CRITICALITY=G2
REPOSITORY_GATE=PASS
WINDOWS_PLATFORM_PROOF=NOT_APPLICABLE
ADJACENT_INTEGRATION_PROOF=NOT_RUN
RUNTIME_CONTACTED=false
PRODUCTION_MUTATED=false
```

A truthful limitation prevents a shallower pass from being promoted into a
deeper claim.

## Default operational layers

The vector is normative. These layers are a practical execution plan.

### L0 — edit feedback

- V0 or V1;
- E0;
- F0;
- G0;
- target under a few minutes.

### L1 — candidate acceptance

- V1 and selected V3/V4 focused proof;
- E0-E3 as required;
- F1;
- G1.

### L2 — exact-head repository acceptance

- V2 plus applicable V3/V4;
- E1-E3;
- F2;
- G2;
- one canonical full repository graph.

### L3 — deployed candidate acceptance

- V5;
- E4;
- F4;
- G3 or G4;
- exact runtime anchors and owner-visible evidence.

### L4 — protected transaction entry and execution

- V6;
- E5 then E6;
- F4;
- G3 then G4;
- read-only preflight before mutation.

### L5 — Finalize and closeout

- V7;
- E5 or E6;
- F4;
- G4;
- post-proof and durable governance settlement.

A future Wave may omit an inapplicable layer. It must not infer the omitted
claim from another layer.

## Gate topology rules

### One canonical full gate

Each repository should have one canonical complete exact-head gate. Other
required contexts should be:

- focused distinct gates;
- environment-specific gates; or
- truthful deterministic path-filtered PASS contexts.

### Platform scarcity

A sole self-hosted platform runner should run only the work requiring that
platform. Portable docs, static, schema, generated, and light secret checks should
use other capacity when policy and budget permit.

### Scheduled work

Scheduled smoke must not silently contend with required PR gates on a sole
runner. Use separate labels, queue-aware skipping, or another pool. Scheduled
results must be classified as F5 and must not be reported as F2 exact-head proof
unless they are explicitly bound to that head and claim.

### Setup reuse

On a serialized runner, multiple jobs may cost more than one staged job because
checkout, dependency installation, browser setup, and cleanup repeat. Job
separation must be justified by isolation, environment, or required-context
semantics.

### Stable required contexts

Path-sensitive gates may return a fast truthful PASS for irrelevant paths while
preserving stable branch-protection names. The result should state why the check
was not applicable.

## Self-hosted runner requirements

Any vector using E2 must prove:

- the intended repository-specific runner is online and idle;
- the runner service has the intended environment;
- the work root is suitable and isolated;
- no prior job-owned process remains;
- Node, Chromium, Playwright, shell, and helper children are job-owned;
- `finally` cleanup is recursive;
- zero owned processes remain afterward; and
- safe stage and elapsed-time fields are retained on failure.

A logical label is a routing request, not physical-capacity proof.

## Timing-sensitive test rules

Use observable conditions rather than narrow fixed sleeps:

- DOM or IPC ready sentinels;
- explicit child `READY` and stop sentinels;
- bounded condition polling;
- stable container identity during readiness; and
- explicit completion receipts.

A timeout is a deadlock guard, not the expected completion time.

## Budget interaction

Validation budgets are tracked per proof depth and operation, but the gate vector
and execution budget remain separate concepts.

Recommended counters:

```text
V1_FOCUSED_CORRECTION_CYCLES
V2_EXACT_HEAD_FULL_GATE_RUNS
V3_PLATFORM_ENVIRONMENT_RECOVERIES
V3_SAME_SIGNATURE_RERUNS
V4_COMPOSED_INTEGRATION_REPAIRS
V5_RUNTIME_PREFLIGHTS
V6_PREPARE_ATTEMPTS
V6_APPLY_ATTEMPTS
V6_VERIFIED_ROLLBACKS
V7_FINALIZE_PREFLIGHTS
V7_FINALIZE_ATTEMPTS
```

Rules:

- V1 correction may be elastic inside the declared source surface;
- V2 full gate should normally run once for the final exact head;
- V3 same-head same-signature rerun maximum is one;
- V5 or V7 read-only proof does not consume a V6 Apply;
- a failed V6 Apply requires verified rollback before a fresh Apply;
- authority and protected boundaries remain separate from validation counters; and
- a deeper proof does not replenish a shallower source-correction budget unless
  the execution pattern explicitly declares that checkpoint.

See `elastic-autonomous-execution-budget-pattern.md` for window, renewal, lifetime,
and progress rules.

## Evidence reuse

Evidence may be reused only when every bound fact remains unchanged.

Examples:

- a V1 test may be reused after metadata-only change when tested source bytes are
  unchanged and policy permits;
- V2 exact-head CI cannot be reused after the head changes;
- V3 proof cannot be reused after runner or platform contract changes;
- V4 proof cannot be reused after either adjacent implementation changes;
- V5 screenshots require unchanged container, image, config, mount, Compose,
  route, rendered state, and acceptance index;
- V6 backup evidence remains bound to its BackupId; and
- V7 receipts remain bound to their exact plan domain and accepted state.

## Failure classification by vector

Classify failure at the boundary where it occurred:

```text
V0_CONSISTENCY_FAILURE
V1_DETERMINISTIC_REGRESSION
V2_REPOSITORY_GATE_FAILURE
V3_RUNNER_OR_PLATFORM_FAILURE
V4_CONTRACT_EDGE_FAILURE
V5_RUNTIME_BINDING_OR_OWNER_ACCEPTANCE_FAILURE
V6_APPLY_OR_ROLLBACK_FAILURE
V7_FINALIZE_OR_CLOSEOUT_FAILURE
```

Also record environment, cadence, and criticality. A V3/E2 failure should not be
“fixed” by unrelated V1 product changes. A V7 receipt mismatch does not prove the
accepted UI is wrong.

## Repeated-failure rules

For one exact head and one sanitized signature:

- classify the first failure;
- perform one proven infrastructure cleanup when applicable;
- permit at most one unchanged-head rerun;
- stop after the second identical signature; and
- require a source, harness, runner-policy, or workflow correction at the correct
  proof depth.

A later pass does not erase the instability record.

## Required gate receipt

```text
proof_depth
execution_environment
cadence
criticality
exact_source_binding
changed_surface
command_graph_hash
runner_or_runtime_identity_class
claim_proved
claim_not_proved
path_filter_disposition
evidence_reused
evidence_reuse_basis
failure_class
failure_signature
```

Protected receipts must also bind prior state, target state, transaction state,
rollback status, and plan domain.

## Completion standard

A change is complete only when:

- the implementation-loop gate passed;
- the deepest applicable final-candidate proof passed;
- exact source and environment binding are recorded;
- cadence and criticality are explicit;
- duplicate command graphs are removed or justified;
- evidence reuse is bound to unchanged state;
- no deeper claim is inferred from a shallower vector;
- protected operations used explicit authorization and verified rollback; and
- Finalize and closeout are complete for a release train.

## Operational boundary

This pattern selects and classifies evidence. It does not authorize product
changes, CI workflow changes, runner mutation, Production contact, credentials,
identity operations, W8, W9, or bypassing required checks.