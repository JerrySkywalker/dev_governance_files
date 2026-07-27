# Canary Runtime Binding Playbook

## Classification

```text
classification: playbook
scope: accepting a Canary release that uses release pointers, containers, and bind mounts
related_waves:
  - Wave 7
related_repositories:
  - jerry-glance-dashboard
  - dev_governance_files
sensitivity_notes: record sanitized identifiers and hashes only; do not retain authentication state, private connection metadata, or raw runtime output
```

## Purpose

Prove that a Canary service is serving the accepted release, rather than a
valid new release combined with stale container or bind-mount state.

## Preconditions

Before any runtime action, identify the accepted immutable release and build
SHA, the approved current-release pointer, the exact service scope, the
permitted rollback, and the Production anchors that must remain unchanged.

Do not treat a successful package build, current symlink switch, or service
health response alone as deployment acceptance.

## Required binding proof

Record one sanitized proof chain that covers every row below. All rows must
agree; a missing, ambiguous, or unequal binding is a fail-closed result.

| Binding | Required proof | Failure classification |
| --- | --- | --- |
| Immutable release | Content-addressed release artifact and manifest identify the accepted build SHA. | `RELEASE_BINDING_UNPROVEN` |
| Current symlink | The current-release pointer resolves to that immutable release. | `CURRENT_POINTER_MISMATCH` |
| Container identity | The target service's identity is recorded before and after the scoped action; unaffected services retain their identity. | `CONTAINER_SCOPE_MISMATCH` |
| Bind mounts | The target container's bind-mount source resolves through the current pointer to the accepted release, and mount intent matches the service definition. | `BIND_MOUNT_SOURCE_MISMATCH` |
| Mounted file hashes | The required file hashes from inside the running container equal the files in the accepted release. | `MOUNTED_CONTENT_MISMATCH` |
| API-reported semantics | The validation API reports the expected packet/schema/version and required domain semantics. | `RUNTIME_SEMANTICS_MISMATCH` |
| Build SHA | The deployed build SHA and accepted build SHA are explicitly present and equal. | `BUILD_SHA_MISMATCH` |
| Rollback behavior | The declared rollback restores the prior accepted release and preserves the scoped service boundary; it is either proven safely or retained as an explicit owner-gated action. | `ROLLBACK_UNPROVEN` |

## Acceptance sequence

1. Bind the accepted immutable release, manifest, and build SHA before changing
   the current-release pointer.
2. Record the current pointer, target-service identity, unaffected-service
   identities, and bind-mount intent using sanitized values.
3. Switch only the approved current-release pointer or perform the separately
   authorized scoped lifecycle action.
4. Re-read the pointer, target container identity, mount source, and mounted
   hashes. A recreated target service must be explicitly expected; an
   unaffected service changing identity is a scope failure.
5. Query the validation API and prove its semantic payload, deployed SHA, and
   accepted SHA agree with the mounted content.
6. Run the declared health checks and confirm the Production anchors remain
   unchanged.
7. Record the rollback trigger, bound action, and verification. Do not attempt
   an undeclared rollback merely to turn an ambiguous deployment into a pass.

## Lifecycle rules

- A bind mount follows the container lifecycle, not merely the symlink
  lifecycle. A release switch may require a scoped service recreation.
- Recreate only the named service, with no dependency fan-out, unless a later
  authorization explicitly expands the scope.
- Never infer content freshness from a changed release directory or a healthy
  container. Mounted hashes and API semantics are both required.
- If the service is intentionally bound to immutable content-addressed mounts,
  prove the mount identifies that immutable release and retain the same
  acceptance chain.
- Keep a mandatory lifecycle backlog when the deploy helper cannot
  deterministically establish the required recreation or immutable mount.

## Completion receipt

Use compact fields such as:

```text
IMMUTABLE_RELEASE_BOUND=true
CURRENT_SYMLINK_BOUND=true
TARGET_CONTAINER_SCOPE=EXPECTED
UNAFFECTED_CONTAINERS_UNCHANGED=true
BIND_MOUNT_SOURCE_BOUND=true
MOUNTED_FILE_HASHES_EQUAL=true
API_SEMANTICS_EQUAL=true
DEPLOYED_ACCEPTED_BUILD_SHA_EQUAL=true
ROLLBACK_BEHAVIOR=<PROVEN|OWNER_GATED_NOT_EXERCISED>
PRODUCTION_UNCHANGED=true
SENSITIVE_OUTPUT=false
```

Do not include raw container output, host names, private paths, credentials,
cookies, tokens, authentication state, or protected-evidence contents in the
receipt.

## Non-goals

This playbook does not authorize Canary deployment, runtime mutation,
Production action, authentication refresh, product changes, or a new Wave. It
defines the proof required only after those actions are separately authorized.
