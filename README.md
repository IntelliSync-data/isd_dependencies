# ISD Dependencies

Local Odoo 18 Community workspace for the ISD addons in this checkout.

## Prerequisites

- Docker Engine + Compose v2
- Git
- Free host port `8069` (or set `HOST_PORT` in `.env`)

```bash
git submodule update --init --recursive
```

Empty addon folders mean the gitlinks were not initialized. The web container refuses to start until nested marketing and OpenEduCat manifests exist.

## First run

First image build downloads `odoo:18.0`, spaCy, and `anthropic`. That download time does **not** count toward the 15-minute startup target.

```bash
make init
make up
```

- URL: <http://localhost:8069>
- Login: `admin` / `admin` (change after first login)
- Application database: `isd` (created automatically; database manager is hidden)

Stop without wiping data: `make stop`  
Start again: `make start`

## Install addons

ISD modules are **not** auto-installed. After login:

1. Settings → Activate developer mode (if **Update Apps List** is hidden)
2. Apps → Update Apps List (first start already ran `update_list()`)
3. Remove the default "Apps" filter if a module does not appear
4. Install **ISD Menu Manager**, then **ISD Payment**

Also installable from this checkout: ISD Marketing Template, ISD Marketing, ISD Profile Management, ISD Chatbot, ISD MCP PhotoApp, ISD AI Dashboard, OpenEduCat Core (and the rest of the OpenEduCat suite).

Do not expect a live payment confirm or a live AI report without optional credentials.

## Reload after code edits

`--dev=xml,reload,qweb` is on. No image rebuild for addon edits (`./addons` is bind-mounted).

| Change | What to do |
|---|---|
| XML / QWeb | Save; hard-refresh the browser |
| Python | Watchdog restarts the process; wait a few seconds |
| OWL / JS / CSS | Hard-refresh; if stale, regenerate assets or restart `web` |
| `requirements.txt` / Dockerfile | `docker compose up --build` |

## Reset

Destructive. Drops the database and filestore.

```bash
make reset
```

You get a fresh `admin` / `admin`. Reinstall addons.

If port 8069 is taken, set `HOST_PORT=18069` in `.env` and open <http://localhost:18069>.

## Addon inventory

| Module | Path | Product depends | Extra library | Live service (optional) |
|---|---|---|---|---|
| `isd_menu` | flat | `base`, `web` | — | — |
| `isd_payment` | flat | `base`, `web` | — | SePay / PayPal / VTC / ACB |
| `isd_mcp_photoapp` | flat | `base`, `web` | — | PhotoApp sync |
| `isd_dashboard` | flat | `board`, `isd_mcp_photoapp` | `anthropic` (in image) | Anthropic API key + public MCP URL |
| `isd_chatbot` | flat | CRM, Calendar, Survey, `openeducat_core` | spaCy + `en_core_web_sm` (in image) | — |
| `isd_profile_management` | flat | `isd_payment`, `isd_marketing_template` | — | — |
| `isd_marketing_template` | `addons/isd_marketing/` | `mail`, `web_editor` | `boto3` (in image) | AWS S3 |
| `isd_marketing` | `addons/isd_marketing/` | `mass_mailing` | — | — |
| `openeducat_core` (+ suite) | `addons/openeducat/` | `hr`, `website`, `account`, … | — | — |

OpenEduCat suite in this checkout: `activity`, `facility`, `parent`, `fees`, `classroom`, `assignment`, `admission`, `exam`, `timetable`, `attendance`, `library`, `erp`, `theme_web_openeducat`.

No addon is blocked on a missing sibling product. Live keys are optional after install.

## Make

| Intent | Command |
|---|---|
| Init submodules + `.env` | `make init` |
| Start | `make up` |
| Logs | `make logs` |
| Odoo shell | `make shell` |
| Install one module | `make install MODULE=isd_menu` |
| Stop (keep data) | `make stop` |
| Reset | `make reset` |

`.env` is gitignored. Commit only `.env.example`.
