# JD-0003: Progress-sensitive autonomous execution budgets

- Status: Accepted
- Scope: Jerry-series checkpointed execution Goals
- Date: 2026-07-30

## Classification

```text
classification: decision
scope: progress-sensitive autonomous execution budgets
related_repositories:
  - dev_governance_files
sensitivity_notes: durable policy only; no local evidence or authentication material
```

## Context

Long-running, bounded Goals routinely encounter tooling, packet, validation,
and CI interruptions after their product and safety boundaries have already
been admitted. Treating every such interruption as an owner-visible blocker
causes needless pauses. Treating them as unlimited permission is equally
unsafe.

## Decision

Jerry-series Goals may use a wide overall execution envelope while keeping the
mutation surface narrow and explicit:

```text
WIDE_OVERALL_EXECUTION_ENVELOPE=true
NARROW_MUTATION_SCOPE=true
BUDGETS_ARE_DOMAIN_SEPARATED=true
BUDGETS_ARE_PROGRESS_SENSITIVE=true
CHECKPOINTS_REPLENISH_TRANSIENT_BUDGETS=true
AUTHORITY_BOUNDARIES_NEVER_AUTO_EXPAND=true
```

Routine tooling and infrastructure failures remain internal to the active Goal
while their relevant domain budget remains and a new observation, candidate
binding, or accepted checkpoint demonstrates progress. They do not by
themselves change product authority.

## Budget domains

Every Goal that permits autonomous continuation must declare independent
budgets for these domains:

| Domain | Controls | Never authorizes |
| --- | --- | --- |
| Authority | The approved repositories, mutation surfaces, and stop gates | A new repository, safety boundary, or owner decision |
| Semantic or product correction | In-scope candidate corrections | A desired-state, ownership, or product-policy change |
| Evidence and packet | Packet methods, preflights, and sealed packet attempts | Altering the candidate to make evidence easier |
| Auditor process | Independently started content reviews | Treating a runtime failure as a PASS |
| Schema and access recovery | Output contracts and evidence accessibility | Changing the reviewed source state |
| CI transient | Actually queued no-change reruns | Hiding deterministic failures |
| Runner environment | Narrow service or toolchain corrections | Product changes or a hosted fallback |
| Runtime or apply | Explicitly authorized, separately bounded execution | Any unapproved apply, installation, or production action |
| Wall-clock and no-progress | Time spent and repeated identical failures | An extension of authority or safety scope |

## Progress rules

Progress is demonstrated only by a new, reviewable fact, such as a different
candidate tree, a successful preflight, a sealed evidence packet, a completed
independent audit, or an accepted exact-main checkpoint. Repeating an identical
failure without a bounded corrective hypothesis consumes the no-progress
budget.

The [Elastic Autonomous Execution Budget Pattern](../patterns/elastic-autonomous-execution-budget-pattern.md)
defines profile defaults, counters, and reset rules. The
[Canonical Git Object Audit Packet Playbook](../playbooks/canonical-git-object-audit-packet-playbook.md)
defines one evidence method that keeps content review bound to canonical source
bytes.

## Top-level exits

Every execution Goal must terminate in exactly one top-level disposition:

```text
COMPLETE
OWNER_DECISION_REQUIRED
UNSAFE_BLOCKER
```

`OWNER_DECISION_REQUIRED` is appropriate when the next bounded action requires
new authority or an intentional policy choice. `UNSAFE_BLOCKER` is appropriate
when continuation could expose sensitive material, violate a declared safety
boundary, or leave the accepted source state unbound. Budget exhaustion alone
does not make a condition unsafe; it makes the next continuation an owner
decision.

## Checkpoints and overrides

An accepted stage exact-main checkpoint may replenish transient operational
counters because it proves a completed boundary. It must not reset authority,
safety, or semantic-policy constraints. Owner overrides are append-only,
scoped to one declared purpose, time-bounded, and recorded as consumed when
used.

## Non-goals

This decision does not:

- authorize a new repository, product capability, desired-state change, or
  route-ownership decision;
- permit unbounded corrections, unattended apply operations, or production
  work;
- replace exact-head, exact-main, or independent-audit proof classes; or
- publish local evidence or runtime data into this governance repository.
