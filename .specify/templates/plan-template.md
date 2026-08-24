# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Source: `.specify/memory/constitution.md` v1.0.0.*

- **I. Addon Isolation**: Business behavior MUST land in the owning
  addon submodule. Workspace files MAY change only for operator
  infrastructure. Nested product checkouts MUST stay nested. Submodule
  URLs MUST NOT be rewritten. A new workspace file MUST be justified
  in Complexity Tracking.
- **II. Local Workspace Completeness**: First-run and verification MUST
  work on the private Compose stack with no remote host, SSH key, or
  production database. `addons_path` MUST include nested
  `isd_marketing` and `openeducat`. Load-time Python extras MUST be in
  `requirements.txt` / the image.
- **III. Optional Live Services**: Missing payment, AI, PhotoApp, or S3
  credentials MUST NOT block start or self-contained install. Live-only
  failures MUST be user-visible, not a workspace crash.
- **IV. Secrets Stay Local**: New settings MUST appear in committed
  `.env.example`. Secrets MUST remain gitignored. Stop MUST preserve
  volumes; wipe MUST be an explicit reset.
- **V. Spec-First Verification**: Plan MUST cite the spec. Workspace
  changes MUST name a quickstart/smoke path. Addon tests belong in the
  addon. Extra Compose services or images beyond `web` + `db` FAIL this
  gate unless justified below.

**Gate status**: [PASS | FAIL — list violations]

### Post-design re-check

[Re-evaluate I–V after research.md, data-model.md, contracts/, and
quickstart.md exist. Extra services or images added in design MUST be
justified in Complexity Tracking.]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
# Workspace glue (operator infrastructure only)
docker-compose.yml
Dockerfile
.env.example
Makefile
README.md
requirements.txt
docker/
├── odoo.conf
└── entrypoint.sh

# Product addons (git submodules — do not flatten)
addons/
├── isd_menu/
├── isd_payment/
├── isd_mcp_photoapp/
├── isd_dashboard/
├── isd_chatbot/
├── isd_profile_management/
├── isd_marketing/          # nested: isd_marketing_template, isd_marketing
└── openeducat/             # nested: openeducat_core + suite
```

**Structure Decision**: Keep workspace glue at repo root. Do not invent
`src/`. Addon-owned code stays in the owning submodule. Nested product
roots stay nested; `addons_path` lists them.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
