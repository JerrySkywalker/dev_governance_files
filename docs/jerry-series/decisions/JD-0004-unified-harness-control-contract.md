# JD-0004: Unified Harness control and Agent context contract

- Status: Accepted
- Date: 2026-07-30
- Scope: Jerry repository-health governance

## Context

Wave 7 experience produced strong but duplicated documents for autonomous
budgets, validation depth, CI topology, and empirical defaults. Numeric values
began to diverge, and Agents lacked a reliable way to distinguish active
specification, conditional operations, and historical evidence.

## Decision

Adopt one versioned Harness system:

```text
Harness = <A,B,P> + L + <V,E,F,G> + domain ledgers + Goal scope + Receipt state
```

The following ownership is mandatory:

```text
semantic source:
  docs/jerry-series/harness/harness-specification-v1.md

numeric source:
  config/repo-health-harness-v1.json

human rationale:
  docs/jerry-series/harness/harness-baseline-v1.md

Goal and Receipt interface:
  docs/jerry-series/harness/harness-goal-receipt-contract-v1.md

Agent routing:
  AGENTS.md
  .agent/context-manifest-v1.json
```

Retrospectives and old Plans remain historical evidence and cannot supply active
defaults. Tool-specific Agent files are adapters, not independent policy.

## Consequences

- `P_INIT` distinguishes admission from a no-progress cycle.
- Six Profiles load defaults without creating authority.
- Every Profile explicitly defines zero-valued prohibited budget domains.
- Frozen parameters require a new baseline version and explicit governance.
- Agents use progressive context loading rather than recursive document loading.
- Ignore files are not security boundaries.
- Active parameter duplication is a contract-test failure.

## Supersession

The semantic and numeric content formerly stored in:

- `patterns/elastic-autonomous-execution-budget-pattern.md`;
- `patterns/validation-depth-and-gate-selection.md`; and
- `patterns/autonomous-budget-and-ci-hyperparameter-baseline.md`

is superseded by the unified Harness sources above.

## Non-goals

This decision does not authorize product changes, runner mutation, Production
contact, credentials, protected evidence access, W8, or W9.
