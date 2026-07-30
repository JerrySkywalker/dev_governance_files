# Validation Depth and Gate Selection Pattern

## Classification

```text
classification: pattern
scope: selecting focused tests, CI gates, integration proof, runtime validation, and protected release evidence
related_waves:
  - Wave 7
related_repositories:
  - dev_governance_files
  - product repositories
  - coordination repositories
sensitivity_notes: durable rules and sanitized evidence classes only
```

## Purpose

Choose the smallest validation set that proves the current delta at the correct
risk boundary, while still requiring the deepest applicable proof for the final
accepted candidate.

This pattern prevents two opposite failures:

- **under-validation**, where a local fixture or repository CI pass is treated as
  proof of a real integration or Production state; and
- **over-validation**, where every narrow change repeats every historical gate,
  consumes scarce runner capacity, and increases environmental flakiness.

## Core rule

```text
validation depth follows the changed surface and the next acceptance boundary;
it does not follow the total age or size of the project history.
```

A deeper proof does not automatically require every lower proof to be repeated.
Each depth contributes a distinct claim.

## CI is not a depth by itself

`CI` describes where automation runs, not what it proves.

A CI job may run:

- a static documentation check;
- focused unit tests;
- a complete repository gate;
- a Windows-specific integration test; or
- a packaged Canary validation.

Conversely, a read-only Production preflight may provide a deeper runtime claim
than a repository CI job even though it is not itself a normal pull-request CI
check.

Every receipt should therefore name:

```text
validation_depth
execution_environment
exact_source_binding
changed_surface
claim_proved
claim_not_proved
```

## Depth model

### D0 — Static and governance consistency

Use for:

- Markdown and policy text;
- JSON or schema-only governance updates;
- knowledge-index changes;
- metadata-only closeout.

Typical proof:

- parse and schema checks;
- Markdown link checks;
- exact-SHA formatting;
- scope and forbidden-marker checks;
- lightweight secret scan;
- `git diff --check`.

D0 does not prove product behavior, platform behavior, runtime state, or
Production safety.

### D1 — Focused deterministic behavior

Use for:

- one parser, wrapper, receipt, selector, or binding;
- one deterministic negative case;
- isolated configuration generation;
- direct regression for an observed defect.

Typical proof:

- directly affected tests;
- three serial repetitions when timing or process behavior changed;
- exact source binding;
- syntax checks;
- sanitized output assertions.

D1 is the normal implementation loop. It should be fast enough to run after each
candidate correction.

### D2 — Repository candidate coherence

Use for:

- a final pull-request candidate;
- changes that affect multiple repository-local components;
- branch-protection required checks.

Typical proof:

- one canonical complete repository gate;
- exact-head checkout assertion;
- repository secret and syntax gates;
- causal CI accounting;
- fresh exact-main proof when the policy requires it.

Rules:

- run the complete gate once for the final exact head;
- do not run the same complete command graph in multiple required jobs without a
  distinct environment justification;
- use path-sensitive fast PASS contexts for irrelevant surfaces; and
- do not use repeated unchanged-head reruns as a substitute for stability.

D2 does not prove a neighboring repository contract or a deployed runtime.

### D3 — Platform-specific behavior

Use only when correctness depends on the platform or runner environment.

Examples:

- Windows ACL and atomic move behavior;
- PowerShell process and filesystem semantics;
- browser behavior tied to a specific managed runtime;
- container or filesystem semantics unavailable in portable unit tests.

Typical proof:

- intended self-hosted runner labels and exact head;
- clean runner preflight;
- job-owned child-process lifecycle;
- zero-orphan cleanup receipt;
- condition-driven synchronization;
- safe failure stage and elapsed time.

A portable static or Node unit test should not consume scarce D3 capacity merely
because the repository also contains Windows-specific code.

### D4 — Real adjacent-implementation integration

Use when one component consumes another component's real output or contract.

Examples:

- Agent to Hub;
- Hub to Gateway;
- Gateway to Android;
- outer release engine to config transaction engine.

Typical proof:

- real upstream producer or read model;
- real downstream parser or controller;
- exact source states for both sides;
- explicit semantic assertions;
- bounded negative cases;
- idempotency where applicable.

Fixtures may replace external services, transport, or fault injection. They
must not replace the contract edge that is the subject of the proof.

D4 is required when independent repository green checks cannot establish
compatibility.

### D5 — Canary or deployed runtime binding

Use when the candidate is deployed into an isolated or non-final runtime.

Typical proof:

- exact deployed source or image identity;
- container or service identity;
- mount and generated-artifact hashes;
- route and health;
- authenticated browser rendering when applicable;
- desktop and mobile screenshots;
- owner-visible product acceptance.

D5 distinguishes technical runtime correctness from human-visible acceptance.
A technically green Canary can still be rejected by the owner.

### D6 — Protected mutation and rollback proof

Use for:

- Production Apply;
- protected runtime mutation;
- identity or credential-adjacent operations;
- operations whose failure requires rollback.

Required before mutation:

- separate explicit authorization;
- exact old-state proof;
- immutable target binding;
- fresh backup namespace;
- archive and manifest integrity;
- read-only diagnostic or preflight;
- rollback availability;
- one writer and one transaction lease.

Required after mutation:

- exact target image or artifact;
- target configuration and mounted content;
- target Compose or equivalent declaration;
- stable runtime identity;
- readiness, health, route, and log gates;
- supported automatic rollback on failure.

A read-only preflight failure does not consume a D6 Apply attempt.

### D7 — Finalization, evidence binding, and closeout

Use after the target has passed acceptance but is not yet durably committed.

Typical proof:

- Finalize preflight;
- inner transaction committed;
- outer journal committed;
- acceptance receipt bound to the correct plan domain;
- screenshot and runtime anchors unchanged;
- post-Finalize runtime proof;
- coordination and governance closeout;
- issue closure, branch retirement, lease release, and retained rollback proof.

An Apply or screenshot packet without D7 proof is not a completed release train.

## Selection procedure

### Step 1 — Identify the changed surface

Classify the delta as one or more of:

```text
documentation
local logic
repository composition
platform behavior
cross-repository contract
runtime binding
protected mutation
transaction finalization
```

### Step 2 — Identify the next acceptance boundary

The next boundary may be deeper than the changed file suggests. A one-line
Finalize wrapper fix can require D4 and D7 because it changes the binding between
two transaction engines and the final commit path.

### Step 3 — Choose implementation-loop proof

Use the narrowest fast proof that can reject a bad edit quickly:

- D0 for docs;
- D1 for source correction;
- D3 focused proof when the delta is platform-specific;
- D4 focused composed proof when the defect crosses a contract edge.

### Step 4 — Choose final-candidate proof

Require the deepest applicable proof once for the accepted candidate:

- D2 for a repository PR;
- D3 when platform behavior matters;
- D4 for real contract edges;
- D5 for deployed visual/runtime acceptance;
- D6 for protected Apply;
- D7 for Finalize and closeout.

### Step 5 — Remove duplicate gates

Expand command graphs before queuing CI. When two required jobs both execute the
same complete graph, select one canonical owner and retain only distinct checks
in the other job.

### Step 6 — Record what was not proved

A truthful receipt should state limitations, for example:

```text
REPOSITORY_GATE=PASS
WINDOWS_PLATFORM_PROOF=NOT_APPLICABLE
RUNTIME_CONTACTED=false
PRODUCTION_MUTATED=false
```

This prevents a D2 pass from being misreported as D5 or D6 evidence.

## Gate topology rules

### Canonical full gate

Each repository should have one canonical complete gate for an exact head.
Other required contexts should be either:

- focused distinct gates; or
- truthful, deterministic path-filtered PASS contexts.

### Platform scarcity

A sole self-hosted platform runner should execute only the work that requires
that platform. Portable checks should use other capacity when policy and budget
allow.

### Scheduled work

Scheduled smoke must not silently contend with required pull-request gates on a
sole runner. Use separate labels, queue-aware skipping, or a different execution
pool.

### Setup reuse

When one runner serializes all jobs, multiple jobs may cost more than one staged
job because checkout, dependency installation, browser setup, and cleanup repeat.
Job separation should be justified by isolation or required-context semantics,
not by an assumption of parallelism.

## Validation and elastic budgets

Budgets should be tracked per depth and per operation.

Recommended counters:

```text
D1_FOCUSED_CORRECTION_CYCLES
D2_EXACT_HEAD_FULL_GATE_RUNS
D3_PLATFORM_ENVIRONMENT_RECOVERIES
D3_SAME_SIGNATURE_RERUNS
D4_COMPOSED_INTEGRATION_REPAIRS
D5_RUNTIME_PREFLIGHTS
D6_PREPARE_ATTEMPTS
D6_APPLY_ATTEMPTS
D6_VERIFIED_ROLLBACKS
D7_FINALIZE_PREFLIGHTS
D7_FINALIZE_ATTEMPTS
```

Rules:

- D1 corrections may be elastic within the declared source surface;
- D2 full gate should normally run once for the final head;
- D3 same-head same-signature rerun maximum is one;
- a D5 or D7 read-only preflight does not consume a D6 Apply;
- a failed D6 Apply requires verified rollback before another fresh Apply;
- each Apply uses a new backup scope unless the contract explicitly supports
  safe idempotent continuation; and
- authority and protected boundaries remain separate from operational counters.

## Evidence reuse

Evidence may be reused only when all facts it binds remain unchanged.

Examples:

- a focused D1 test may be reused after a metadata-only commit when the tested
  source bytes are unchanged and policy permits it;
- exact-head D2 CI cannot be reused after the head changes;
- D5 screenshots may be reused after a source-only Finalize correction only when
  container identity, image, config, mount, Compose, and rendered state remain
  unchanged;
- D6 backup evidence remains bound to its BackupId; and
- D7 receipts remain bound to their own plan domain and exact accepted state.

## Failure classification by depth

A failure should be classified at the boundary where it occurred:

```text
D0_CONSISTENCY_FAILURE
D1_DETERMINISTIC_REGRESSION
D2_REPOSITORY_GATE_FAILURE
D3_RUNNER_OR_PLATFORM_FAILURE
D4_CONTRACT_EDGE_FAILURE
D5_RUNTIME_BINDING_OR_OWNER_ACCEPTANCE_FAILURE
D6_APPLY_OR_ROLLBACK_FAILURE
D7_FINALIZE_OR_CLOSEOUT_FAILURE
```

Do not fix a D3 runner contamination issue by changing unrelated D1 product
logic. Do not treat a D7 receipt mismatch as evidence that the accepted UI is
wrong.

## Repeated-failure rules

For one exact head and one failure signature:

- classify the first failure;
- perform one proven infrastructure cleanup when applicable;
- permit at most one unchanged-head rerun;
- stop after the second identical signature; and
- require a source, harness, runner-policy, or workflow correction at the
  correct depth.

A later pass does not erase the instability record.

## Completion standard

A change is complete only when:

- the implementation-loop proof passed;
- the deepest applicable final-candidate proof passed;
- exact source and environment binding are recorded;
- duplicate gates and reused evidence are accounted for;
- no deeper claim is inferred from a shallower proof;
- protected operations used explicit authorization and verified rollback; and
- finalization and closeout are complete when the work is a release train.

## Operational boundary

This pattern selects evidence. It does not authorize:

- product changes;
- CI workflow changes;
- runner mutation;
- Production contact;
- credentials or identity operations;
- W8 or W9; or
- bypassing required checks.
