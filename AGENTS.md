# Repository Guidelines

Operator workspace for ISD Odoo 18 Community addons. Product code lives in git submodules under `addons/`. Root files are Compose/Makefile/docs glue only.

Constitution (v1.0.0) at `.specify/memory/constitution.md` wins over README, specs, and plans when they conflict. Spec `001-odoo-local-dev` still calls the constitution a stub — ignore that claim.

## Project Overview

Give a developer a private local Odoo + Postgres stack that can install every addon in this checkout without BloomPod, VFO, or other remotes.

- Target: **Odoo 18 Community**, Python 3.12, PostgreSQL 15.
- First run creates DB `isd` with starter `admin` / `admin` (change after first login). ISD modules are **not** auto-installed.
- Live payment, Anthropic, PhotoApp, and S3 credentials are optional after install. Missing keys must not crash start, install, or config screens. Live-only actions may fail with a user-visible error.
- Feature work on this workspace follows Spec Kit: `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.

## Architecture & Data Flow

Two Compose services. Image is thin `FROM odoo:18.0` with extras in `/opt/odoo-extra`. Addons are **never** copied into the image (`.dockerignore` excludes `addons/`); they are bind-mounted.

```
host ./addons  →  /mnt/extra-addons
addons_path = core Odoo
            + /mnt/extra-addons                  # flat ISD + PhotoApp
            + /mnt/extra-addons/isd_marketing    # nested
            + /mnt/extra-addons/openeducat       # nested
```

Odoo only scans **immediate children** of each `addons_path` entry. Listing only `/mnt/extra-addons` hides `isd_marketing_template` and `openeducat_core`, so Chatbot and Profile Management look blocked.

```
PhotoApp REST  ←  isd_mcp_photoapp  --MCP /mcp/photoapp?token=-->  Anthropic
                                              ↑
                                       isd_dashboard (auth=user)

isd_payment (SePay/PayPal/VTC/ACB, public /api/payment/<id>/*)
        ↑ ORM + HTTP
isd_profile_management --marketing.template--> isd_marketing_template
        + public /api/profile/* (portal users)

isd_chatbot --op.student--> openeducat_core
          --crm/calendar/survey--> Odoo std
          --/chatbot/* /isd_chatbot/webhook /api/inquiry--> public HTTP

isd_menu independently overrides ir.ui.menu.load_menus
isd_marketing (mass_mailing snippets) is isolated from the template module
```

Entrypoint (`docker/entrypoint.sh`): fail if nested manifests missing → `wait-for-psql.py` → if DB absent, `odoo -i base --without-demo=all` then `update_list()` → `exec odoo -d isd --db-filter=^isd$ --dev=xml,reload,qweb`. Never `-i` ISD modules on `up`.

## Key Directories

| Path | Role |
|---|---|
| `addons/isd_menu` | Per-user menu show/hide + custom root order. Flat submodule. |
| `addons/isd_payment` | Custom gateways (not `payment.acquirer`). Public JSON API + ACB webhooks. |
| `addons/isd_mcp_photoapp` | PhotoApp sync + public MCP JSON-RPC/SSE. |
| `addons/isd_dashboard` | Claude + PhotoApp MCP reports. Depends on `isd_mcp_photoapp`. |
| `addons/isd_profile_management` | Packages/steps/payments. Depends on `isd_payment` + `isd_marketing_template`. |
| `addons/isd_chatbot` | Widget, Facebook/Zalo webhook, inquiry → CRM/calendar/survey/`op.student`. Own constitution. |
| `addons/isd_marketing/` | **Nested** product: `isd_marketing` (views/assets only) + `isd_marketing_template` (Jinja + S3). |
| `addons/openeducat/` | **Nested** vendor suite. Only Chatbot depends on `openeducat_core`. |
| `docker/` | `odoo.conf`, `entrypoint.sh`. |
| `specs/001-odoo-local-dev/` | Workspace feature spec, plan, contracts, quickstart. |
| `.specify/` | Constitution, Spec Kit templates/scripts. |
| `.github/workflows/` | Remote SSH deploy (bloompod / vfo / ehub-demo). **Do not change** for local-dev work. |

Empty `addons/<name>` folders mean gitlinks were not initialized — not an Odoo bug.

## Development Commands

```bash
make init                         # submodules + .env + nested-manifest asserts
make up                           # init + compose up --build -d --wait
make start                        # up without rebuild
make stop                         # keep volumes
make logs                         # follow web
make shell                        # odoo shell on DB isd
make install MODULE=isd_menu      # -i only, then restart web if needed
make reset                        # down -v then up — DESTROYS DB + filestore
```

Login: `http://localhost:8069/web/login` (`HOST_PORT` in `.env` if 8069 is taken).

Install from Apps (developer mode → Update Apps List → drop the default "Apps" filter). Documented first pair: **ISD Menu Manager**, then **ISD Payment**.

Reload (`--dev=xml,reload,qweb` — never `--dev=all`, it hangs on PDB):

| Change | Action |
|---|---|
| XML / QWeb | Save; hard-refresh browser |
| Python | Watchdog restarts; wait a few seconds |
| OWL / JS / CSS | Hard-refresh; regenerate assets if stale |
| `requirements.txt` / Dockerfile | `docker compose up --build` |

No image rebuild for addon edits.

## Code Conventions & Common Patterns

**Ownership.** Business models, views, controllers, security, and product docs stay in the owning submodule. Workspace files (`docker-compose.yml`, `Dockerfile`, `docker/`, `Makefile`, `.env.example`, root `README.md`, `requirements.txt`) change only for operator infra. Do not flatten nested checkouts or rewrite submodule URLs.

**Manifests.** All first-party modules: `18.0.1.0.0`, `category: ISD Modules`, `application: True`, `auto_install: False`, `license: LGPL-3`. Cross-addon deps go in `__manifest__.py` `depends` — never vendor sibling code.

**Model names are mixed. Do not “fix” them.**

| Style | Examples |
|---|---|
| Dotted `isd.*` | `isd.mcp.photoapp.config`, `isd.dashboard.report` |
| Underscore module | `isd_payment.method`, `isd_payment.transaction` |
| Unprefixed | `profile.management`, `user.profile`, `chatbot.config`, `customer.inquiry`, `marketing.template` |

Inherit sparingly: `res.users`, `res.config.settings`, `ir.ui.menu`, `mail.thread` / `mail.activity.mixin`. Payment is a custom `isd_payment.method`, not Odoo’s payment provider stack.

**HTTP.** External surfaces are typically `type='http'` or `type='json'`, `auth='public'`, `csrf=False`, CORS `*` or per-method. Public controllers almost always `sudo()`. Auth is ad-hoc:

- MCP: `isd.mcp.photoapp.token` Bearer or `?token=`
- ACB: `x-api-key` / `acb_api_key` + optional IP whitelist
- Marketing: `/api/template/<api_key>/send` (the unkeyed `/api/template/send` ignores `api_key`)
- Payment create/confirm, profile create, inquiry CRUD: knowing integer IDs

Do not tighten public ACL/auth as a drive-by. Those are product decisions.

**Errors.** Backend: `UserError`. Public JSON: `{success, error, error_code}` or JSON-RPC error objects. Live-service failure must be user-visible, not a process crash or a silent success.

**Config / secrets.** `res.config.settings` → `ir.config_parameter` with prefixes `isd_dashboard.*`, `isd_chatbot.*`, `isd_profile_management.*`, `isd_marketing_template.*`. Provider secrets live in model fields, not `os.environ`. Never commit `.env`.

**Async.** Dashboard: `threading.Thread` + `odoo.registry` cursor + **raw SQL** on `isd_dashboard_task` / `report` / `usage` — field/table renames must update `addons/isd_dashboard/controllers/dashboard.py`. Payment ACB: queue `isd_payment.webhook_log`, daily cron. Chatbot: daily webhook cleanup cron.

**Groups.** User < Manager pattern (`group_isd_payment_*`, `group_isd_mcp_*`, `group_dashboard_*`, `group_profile_*`, `group_chatbot_*`) plus `ir.rule` on assigned records.

**Chatbot widget.** Frontend assets in the manifest are commented out. Edit the assembled JS in `addons/isd_chatbot/controllers/main.py`, not `static/src`. Chatbot has its own constitution (`addons/isd_chatbot/.specify/memory/constitution.md`); changes that span workspace + chatbot must satisfy both.

**Profile payments.** `models/services/payment_service.py` is a stub. Do not resurrect local SePay/VTC/PayPal — go through `isd_payment`.

## Important Files

| File | Why |
|---|---|
| `Makefile` | Operator CLI. No `test` target. `install` is `-i` not `-u`; hardcodes `odoo`/`odoo` DB creds. |
| `docker-compose.yml` | `db` (postgres:15) + `web`. Volumes `odoo-db-data`, `odoo-web-data`. |
| `docker/odoo.conf` | Nested `addons_path`, `list_db=False`, `workers=0`, `without_demo=all`. `admin_passwd=admin` is hardcoded — `ADMIN_PASSWD` in `.env` is unused. |
| `docker/entrypoint.sh` | Nested-manifest gate, first-run `-i base`, `--dev=xml,reload,qweb`. |
| `Dockerfile` | venv + `PYTHONPATH` for extras. Addons not `COPY`’d. |
| `.env.example` | Every supported setting. Live keys commented. |
| `.gitmodules` | Eight sibling remotes `../<name>.git`. |
| `specs/001-odoo-local-dev/contracts/` | Operator API: `compose.md`, `env.md`, `http.md`, `addons-path.md`. |
| `specs/001-odoo-local-dev/quickstart.md` | Workspace smoke path. |
| `addons/isd_mcp_photoapp/controllers/mcp.py` | MCP tools + SSE + streamable HTTP (`/mcp/photoapp` is what Anthropic calls). |
| `addons/isd_payment/controllers/main.py` | Public payment + ACB webhooks (~1.5k lines). |
| `addons/isd_dashboard/controllers/dashboard.py` | Claude spawn/poll; MCP URL must be **public HTTPS**. |

Public HTTP map (high-signal):

- `/mcp/photoapp`, `/mcp/photoapp/sse`, `/mcp/photoapp/message`
- `/api/payment/<method_id>/{create,confirm,transaction,transactions}`
- `/acb_pay/webhook/{realtime,daily}`
- `/api/profile/{create,confirm-payment,check-payment}`
- `/isd_profile_management/payment/{ipn,check}`
- `/chatbot/widget.js`, `/chatbot/api/chat`, `/isd_chatbot/webhook?merchant=`
- `/api/inquiry*`
- `/isd_dashboard/{submit_report,poll,saved_reports,...}` (`auth=user`; submit needs `group_dashboard_manager`)
- `/api/template/<api_key>/send`, `/media/*`

## Runtime/Tooling Preferences

- Docker Engine + Compose **v2**. One instance per machine. A second instance needs a different `HOST_PORT` and must not share named volumes.
- Official `odoo:18.0` (pin 18, not `latest`). Community standard apps (`mail`, `web_editor`, `mass_mailing`, `crm`, `calendar`, `survey`, `portal`, `board`, `hr`, `website`, `account`, …) are assumed in the image. Enterprise out of scope.
- Image extras (`requirements.txt`): spaCy + `en_core_web_sm`, `boto3`, `paramiko`, `anthropic>=0.40.0`. A documented installable module must not fail import because an extra was omitted from the image.
- `POSTGRES_DB=postgres` is the bootstrap DB. App DB is `ODOO_DB=isd`. Do not set `POSTGRES_DB=isd` as a substitute for the entrypoint.
- Host `.env` uses `DB_USER` / `DB_PORT` / `DB_PASSWORD` (avoids colliding with host `$USER`). Container still sees official `HOST` / `USER` / `PASSWORD` / `PORT`.
- Extra Compose services, reverse proxies, mail sidecars, or images beyond `web` + `db` need Complexity Tracking in the plan. Default is two services.
- Slash commands use a hyphen: `/speckit-specify` (see `.specify/integration.json`).

## Testing & QA

No root pytest. That absence must not skip verification.

**Workspace glue** (compose, Dockerfile, entrypoint, Makefile, README): prove with `specs/001-odoo-local-dev/quickstart.md` — login, catalog (including nested Marketing Template + OpenEduCat Core), one install, persist across `stop`/`start`, reset if you touched reset.

**Addon-owned behavior** (record rules, public HTTP, inquiry promotion, payment confirm): tests in the owning addon, or manual cases in that addon’s spec. Do not move product tests into workspace files.

Only first-party suite today: `addons/isd_chatbot/tests/` (`HttpCase` + `TransactionCase`, `@tagged('post_install', '-at_install', 'isd_chatbot')`). Graph is mocked. Run on a **throwaway** DB, not operator `isd`:

```bash
docker compose exec web odoo -d <test-db> --test-enable --stop-after-init \
  -u isd_chatbot --test-tags=isd_chatbot --no-http \
  --db_host db --db_user odoo --db_password odoo
```

All other ISD addons have **zero** `tests/`. After changing them: add Odoo tests for new public POST / record-rule / payment-confirm paths, then `make install MODULE=<name>` and open one screen without live keys.

OpenEduCat has `TransactionCase` + `*Common` fixtures that `env.ref()` demo XML. Local `without_demo=all` will fail those unless you use a demo-enabled throwaway DB. Do not rewrite vendor test style.

GitHub workflows are SSH deploy + `systemctl restart`. Green CI ≠ tests passed. Do not treat them as a test matrix, and do not edit them for local-dev features.
