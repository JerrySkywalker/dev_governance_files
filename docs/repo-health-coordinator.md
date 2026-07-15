# Deterministic dual-Codex repository-health coordinator

The coordinator is a dependency-free PowerShell module with Plan, Start, Resume, Status, Audit, and DryRun modes. It owns governance state, one repository lock, and one writer-session admission; it never owns product source.

Automatic noninteractive launch is deliberately disabled for Wave 0 because local hapi resolves to the documented Codex CLI help rather than a distinct supported launcher. Plan and Start generate deterministic implementer and supervisor queue files for manual attach. The generated constraints are agents.max_threads=8, agents.max_depth=1, and features.multi_agent_v2.max_concurrent_threads_per_session=8.

State is JSON written through same-volume atomic replacement. Result envelopes are sanitized and supervisors are rejected if they claim product writes or Git mutation. Blockers are fingerprints of only the seven finite fields in the blocker schema. First occurrence requests architect analysis, second requests architect plus adversarial audit, third reaches HUMAN_REQUIRED; high-risk classes escalate immediately.

Run the no-dependency synthetic harness with:

    pwsh -NoProfile -File tests/repo-health/Test-RepoHealthCoordinator.ps1

The harness uses temporary synthetic repositories only and removes its fixture root in a finally block.
