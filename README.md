# dev_governance_files

[简体中文](README.zh-CN.md)

Versioned governance, Harness, playbooks, plans, and engineering lessons for
Jerry's local/cloud development workflow.

## What is active

The repository now has an explicit Agent context contract. Not every document is
an execution instruction.

- `AGENTS.md` — short Agent routing and safety instructions.
- `.agent/context-manifest-v1.json` — machine-readable context classification.
- `docs/jerry-series/harness/` — active Repository-Health Harness specification.
- `config/repo-health-harness-v1.json` — the only active Harness numeric source.
- `docs/jerry-series/playbooks/` — conditional operational methods.
- `docs/jerry-series/decisions/` — accepted normative rationale.
- `docs/jerry-series/retrospectives/` — historical Wave and incident lessons.
- `docs/jerry-series/plans/` — historical or explicitly bound plans; not defaults.

Start Harness work at
[`docs/jerry-series/harness/README.md`](docs/jerry-series/harness/README.md).

Windows workstation directory and Python/uv/Conda bootstrap governance is at
[`WINDOWS_DEV_BOOTSTRAP_V2.md`](WINDOWS_DEV_BOOTSTRAP_V2.md). Its directory
manifest is the source of truth; its bootstrap entrypoint is topology-only and
does not mutate a workstation's package, profile, dotfiles, or device state.

## Agent context classes

| Class | Default behavior |
| --- | --- |
| `AGENT_INSTRUCTION` | automatically discovered short instructions |
| `ACTIVE_NORMATIVE` | read when the task matches; current source of truth |
| `CONDITIONAL_OPERATIONAL` | read only when environment/layer conditions match |
| `ACTIVE_NORMATIVE_RATIONALE` | read to understand accepted policy decisions |
| `HISTORICAL_REFERENCE` | explicit historical review only; never execute |
| `ARCHIVE_EXPLICIT_ONLY` | explicit audit or current Goal binding only |
| `MACHINE_GENERATED` | edit through source/generator only |

## Harness identifiers

```text
MODEL_ID=JERRY_HARNESS_MODEL_V1
BASELINE_ID=JERRY_AUTONOMY_CI_PARAMS_V1
CONTEXT_MANIFEST_ID=JERRY_AGENT_CONTEXT_V1
```

The Harness is expressed as:

```text
Version selectors
+ Control vector <A,B,P>
+ Operational layer L
+ Proof vector <V,E,F,G>
+ Domain budget ledger
+ Goal scope
+ Current receipt state
```

## Safe development workflow

1. Classify the task and read only the routed context.
2. Preserve active/historical boundaries.
3. Make focused changes.
4. Run the relevant contract tests.
5. Inspect the complete diff and generated-file drift.
6. Commit through a reviewed branch and pull request.

## Validation

Harness and Agent-context changes should run:

```powershell
pwsh -NoProfile -File .\tests\repo-health\Test-RepoHealthHarnessContract.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-WriterLeaseV1Settlement.ps1
pwsh -NoProfile -File .\tests\repo-health\Test-AgentContextContract.ps1
pwsh -NoProfile -File .\scripts\repo-health\Build-RepoHealthHarnessReference.ps1 -Check
pwsh -NoProfile -File .\scripts\repo-health\Build-AgentContextAdapters.ps1 -Check
pwsh -NoProfile -File .\tests\windows-dev\Test-WindowsDevBootstrap.ps1
```

Existing project-specific tests remain applicable to their own changed surfaces.

## Safety boundary

Merging this repository does not authorize or perform product deployment,
Production mutation, credential acquisition, authentication-policy changes,
runner recovery, protected-evidence access, or W8/W9 execution.

## License

MIT. See `LICENSE`.
