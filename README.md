# pypowerwall-homeassistant

Home Assistant add-on repository that wraps
[jasonacox/pypowerwall](https://github.com/jasonacox/pypowerwall) into a
supervised HA add-on.

## Why this add-on?

The official Tesla integrations for Home Assistant expose common sensors like
battery level, solar production, and grid power. However, they **do not** expose
advanced electrical metrics available from the Powerwall Gateway's local API:

- **Reactive power** (var) — site, battery, load, solar
- **Apparent power** (VA) — site, battery, load, solar
- **Power factor**
- **Voltage / current per phase**
- **Frequency**

This add-on runs [pypowerwall](https://github.com/jasonacox/pypowerwall) as a
local API proxy that talks directly to your Powerwall Gateway, exposing all of
this data via a simple REST API. You can then create **REST sensors** in Home
Assistant for any metric the Gateway reports.

### Real-world use case

Tesla Powerwall has a ~5 kVA apparent power limit for backup mode. If your
home's reactive power is high (large AC compressors, motors, etc.), the
Powerwall may refuse to enter backup mode. Monitoring reactive and apparent
power lets you identify the problem — something impossible with the standard
Tesla integrations.

## Installation

1. In Home Assistant go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu (top-right) → **Repositories**.
3. Paste this repository URL:

   ```text
   https://github.com/eugenet8k/pypowerwall-homeassistant
   ```

4. Click **Add**, then refresh the page.
5. Find **PyPowerwall** in the store, click it, and hit **Install**.

## Configuration

After installing, open the add-on's **Configuration** tab and set:

| Option        | Required | Example               |
| ------------- | -------- | --------------------- |
| `PW_EMAIL`    | yes      | `user@example.com`    |
| `PW_PASSWORD` | yes      | `mysecret`            |
| `PW_HOST`     | yes      | `10.0.1.235`          |
| `PW_TIMEZONE` | no       | `America/Los_Angeles` |

See [pypowerwall/DOCS.md](pypowerwall/DOCS.md) for the full option reference.

## API URL — internal vs. external

| Where you're calling from                               | URL to use                                                   |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| **HA `configuration.yaml`** (REST sensors, automations) | `http://04ed3140-pypowerwall:8675/`                          |
| **Browser / LAN devices**                               | `http://homeassistant.local:8675/` or `http://<ha-ip>:8675/` |

> The internal hostname (`04ed3140-pypowerwall`) only works inside the HA Docker
> network — from `configuration.yaml`, other add-ons, and automations. It will
> **not** resolve from your browser. For browser access, use the HA host IP with
> port 8675.
>
> **Note:** The prefix `04ed3140` is unique to each HA installation. Check your
> add-on's **Info** tab for the actual hostname assigned to your instance.

## REST sensor examples

This is the primary use case — create REST sensors in `configuration.yaml` to
get the advanced metrics not available in standard Tesla integrations.

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
available fields. Keep all sensors under one `resource` block to avoid redundant
API calls.

See [pypowerwall/DOCS.md](pypowerwall/DOCS.md) for more details.

## How it works

The add-on is a thin wrapper around the upstream Docker image. At startup a
small Python entrypoint (`run.py`):

1. Reads `/data/options.json` (written by the HA Supervisor with your config).
2. Exports every key as an environment variable.
3. `exec`s the original upstream CMD — so the container runs exactly like the
   standalone Docker image, no patches required.

This means **any** update to `jasonacox/pypowerwall` is picked up automatically
when you rebuild the add-on.

---

## Using this as a template for other Docker images

The structure is intentionally generic. To wrap **any** Docker image as an HA
add-on:

1. Copy the `pypowerwall/` directory and rename it (e.g. `my-app/`).
2. Edit `Dockerfile` — change the `BUILD_FROM` default to your image:

   ```dockerfile
   ARG BUILD_FROM=your-org/your-image:tag
   FROM ${BUILD_FROM}
   ```

3. Edit `config.yaml`:
   - Change `name`, `slug`, `description`, `version`.
   - Update `ports` to match your image's exposed port(s).
   - Replace `options` / `schema` with the environment variables your image
     expects.
4. `run.py` needs **no changes** — it already exports all options as env vars
   and exec's the upstream CMD.
5. Commit, push, and add the repo to your HA instance.

### Example: wrapping `linuxserver/code-server`

```yaml
# my-codeserver/config.yaml
name: 'Code Server'
version: '0.1.0'
slug: 'codeserver'
description: 'VS Code in the browser'
arch: [aarch64, amd64]
init: false
ports:
  8443/tcp: 8443
options:
  PASSWORD: ''
  SUDO_PASSWORD: ''
  TZ: 'America/Los_Angeles'
schema:
  PASSWORD: password
  SUDO_PASSWORD: password
  TZ: str
```

```dockerfile
# my-codeserver/Dockerfile
ARG BUILD_FROM=linuxserver/code-server
FROM ${BUILD_FROM}
COPY run.py /ha_run.py
ENTRYPOINT ["python3", "/ha_run.py"]
```

That's it — the same `run.py` handles the rest.

## Repository layout

```text
repository.yaml          # HA add-on repository metadata
pypowerwall/
  config.yaml            # Add-on configuration & option schema
  Dockerfile             # Wraps upstream image, injects entrypoint
  run.py                 # Reads options.json → env vars → exec CMD
  DOCS.md                # In-app documentation (shown in HA UI)
  CHANGELOG.md           # Version history
```

## License

MIT
