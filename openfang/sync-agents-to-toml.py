#!/usr/bin/env python3
"""Sync OpenFang agents from DB to TOML files on disk.

UI-created agents only exist in the database and get lost if the DB is cleared.
This script exports them as TOML files so they load on boot like disk-based agents.

Usage: python3 sync-agents-to-toml.py [--db PATH] [--agents-dir PATH] [--dry-run]
"""

import argparse
import os
import sqlite3
import sys

try:
    import msgpack
except ImportError:
    print("Error: python3-msgpack required. Install with: sudo apt install python3-msgpack")
    sys.exit(1)


def manifest_to_toml(data):
    """Convert a msgpack manifest dict to TOML string."""
    lines = []

    # Top-level scalar fields
    for key in ["name", "version", "description", "author", "module"]:
        if key in data and data[key] is not None:
            lines.append(f'{key} = "{data[key]}"')

    if "tags" in data and data["tags"]:
        tags = ", ".join(f'"{t}"' for t in data["tags"])
        lines.append(f"tags = [{tags}]")

    lines.append("")

    # [model] section
    if "model" in data:
        m = data["model"]
        lines.append("[model]")
        if m.get("base_url"):
            lines.append(f'base_url = "{m["base_url"]}"')
        if m.get("provider"):
            lines.append(f'provider = "{m["provider"]}"')
        if m.get("model"):
            lines.append(f'model = "{m["model"]}"')
        if m.get("api_key_env"):
            lines.append(f'api_key_env = "{m["api_key_env"]}"')
        if m.get("max_tokens"):
            lines.append(f"max_tokens = {m['max_tokens']}")
        if m.get("temperature") is not None:
            lines.append(f"temperature = {m['temperature']}")
        if m.get("system_prompt"):
            lines.append(f'system_prompt = """{m["system_prompt"]}"""')
        lines.append("")

    # [[fallback_models]]
    for fb in data.get("fallback_models", []) or []:
        lines.append("[[fallback_models]]")
        if fb.get("provider"):
            lines.append(f'provider = "{fb["provider"]}"')
        if fb.get("model"):
            lines.append(f'model = "{fb["model"]}"')
        if fb.get("base_url"):
            lines.append(f'base_url = "{fb["base_url"]}"')
        if fb.get("api_key_env"):
            lines.append(f'api_key_env = "{fb["api_key_env"]}"')
        lines.append("")

    # [resources]
    if "resources" in data and data["resources"]:
        r = data["resources"]
        lines.append("[resources]")
        for k, v in r.items():
            if v is not None:
                lines.append(f"{k} = {v}")
        lines.append("")

    # [capabilities]
    if "capabilities" in data and data["capabilities"]:
        c = data["capabilities"]
        lines.append("[capabilities]")
        for k, v in c.items():
            if v is not None and isinstance(v, list):
                items = ", ".join(f'"{i}"' for i in v)
                lines.append(f"{k} = [{items}]")
        lines.append("")

    # [autonomous]
    if "autonomous" in data and data["autonomous"]:
        a = data["autonomous"]
        lines.append("[autonomous]")
        for k, v in a.items():
            if v is not None:
                lines.append(f"{k} = {v}")
        lines.append("")

    # [exec_policy]
    if "exec_policy" in data and data["exec_policy"]:
        ep = data["exec_policy"]
        lines.append("[exec_policy]")
        if isinstance(ep, dict):
            for k, v in ep.items():
                if isinstance(v, str):
                    lines.append(f'{k} = "{v}"')
                elif v is not None:
                    lines.append(f"{k} = {v}")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Sync OpenFang agents from DB to TOML")
    parser.add_argument("--db", default=os.path.expanduser("~/.openfang/data/openfang.db"))
    parser.add_argument("--agents-dir", default=os.path.expanduser("~/.openfang/agents"))
    parser.add_argument("--dry-run", action="store_true", help="Print what would be done without writing")
    args = parser.parse_args()

    conn = sqlite3.connect(args.db)
    rows = conn.execute("SELECT id, name, manifest FROM agents").fetchall()

    synced = 0
    for agent_id, name, manifest in rows:
        data = msgpack.unpackb(manifest, raw=False)
        slug = name.lower().replace(" ", "-")
        agent_dir = os.path.join(args.agents_dir, slug)
        toml_path = os.path.join(agent_dir, "agent.toml")

        if os.path.exists(toml_path):
            # Already has a TOML — skip
            continue

        toml_content = manifest_to_toml(data)
        model_name = data.get("model", {}).get("model", "unknown")
        provider = data.get("model", {}).get("provider", "unknown")

        if args.dry_run:
            print(f"Would create: {toml_path} ({provider}/{model_name})")
        else:
            os.makedirs(agent_dir, exist_ok=True)
            with open(toml_path, "w") as f:
                f.write(toml_content)
            print(f"Created: {toml_path} ({provider}/{model_name})")
        synced += 1

    conn.close()
    if synced == 0:
        print("All DB agents already have TOML files on disk.")
    else:
        action = "Would sync" if args.dry_run else "Synced"
        print(f"{action} {synced} agent(s).")


if __name__ == "__main__":
    main()
