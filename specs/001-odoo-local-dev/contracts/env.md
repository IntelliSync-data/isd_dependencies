# Contract: Environment

**Files**: committed `.env.example`; local `.env` (gitignored)

Compose substitutes these into `docker-compose.yml`. Official Odoo entrypoint also reads `HOST`/`PORT`/`USER`/`PASSWORD`.

| Variable | Default | Purpose |
|---|---|---|
| `HOST_PORT` | `8069` | Host port published to container `8069` |
| `HOST` | `db` | Postgres hostname inside the compose network |
| `DB_PORT` | `5432` | Mapped to container `PORT` (avoid host `PORT`) |
| `DB_USER` | `odoo` | Mapped to container `USER` (avoid host `$USER`) |
| `DB_PASSWORD` | `odoo` | Mapped to container `PASSWORD` |
| `POSTGRES_USER` | `odoo` | Must equal `DB_USER` |
| `POSTGRES_PASSWORD` | `odoo` | Must equal `DB_PASSWORD` |
| `POSTGRES_DB` | `postgres` | Server bootstrap DB only |
| `ODOO_DB` | `isd` | Application database created on first start |
| `ADMIN_PASSWD` | `admin` | Odoo master password (`admin_passwd`) |

Optional (unused at start; documented only):

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Live dashboard prompts |
| `SEPAY_API_TOKEN` | Live payment confirm |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Marketing Template S3 |

`.env` must never be committed. Changing `HOST_PORT` is the documented fix when 8069 is taken.
