#!/usr/bin/env bash
set -euo pipefail

AGENTS_JSON="/home/ubuntu/.hermes/edge-hermes/agents.json"
WG_CLIENTS="/opt/server-ops/wireguard/clients.tsv"
STATUS_CENTER="/opt/server-ops/bin/status-center.py"
DOCS_DIR="/opt/server-ops/docs"
EDGE_DOCS_DIR="/opt/server-ops/edge-hermes/docs"

usage() {
  cat <<'USAGE'
Hermes Edge Admin

Usage:
  sudo /opt/server-ops/bin/hermes-edge-admin.sh list
  sudo /opt/server-ops/bin/hermes-edge-admin.sh show <device>
  sudo /opt/server-ops/bin/hermes-edge-admin.sh status
  sudo /opt/server-ops/bin/hermes-edge-admin.sh docs
  sudo /opt/server-ops/bin/hermes-edge-admin.sh render-windows-bootstrap <device>
  sudo /opt/server-ops/bin/hermes-edge-admin.sh check-bootstrap-template <device>
  sudo /opt/server-ops/bin/hermes-edge-admin.sh add-device
  sudo /opt/server-ops/bin/hermes-edge-admin.sh staged-devices
  sudo /opt/server-ops/bin/hermes-edge-admin.sh help

Commands:
  list           List registered edge agents and WireGuard clients.
  show DEVICE    Show safe details for one device. API keys are never printed.
  status         Run Status Center.
  docs           List server-ops runbook documents.
  render-windows-bootstrap DEVICE
                 Generate Windows edge bootstrap template. No API key is embedded.
  check-bootstrap-template DEVICE
                 Render and validate generated Windows bootstrap template.
  add-device     Interactively create a draft onboarding plan. Does not modify live configs.
  staged-devices List staged onboarding plans.
  help           Show this help.

Safety:
  This v0.1 script does not modify live WireGuard, agents.json, keys, or Hermes .env.
  It may write draft onboarding files under /opt/server-ops/edge-hermes/generated.
USAGE
}

require_root_hint() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "WARN: This command is designed to run with sudo for root-only server-ops paths." >&2
  fi
}

list_devices() {
  require_root_hint

  echo "== Edge Hermes agents =="
  if [[ -f "$AGENTS_JSON" ]]; then
    python3 - "$AGENTS_JSON" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text(encoding="utf-8"))
agents = data.get("agents", {})

if not agents:
    print("(none)")
else:
    print(f"{'NAME':<24} {'IP':<14} {'URL':<28} {'KEY_LEN':<7} ROLE")
    for name, a in sorted(agents.items()):
        url = a.get("url", "")
        ip = url.replace("http://", "").replace("https://", "").split(":")[0]
        key_len = len(a.get("key", ""))
        role = a.get("role", "")
        if len(role) > 48:
            role = role[:45] + "..."
        print(f"{name:<24} {ip:<14} {url:<28} {key_len:<7} {role}")
PY
  else
    echo "(agents.json not found: $AGENTS_JSON)"
  fi

  echo
  echo "== WireGuard clients =="
  if [[ -f "$WG_CLIENTS" ]]; then
    if [[ -s "$WG_CLIENTS" ]]; then
      awk -F '\t' 'BEGIN { printf "%-24s %-14s %s\n", "NAME", "IP", "CREATED_OR_NOTE" } { printf "%-24s %-14s %s\n", $1, $2, $3 }' "$WG_CLIENTS"
    else
      echo "(empty)"
    fi
  else
    echo "(clients.tsv not found: $WG_CLIENTS)"
  fi
}

show_device() {
  require_root_hint

  local device="${1:-}"
  if [[ -z "$device" ]]; then
    echo "ERROR: device name required." >&2
    usage
    exit 2
  fi

  if [[ ! -f "$AGENTS_JSON" ]]; then
    echo "ERROR: agents.json not found: $AGENTS_JSON" >&2
    exit 1
  fi

  python3 - "$AGENTS_JSON" "$WG_CLIENTS" "$device" <<'PY'
import json
import sys
from pathlib import Path

agents_path = Path(sys.argv[1])
wg_path = Path(sys.argv[2])
name = sys.argv[3]

data = json.loads(agents_path.read_text(encoding="utf-8"))
agents = data.get("agents", {})

if name not in agents:
    print(f"ERROR: edge agent not found: {name}", file=sys.stderr)
    print("Known agents:")
    for n in sorted(agents):
        print(f"  {n}")
    raise SystemExit(2)

a = agents[name]
url = a.get("url", "")
ip = url.replace("http://", "").replace("https://", "").split(":")[0]

print(f"Device: {name}")
print(f"URL: {url}")
print(f"IP: {ip}")
print(f"Key length: {len(a.get('key', ''))}")
print(f"Role: {a.get('role', '')}")
print(f"Aliases: {len(a.get('aliases', []))}")
print(f"Capabilities: {', '.join(a.get('capabilities', []))}")

print()
print("WireGuard registry:")
found = False
if wg_path.exists():
    for line in wg_path.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.split("\t")
        if len(parts) >= 2 and (parts[0] == name or parts[1] == ip):
            print("  " + line)
            found = True
if not found:
    print("  (no matching clients.tsv row)")

print()
print("Sensitive fields:")
print("  API key: hidden")
print("  WireGuard private key: hidden")
PY

  echo
  echo "Health check:"
  local url
  url="$(python3 - "$AGENTS_JSON" "$device" <<'PY'
import json, sys
from pathlib import Path
data=json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(data["agents"][sys.argv[2]].get("url","").rstrip("/"))
PY
)"
  if [[ -n "$url" ]]; then
    curl -sS --max-time 10 "$url/health" || true
    echo
  else
    echo "(no URL)"
  fi
}

status_center() {
  require_root_hint

  if [[ -x "$STATUS_CENTER" ]]; then
    "$STATUS_CENTER"
  else
    echo "ERROR: status-center.py not executable or not found: $STATUS_CENTER" >&2
    exit 1
  fi
}

list_docs() {
  require_root_hint

  echo "Server-ops docs:"
  find "$DOCS_DIR" "$EDGE_DOCS_DIR" \
    -maxdepth 1 -type f -name "*.md" -printf "  %p\n" 2>/dev/null | sort || true
}

render_windows_bootstrap() {
  require_root_hint

  local device="${1:-}"
  if [[ -z "$device" ]]; then
    echo "ERROR: device name required." >&2
    usage
    exit 2
  fi

  /opt/server-ops/bin/render-windows-bootstrap.py "$device"
}

add_device() {
  require_root_hint
  /opt/server-ops/bin/stage-edge-device.py
}

staged_devices() {
  require_root_hint

  local root="/opt/server-ops/edge-hermes/generated/devices"
  echo "Staged edge devices:"
  if [[ ! -d "$root" ]]; then
    echo "  (none)"
    return 0
  fi

  local plans
  plans="$(find "$root" -mindepth 2 -maxdepth 2 -name "device-plan.json" -print 2>/dev/null | sort || true)"

  if [[ -z "$plans" ]]; then
    echo "  (none)"
    return 0
  fi

  printf "%s\n" "$plans" | while read -r plan; do
    python3 - "$plan" <<'PY2'
import json, sys
from pathlib import Path
p=Path(sys.argv[1])
data=json.loads(p.read_text(encoding="utf-8"))
print(f"  {data.get('device','?'):<24} {data.get('wireguard_ip','?'):<14} {data.get('device_type','?'):<8} {data.get('created_at','')}")
PY2
  done
}


check_bootstrap_template() {
  require_root_hint

  local device="${1:-}"
  if [[ -z "$device" ]]; then
    echo "ERROR: device name required." >&2
    usage
    exit 2
  fi

  local file="/opt/server-ops/edge-hermes/generated/${device}-windows-bootstrap.ps1"
  local fail=0

  echo "Rendering bootstrap template for: $device"
  /opt/server-ops/bin/render-windows-bootstrap.py "$device"

  if [[ ! -f "$file" ]]; then
    echo "[FAIL] generated file not found: $file"
    return 1
  fi

  echo
  echo "Checking: $file"

  check_required() {
    local pattern="$1"
    local label="$2"

    if grep -Fq "$pattern" "$file"; then
      echo "[OK] $label"
    else
      echo "[FAIL] missing: $label"
      fail=$((fail+1))
    fi
  }

  check_absent() {
    local pattern="$1"
    local label="$2"

    if grep -Fq "$pattern" "$file"; then
      echo "[FAIL] forbidden legacy marker exists: $label"
      fail=$((fail+1))
    else
      echo "[OK] absent: $label"
    fi
  }

  check_required 'Write-Step "Apply known-good Gateway and Watchdog logic"' "known-good override block"
  check_required 'HERMES_GIT_BASH_PATH' "Git Bash path hardening"
  check_required 'Start-Process -FilePath' "detached gateway Start-Process"
  check_required '"gateway", "run", "--replace"' "gateway run --replace"
  check_required 'path_precedence = [ordered]@{' "file policy path_precedence"
  check_required 'aiohttp' "aiohttp dependency check"

  check_absent 'Write-Step "Create hidden gateway runner"' "legacy gateway runner block"
  check_absent 'Write-Step "Create watchdog"' "legacy watchdog block"
  check_absent '$_.CommandLine -like "*hermes-edge*"' "unsafe process match pattern"

  if grep -Eq '[A-Fa-f0-9]{64}' "$file"; then
    echo "[FAIL] possible embedded 64-character hex secret found"
    fail=$((fail+1))
  else
    echo "[OK] no embedded 64-character hex secret"
  fi

  echo
  if [[ "$fail" -eq 0 ]]; then
    echo "Bootstrap template check: OK"
    return 0
  else
    echo "Bootstrap template check: FAIL=$fail"
    return 1
  fi
}


cmd="${1:-help}"
case "$cmd" in
  list)
    list_devices
    ;;
  show)
    show_device "${2:-}"
    ;;
  status)
    status_center
    ;;
  docs)
    list_docs
    ;;
  render-windows-bootstrap)
    render_windows_bootstrap "${2:-}"
    ;;
  check-bootstrap-template)
    check_bootstrap_template "${2:-}"
    ;;
  add-device)
    add_device
    ;;
  staged-devices)
    staged_devices
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "ERROR: unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
