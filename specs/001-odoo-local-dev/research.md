# Research: Local Odoo Addon Workspace

**Feature**: `001-odoo-local-dev`  
**Date**: 2026-08-24

## Official image and version

**Decision**: Build a thin local image `FROM odoo:18.0` (tag `18.0`, not `latest` / `19`).

**Rationale**: Every ISD and OpenEduCat manifest is `18.0.*`. Official image already exposes `/mnt/extra-addons`, `/var/lib/odoo`, ports 8069/8071/8072, and an entrypoint that waits for Postgres (`HOST`/`USER`/`PASSWORD`). Pinning `18.0` avoids a silent jump to 19.

**Alternatives considered**:
- `odoo:latest` / `19.0` — wrong major; addons will not load.
- Community source checkout (`odoo-bin`) — more moving parts than a local workspace needs.
- Enterprise image — none exists; Enterprise is out of scope.

## Extra Python libraries

**Decision**: Custom `Dockerfile` installs root `requirements.txt` plus `anthropic>=0.40.0` at image build time (`USER root`, `pip3 install --break-system-packages`, then `USER odoo`).

**Rationale**: FR-008 requires spaCy + English model, boto3, and the dashboard AI client to be present so Chatbot / Marketing Template / Dashboard can *load*. The stock image does not include them. Ubuntu Noble system Python needs `--break-system-packages`. First image build downloads the spaCy wheel; that time is excluded from the 15-minute first-run target (spec edge case).

**Alternatives considered**:
- `pip install` on every container start — slow, network-dependent, hides failures.
- Bind-mount a host venv — fragile across OS/arch.
- Skip extras until a module is installed — Odoo refuses install when `external_dependencies` are missing.

## PostgreSQL

**Decision**: `postgres:15` with `POSTGRES_DB=postgres`, `POSTGRES_USER`/`PASSWORD` matching Odoo `USER`/`PASSWORD`. Named volume for data. Odoo application database name is `isd` (created by our entrypoint, not by `POSTGRES_DB`).

**Rationale**: Matches the official Docker Library Odoo README. `POSTGRES_DB=postgres` is the server bootstrap DB; Odoo creates its own database. Official entrypoint defaults `HOST=db`, `USER=odoo`, `PASSWORD=odoo`.

**Alternatives considered**:
- `postgres:16` — fine, but undocumented vs official examples.
- One container (Odoo + Postgres) — harder to reset independently, not the official pattern.

## Nested addons path

**Decision**: Mount `./addons` at `/mnt/extra-addons`. Set `addons_path` to:

```text
/mnt/extra-addons,/mnt/extra-addons/isd_marketing,/mnt/extra-addons/openeducat
```

Core addons stay implicit (official `odoo.conf` only lists `/mnt/extra-addons`; Odoo still loads packaged addons). If the Apps catalog is missing standard apps during implementation, prepend `/usr/lib/python3/dist-packages/odoo/addons`.

**Rationale**: Flat modules (`isd_menu`, `isd_payment`, `isd_chatbot`, `isd_dashboard`, `isd_profile_management`, `isd_mcp_photoapp`) sit directly under `addons/`. Marketing and OpenEduCat modules sit one folder deeper. Odoo only scans immediate children of each `addons_path` entry.

**Alternatives considered**:
- Flatten / copy nested modules into `addons/` — fights git submodules.
- Multiple volume mounts — more compose noise for the same paths.

## First-run database (login without the manager)

**Decision**: Wrap the official entrypoint. After `wait-for-psql.py`, if database `isd` does not exist, run:

```text
odoo -d isd -i base --without-demo=all --stop-after-init --no-http
```

then `ir.module.module.update_list()` via `odoo shell`, then start:

```text
odoo -d isd --db-filter=^isd$ --dev=xml,reload,qweb
```

Default Odoo admin after `-i base` is `admin` / `admin`. Hide the database manager (`list_db = False`).

**Rationale**: FR-003/004 require a login screen and working starter credentials. The stock image with no `-d` shows `/web/database/manager` instead. Do **not** `-i` ISD addons (Story 2 is catalog install). `--without-demo=all` keeps first-run small.

**Alternatives considered**:
- Leave the database manager — fails Story 1.
- `-i` all ISD modules on first boot — contradicts Story 2 and makes first start fragile.
- Separate `init` Compose service — extra moving part for a one-shot check.

## Dev reload

**Decision**: `--dev=xml,reload,qweb` (not `--dev=all`). Document: XML/QWeb hot-reload; Python restart via watchdog `reload`; OWL/JS/CSS need a browser hard refresh (and sometimes an assets regenerate).

**Rationale**: Official image already ships `python3-watchdog`. `--dev=all` enables the debugger and can hang the HTTP process. Story 3 requires a documented reload path, not a hung PDB.

**Alternatives considered**:
- No `--dev` — every XML edit needs `-u module`.
- `--dev=all` — worse local UX.

## Secrets and local overrides

**Decision**: Committed `.env.example`; gitignored `.env` (already in `.gitignore` with `!.env.example`). Compose reads `.env` for published host port, DB credentials, master password, database name. Optional live-service keys stay in `.env` comments only (not required to start).

**Rationale**: FR-012. Official image already maps `HOST`/`USER`/`PASSWORD` from the environment.

**Alternatives considered**:
- Docker secrets files — heavier than needed for a single-developer stack.
- Hard-coded compose values — cannot change port when 8069 is taken (spec edge case).

## Reset

**Decision**: `docker compose down -v` then `docker compose up --build`. Document as destructive. No extra reset script in v1.

**Rationale**: Named volumes hold Postgres data and `/var/lib/odoo`. Removing them returns first-run (FR-014). One command, official Compose behavior.

**Alternatives considered**:
- Custom `reset.sh` that also deletes bind mounts — nothing to delete besides volumes.
- SQL `DROP DATABASE` only — leaves filestore orphans.

## Demo data

**Decision**: `--without-demo=all`.

**Rationale**: Spec does not require demo records. Empty base DB is enough for catalog install and login. Smaller, faster, deterministic.

## Documentation location

**Decision**: Repo-root `README.md` is the first-run + addon inventory (FR-009, FR-016). `specs/001-odoo-local-dev/quickstart.md` is the validation script for implement/verify.

**Rationale**: Developers will not look under `specs/` to start the stack.

## Compose topology

**Decision**: Two services (`web`, `db`), one `Dockerfile`, `docker/odoo.conf`, `docker/entrypoint.sh`. Postgres healthcheck; `web` `depends_on: db` with `condition: service_healthy`. Publish `${HOST_PORT:-8069}:8069`.

**Rationale**: Official Compose shape plus the two things this repo uniquely needs (nested addons path + extras image + first-run DB).

**Alternatives considered**:
- nginx / longpolling worker — not required for one-developer `--dev` (workers=0).
- Mailhog / local S3 — live extras are optional.

## Testing

**Decision**: No unit-test framework for this feature. Proof is the quickstart: compose up, HTTP login page, catalog lists ISD modules, one module installs, stop/start keeps the DB.

**Rationale**: The deliverable is a running workspace, not a library. Spec success criteria are operator-visible.
