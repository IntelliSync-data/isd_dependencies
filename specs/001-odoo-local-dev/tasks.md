# Tasks: Local Odoo Addon Workspace

**Input**: Design documents from `/specs/001-odoo-local-dev/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not requested. Validation is `quickstart.md` smoke, not a test suite.

**Organization**: Tasks grouped by user story so each story can be implemented and checked independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (`US1`…`US5`)
- Include exact file paths in descriptions

## Path Conventions

Repo-root workspace (from plan.md): `docker-compose.yml`, `Dockerfile`, `.env.example`, `docker/`, `README.md`, `requirements.txt`, `addons/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Files and pins every later phase needs

- [x] T001 Create `docker/` directory at repo root
- [x] T002 [P] Add `anthropic>=0.40.0` to `requirements.txt` (keep existing spaCy / boto3 / paramiko pins)
- [x] T003 [P] Write `.env.example` with `HOST_PORT`, `HOST`, `PORT`, `USER`, `PASSWORD`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `ODOO_DB`, `ADMIN_PASSWD` per `specs/001-odoo-local-dev/contracts/env.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Image + Compose + config so a stack can start. No user-story entrypoint logic yet.

**⚠️ CRITICAL**: No user story work until this phase is complete

- [x] T004 [P] Write `docker/odoo.conf` with `addons_path` `/mnt/extra-addons,/mnt/extra-addons/isd_marketing,/mnt/extra-addons/openeducat`, `data_dir = /var/lib/odoo`, `list_db = False`, `admin_passwd` left for env/entrypoint
- [x] T005 [P] Write `Dockerfile` `FROM odoo:18.0`, `USER root`, install `requirements.txt` via `pip3 install --break-system-packages`, copy `docker/odoo.conf` to `/etc/odoo/odoo.conf`, `USER odoo`
- [x] T006 Write `docker-compose.yml`: service `db` (`postgres:15`, `POSTGRES_*`, named volume `odoo-db-data`, healthcheck); service `web` (build `.`, `depends_on: db` healthy, `${HOST_PORT:-8069}:8069`, volumes `./addons:/mnt/extra-addons` and `odoo-web-data:/var/lib/odoo`, env `HOST`/`USER`/`PASSWORD`/`ODOO_DB`/`ADMIN_PASSWD`)

**Checkpoint**: `docker compose config` succeeds. Do not expect login yet (no first-run DB).

---

## Phase 3: User Story 1 - Start a local workspace from a fresh clone (Priority: P1) 🎯 MVP

**Goal**: One-command start reaches `/web/login`; `admin`/`admin` works; data survives `compose stop`.

**Independent Test**: `git submodule update --init --recursive`, `cp .env.example .env`, `docker compose up --build`, open `http://localhost:8069/web/login`, sign in `admin`/`admin`. No database manager.

### Implementation for User Story 1

- [x] T007 [US1] Write `docker/entrypoint.sh`: call official `wait-for-psql.py`; if database `$ODOO_DB` (default `isd`) is missing, run `odoo -d $ODOO_DB -i base --without-demo=all --stop-after-init --no-http`; then `exec odoo -d $ODOO_DB --db-filter=^${ODOO_DB}$`
- [x] T008 [US1] Set `Dockerfile` `ENTRYPOINT` to `docker/entrypoint.sh` and make the script executable
- [x] T009 [US1] Write first-run section in `README.md`: submodule init, `cp .env.example .env`, `docker compose up --build`, URL `http://localhost:8069`, starter credentials `admin`/`admin`, note that first image build time is excluded from the 15-minute target

**Checkpoint**: Story 1 is demoable. ISD addons are not installed yet.

---

## Phase 4: User Story 2 - Install the addons this checkout can run (Priority: P1)

**Goal**: Nested marketing/OpenEduCat modules are discoverable; Apps list shows ISD modules; Menu and Payment install without missing-module errors.

**Independent Test**: Update Apps List, install ISD Menu Manager, open a user form and see menu config. Search also finds OpenEduCat Core and ISD Marketing Template.

### Implementation for User Story 2

- [x] T010 [US2] In `docker/entrypoint.sh` fail fast with a clear message if `/mnt/extra-addons/isd_marketing/isd_marketing_template/__manifest__.py` or `/mnt/extra-addons/openeducat/openeducat_core/__manifest__.py` is missing (empty gitlinks)
- [x] T011 [US2] After first-run `-i base` in `docker/entrypoint.sh`, run `odoo shell -d $ODOO_DB --no-http` to call `env['ir.module.module'].update_list(); env.cr.commit()` so ISD apps appear without a manual list refresh
- [x] T012 [US2] Add install section to `README.md`: developer mode if needed, Apps search names, install Menu then Payment; note Chatbot/Dashboard/Profile/PhotoApp/OpenEduCat Core are also installable; do not auto-`-i` ISD modules

**Checkpoint**: Stories 1 and 2 both work. Catalog install is manual.

---

## Phase 5: User Story 3 - Edit addon code and see the change locally (Priority: P2)

**Goal**: XML/QWeb reload without image rebuild; documented matrix for Python vs assets.

**Independent Test**: Change a visible label in `addons/isd_menu`, hard-refresh the browser, new label appears without `docker compose build`.

### Implementation for User Story 3

- [x] T013 [US3] Append `--dev=xml,reload,qweb` to the long-running `odoo` exec in `docker/entrypoint.sh` (not `--dev=all`)
- [x] T014 [US3] Add reload matrix to `README.md`: XML/QWeb auto; Python via watchdog restart; OWL/JS/CSS hard refresh / asset regenerate; no rebuild

**Checkpoint**: Edit-reload loop documented and working for an installed module.

---

## Phase 6: User Story 4 - Know installables versus live-service extras (Priority: P2)

**Goal**: README inventory lists every addon, product deps, and optional live credentials. Dashboard install does not require an API key.

**Independent Test**: A new developer can predict from `README.md` that every module in this checkout installs, and that live AI/payment need optional keys.

### Implementation for User Story 4

- [x] T015 [US4] Add addon inventory table to `README.md` covering flat ISD modules, nested marketing, OpenEduCat suite, extras (spaCy, boto3, anthropic), and optional live services (SePay, Anthropic, PhotoApp, S3) per `specs/001-odoo-local-dev/contracts/addons-path.md`

**Checkpoint**: Documentation matches the checkout; no addon marked product-blocked.

---

## Phase 7: User Story 5 - Keep secrets local and reset when needed (Priority: P3)

**Goal**: `.env` stays local; documented reset wipes volumes; `HOST_PORT` avoids port clashes.

**Independent Test**: Change a value in `.env` — git does not stage it. `docker compose down -v && docker compose up --build` yields a fresh `admin`/`admin` and Menu is uninstalled.

### Implementation for User Story 5

- [x] T016 [US5] Confirm `.gitignore` contains `.env` and `!.env.example`; add those lines if missing
- [x] T017 [US5] Add reset and port-override section to `README.md`: `docker compose down -v` is destructive; `HOST_PORT=18069` when 8069 is taken

**Checkpoint**: All five stories independently checkable.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Operator UX and quickstart proof

- [x] T018 [P] Add `web` healthcheck in `docker-compose.yml` hitting `http://localhost:8069/web/login`
- [x] T019 Run `specs/001-odoo-local-dev/quickstart.md` scenarios 1–3 (login, catalog + Menu install, stop/start persistence) and fix any gap

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none
- **Foundational (Phase 2)**: Setup — BLOCKS all stories
- **US1 (Phase 3)**: Foundational — MVP
- **US2 (Phase 4)**: Foundational; uses US1 entrypoint (edit same `docker/entrypoint.sh`)
- **US3 (Phase 5)**: Foundational; edits `docker/entrypoint.sh` after US1/US2
- **US4 (Phase 6)**: can start after US2 README install section exists (same `README.md`)
- **US5 (Phase 7)**: can start after `.env.example` exists; README section after US1 first-run
- **Polish (Phase 8)**: after US1 at minimum; T019 after US2

### User Story Dependencies

- **US1 (P1)**: no other story — MVP
- **US2 (P1)**: needs US1 running workspace + foundational `addons_path`
- **US3 (P2)**: needs at least one installed addon (US2) to demo reload
- **US4 (P2)**: docs only; independently testable once README inventory exists
- **US5 (P3)**: docs + gitignore; reset test needs a used workspace

### Parallel Opportunities

- T002 / T003 after T001
- T004 / T005 after Setup
- T015 / T016 once foundation files exist (different files)
- T018 anytime after T006

US2–US5 share `README.md` and `docker/entrypoint.sh` — do not parallelize those edits.

---

## Parallel Example: Setup + Foundation

```bash
# After T001:
Task: "Add anthropic>=0.40.0 to requirements.txt"
Task: "Write .env.example per contracts/env.md"

# After Setup:
Task: "Write docker/odoo.conf nested addons_path"
Task: "Write Dockerfile FROM odoo:18.0"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup
2. Phase 2 Foundational
3. Phase 3 US1
4. **STOP**: login works at `http://localhost:8069`
5. Then US2 (catalog) before claiming the workspace is useful for addon review

### Incremental Delivery

1. Setup + Foundation → `compose config` works
2. US1 → login MVP
3. US2 → install Menu/Payment + nested discovery
4. US3 → reload loop
5. US4 → inventory
6. US5 → secrets/reset
7. T019 quickstart 1–3

---

## Notes

- [P] = different files, no incomplete dependency
- Do not `-i` ISD modules in the entrypoint
- Do not use `--dev=all`
- Do not add nginx, mail, or S3 sidecars
- Commit after each phase checkpoint
