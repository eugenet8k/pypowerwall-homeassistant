#!/bin/sh
# Home Assistant add-on entrypoint.
#
# Reads /data/options.json (written by the HA Supervisor),
# exports every key=value as an environment variable, then
# exec's the original upstream CMD.

set -e

CONFIG="/data/options.json"

echo "[ha-addon] Starting entrypoint..."
echo "[ha-addon] CMD args: $*"
echo "[ha-addon] Working dir: $(pwd)"

if [ -f "$CONFIG" ]; then
    echo "[ha-addon] Loading configuration from $CONFIG"

    # Use python3 for reliable JSON parsing (available in pypowerwall image)
    eval "$(python3 -c "
import json, shlex
with open('$CONFIG') as f:
    opts = json.load(f)
for k, v in opts.items():
    if isinstance(v, bool):
        v = 'true' if v else 'false'
    print(f'export {k}={shlex.quote(str(v))}')
")"

    # Mirror PW_TIMEZONE → TZ
    if [ -n "$PW_TIMEZONE" ] && [ -z "$TZ" ]; then
        export TZ="$PW_TIMEZONE"
    fi

    echo "[ha-addon] Configuration loaded"
else
    echo "[ha-addon] No $CONFIG found, starting with default env"
fi

# Exec the CMD passed by Docker (inherited from upstream image)
if [ $# -gt 0 ]; then
    echo "[ha-addon] Executing: $*"
    exec "$@"
else
    # Fallback: upstream pypowerwall default
    echo "[ha-addon] No CMD inherited, falling back to: python3 server.py"
    exec python3 server.py
fi
