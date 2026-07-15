# Repository-Health Governance Rules

## Branch Model

'main' is the stable source-integration branch. 'dev' is currently absent and must not be created unless a real tested-integration need appears. Every other branch is short-lived.

## Branch Target Rules

This repository owns governance source and deterministic coordinator code; it does not own product repositories. Product-repository writes require their own later repository-health Goal. Production mutation is prohibited.

## Short-Lived Branch Lifecycle

Create, implement, validate, audit, PR, merge to 'main' or a justified 'dev', delete the remote branch, delete the local branch, then remove its worktree. Unmerged work receives exactly one finite classification: 'MERGE_TO_MAIN', 'MERGE_TO_DEV', 'CLOSE_SUPERSEDED', 'ARCHIVE_TAG_AND_CLOSE', 'DELETE_NO_UNIQUE_COMMITS', or 'HOLD_EXTERNAL_EVIDENCE'.

## Single-Writer Rule

One root implementer is the only workspace and Git writer. Supporting agents are read-only. The coordinator must be deterministic and must acquire one repository lock before a writer session starts.

## Agent Allocation

Repository-health Goals use one root implementer and at most seven direct read-only subagents. Recursive subagents are prohibited. A supervisor is product-repository read-only and may create only governance state and bounded follow-up Goals.

## Blocker Handling

The first repeated blocker requires architect-first analysis; the second requires architect plus adversarial audit; the third requires a human. High-risk classifications escalate immediately. Do not persist raw diagnostics, secrets, environment values, private paths, or private connection metadata.

## Repository-Specific Preservation Rules

Do not modify unrelated Edge, SSH, MATLAB, or legacy governance artifacts. The existing remote-only 'governance/ssh-key-store' branch is held for a later repository-health classification and is not part of Wave 0.
