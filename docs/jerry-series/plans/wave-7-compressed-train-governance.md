# Wave 7 Compressed Train Governance

## Identity

```text
GOVERNANCE_VERSION=1.7
AMENDMENT_ID=W7V-R03-PHASE-A-CLOSEOUT-AND-COMPRESSED-WAVE7-TRAIN
RUN_ID=W7-COMPRESSED-001
COORDINATION_REPOSITORY=JerrySkywalker/jerry-wave7-train
STATUS=MATERIALIZATION_AUTHORIZED_EXECUTION_NOT_STARTED
```

This amendment closes the completed authentication-automation portion of the
Pre-W7B Dashboard hardening interlude and authorizes a compact durable run
bundle for one future continuous W7B-through-W7E execution. It does not start
W7B and does not authorize W8 or W9.

## Phase A closeout

The accepted Phase A facts are:

```text
M_DASH_AUTH_AUTOMATION_READY=true
PHASE_A_COMPLETE=true
G1_COMPLETE=true
DASHBOARD_EXACT_MAIN=88b9b8e41b992887f832c5c31e230f373700ab5c
```

The repository-local helper at `jerry-glance-dashboard/tools/web-auth` is
complete and may be used for Canary validation only.

## Deferred Dashboard work

```text
PHASE_B_STATUS=DEFERRED_BY_OWNER
PHASE_C_STATUS=DEFERRED_BY_OWNER
M_PRE_W7B_DASHBOARD_HARDENING_COMPLETE=false
DEFERRED_INTERLUDE=POST_WAVE7_DASHBOARD_UI_HARDENING
```

Phase B and Phase C are removed from W7B admission. They remain owner-gated,
not authorized for execution, and are placed after W7E and before any later W8
decision. Historical Phase A through Phase C plans remain preserved as the
record of the original design.

## W7B admission

W7B may start only when all four facts are true at the same live admission:

```text
W7V_OVERALL_STATUS=COMPLETE
M_DASH_AUTH_AUTOMATION_READY=true
W7B_OWNER_AUTHORIZATION=true
W7B_STARTED=false
```

The current run-bundle materialization authorization is not
`W7B_OWNER_AUTHORIZATION`. Issue comments, repository discussions, and
notifications are never executable authorization.

## Compressed execution contract

The future execution uses one continuous checkpointed root Implementer from
W7B through W7E. Each Wave retains:

- its distinct Wave and step identity;
- a distinct outcome and milestone;
- real replay against the adjacent implementation;
- `NO_PRODUCT_DELTA_REQUIRED` as the default outcome;
- a product PR only when replay proves a deterministic defect;
- exact-head and exact-main validation when a product changes;
- fresh independent read-only audit; and
- a safe Canary packet.

The Implementer is the sole product and Git writer. Architect freezes Plan and
Goal. Auditor and Supervisor provide independently launched read-only
acceptance. Owner decisions are durable only as merged `DEC` files in the
coordination repository. GitHub issue comments are notification only.

Detailed local evidence remains under
`V:\src\integration-inventory\repo-health\runs\W7-COMPRESSED-001\`.
The coordination repository is a compact durable mailbox and contains no raw
diagnostics, credentials, private connection metadata, screenshots, or
secret-bearing evidence.

## Wave order

1. W7B — Message Gateway readiness chain.
2. W7C — device identity chain.
3. W7D — Edge to Control to Client to SkyBridge proxy chain.
4. W7E — workstation and Wear OS auxiliary links.
5. combined Canary visual acceptance.
6. Wave 7 retrospective.
7. stop.

W8 and W9 remain planned but not authorized.

## Validation-machine policy

One owner-designated validation machine is recorded for the run and must pass
capability preflight before replay. A Wave may record another explicitly
designated machine when its platform requires it, but the run does not require
all development laptops to be initialized.

Multi-machine initialization remains backlog work. It is neither an admission
gate nor a reason to mutate unrelated workstations.

## Production validation-only authentication

Production authentication is validation-only. The Implementer may consume an
already provisioned owner-controlled validation context only when the future
Goal explicitly authorizes that validation. Automated Production credential
acquisition, credential creation, credential discovery, policy weakening,
authentication bypass, and persistent session creation are prohibited.

The completed web-auth helper is used only with the Canary route. It must not
automatically acquire Production credentials.

## Combined Canary acceptance

After W7E, the run assembles one safe combined Canary packet from the distinct
Wave packets. The packet contains no credentials or storage-state contents and
must bind the replayed repository SHAs, deterministic results, sanitized visual
artifacts, and owner acceptance. Failure returns to the affected Wave
checkpoint; it does not authorize broad product change.

## Stop boundary

After W7E and the combined Canary acceptance, the Implementer records the Wave
7 retrospective and stops. A later explicit owner Goal is required for W8,
W9, the deferred Dashboard UI hardening interlude, Production mutation, or any
other product execution.
