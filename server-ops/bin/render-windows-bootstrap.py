#!/usr/bin/env python3
"""Render the Windows Edge Hermes bootstrap from the repo-local template."""

from __future__ import annotations

import argparse
from pathlib import Path


DEFAULTS = {
    "laptop-zenbookduo": {
        "wireguard_ip": "10.66.0.21",
        "edge_port": "8642",
    }
}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def render(device: str, wireguard_ip: str, edge_port: str) -> str:
    template_path = (
        repo_root()
        / "server-ops"
        / "edge-hermes"
        / "templates"
        / "windows-bootstrap.ps1.tmpl"
    )
    template = template_path.read_text(encoding="utf-8")
    replacements = {
        "{{DEVICE_NAME}}": device,
        "{{WIREGUARD_IP}}": wireguard_ip,
        "{{EDGE_PORT}}": edge_port,
    }
    for marker, value in replacements.items():
        template = template.replace(marker, value)
    return template


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("device")
    parser.add_argument("--wireguard-ip")
    parser.add_argument("--edge-port", default=None)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    defaults = DEFAULTS.get(args.device, {})
    wireguard_ip = args.wireguard_ip or defaults.get("wireguard_ip", "10.66.0.21")
    edge_port = args.edge_port or defaults.get("edge_port", "8642")
    content = render(args.device, wireguard_ip, edge_port)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8", newline="\n")
    else:
        print(content, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
