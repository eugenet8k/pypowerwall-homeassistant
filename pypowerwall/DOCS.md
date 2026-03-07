# PyPowerwall — Home Assistant Add-on

Runs [jasonacox/pypowerwall](https://github.com/jasonacox/pypowerwall) as a
supervised Home Assistant add-on, giving you a local API proxy and dashboard for
Tesla Powerwall systems.

## Configuration

| Option            | Default               | Description                                             |
| ----------------- | --------------------- | ------------------------------------------------------- |
| `PW_EMAIL`        | _(empty)_             | Tesla account email                                     |
| `PW_PASSWORD`     | _(empty)_             | Tesla account password                                  |
| `PW_HOST`         | _(empty)_             | IP address of the Powerwall Gateway (e.g. `10.0.1.235`) |
| `PW_PORT`         | `8675`                | Port the proxy listens on inside the container          |
| `PW_TIMEZONE`     | `America/Los_Angeles` | Timezone for data display                               |
| `PW_CACHE_EXPIRE` | `5`                   | Cache expiry in seconds                                 |
| `PW_DEBUG`        | `no`                  | Enable verbose debug logging (`yes` / `no`)             |
| `PW_HTTPS`        | `no`                  | Use HTTPS when talking to the Gateway (`yes` / `no`)    |
| `PW_STYLE`        | `solar`               | Dashboard style (e.g. `solar`, `clear`, `grafana`)      |

## Quick start

1. Install the add-on from this repository.
2. Open the **Configuration** tab and fill in at minimum:
   - `PW_EMAIL` — your Tesla account email
   - `PW_PASSWORD` — your Tesla account password
   - `PW_HOST` — the LAN IP of the Powerwall Gateway
3. Click **Save**, then **Start**.
4. The API is available at `http://<your-ha-ip>:8675/`.

## Network access

The add-on needs to reach the Powerwall Gateway on your LAN. By default this
works on most setups. If the gateway is unreachable, try enabling **Host
networking** in the add-on's network settings.

## Useful API endpoints

Once running, you can query the proxy:

```text
GET /api/status
GET /api/system_status/soe
GET /api/meters/aggregates
GET /stats
```

See the upstream
[pypowerwall documentation](https://github.com/jasonacox/pypowerwall) for the
full API reference.
