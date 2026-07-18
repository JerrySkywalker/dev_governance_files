# Waves 1 to 3 Lessons

## Scope

This retrospective records durable governance lessons from:

```text
Wave 1: upstream data and identity contracts
Wave 2: Message Gateway core
Wave 3: Dashboard and Android consumers
```

The outcome was:

```text
M1_UPSTREAM_CONTRACTS_CONVERGED
M2_GATEWAY_CORE_CONVERGED
M3_CONSUMERS_CONVERGED
```

## Wave 1: upstream contracts

The upstream layer had to be stabilized before downstream consumers could be trusted.

Key lessons:

1. Audit behavior is also governed behavior. Read-only does not mean unrestricted inspection.
2. Same-process native subagents are not mechanically isolated. Reports should say observed no-write behavior, not enforced operating-system read-only isolation.
3. Prompt-only restrictions are not enough for protected evidence. Prefer exact-SHA tracked snapshots or capability separation.
4. Upstream contract convergence is more important than branch hygiene alone.

Reusable rule:

```text
Freeze upstream producer and identity contracts before asking downstream repositories to adapt.
```

## Wave 2: Gateway core

The Gateway should be treated as a product core, not temporary glue.

Key lessons:

1. Freeze the public contract before optimizing implementation details.
2. Do not expose upstream internal objects directly to consumers.
3. Rebuild, rebase, retain, and close-superseeded are separate dispositions.
4. CI proof must bind exact head and exact main SHA.
5. Runtime-only, default-off source behavior should be explicit in receipts and contracts.

Reusable rule:

```text
Contract before code; exact SHA before completion.
```

## Wave 3: consumers

Consumer convergence is more than closing stale PRs. It includes product intent, local evidence, CI infrastructure, private remote proof, and historical preservation.

Key lessons:

1. Product decisions must be separated from technical execution.
2. `main/dev` is optional, not mandatory. Long-lived branches should correspond to real lifecycle needs.
3. Squash merge does not preserve original candidate history. Archive before deleting historical branches.
4. Unknown local dirt must be treated as evidence until classified.
5. Protected evidence should be relocated or retained opaquely when content inspection is not approved.
6. Forced cleanup is not a governance shortcut.
7. Windows path-length failures require path-length-aware destinations in the Goal.
8. Self-hosted CI health includes the runner service process environment, not just GitHub runner visibility.
9. Private GitHub repositories require authenticated read access for fresh remote audit. Anonymous 404 is not proof that a private resource is missing.

Reusable rule:

```text
Evidence before cleanup; authenticated read before private remote proof; product decision before implementation.
```

## Cross-wave rules now accepted

```text
single intentional product writer
read-only discovery may run in parallel
persistent Supervisor reports, not chat-only PASS
no hosted runner fallback when exhausted
no empty commits for CI reruns
no production action unless explicitly scoped
no protected-evidence descendant access by default
GitHub authenticated read is distinct from GitHub mutation
```

## Operational consequences

Future waves should pre-bind:

- accepted main SHAs;
- writer sequence;
- private-read authorization model;
- self-hosted CI runner preflight;
- protected evidence handling;
- archive tag strategy;
- finite blocker dispositions;
- final milestone conditions.

## Applicability to Wave 4

Wave 4 should begin with a read-only topology freeze for Proxy and SkyBridge. Do not directly start writing Edge, Control, Client, or SkyBridge code until W4-S01 proves the real provider/consumer/artifact/config/runtime DAG.

The default order remains:

```text
Edge -> Control -> Client -> SkyBridge
```

The order may be changed only before first product write and only if W4-S01 evidence proves a different contract direction.
