# Quickstart: Local Odoo Addon Workspace

Validate the implementation against [spec.md](./spec.md). Commands assume repo root.

## Prerequisites

- Docker Engine + Compose v2
- Git
- Free host port `8069` (or set `HOST_PORT` in `.env`)
- Submodules present:

```bash
git submodule update --init --recursive
test -f addons/isd_menu/__manifest__.py
test -f addons/isd_marketing/isd_marketing_template/__manifest__.py
test -f addons/openeducat/openeducat_core/__manifest__.py
test -f addons/isd_mcp_photoapp/__manifest__.py
```

## Setup

```bash
cp .env.example .env
docker compose up --build
```

First image build downloads `odoo:18.0`, spaCy model, and `anthropic`. That time does not count toward the 15-minute target.

Wait until `web` is healthy (login page answers).

## Scenario 1 — Login (P1 / SC-001–003)

1. Open `http://localhost:8069/web/login`
2. Expect the login form, not the database manager
3. Sign in `admin` / `admin`
4. Expect the backend home with no missing-database banner

## Scenario 2 — Catalog + one install (P1 / SC-004)

1. Enable developer mode (Settings) if Update Apps List is hidden
2. Apps → Update Apps List
3. Search `ISD Menu` and `ISD Payment` — both installable
4. Search `OpenEduCat Core` and `ISD Marketing Template` — both visible (proves nested path)
5. Install **ISD Menu Manager**
6. Open a user form — menu-config surface is present

Optional deeper check: install Payment, Marketing Template, Profile Management, PhotoApp, Dashboard, Chatbot. Dashboard install must succeed with no Anthropic key.

## Scenario 3 — Persist (SC-008)

```bash
docker compose stop
docker compose up
```

Login still works. ISD Menu is still installed.

## Scenario 4 — Reload path (P2 / SC-005)

1. Edit a user-visible string in `addons/isd_menu` (a view label)
2. Follow README reload notes (`--dev=xml,reload,qweb`: XML should refresh; hard-refresh the browser)
3. New label appears without `docker compose build`

## Scenario 5 — Reset (P3 / FR-014)

```bash
docker compose down -v
docker compose up --build
```

Login is a fresh `admin` / `admin`. ISD Menu is not installed.

## Scenario 6 — Port clash (edge)

Set `HOST_PORT=18069` in `.env`, `docker compose up`. Login at `http://localhost:18069/web/login`.

## Done when

- Scenarios 1–3 pass
- README lists every addon and marks live credentials optional
- `.env` is gitignored; `.env.example` is committed
