# Wave 7A Retrospective — Codex Usage Safe Message Chain

## Status

- Wave: `W7A`
- Milestone: `M7A_CODEX_USAGE_CHAIN_GREEN`
- Result: `ACHIEVED`
- Chain semantics: `SAFE_USAGE_CHANGE_MESSAGE`
- W7B started: `false`

## Final exact product states

- `jerry-telemetry-agent`: `e2eefd1630d6231ea5fe7388c3caf1394576c8f6`
- `jerry-telemetry-hub`: `8960abd64f1736de5a31788f8a65e31c76ed6971`
- `jerry-message-gateway`: `39b9adbf1d9f15e2f98c1e3962e5123dacc5950f`
- `jerry-devops-android`: `9a00ed80c70a8f8afa8a1b967d2d32870e8ceb67`

## Product outcomes

- Agent: `NO_PRODUCT_DELTA_REQUIRED`
- Hub: `NO_PRODUCT_DELTA_REQUIRED`
- Gateway: `MINIMAL_PROVIDER_CONTRACT_DELTA_IMPLEMENTED`
- Android: `MINIMAL_TESTABILITY_DELTA_IMPLEMENTED`

The Gateway correction bound the Hub usage-summary request to the configured expected node. The Android correction exposed the existing Message Gateway JSON parser as an internal test seam without changing UI, network, persistence, release, or security behavior.

## Accepted result

The final exact-state local chain proved:

```text
synthetic four-window backend usage
  -> Agent real normalizer and signed event path
  -> Hub real ingest and safe read model
  -> Gateway one-shot Codex usage source
  -> bounded subject-scoped safe message
  -> Android bounded inbox projection
  -> idempotent acknowledgement
```

Accepted properties included:

- four-window preservation;
- provider and consumer contract compatibility;
- semantic deduplication;
- safe bounded Android message projection;
- acknowledgement and post-ack empty inbox;
- no real Codex authentication read;
- no real ChatGPT request;
- no production Hub or Gateway request;
- no physical-device action;
- no signing or production action.

## Principal lessons

### 1. Cross-repository E2E found a real defect that local smoke tests did not

Agent, Hub, Gateway, and Android each had local tests, but the exact Hub-to-Gateway path still lacked the expected-node query binding. A chain milestone must execute the real adjacent implementations rather than combine independent green flags.

### 2. Handwritten fixtures are useful but not sufficient as the primary proof

Fixtures remain appropriate for focused unit and negative tests. The primary compatibility proof must originate from the upstream real normalizer or read model and be consumed by the downstream real parser.

### 3. Completion requires explicit evidence disposition

Several Gradle attempts produced useful information but were not acceptance evidence. Every attempt was classified as accepted, rejected, superseded, informational-only, or preserved. A later passing command did not automatically rehabilitate an earlier unsafe path.

### 4. Tool bootstrap is part of the trust boundary

The Android test could not be accepted until the Gradle distribution, wrapper JAR, dependency sources, task graph, and offline execution path were independently proven. `--offline` does not provision a missing Wrapper distribution; a verified local distribution source was required.

### 5. Lexical task-name bans must be refined by semantic evidence

The initial guard rejected every task containing `bundle`. The exact tasks `bundleDebugClassesToCompileJar` and `bundleDebugClassesToRuntimeJar` were later proven to produce unit-test class JAR intermediates, not Android App Bundles. Safety guards should fail closed, but owner-approved exceptions must bind to exact task paths, classes, outputs, dependency closures, source SHA, and graph hash.

### 6. Runtime overrides should remain narrow, append-only, and consumable

The sequence of owner overrides preserved safety while progressively resolving proxy-port drift, timeout behavior, supervised long-running processes, checksum failures, trusted source acquisition, task semantics, and final S04 replay. An override never silently broadened the previous one.

### 7. Long-running commands need explicit process supervision

Wrapper and dependency acquisition should be launched as owned child processes with redirected logs, bounded absolute time, periodic metadata polling, and no output-silence termination.

### 8. A successful technical test is not enough when the acquisition path was unauthorized

The first S04 Android test passed but was rejected because the Wrapper performed an unauthorized distribution download. The safe result was replayed with the previously verified local distribution before final acceptance.

### 9. Human-visible validation should be a durable channel, not a one-off artifact

The post-W7A operator demo proved the value of directly viewing the four-window Hub summary, Gateway safe message, acknowledgement, and empty post-ack inbox. Future integration Waves should publish allowlisted visual packets to an authenticated canary Glance Dashboard and require both Playwright screenshot review and human browser acceptance.

## Visual-validation policy introduced after W7A

The next infrastructure step is `W7V — Dual Dashboard Visual Validation Infrastructure`.

It establishes:

- a stable production Dashboard channel;
- an isolated authenticated canary Dashboard channel;
- a generic safe Wave validation packet contract;
- a reusable visual-validation card;
- exact-SHA canary deployment;
- authenticated Playwright screenshots for desktop and mobile viewports;
- owner human visual acceptance before later cross-repository Wave closeout.

W7B remains not started until W7V reaches its milestone.

## Durable local evidence

- `V:/src/integration-inventory/repo-health/w7a-codex-usage-chain-checkpoint.json`
- `V:/src/integration-inventory/repo-health/w7a-codex-usage-chain-report.md`
- `V:/src/integration-inventory/repo-health/w7a-operator-demo/w7a-operator-demo.md`
- `V:/src/integration-inventory/repo-health/w7a-governance-closeout-facts.md`

These local files remain the detailed execution evidence. This retrospective records only durable governance lessons and final classifications.