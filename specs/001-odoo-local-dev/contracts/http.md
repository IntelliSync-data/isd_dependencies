# Contract: HTTP surface

**Base URL**: `http://localhost:${HOST_PORT}` (default `http://localhost:8069`)

## After first `compose up` (status `ready`)

| Request | Response |
|---|---|
| `GET /web/login` | `200`, Odoo login form (not `/web/database/selector` or `/web/database/manager`) |
| `GET /web/database/manager` | not offered (`list_db = False`) or redirects away |
| POST login `admin` / `admin` | session + backend home (`/odoo` or `/web`) |

## After Apps → Update Apps List (or first-run `update_list()`)

Searching Apps (remove the default "Apps" filter if needed) lists at least:

`isd_menu`, `isd_payment`, `isd_marketing`, `isd_marketing_template`, `isd_profile_management`, `isd_chatbot`, `isd_mcp_photoapp`, `isd_dashboard`, `openeducat_core`

Install via UI is the supported path. Live-service actions may 4xx/5xx without keys; the workspace stays up.

## After stop / start

Same URL, same database, same installed modules and records.
