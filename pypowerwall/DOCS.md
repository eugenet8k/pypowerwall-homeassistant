# PyPowerwall — Home Assistant Add-on

Runs [jasonacox/pypowerwall](https://github.com/jasonacox/pypowerwall) as a
supervised Home Assistant add-on, giving you a local API proxy and dashboard for
Tesla Powerwall systems.

## Why this add-on?

The official Tesla integrations for Home Assistant (Tesla Solar / Powerwall)
expose common sensors like battery level, solar production, grid power, etc.
However, they **do not** expose advanced electrical metrics such as:

- **Reactive power** (var)
- **Apparent power** (VA)
- **Power factor**
- **Voltage / current per phase**
- **Frequency**

These metrics are available directly from the Powerwall Gateway's local API.
This add-on runs a local proxy that talks to the Gateway and makes all of this
data available via a simple REST API — which you can then consume as **REST
sensors** in Home Assistant.

**Real-world use case:** Tesla Powerwall has a ~5 kVA apparent power limit for
backup mode. If your home's reactive power is high (large AC motors,
compressors, etc.), the Powerwall may refuse to go into backup mode. Monitoring
reactive and apparent power lets you identify and fix these issues.

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
4. Verify the add-on is running (green icon, hostname shown on Info tab).
5. Add REST sensors to your `configuration.yaml` (see examples below).

## API URL — internal vs. external

| Where you're calling from                               | URL to use                                                   |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| **HA `configuration.yaml`** (REST sensors, automations) | `http://04ed3140-pypowerwall:8675/`                          |
| **Browser / LAN devices**                               | `http://homeassistant.local:8675/` or `http://<ha-ip>:8675/` |

> **Important:** The internal hostname (`04ed3140-pypowerwall`) only works
> inside the HA Docker network — from `configuration.yaml`, other add-ons, and
> HA automations. It will **not** resolve from your browser or other LAN
> devices. For those, use the HA host IP with port 8675.
>
> **Note:** The prefix `04ed3140` is unique to each HA installation. Check
> your add-on's **Info** tab for the actual hostname assigned to your instance.

## Useful API endpoints

| Endpoint                 | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| `/aggregates`            | Power data for site, battery, load, solar (includes reactive & apparent power) |
| `/api/status`            | System status                                                                  |
| `/api/system_status/soe` | State of energy (battery %)                                                    |
| `/api/meters/aggregates` | Detailed meter aggregates                                                      |
| `/stats`                 | Proxy statistics                                                               |
| `/help`                  | Full list of all available endpoints                                           |

## REST sensor examples

Add the following to your `configuration.yaml` to create REST sensors from the
proxy's API. All sensors should go under a single `resource` entry to avoid
redundant API calls.

```yaml
rest:
  - resource: http://04ed3140-pypowerwall:8675/aggregates
    scan_interval: 10
    verify_ssl: false
    sensor:
      - name: 'Gateway Site Reactive Power'
        unique_id: gateway_site_reactive_power
        value_template:
          '{{ value_json.site.instant_reactive_power | float | round(0) }}'
        unit_of_measurement: 'var'
        device_class: reactive_power
        state_class: measurement

      - name: 'Gateway Site Apparent Power'
        unique_id: gateway_site_apparent_power
        value_template:
          '{{ value_json.site.instant_apparent_power | float | round(0) }}'
        unit_of_measurement: 'VA'
        device_class: apparent_power
        state_class: measurement

      - name: 'Gateway Site Frequency'
        unique_id: gateway_site_frequency
        value_template: '{{ value_json.site.frequency | float | round(2) }}'
        unit_of_measurement: 'Hz'
        device_class: frequency
        state_class: measurement
```

The same pattern works for `battery`, `load`, and `solar` — just replace `site`
in the `value_template`. Browse `/aggregates` in your browser to see all
available fields.

## Network access

The add-on needs to reach the Powerwall Gateway on your LAN. By default this
works on most setups. If the gateway is unreachable, try enabling **Host
networking** in the add-on's network settings.

See the upstream
[pypowerwall documentation](https://github.com/jasonacox/pypowerwall) for the
full API reference.
