# Main/Dev Policy V2

Status: ACTIVE
Version: 2.0
Amendment: `W1-R01-MAIN-DEV-POLICY-V2`

This policy is the active governance interpretation for repository-health work. It supersedes the active interpretation of [the preserved V1 policy](../../config/branch-lifecycle-policy.json); it does not rewrite that historical policy or any Wave 1 receipt. The canonical machine-readable form is `policy/main-dev-policy-v2.json`.

## Branch roles

`main` is the accepted and fully validated source baseline. It is safe for downstream contracts, but it does not imply production deployment. Direct push and force-push are prohibited.

`dev` is optional, never mandatory. Create it only for a named integration train containing tested, coherent work that is not yet eligible for `main`. It must name an owner and milestone, have CI, state promotion conditions, and define an exit policy. It must never store historical evidence, speculative ideas, or secrets.

Feature branches are short-lived and target `main` by default. They target `dev` only when the named integration train requires it.

Release is represented by release tags, artifacts, and deployment receipts. A branch name alone is not a release claim.

## Decision rules

Create `dev` only when all relevant conditions support a coherent tested integration candidate: multiple interdependent changes need continuous integration, cross-repository acceptance is still pending, and `main` must remain the stable downstream-contract baseline.

Do not create `dev` when one bounded PR can be fully validated; the only remaining action is production deployment; the content is historical evidence, speculative, or superseded; or no coherent integrated candidate exists.

## Promotion and cleanup

Feature to `dev` requires a PR and exact-head gates. `dev` to `main` requires a dedicated promotion PR, full CI, cross-contract validation, a fresh Supervisor, and equality of the exact audited SHA.

There are no unnamed long-lived branches and no `dev` branch without an active integration train. History is retained through archive tags; follow-up product work is retained through backlog records. Every Wave closes with an explicit `main`/`dev` disposition.

## Admission, evidence, and proof

Admission reports these separate states:

- `TRACKED_CLEAN`: tracked worktree content is clean.
- `APPROVED_PRESERVED_EVIDENCE`: a known preservation surface is present, with a verified ledger and access boundary; it is not unknown dirt.
- `UNKNOWN_DIRT`: unclassified dirt blocks admission.
- `SNAPSHOT_REQUIRED`: the reviewer must not access original worktree evidence and therefore receives a tracked snapshot bound to the exact source SHA and deterministic tree digest.

`SNAPSHOT_REQUIRED` is mandatory whenever original evidence is out of reviewer scope. The snapshot's isolation, SHA binding, and deterministic tree digest must all verify before admission.

Exact-head proof names the literal reviewed PR head, never a synthetic merge. Exact-main proof is a fresh post-merge audit whose audited SHA equals the accepted `main` SHA. A hosted CI claim must identify a passing run for that exact SHA; a local gate is local proof only; a repository without configured CI is reported as `NOT_CONFIGURED`; and neither CI nor `main` proves production deployment.

Native interactive-TUI work is operator-managed: automatic hard timeouts and automatic role-process kills are prohibited.
