# Incremental Resume Goal Pattern

## Classification

```text
classification: pattern
scope: resuming bounded multi-step Goals after an accepted checkpoint
related_waves:
  - Wave 7
related_repositories:
  - dev_governance_files
  - coordination repositories
sensitivity_notes: point to sanitized durable state; never copy protected evidence, credentials, or raw diagnostics
```

## Problem

A long-running Goal accumulates decisions, rejected attempts, and receipts.
Repeating that whole history in every resume Goal wastes context and makes the
current authorization difficult to review. Omitting the history entirely is
also unsafe because the next executor loses the accepted boundary.

## Core rule

```text
Resume from durable-state pointers plus a compact Accepted Delta.
Do not repeat full history when the durable record can be read directly.
```

Use this pattern together with
[Recovery Goal Evidence Binding](recovery-goal-evidence-binding.md) when a
resume addresses a blocker.

## Durable-state pointers

The Goal must identify, without copying their full contents:

- the authoritative run, plan, and last accepted checkpoint;
- the exact accepted source or deployment binding, where applicable;
- the decision or receipt that authorizes the resume;
- the superseded blocker record, if any; and
- the next checkpoint that will be written on completion or hard stop.

Pointers are references, not a substitute for revalidation. The executor reads
the named state and revalidates the facts that can drift before any mutation.

## Compact Accepted Delta

Place this block near the beginning of every resume Goal:

```text
LAST_ACCEPTED_CHECKPOINT=<durable pointer>
CURRENT_DELTA=<one newly observed fact>
ALLOWED_MUTATION=<smallest authorized change or NONE>
UNCHANGED_BOUNDARIES=<comma-separated non-goals>
REQUIRED_PROOF=<next validation boundary>
HARD_STOP=<first condition that requires a new decision>
```

The delta must be small enough for an independent reviewer to determine why the
prior state is insufficient and why the stated mutation is the narrowest safe
response. It must not restate completed work, raw logs, credentials, cookies,
storage state, or protected-evidence contents.

## Elastic PR and commit budget

Set a budget that is finite yet matches the repair risk:

- start with one primary PR and a small implementation/test commit allowance;
- permit an additional PR or corrective commit only for a deterministic defect
  adjacent to the accepted change;
- require the primary change to merge and a fresh deterministic observation
  before consuming the adjacent-fix allowance; and
- stop for owner authorization when the defect crosses the declared component,
  data contract, security boundary, runtime, or deployment scope.

An elastic budget changes the count within a declared envelope; it never turns
an unrelated discovery into an automatic authorization.

## Adjacent-fix authorization

An adjacent fix is permitted only when all of these are true:

1. the primary mutation is accepted or its failure is deterministically
   classified;
2. the new defect is in the same declared component or direct binding edge;
3. no protected boundary changes, including production, credentials, identity,
   repository ownership, or unrelated UI/data semantics;
4. the Goal states the maximum additional PRs and commits; and
5. the next validation can distinguish the adjacent fix from the primary one.

Otherwise, record the evidence pointer and stop for a new Goal or owner
decision.

## Risk-tier validation

Choose validation from the risk of the delta, not from the amount of history:

| Risk tier | Typical delta | Minimum validation |
| --- | --- | --- |
| 0 — documentation | Governance text only | Markdown links, formatting, secret scan, diff/scope check |
| 1 — local deterministic | Isolated code or configuration binding | Focused tests plus exact source binding |
| 2 — CI or integration | Repository integration or runner-dependent change | Exact-head proof, causal CI accounting, and fresh acceptance |
| 3 — runtime or deployment | Canary runtime, auth path, or release binding | Full runtime-binding proof, bounded rollback proof, and owner gate |
| 4 — protected or production | Production, identity, credentials, or protected evidence | Separate explicit authorization; do not infer permission from this pattern |

Higher-tier proof does not make lower-tier history a new task. It only proves
the current delta at the correct boundary.

## Bounded hard stops

Every resume Goal must stop immediately on:

- base, identity, or durable-state pointer drift;
- dirty or locked state outside the accepted scope;
- a new defect outside the declared adjacent-fix envelope;
- exhausted PR, commit, retry, or rollback budget;
- failed required proof or an ambiguous result; or
- any production, credential, identity, protected-evidence, or unrelated
  repository expansion.

The hard-stop receipt records the accepted checkpoint, sanitized observed
classification, unchanged boundaries, and the decision required to continue.

## Recommended Goal size and structure

Prefer one Goal per accepted delta and one primary completion boundary. A Goal
should normally contain:

1. immutable admission and durable-state pointers;
2. one compact Accepted Delta;
3. an exact mutation surface and non-goals;
4. elastic but finite PR/commit and retry budgets;
5. risk-tier validation with an exact expected result;
6. bounded hard stops; and
7. a compact completion or stop receipt.

If the Goal needs a narrative chronology to be understandable, replace the
chronology with pointers and split the next delta into a separate Goal. A
resume pattern does not authorize a new Wave, a broader repository set, or
unbounded corrective work.
