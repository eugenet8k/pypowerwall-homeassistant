#!/bin/sh
# Home Assistant add-on entrypoint.
#
# Reads /data/options.json (written by the HA Supervisor),
# exports every key=value as an environment variable, then
# exec's the original upstream CMD.

CONFIG="/data/options.json"

if [ -f "$CONFIG" ]; then
    # Parse each top-level key/value from the JSON and export as env vars.
    # Works with any POSIX shell — no jq or python required.
    # Handles string, number, and boolean values.
    eval "$(
        sed -e 's/^{//' -e 's/}$//' -e 's/^ *//' "$CONFIG" \
        | grep -v '^\s*$' \
        | sed -e 's/^"\([^"]*\)": *"\(.*\)".*$/export \1="\2"/' \
              -e 's/^"\([^"]*\)": *\([0-9][0-9]*\).*$/export \1="\2"/' \
              -e 's/^"\([^"]*\)": *true.*$/export \1="true"/' \
              -e 's/^"\([^"]*\)": *false.*$/export \1="false"/'
    )"

    # Mirror PW_TIMEZONE → TZ
    if [ -n "$PW_TIMEZONE" ] && [ -z "$TZ" ]; then
        export TZ="$PW_TIMEZONE"
    fi

    echo "[ha-addon] Configuration loaded from $CONFIG"
fi

# Exec the CMD passed by Docker (inherited from upstream image)
exec "$@"
