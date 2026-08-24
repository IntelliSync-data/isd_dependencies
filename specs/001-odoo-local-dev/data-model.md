# Data Model: Local Odoo Addon Workspace

**Feature**: `001-odoo-local-dev`  
**Date**: 2026-08-24

This feature does not introduce business tables. Entities are the local workspace and its operator-visible state.

## WorkspaceInstance

A running or stopped local stack started from this checkout.

| Field | Type | Rules |
|---|---|---|
| name | string | Compose project name; default directory name |
| published_url | url | Default `http://localhost:8069`; host port from `.env` |
| application_db | string | Always `isd` after first successful start |
| status | enum | `absent` → `starting` → `ready` → `stopped`; `failed` on port-in-use or DB unreachable |
| created_at | datetime | First successful `-i base` |

**Transitions**: `absent` + `docker compose up --build` → `starting` → `ready`. `docker compose stop` → `stopped` (data kept). `docker compose down -v` → `absent` (data destroyed).

## WorkspaceSettings

Local-only overrides. Persisted in `.env` (not committed). Schema: [contracts/env.md](./contracts/env.md).

| Field | Required to start | Default |
|---|---|---|
| HOST_PORT | no | `8069` |
| POSTGRES_USER | no | `odoo` |
| POSTGRES_PASSWORD | no | `odoo` |
| ODOO_DB | no | `isd` |
| ADMIN_PASSWD | no | `admin` (database manager master; manager hidden after init) |
| HOST / USER / PASSWORD | no | `db` / `odoo` / `odoo` |
| live-service keys | no | empty |

**Validation**: `HOST_PORT` is a free host TCP port. Postgres user/password on `web` must match `db`.

## WorkspaceVolume

| Name | Mount | Survives `compose stop` | Survives `compose down -v` |
|---|---|---|---|
| odoo-web-data | `/var/lib/odoo` | yes | no |
| odoo-db-data | Postgres data dir | yes | no |
| bind `./addons` | `/mnt/extra-addons` | yes (host files) | yes |

Filestore + DB rows are **Workspace data** (spec entity). Bind mount is source, not workspace data.

## StarterAdministrator

Created by `-i base` on first start.

| Field | Value |
|---|---|
| login | `admin` |
| password | `admin` |
| groups | Settings / Administration |
| mutable | yes — after first login the documented pair may no longer work |

## AddonInventoryEntry

One installable module visible after `update_list()`.

| Field | Rules |
|---|---|
| technical_name | Directory name (`isd_menu`, `openeducat_core`, …) |
| display_name | Manifest `name` |
| path_kind | `flat` (child of `addons/`) or `nested` (child of `addons/isd_marketing` or `addons/openeducat`) |
| product_depends | Manifest `depends` |
| extra_libraries | Manifest `external_dependencies.python` |
| install_status | `uninstalled` \| `installed` \| `to upgrade` |
| live_service | optional note (SePay, Anthropic, PhotoApp, S3) |

**Invariant**: After first-run `update_list()`, every module in [contracts/addons-path.md](./contracts/addons-path.md) is `uninstalled` and listed. None are missing-product-blocked.

## Relationships

```text
WorkspaceInstance 1──1 WorkspaceSettings
WorkspaceInstance 1──* WorkspaceVolume
WorkspaceInstance 1──1 StarterAdministrator   (after first ready)
WorkspaceInstance 1──* AddonInventoryEntry    (after update_list)
```
