# Contract: Compose CLI

**Consumer**: developer on a machine with Docker Compose v2  
**Provider**: `docker-compose.yml` at repo root

## Commands

| Intent | Command | Expected |
|---|---|---|
| First start / start | `docker compose up --build` | `web` becomes healthy; [http.md](./http.md) login is reachable |
| Background | `docker compose up --build -d` | same, detached |
| Stop (keep data) | `docker compose stop` | next `up` reuses DB `isd` and filestore |
| Reset (destroy data) | `docker compose down -v` then `up --build` | next start re-runs `-i base`; previous records gone |
| Logs | `docker compose logs -f web` | Odoo stdout |
| One-shot module install (optional) | `docker compose exec web odoo -d isd -i isd_menu --stop-after-init --no-http` | module installed; then restart `web` |

## Failure

| Condition | Signal |
|---|---|
| Host port taken | Compose bind error; change `HOST_PORT` in `.env` |
| Submodules not checked out | `/mnt/extra-addons/<name>` empty; Apps list missing ISD modules — README must require `git submodule update --init --recursive` |
| Postgres not ready | `web` waits via official `wait-for-psql.py` (30s) then exits |

## Non-goals

Does not install ISD addons on `up`. Does not publish 8071/8072. Does not start a second project on the same host ports.
