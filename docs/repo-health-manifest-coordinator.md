# Process-isolated repository-health manifest coordinator

`Invoke-RepoHealthManifestCoordinator.ps1` is the interactive-TUI control plane. It does not use the detached runner scripts.

Each generated Goal starts with one compact JSON header containing the exact binding fields: run, wave, step, phase, role, working directory, repository identity, stable branch, expected SHAs, write surfaces, path, and canonical Goal SHA-256. The SHA covers the header with its SHA field blank plus the complete body; this avoids an impossible self-hash while detecting any header or body change.

Before every launch, `RunStep` reloads the exact manifest and Goal, verifies the header/path/hash/repository/working-directory/role/dependencies/prior milestones/resume state, independently checks the local repository root and GitHub remote, and requires the declared expected-input SHA to equal `HEAD`. Every role receives `codex exec --profile <mapped-profile> -C <header working_directory>` with no sandbox, approval, or bypass override.

Process envelopes are v3 objects with an exact whitelist. Unknown fields, duplicate semantic JSON fields, missing fields, unsafe summaries, unbound identities, malformed SHAs, read-only mutation claims, and missing Supervisor `audited_sha` all fail closed. The coordinator independently compares before/after Git state for non-Implementers.

Implementer launch holds the global writer and repository locks. A post-Implementer candidate SHA is independently observed before a Supervisor Goal is generated. `Assert-RepoHealthBranchStability` rejects moved candidates or a PR/base/audited/expected-merge mismatch before merge. Process stdout/stderr are represented only by bounded counts in a sanitized log.

`tests/repo-health/Test-RepoHealthManifestReadOnlyAudit.ps1 -ExpectedHead <sha>` is the no-write exact-head audit for a Supervisor profile. It exercises the pure binding, envelope, post-Implementer SHA, branch-stability, AST, JSON, and diff checks without creating fixtures. The full synthetic fixture suite remains an Implementer-only proof because it intentionally creates bounded temporary repositories and lock files.
