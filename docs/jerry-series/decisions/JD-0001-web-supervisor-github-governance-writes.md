# JD-0001: Web supervisor may write governance documentation

Status: Accepted  
Scope: Jerry Series / governance documentation  
Date: 2026-07-18

## Context

The Jerry series workflow separates supervisory architecture work from local implementation work.

The web conversation with ChatGPT is used to supervise, design, review, and coordinate cross-repository plans. Local Codex is used to operate product repositories, run local tests, manage worktrees, handle protected evidence, and perform subsystem implementation.

Previous waves showed that design experience should not remain only in chat context. It needs durable, reviewable storage in GitHub.

## Decision

ChatGPT web may perform GitHub operations for governance documentation in `JerrySkywalker/dev_governance_files`, including:

- creating docs-only branches;
- writing governance Markdown files;
- opening docs-only pull requests;
- creating or updating governance issues, labels, milestones, and PR descriptions when explicitly requested.

ChatGPT web may also perform read-only GitHub inspection of product repositories and may create product-repository issues or comments when requested.

The following remain local-Codex responsibilities:

- product repository code changes;
- local Git operations;
- worktree cleanup;
- archive tags;
- CI execution and recovery;
- protected evidence movement;
- local path inspection;
- runner service operations;
- production or runtime operations.

## Rationale

Governance documentation is a supervisory artifact. It is closer to architecture memory than to product implementation. Requiring local Codex for every small governance note adds delay and increases the chance that lessons remain only in chat.

Product code, evidence, and CI state are different: they depend on local filesystems, worktrees, runners, and protected evidence. They remain under local Codex control.

## Rules

1. Web-originated GitHub writes must be docs-only unless a separate explicit authorization is given.
2. Product repositories remain read-only from the web except for issues, comments, and reviews.
3. Web-created PRs must state that no product code, CI, production system, or protected evidence was touched.
4. Sensitive content must be summarized, not copied.
5. Raw logs, credentials, headers, tokens, protected evidence descendants, and private runtime payloads must not be committed.
6. When a task needs local verification, route it to local Codex.

## Consequences

This creates a durable governance memory layer:

```text
ChatGPT web = supervisor / architect / governance writer
Local Codex = implementer / subsystem architect / local verifier
GitHub = shared governance memory and audit ledger
```

The rule can be revised later if governance writes need stronger local validation.
