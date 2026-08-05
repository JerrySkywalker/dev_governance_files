# JD-0005: Close the Repository Health Program and separate Post-Health Programs

- Status: Accepted
- Date: 2026-08-06
- Scope: Jerry repository-health governance

## Context

The Repository Health Program was created to converge repository identity,
default branches, short-lived work, worktrees, retained evidence, pull-request
state, deterministic validation, and exact-source acceptance. It was not a
promise that every product, platform, deployment, or physical-device milestone
would be completed inside the same program.

Later master-plan amendments mixed repository convergence with product and
runtime ambitions. That made an incomplete product track appear to keep the
health program open even after canonical repository-health debt had reached
zero. A fresh live audit now classifies every admitted repository and retained
work line without an unknown state.

## Decision

Close the Repository Health Program through the monotonic version 2.0 terminal
amendment in the [master plan](../../repo-health-master-wave-plan.md).

The effective closeout state is:

```text
REPOSITORY_HEALTH_PROGRAM_STATUS=COMPLETE
CANONICAL_REPOSITORY_HEALTH_DEBT_REMAINING=false
POST_W7_REPOSITORY_CONVERGENCE=COMPLETE
FINAL_HEALTH_CLOSEOUT_AUDIT=PASS
OLD_W8_W9_EXECUTION_STATUS=SUPERSEDED_UNEXECUTED
HISTORICAL_DEFINITIONS_PRESERVED=true
PRODUCT_WORK_NOT_CLAIMED_COMPLETE=true
```

Prior amendments, Wave definitions, evidence, blockers, and accepted
milestones remain historical truth. The terminal amendment supplies current
effective-state precedence; it does not rewrite old W8 or W9 work as executed
or complete.

Product incompleteness is not repository-health debt when the repository has a
resolved canonical identity, a classified default branch and retained work,
no unknown unique history, and an explicit backlog owner outside the Health
Program.

## Post-Health Foundation Tracks

- Coordination Loop;
- JPC Multi-device Enrollment; and
- OpenCode Workspace Hub.

These tracks own foundation-platform capability that may support later product
programs. Their registration does not authorize execution.

## Post-Health Product Tracks

- Dashboard / Message Gateway;
- Android / Wear OS; and
- Workstation Manager.

These tracks own product, runtime/deployment, and owner-controlled physical
acceptance backlog. Their registration does not claim product completion.

## Prohibited consequences

This decision does not authorize product-repository writes, protected runtime
Apply, Production or Canary mutation, credential or identity decisions, CI
runner changes, Android or Wear device contact, Workstation Manager physical
machine Pilot, force-push, deletion of retained evidence, or mutation of open
PR heads outside `dev_governance_files`.

## Reopening repository-health status

A future program may reopen repository-health status only through a new
explicit governance decision and Goal that identifies fresh canonical
repository-health debt, binds it to live exact-source evidence, classifies all
affected unique work, defines an allowed write boundary, and appends a newer
monotonic amendment. Product backlog, runtime backlog, or a missing physical
acceptance result alone is insufficient.

## Consequences

- The registry records repository classification separately from retained work.
- Old W8/W9 definitions remain discoverable as historical, unexecuted scope.
- New foundation or product execution requires separate authority and proof.
- Historical Retrospectives remain non-normative and cannot reopen the program.

## Non-goals

This decision does not duplicate Harness numeric parameters and does not change
the active Harness semantic or numeric sources.
