# dev_governance_files

Personal development governance files for Jerry's local/cloud engineering workflow.

## Purpose

This repository stores versioned governance scripts, templates, runbooks, and tests that should not live directly inside one application repository such as SkyBridge.

It currently covers:

- Windows development directory governance for `C:\Dev` and `V:\`.
- C-only Python / Conda layout scripts.
- SSH key storage guidance and setup helpers.
- MATLAB MCP machine/project setup helpers.
- Edge Hermes server-ops generator, templates, tests, and docs.

## Current Contents

```text
README.md
LICENSE
README_directory_rules_full.md
README_c_drive_rules.md
README_v_drive_rules.md
create_c_dev_structure.ps1
create_c_python_conda_structure.ps1
create_v_devdrive_structure.ps1
docs/
  EDGE_HERMES_BOOTSTRAP_GENERATOR.md
mcp/
  README.md
  matlab/
    install_matlab_mcp_machine.ps1
    setup_project_matlab_mcp.ps1
    README_machine_install.md
    README_project_setup.md
scripts/
  ci/
    test-edge-bootstrap-generator.ps1
secrets/
  ssh/
    setup_ssh_key_store.ps1
    ssh_config.example
    README_ssh_key_store.md
server-ops/
  bin/
    hermes-edge-admin.sh
    render-windows-bootstrap.py
  edge-hermes/
    templates/
      windows-bootstrap.ps1.tmpl
```

## Current Status

The adaptive Windows Edge Hermes bootstrap generator is implemented and tested in dry-run/static mode.

Validated:

- Generated bootstrap parses as PowerShell.
- Generated bootstrap supports `-Audit`, `-Plan`, `-Apply`, and `-Repair`.
- `-Audit` and `-Plan` dry-run paths are tested with fake Hermes runtime files.
- The old `C:\Dev\tools\bin\python.exe` assumption is removed.
- Health checks use proxy bypass patterns to avoid WireGuard/private-IP proxy interception.
- No production deployment has been performed from this repository.

The directory governance, SSH key store, and MATLAB MCP scripts remain local workstation governance helpers. They should stay idempotent and conservative.

## Safe Development Workflow

Use this repository for generator, template, documentation, runbook, and test work.

Do not:

- Run generated Edge bootstrap scripts with `-Apply` or `-Repair` during normal development.
- Stop or restart Edge Hermes.
- Modify Windows Scheduled Tasks.
- Modify SkyBridge from this repository.
- Modify production `/opt/server-ops` directly from local tests.
- Push secrets, private keys, API keys, real `.env` files, WireGuard keys, or production `agents.json`.

Preferred workflow:

1. Make small documentation, script, or template changes.
2. Run targeted local tests.
3. Inspect `git diff`.
4. Commit focused changes.
5. Open a PR for review.

## Test Commands

Edge bootstrap generator test:

```powershell
pwsh -File .\scripts\ci\test-edge-bootstrap-generator.ps1
```

Directory governance scripts are intended to be idempotent. Review each script before running it on a new machine:

```powershell
pwsh -File .\create_c_dev_structure.ps1
pwsh -File .\create_c_python_conda_structure.ps1
pwsh -File .\create_v_devdrive_structure.ps1
```

MATLAB MCP setup helpers:

```powershell
pwsh -File .\mcp\matlab\install_matlab_mcp_machine.ps1
pwsh -File .\mcp\matlab\setup_project_matlab_mcp.ps1 -ProjectRoot "V:\src\your-project"
```

## Production Rollout Warning

Merging this repository does not deploy anything to production.

A future maintenance window is required before copying Edge Hermes generator files to:

```text
/opt/server-ops
```

Production rollout must include backup, render, audit, plan, and manual review before any apply/repair operation.

Do not run generated bootstrap with `-Apply` or `-Repair` until SkyBridge development is not actively depending on Edge Hermes.

## TODO

### P0 - Next Maintenance-Window Tasks

- [ ] Create a production rollout plan for copying the adaptive generator to `/opt/server-ops`.
- [ ] Back up current `/opt/server-ops/bin/hermes-edge-admin.sh` before rollout.
- [ ] Render a bootstrap on the cloud server using the new generator.
- [ ] Review generated bootstrap locally before any execution.
- [ ] Run only `-Audit` and `-Plan` first.
- [ ] Do not run `-Apply` or `-Repair` until SkyBridge development is not actively depending on Edge Hermes.

### P1 - Generator Improvements

- [ ] Move device defaults out of Python constants into a versioned sample config.
- [ ] Support multiple devices without editing code.
- [ ] Add test cases for unknown devices and custom `--wireguard-ip`.
- [ ] Add stronger secret scanning for generated files.
- [ ] Add GitHub Actions CI if useful.

### P2 - Edge Hermes Operations

- [ ] Design a safe `jhermes-update` real maintenance-window test.
- [ ] Document how to restore from known-good Edge Hermes runner/VBS/task.
- [ ] Decide whether watchdog should be enabled by default or kept optional.
- [ ] Document proxy bypass rules for WireGuard/private-IP health checks.

### P3 - SkyBridge Coordination

- [ ] Keep this repository separate from `skybridge-agent-hub`.
- [ ] Do not run Edge bootstrap production rollout during active SkyBridge debugging.
- [ ] After SkyBridge current milestone ends, schedule Edge bootstrap production rollout.

## Reference Docs

- `README_directory_rules_full.md`: overall `C:\Dev` and `V:\` directory governance.
- `README_c_drive_rules.md`: `C:\Dev` responsibilities and anti-patterns.
- `README_v_drive_rules.md`: `V:\` responsibilities and anti-patterns.
- `docs/EDGE_HERMES_BOOTSTRAP_GENERATOR.md`: adaptive Edge Hermes bootstrap generator workflow.
- `mcp/matlab/README_machine_install.md`: machine-level MATLAB MCP install.
- `mcp/matlab/README_project_setup.md`: project-level MATLAB MCP setup.
- `secrets/ssh/README_ssh_key_store.md`: SSH private key storage and OpenSSH config guidance.

## Agent Notes

This section is for coding agents and automation tools.

- Keep this repository as a governance baseline and script toolkit.
- Prefer precise updates over broad rewrites.
- Keep terminology stable: `C:\Dev` is the governance/stable layer; `V:\` is the working/high-IO layer.
- Keep C-only Python / Conda as an explicit mode, not a silent replacement of all cache rules.
- Preserve script idempotency and safe defaults.
- Avoid destructive changes unless explicitly requested and documented.
- Suggested commit prefixes: `docs:`, `scripts:`, `governance:`, `mcp:`, `ops:`.

## License

This repository uses the MIT License. See `LICENSE`.
