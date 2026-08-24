<!--
Sync Impact Report
- Version change: (unfilled template) → 1.0.0
- Modified principles:
  - [PRINCIPLE_1_NAME] → I. Addon Isolation
  - [PRINCIPLE_2_NAME] → II. Local Workspace Completeness
  - [PRINCIPLE_3_NAME] → III. Optional Live Services
  - [PRINCIPLE_4_NAME] → IV. Secrets Stay Local
  - [PRINCIPLE_5_NAME] → V. Spec-First Verification
- Added sections:
  - Stack & Compatibility
  - Development Workflow
  - Governance (ratified procedure, versioning, compliance review)
- Removed sections: none (template placeholders replaced)
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ updated
  - .specify/templates/spec-template.md ✅ updated
  - .specify/templates/tasks-template.md ✅ updated
  - .specify/templates/checklist-template.md ✅ updated
  - README.md ✅ updated (governance pointer)
  - .claude/skills/speckit-*/SKILL.md ✅ reviewed, no edit (generic constitution loaders; no stale principle names)
- Follow-up TODOs:
  - specs/001-odoo-local-dev/plan.md still records a stub Constitution Check; re-evaluate on the next /speckit-plan or /speckit-analyze pass
  - specs/001-odoo-local-dev/spec.md assumption "Constitution file is still a placeholder" is stale; refresh on the next spec edit
-->

# ISD Dependencies Constitution

## Core Principles

### I. Addon Isolation

This repository is the operator workspace around ISD Odoo addons. Each
product lives in its own git submodule under `addons/`.

- Business models, views, controllers, security, and product docs MUST
  live in the owning addon. Workspace files (`docker-compose.yml`,
  `Dockerfile`, `docker/`, `Makefile`, `.env.example`, root `README.md`,
  `requirements.txt`) MAY change only for local-operator infrastructure.
- Cross-addon product dependencies MUST be declared in that addon's
  `__manifest__.py` `depends` list. Workspace glue MUST NOT copy or
  vendor sibling product code.
- Nested product checkouts (`addons/isd_marketing/<module>`,
  `addons/openeducat/<module>`) MUST stay nested. Flat ISD modules
  (`isd_menu`, `isd_payment`, `isd_mcp_photoapp`, `isd_dashboard`,
  `isd_chatbot`, `isd_profile_management`) MUST stay flat.
- Submodule URLs and layouts MUST NOT be rewritten to make a module
  appear. Empty addon folders mean gitlinks were not initialized.
- When an addon ships its own constitution, that addon's product
  principles govern that addon's domain. This constitution governs the
  workspace. A change that spans both MUST satisfy both.

Rationale: The checkout is an aggregation of independently versioned
products. Flattening or mixing business logic into Compose files makes
the products undeployable on the existing remote hosts.

### II. Local Workspace Completeness

A fresh clone MUST start a private Odoo 18 Community workspace without
remote hosts, SSH keys, or production data.

- The stack MUST run the application and a dedicated data store from
  this checkout. First-run documentation MUST name prerequisites,
  published address, starter credentials, first addons to install, and
  the reload path.
- `addons_path` MUST include the bind-mounted addon root **and** the
  nested marketing and OpenEduCat product roots. A path that only lists
  the top of `addons/` FAILS this principle.
- Python extras required to *load* addons this workspace claims to
  support (spaCy + `en_core_web_sm`, `boto3`, `anthropic`) MUST be
  present in the image via `requirements.txt`. A documented installable
  module MUST NOT fail import because an extra was omitted from the
  image.
- After images exist, the login screen MUST be reachable within 15
  minutes of unattended startup. First-time image download is excluded
  from that target and MUST be stated as excluded.
- Addon edits under `addons/` MUST appear after the documented reload
  step. A remote deploy MUST NOT be required to review a local change.

Rationale: The only previously runnable environments were remote
production-like hosts. A workspace that still needs those hosts is not
a local workspace.

### III. Optional Live Services

Live payment providers, AI vendors, PhotoApp sync, and cloud object
storage are extras after install, not prerequisites.

- Missing live-service credentials MUST NOT prevent workspace start or
  self-contained addon install.
- Opening a configuration or home screen for a supported addon MUST
  NOT crash the workspace when those credentials are absent.
- Live-only actions MAY fail. Failure MUST be a user-visible error,
  not a process crash or a silent no-op that looks like success.
- Workspace documentation MUST list each addon, its product
  dependencies, extra libraries the image already provides, and which
  live credentials remain optional.

Rationale: Reviewers need real menus and screens. Confusing "module
installed" with "live gateway call works" blocks local review.

### IV. Secrets Stay Local

Developer overrides stay on the developer machine.

- Published address, master password, database password, and live API
  keys MUST live in a gitignored local settings file. Version control
  MUST NOT propose committing those values.
- A committed example (`.env.example`) MUST list every supported
  setting, with live-service keys commented as optional.
- Ordinary stop/start MUST preserve application records and uploaded
  files. Only an explicit, documented reset path MAY destroy them, and
  that path MUST warn that it is destructive.
- Starter administrator credentials (`admin` / `admin` on a fresh
  `isd` database) are initial-only. Documentation MUST say they MUST
  be changed after first login.

Rationale: Shared remotes already hold real credentials. A local
workspace that leaks keys or silently wipes a teammate's data fails
its purpose.

### V. Spec-First Verification

Feature work in this repository follows Spec Kit. Unspecified workspace
changes are not done.

- New behavior MUST be specified (`/speckit-specify`) before it is
  planned or implemented. Plans MUST pass the Constitution Check in
  the plan template before Phase 0 research and again after Phase 1
  design. Unjustified violations FAIL the gate.
- Workspace-glue changes MUST be proven by a documented smoke path
  (feature `quickstart.md` and/or the root README first-run steps):
  start, login, catalog visibility, one install, persist across stop,
  reset when the feature touches reset.
- This workspace has no root pytest suite. That absence MUST NOT be
  used to skip verification. Addon-owned behavior (record rules,
  public HTTP, inquiry promotion, payment confirm) MUST be tested in
  the owning addon, or listed as manual cases in that addon's spec.
- Extra Compose services, reverse proxies, mail sidecars, or images
  beyond `web` + `db` MUST be justified in Complexity Tracking with
  the simpler alternative that was rejected.

Rationale: Two services and a thin image already cover first run.
Complexity that is not specified cannot be reviewed.

## Stack & Compatibility

- Target platform is **Odoo 18 Community**. Addon manifests in this
  checkout use `18.0.x`. Enterprise-only apps are out of scope.
- Packaging is a **Docker Compose v2** stack: official `odoo:18.0`
  plus PostgreSQL 15. One workspace instance per machine is the v1
  contract. A second instance on the same host MUST use a different
  `HOST_PORT` and MUST NOT share volumes unless the operator accepts
  data clobber.
- Community standard apps (`mail`, `web_editor`, `mass_mailing`,
  `crm`, `calendar`, `survey`, `portal`, `board`, `hr`, `website`,
  `account`, `product`, `base_automation`) are assumed present in the
  image. ISD modules MUST NOT be auto-installed on first start.
- Existing GitHub deploy workflows (BloomPod, VFO, ehub-demo) live in
  the addon remotes. This workspace MUST NOT change those pipelines.
- `--dev=xml,reload,qweb` is the local reload contract. Image rebuild
  is reserved for `requirements.txt` / Dockerfile changes.

## Development Workflow

1. Initialize submodules and local settings: `make init`.
2. Start and wait healthy: `make up`. Stop without wipe: `make stop`.
3. Install addons from Apps (or `make install MODULE=...`) after
   login. Menu Manager then Payment is the documented first pair.
4. Specify → plan → tasks → implement for new workspace behavior.
   Every plan MUST fill Constitution Check against principles I–V.
5. Verify with the feature quickstart or the README first-run path
   before calling the work done.
6. Reset (`make reset` / `docker compose down -v`) only when the
   operator explicitly wants a fresh `isd` database.

Reviews and pull requests for this repository MUST confirm: no
business logic in workspace files, nested paths still discovered,
`.env` uncommitted, live credentials still optional, and smoke steps
updated when first-run behavior changes.

## Governance

This constitution supersedes informal practice, README convenience
notes, and generated Spec Kit artifacts when they conflict. Specs,
plans, and tasks MUST be amended to comply; the constitution is not
reinterpreted to fit a feature.

Amendments:

1. Edit `.specify/memory/constitution.md` via `/speckit-constitution`
   (or an equivalent reviewed change that still runs the propagation
   checklist).
2. Record the version bump, the principle or section that changed,
   and a migration note when existing specs or plans would fail the
   new gate.
3. Propagate gates into `.specify/templates/` before merge.
4. Approval is a reviewed pull request against this repository. A
   principle removal or incompatible redefinition MUST be called out
   in the PR title or summary.

Versioning (SemVer on the constitution, not the Odoo addons):

- **MAJOR**: remove or incompatibly redefine a principle or gate.
- **MINOR**: add a principle or section, or materially expand a gate.
- **PATCH**: wording, typo, or non-semantic clarification.

Compliance review:

- `/speckit-plan` MUST evaluate Constitution Check twice (pre-research
  and post-design). Unjustified FAIL blocks planning.
- `/speckit-analyze` and `/speckit-converge` treat a MUST violation as
  CRITICAL. They MUST NOT dilute or ignore a principle.
- Runtime guidance for operators is `README.md`. Runtime guidance for
  a single addon stays in that addon.

**Version**: 1.0.0 | **Ratified**: 2026-08-24 | **Last Amended**: 2026-08-24
