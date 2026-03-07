#!/usr/bin/env python3
"""Home Assistant add-on entrypoint.

Reads configuration from /data/options.json (written by the HA Supervisor),
exports every key as an environment variable, then exec's the original
upstream CMD so the wrapped Docker image runs exactly as intended.
"""

import json
import os
import sys

CONFIG_PATH = "/data/options.json"


def load_options() -> dict:
    """Load add-on options written by the HA Supervisor."""
    if not os.path.isfile(CONFIG_PATH):
        return {}
    with open(CONFIG_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def export_options(options: dict) -> None:
    """Set every option as an environment variable."""
    for key, value in options.items():
        if isinstance(value, bool):
            value = "true" if value else "false"
        os.environ[key] = str(value)

    # Mirror PW_TIMEZONE → TZ so the container picks up the right timezone
    tz = options.get("PW_TIMEZONE")
    if tz:
        os.environ.setdefault("TZ", str(tz))


def main() -> None:
    options = load_options()
    export_options(options)

    # Log what we're about to run (skip secrets)
    safe = {k: ("***" if "pass" in k.lower() else v) for k, v in options.items()}
    print(f"[ha-addon] Configuration: {json.dumps(safe)}", flush=True)

    if len(sys.argv) > 1:
        # Exec the CMD inherited from the upstream image
        os.execvp(sys.argv[1], sys.argv[1:])
    else:
        # Fallback: default pypowerwall startup
        print("[ha-addon] No CMD inherited — falling back to python3 -u server.py",
              flush=True)
        os.execvp("python3", ["python3", "-u", "server.py"])


if __name__ == "__main__":
    main()
