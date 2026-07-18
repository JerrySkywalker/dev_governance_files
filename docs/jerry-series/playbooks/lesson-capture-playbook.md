# Lesson Capture Playbook

## Purpose

Capture reusable Jerry series design experience into durable GitHub documentation instead of leaving it only in chat history.

## Triggers

Use `CAPTURE_JERRY_LESSONS` when the current conversation produced reusable experience but should not write GitHub yet.

Use `SAVE_JERRY_LESSONS_TO_GITHUB` when the captured lessons should be written to `dev_governance_files` as a docs-only pull request.

Use `CREATE_GOVERNANCE_ISSUE` when the lesson requires follow-up by local Codex or should first be tracked as an issue.

Use `LOCAL_CODEX_REQUIRED` when the work involves product code, local Git state, worktrees, CI, protected evidence, runner state, or production systems.

## Classification

Classify each lesson as one of:

```text
principle       stable cross-wave rule
playbook        executable repeatable process
retrospective   what happened and what changed
decision        durable authority or workflow decision
pattern         reusable Goal, blocker, or evidence template
```

## Capture format

Each captured lesson should include:

```text
title
classification
scope
context
decision_or_rule
operational_steps
non_goals
related_waves
related_repositories
sensitivity_notes
```

## GitHub write path

For docs-only governance updates:

1. Create a short-lived branch in `dev_governance_files`.
2. Write Markdown under `docs/jerry-series/`.
3. Avoid raw logs, secrets, private payloads, protected-evidence descendants, and unredacted local evidence.
4. Open a PR against `main`.
5. State that the PR is docs-only and does not touch product repositories.

## When to avoid direct web writes

Do not use web GitHub writes when the update needs:

- local tests;
- code generation or compilation;
- local filesystem evidence;
- branch/worktree cleanup;
- protected-evidence relocation;
- CI reruns;
- runner service changes;
- production or runtime changes.

Those tasks must be sent to local Codex.

## Review checklist

Before opening a governance lesson PR, verify:

- no credential or token text is included;
- no raw Authorization header or cookie is included;
- no protected evidence child names are included unless already explicitly public and safe;
- no private runtime payload is included;
- each lesson states its operational boundary;
- product code is untouched.
