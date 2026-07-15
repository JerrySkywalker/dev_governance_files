# Process-isolated repository-health manifest coordinator

`Invoke-RepoHealthManifestCoordinator.ps1` adds a versioned manifest control plane without changing the legacy queue-file coordinator or its v1 state and envelope schemas.

It validates the manifest, live routing, and W1-S01 receipt before creating a durable manifest state. Every external role launch is delivered through standard input, uses the mapped profile with an explicit working directory, and rejects sandbox, approval, and bypass overrides. Process stdout and stderr are never persisted; only validated v2 envelopes and bounded counters are durable.

An Implementer product phase must hold both `product-writer.lock` and the repository lock. Architect, Supervisor, Auditor, and Mechanical envelopes reject Git or product-source mutations. A deadline with fewer than 45 minutes remaining prevents a new phase; `Stop` writes a resumable safe-pause request.

The manifest control plane is deliberately separate from `start-overnight-run.ps1` and `start-foreground-run.ps1`; those runners are not part of this interactive TUI path.
