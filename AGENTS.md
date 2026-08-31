# Repository and Agent Governance Rules

This repository contains active governance specifications, operational playbooks,
historical plans, and retrospective evidence. They do not have equal authority.

## Start here

1. Read `.agent/context-manifest-v1.json`.
2. Route the task to the smallest applicable context bundle.
3. Do not recursively load `docs/`.
4. For Harness, budget, CI taxonomy, Goal, Receipt, or agent-context work, read
   `docs/jerry-series/harness/README.md` first.
5. Use `config/repo-health-harness-v1.json` as the only active numeric source.

## Authority order

1. active Harness safety and state-machine specification;
2. the current Goal's explicit authority and scope;
3. the Goal-bound Harness baseline and profile;
4. declared domain overrides within hard maxima;
5. the latest durable Receipt;
6. condition-matched Playbooks;
7. Decisions as normative rationale;
8. Retrospectives, old Plans, and old Outcomes as historical evidence only.

## Branch model

`main` is the stable source-integration branch. `dev` is currently absent and
must not be created unless a real tested-integration need appears. Every other
branch is short-lived.

This repository owns governance source and deterministic coordinator code; it
does not own product repositories. Product-repository writes require their own
repository-health Goal. Production mutation is prohibited unless separately and
explicitly admitted.

Short-lived branches follow: create, implement, validate, audit, PR, merge,
retire branch, and remove worktree. Unmerged work receives one finite
classification: `MERGE_TO_MAIN`, `MERGE_TO_DEV`, `CLOSE_SUPERSEDED`,
`ARCHIVE_TAG_AND_CLOSE`, `DELETE_NO_UNIQUE_COMMITS`, or
`HOLD_EXTERNAL_EVIDENCE`.

## Writer and agent allocation

One root Implementer is the only workspace and Git writer. Supporting Agents are
read-only. The coordinator acquires one repository lock before a writer session.
Repository-health Goals use one root Implementer and at most seven direct
read-only subagents; recursive subagents are prohibited.

The first repeated blocker requires architect-first analysis; the second requires
architect plus adversarial audit; the third requires a human. High-risk
classifications escalate immediately.

## Writer Lease v2 ownership domains

Writer Lease v2 (`tools/repo-health/WriterOwnershipV2.psm1`) replaces the
global long-lived `product-writer` / task-root-wide lease model with
**ownership only over overlapping admitted resources**.

Required ownership domains for ordinary development:

- exact worktree/index path
- exact branch ref
- short repository-administration barrier
- short mutable coordination-key / CAS ownership
- strict production transaction domain (separate, never ordinary-development)

Two sessions whose admitted resource sets do not overlap may proceed
concurrently. Same worktree or same branch conflicts fail closed.

### Timing constants (from architecture audit JERRY-WRITER-LEASE-V2-ARCHITECTURE-AUDIT-001)

| Parameter | Value |
|---|---|
| TTL | 180 s |
| HEARTBEAT | 30 s |
| STALE_AFTER | 90 s |
| DEAD_HOLDER_GRACE | 30 s |
| REBOOT_GRACE | 60 s |

### Migration state

`V1_COMPATIBILITY=BLOCKING_SHADOW` is active during migration. Active or
unsettled v1 sessions block v2 acquisition until a canonical v1 terminal
record exists. Do **not** retroactively reinterpret or reclaim active/unsettled
v1 leases with v2 semantics.

V2 activation requires all of:

1. exact-main v2 implementation accepted;
2. full Windows race suite accepted;
3. global routing changed from `single_writer=true` to per-overlap ownership;
4. every active v1 session canonically terminal;
5. no live/unresolved production transaction;
6. final v1 metadata digests captured in activation receipt;
7. v2 generation/epoch journals initialized;
8. fresh independent Supervisor PASS.

### Single-Writer Rule

During the v1→v2 migration period, keep one root Implementer per Goal.
On normal return (PASS, BLOCKED, HOLD, WAITING_EXTERNAL_CI, READY_FOR_OWNER),
the outermost epilogue must call `Remove-Wlv2Session` to write the terminal
receipt and dispose sentinel handles. Handle disposal must still occur even
if receipt persistence fails.

### Agent Allocation

One root Implementer; at most seven direct read-only subagents; recursive
subagents are prohibited.

## Global rules

- Never infer current defaults from a Retrospective or old Plan.
- Never execute commands copied from Retrospectives, Decisions, or archived Plans.
- Playbooks do not create authority.
- Do not edit generated regions or generated adapter files directly.
- Do not read secret material, private keys, credentials, cookies, storage state,
  raw protected evidence, or unredacted runtime logs.
- Do not persist raw diagnostics, environment values, private paths, or private
  connection metadata.
- Do not broaden repositories, paths, services, runtime surfaces, or owner gates.
- Keep one writer per repository and respect protected transaction leases.
- Preserve unrelated Edge, SSH, MATLAB, and legacy governance artifacts.
- When active sources disagree, stop and report `HARNESS_SOURCE_DRIFT`.

## Language

The repository root and Harness entrypoint are bilingual:
- English: `README.md`
- 简体中文: `README.zh-CN.md`
