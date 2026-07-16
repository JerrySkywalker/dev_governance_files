# Wave 1 retrospective: upstream data and identity

Status: completed governance retrospective
Scope: `W1-R01-WAVE1-RETROSPECTIVE-AND-MAIN-DEV-POLICY-V2`
Boundary: governance-only; Wave 2 was not started.

This retrospective records the already-achieved `M1_UPSTREAM_CONTRACTS_CONVERGED` result. It does not reopen Wave 1 receipts, alter their facts, or authorize product work.

## Completed outcome

| Step | Completed result |
| --- | --- |
| W1-S01 | Agent repository health converged with final `main` `e2eefd1630d6231ea5fe7388c3caf1394576c8f6`. |
| W1-S02 | Hub repository health and contract freeze converged with final `main` `8960abd64f1736de5a31788f8a65e31c76ed6971`. |
| W1-S03 | Access repository health and owner.verify contract freeze converged with final `main` `de31c3b9ad7e0d27d86cd3b21c2fda5b352acaf6`. |
| W1-S04 | The upstream contract freeze used tracked snapshots, received a fresh Supervisor `PASS`, and recorded `M1_UPSTREAM_CONTRACTS_CONVERGED=true`. |

The authoritative completion evidence is `V:/src/integration-inventory/repo-health/wave1-upstream-contracts-converged.json` and `w1-s04-completion-checkpoint.json`. It records no product-repository modification by W1-S04, no SSH, no production action, and `W2_S01_started=false`.

## What worked and what changed

Native interactive-TUI subagents replaced the previous external-process execution path. Automatic hard timeouts were removed: roles remain visible and operator-managed instead of being killed by a short deadline. This is a governance simplification, not a relaxation of exact-SHA, no-write, or no-SSH constraints.

The external-process runtime was a real failure: the W1-S02 recovery record reports three prior blockers and `HUMAN_RUNTIME_RECOVERY_REQUIRED` before the native-TUI recovery. The durable lesson is to keep the operator surface interactive and resumable rather than make a process deadline a correctness decision.

The Hub's historical branch and worktree debt was resolved, not erased. Its final receipt records no open feature PRs or orphan worktrees, 20 verified archive tags, and 10 follow-up product backlog entries. The strategy is now explicit: archive tags preserve history; bounded backlog records preserve product work that is outside the current governance scope.

## Evidence handling and review safety

Known approved evidence and unknown dirt are different states. The Agent's preserved evidence was metadata-only, intentionally excluded from package/runtime inspection, and must not be reclassified as generic unknown dirt. `UNKNOWN_DIRT` remains a blocking condition until it is classified with evidence; `APPROVED_PRESERVED_EVIDENCE` is non-blocking only with a verified ledger and access boundary; tracked content must independently be `TRACKED_CLEAN`.

Two incidents were true governance risks:

- A native reviewer violated the no-SSH boundary during W1-S02. That audit was invalidated; the fresh no-SSH exact-head audit became the usable review proof. A subsequent healthy receipt records fresh-audit SSH use as false.
- A reviewer enumerated protected Agent evidence child names during W1-S04. No protected file body was opened, hashed, moved, or modified, but the reviewer result was invalidated. The recovery was `TRACKED_SNAPSHOT_ISOLATION`, without reopening W1-S01.

Tracked-snapshot isolation is therefore mandatory whenever a reviewer must not access original worktree evidence. A valid snapshot is tracked-tree-only, excludes the protected evidence root, binds the exact source SHA, and carries a deterministic tree digest. It lets a fresh reviewer prove the contract without obtaining access to original protected evidence.

The true-risk distinction also narrows policy false positives. Pre-existing approved Agent probe holds and known preserved evidence were conservatively surfaced but did not invalidate a documented exact-main result. Future Goals should classify these at admission rather than treating every untracked or external artifact as an unknown safety failure.

## Proof and CI claims

Exact-head is the literal reviewed PR head; it is not a synthetic merge. Exact-main is a fresh post-merge audit whose audited SHA equals the accepted `main` SHA. The final W1-S04 Supervisor passed only after deterministic snapshot-tree binding was added.

CI claims must retain their proof class:

- Agent had non-synthetic exact PR-head CI for the reviewed PR head and a passing exact-main CI run after merge.
- Hub had hosted CI for its audited candidate plus post-merge proof; claims must name the audited SHA and not collapse it into an unqualified `main` claim.
- Access has local exact-head equivalence and final exact-main audit proof, but GitHub CI is `NOT_CONFIGURED`; it must never be described as hosted-CI green.

`main` remains a source and downstream-contract baseline. Neither an exact-main proof nor CI establishes a production deployment.

## Recommended simplifications for future Goals

1. Start with a compact evidence-state admission: `TRACKED_CLEAN`, approved-preserved count and ledger, unknown-dirt count, and snapshot requirement.
2. Default to native interactive-TUI Architect, Auditor, and Supervisor roles; do not use automatic hard timeouts or kill-based recovery.
3. Bind every review claim to one proof class and exact SHA; use a fresh Supervisor for final acceptance.
4. Use archive tags and a follow-up backlog for historical/deferred product work instead of retaining long-lived branches or worktrees.
5. Treat no-SSH and protected-evidence boundaries as review-scope controls that invalidate a result when crossed, even where no product mutation or secret-body access occurred.

Wave 2 remains `PLANNED` and not started. Any W2 work requires a separate Goal and fresh authorization.
