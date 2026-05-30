# Edge Hermes Bootstrap Generator

The Windows Edge Hermes bootstrap is generated locally from:

```text
server-ops/edge-hermes/templates/windows-bootstrap.ps1.tmpl
```

Render it with:

```powershell
python .\server-ops\bin\render-windows-bootstrap.py laptop-zenbookduo --output .\server-ops\edge-hermes\generated\laptop-zenbookduo-windows-bootstrap.ps1
```

The repository workflow is dry-run first. Development and CI render and parse the
PowerShell only; they do not deploy to Windows, register scheduled tasks, modify
firewall rules, stop processes, or write Hermes runtime state.

## Modes

`-Audit` is the default. It resolves and prints environment state only.

`-Plan` prints the files, task executable, health checks, and file access policy
scope that would be used. It performs no writes.

`-Apply` writes the Edge bootstrap files and registers the scheduled task after
confirmation. It may prompt for the Edge API key. Use this only during a manual
deployment window.

`-Repair` repairs generated runner, launcher, watchdog, policy, and task files.
It does not overwrite the API key unless explicitly confirmed.

`-Force` allows confirmations to be bypassed for intentional overwrite or task
registration operations. Pair it with care; it is not used by automated tests.

Optional flags:

```powershell
-NoTask
-NoStart
-NoFirewall
-NonInteractive
```

## Adaptive Resolution

Hermes command resolution order:

```text
1. -HermesCommand
2. Get-Command hermes
3. C:\Dev\tools\bin\hermes.cmd
4. %LOCALAPPDATA%\hermes\hermes-agent\venv\Scripts\hermes.exe
5. Interactive prompt
```

Hermes private Python resolution order:

```text
1. -HermesPython
2. %LOCALAPPDATA%\hermes\hermes-agent\venv\Scripts\python.exe
3. sibling python.exe beside detected hermes.exe
4. Interactive prompt
```

Hermes private Python is diagnostic/runtime state only and must not be added to
`PATH`.

Base Python is resolved only when venv rebuild is explicitly requested:

```text
1. -BasePython
2. %UV_PYTHON_INSTALL_DIR%\cpython-3.11*-windows-*\python.exe
3. C:\Dev\tools\uv-python\cpython-3.11*-windows-*\python.exe
4. py -3.11
5. Interactive prompt
```

The generator must not require or create `C:\Dev\tools\bin\python.exe`.

## Generated Files

The bootstrap initializes these paths before writing files:

```text
%LOCALAPPDATA%\hermes-edge\start-hermes-edge-runner.ps1
%LOCALAPPDATA%\hermes-edge\start-hermes-edge-hidden.vbs
%LOCALAPPDATA%\hermes-edge\watchdog-hermes-edge.ps1
%LOCALAPPDATA%\hermes-edge\watchdog-hermes-edge-hidden.vbs
%LOCALAPPDATA%\hermes-edge\policy\file-access-policy.json
```

The scheduled task uses absolute Windows executables:

```text
C:\Windows\System32\wscript.exe
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Health checks use `curl.exe --noproxy "*"` for localhost and WireGuard URLs.
Plain `curl` can return proxy-related `502 Bad Gateway` responses for private
WireGuard addresses.

## Validation

Run the local generator CI:

```powershell
pwsh -File .\scripts\ci\test-edge-bootstrap-generator.ps1
```

The test renders a sample bootstrap, asserts required adaptive markers, rejects
the legacy fake global Python path, parses the rendered PowerShell with
`[scriptblock]::Create(...)`, and scans for real-looking secrets.
