# Implementation Plan: Local Odoo Addon Workspace

**Branch**: `001-odoo-local-dev` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-odoo-local-dev/spec.md`

## Summary

Give a developer a one-command local Odoo 18 Community workspace (Compose: `web` + `db`) that mounts this checkout’s addons, discovers nested marketing/OpenEduCat modules, auto-creates database `isd` with starter admin `admin`/`admin`, and leaves ISD module install to the Apps catalog. A thin image on `odoo:18.0` installs Python extras at build time. Live payment/AI/PhotoApp keys stay optional.

## Technical Context

**Language/Version**: Python 3.12 (Odoo 18 official image, Ubuntu Noble)

**Primary Dependencies**: `odoo:18.0` image, Docker Compose v2, PostgreSQL 15, spaCy + `en_core_web_sm`, boto3, anthropic>=0.40.0, paramiko (already in `requirements.txt`)

**Storage**: PostgreSQL 15 named volume; Odoo filestore named volume at `/var/lib/odoo`

**Testing**: Quickstart smoke (compose up, HTTP login, Apps list, one install, restart persistence). No pytest suite.

**Target Platform**: Linux developer workstation with Docker Engine + Compose v2

**Project Type**: local development workspace (Compose stack around existing addons)

**Performance Goals**: Login screen within 15 minutes of unattended startup after images exist (SC-001)

**Constraints**: Community 18 only; one instance per machine; no remote deploy changes; extras baked in image; 8069 overridable via `.env`

**Scale/Scope**: 2 Compose services; 8 git submodules; ~20 installable modules (6 flat ISD + 2 nested marketing + 14 OpenEduCat); 1 blocked-on-credentials path (live AI/payment)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template (placeholder principle names, no ratified version). **No enforceable project gates.**

Applied anyway:

- Simplicity: two services, one Dockerfile, no nginx/mail/S3 sidecars.
- Library-first: N/A (operator workspace, not a library).
- CLI: Compose CLI is the interface (`up`, `down -v`).
- Test-first: N/A (constitution stub). Validation is the quickstart, not TDD.
- Observability: container logs only.

**Gate: PASS** (no constitution violations possible against a stub).

### Post-design re-check

Design adds a wrapper entrypoint and a thin image only because the stock `odoo:18.0` image cannot (a) create `isd` on first start or (b) load Chatbot/Dashboard extras. No extra services. **Still PASS.**

## Project Structure

### Documentation (this feature)

```text
specs/001-odoo-local-dev/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── compose.md
│   ├── env.md
│   ├── http.md
│   └── addons-path.md
└── tasks.md              # /speckit-tasks — not created here
```

### Source Code (repository root)

```text
docker-compose.yml
Dockerfile
.env.example
docker/
├── odoo.conf
└── entrypoint.sh
README.md                 # first-run + addon inventory (FR-009/016)
requirements.txt          # add anthropic>=0.40.0
addons/                   # existing git submodules (unchanged)
```

**Structure Decision**: Keep the stack at repo root (this repo *is* the addon checkout). Do not invent `src/`. Nested product roots stay as submodule layouts; `addons_path` lists them.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Custom image + entrypoint on top of official `odoo:18.0` | Must bake extras (FR-008) and auto-create DB `isd` (FR-003/004) | Plain `image: odoo:18.0` shows the database manager and cannot import spaCy/anthropic |
