# Changelog

## 0.1.3

- Switch back to bridge networking so the add-on gets a hostname (`pypowerwall`)
- Port 8675 exposed via standard port mapping

## 0.1.2

- Fix: enable `host_network: true` so port 8675 is reachable and the add-on can
  reach the Powerwall gateway on the LAN

## 0.1.1

- Fix: replaced Python entrypoint with POSIX shell script — upstream image does
  not have `python3` on `$PATH`

## 0.1.0

- Initial release
- Wraps `jasonacox/pypowerwall` as a Home Assistant add-on
- All configuration via the HA add-on UI
