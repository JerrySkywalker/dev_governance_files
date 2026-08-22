# JD-0006: Public repository naming policy

Status: Accepted  
Scope: JerrySkywalker repository naming and visibility  
Date: 2026-08-22

## Decision

Use the `jerry-` prefix only for Jerry-private, internal, or personal
repositories. Such repositories are private by default.

Reusable infrastructure and public product repositories use a neutral name.
They are public only when an explicit project policy or release decision says
that public distribution is intended.

This is a naming and visibility convention, not a blanket instruction to change
existing repository visibility. Existing repositories are assessed individually
so that consumer links, operational ownership, and release history are not
broken by an unattended mass change.

## Applied migration

The public `JerrySkywalker/jerry-terminal-ui` repository was an accidental
prefix/visibility mismatch. Its history-preserving repository rename to
`JerrySkywalker/terminal-ui-contract` is the corrective migration for the
shared public terminal UI contract.

## Audit record

The 2026-08-22 inventory found the remaining `jerry-*` repositories private
except for `JerrySkywalker/jerry-telemetry-agent`. That public repository is an
anomaly for separate owner-aware classification; this decision does not change
its visibility or name.

## Consequences

- New public crates and reusable infrastructure must not use a `jerry-*`
  package name.
- A repository rename is preferred over duplication when preserving public
  history, issues, pull requests, and releases matters.
- A neutral repository may remain private unless its own project policy
  explicitly selects public distribution.
