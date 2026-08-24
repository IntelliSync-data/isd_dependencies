# Feature Specification: Local Odoo Addon Workspace

**Feature Branch**: `001-odoo-local-dev`

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "help me review addons/ (odoo addons) now I want you help me setup local development env (docker compose)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start a local workspace from a fresh clone (Priority: P1)

A developer who has just cloned this repository wants a documented, one-command way to start a private local workspace that runs the ISD business application and a dedicated data store. They can open the login screen in a browser, sign in with documented starter credentials, and see the standard application home without needing access to BloomPod, VFO, or any other remote server.

**Why this priority**: Today the only runnable environments are remote production-like servers. Without a local workspace, no other addon review, install, or change can be verified safely.

**Independent Test**: From a clean checkout, follow the documented first-run steps. The login screen appears, starter credentials work, and the home screen loads. No remote host, SSH key, or production database is required.

**Acceptance Scenarios**:

1. **Given** a fresh clone of this repository and a machine that meets the documented prerequisites, **When** the developer follows the first-run instructions, **Then** the application login screen is reachable in a browser within 15 minutes of unattended startup (excluding first-time download of the workspace pieces).
2. **Given** the local workspace has finished starting, **When** the developer signs in with the documented starter credentials, **Then** they land on the application home screen without error banners about a missing database or failed startup.
3. **Given** the local workspace is running, **When** the developer stops it and starts it again, **Then** previously created records and uploaded files are still present.

---

### User Story 2 - Install the addons this checkout can run (Priority: P1)

A developer wants to install every ISD addon in this repository — Menu Manager, Payment, Marketing Template, Marketing, Profile Management, Chatbot, PhotoApp connector, AI Dashboard, and OpenEduCat Core — from the application catalog. After install, the corresponding menus and screens appear, so they can review real behavior instead of reading source only.

**Why this priority**: All product dependencies now live in this checkout. If nested marketing or education modules fail to appear, the workspace is pointing at the wrong folder depth.

**Independent Test**: From the running local workspace, refresh the app list, install Menu Manager, Payment, Marketing Template, Profile Management, Chatbot, PhotoApp connector, AI Dashboard, and OpenEduCat Core, and open one screen from each.

**Acceptance Scenarios**:

1. **Given** a running local workspace, **When** the developer refreshes the app list, **Then** ISD Menu Manager, ISD Payment, ISD Marketing Template, ISD Marketing, ISD Profile Management, ISD Chatbot, ISD MCP PhotoApp, ISD AI Dashboard, and OpenEduCat Core appear as installable applications.
2. **Given** those applications are visible, **When** the developer installs them, **Then** each install completes without a missing-module error and an administrator can open one screen from each.
3. **Given** ISD Payment is installed, **When** an administrator opens Payment Methods, **Then** they can create a method record and save it without calling a live payment provider.
4. **Given** ISD Menu Manager is installed, **When** an administrator opens a user form, **Then** the per-user menu configuration surface is present.
5. **Given** modules that live one folder deeper than the top of `addons/` (marketing templates, OpenEduCat Core), **When** the developer refreshes the app list, **Then** those modules are discovered without the developer copying them into a flatter folder.

---

### User Story 3 - Edit addon code and see the change locally (Priority: P2)

A developer changes a screen, label, or server-side behavior in a local addon folder and wants that change to appear in their local workspace after a documented reload step. They must not push to a deployment branch or wait for a remote server restart.

**Why this priority**: The point of a local workspace is a short edit-review loop. If code on disk is ignored until a remote deploy, the environment fails its purpose.

**Independent Test**: Change a visible string in an installed self-contained addon, follow the documented reload step, and confirm the new string appears.

**Acceptance Scenarios**:

1. **Given** an installed self-contained addon and a running local workspace, **When** the developer changes a user-visible label in that addon and follows the documented reload path, **Then** the new label appears without rebuilding the whole workspace from scratch.
2. **Given** the developer is iterating, **When** they look at the documented reload path, **Then** it states whether a process restart, module upgrade, or browser refresh is required for server-side, screen, and styling changes.

---

### User Story 4 - Know installables versus live-service extras (Priority: P2)

A developer reviewing this repository needs a clear, documented inventory of every addon under `addons/`: what it is for, what it depends on, and which live external services are optional after install. They should not confuse "module installed" with "live AI or payment call works".

**Why this priority**: Every product dependency is now in this checkout. The remaining gaps are extra libraries and optional live credentials, not missing sibling products.

**Independent Test**: A new developer reads the workspace documentation and can correctly predict that every addon in this checkout can install, and that live dashboard prompts and live payment confirmations still need optional credentials.

**Acceptance Scenarios**:

1. **Given** the workspace documentation, **When** a developer looks up any addon in this checkout, **Then** the entry states it is installable and names any optional live service.
2. **Given** a running local workspace with no AI-vendor key, **When** a developer installs ISD AI Dashboard, **Then** install succeeds and opening the dashboard configuration screen does not crash the workspace.
3. **Given** the same documentation, **When** a developer looks up extra libraries (language model, AI client, cloud SDK), **Then** they can tell which extras the local workspace already provides and which remain optional for live external services.

---

### User Story 5 - Keep secrets local and reset when needed (Priority: P3)

A developer wants personal settings (published address, master password, optional live-service keys) to stay on their machine. When a workspace is dirty or broken, they want a documented reset that returns them to first-run state without affecting teammates.

**Why this priority**: First run and addon install already deliver value. Secrets hygiene and reset prevent leaked keys and unrecoverable local data, but they are not required to prove the workspace works.

**Independent Test**: Copy the committed example settings, change one local-only value, confirm it is not committed, then run the documented reset and verify the workspace asks for first-run setup again.

**Acceptance Scenarios**:

1. **Given** the committed example settings, **When** a developer copies them to a local-only settings file and changes the published address or a secret, **Then** version control does not propose committing those local values.
2. **Given** a workspace that already has records, **When** the developer follows the documented reset path, **Then** the next start is a fresh workspace and previous records are gone.
3. **Given** a workspace with no live-service keys, **When** the developer starts it and installs the self-contained addons, **Then** start and install succeed.


### Edge Cases

- First start on a machine that has never downloaded the workspace pieces: startup may exceed 15 minutes; documentation must say download time is excluded from the first-run target.
- The documented published address is already in use: startup must fail with a clear "address already in use" message and a documented way to choose another address.
- Starter credentials are changed after first login: subsequent documented logins must use the new credentials; the first-run doc must say they are initial only.
- A blocked addon is installed after someone later adds the missing sibling product beside the existing addons: install should then succeed without moving the self-contained addons.
- External payment providers, the AI vendor, or the public data connector are unreachable: self-contained install and basic screens still work; live-gateway or live-AI actions may fail with a user-visible error, not a workspace crash.
- Workspace data is deleted: the next start creates a fresh store and the developer must reinstall addons; documentation must warn that this is destructive.
- Two developers start the workspace on one machine: they must be able to isolate addresses and data so one instance does not overwrite the other, or documentation must state that only one instance per machine is supported.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide a documented local workspace that starts the ISD business application and its data store together from this checkout.
- **FR-002**: Developers MUST be able to reach the application login screen in a browser after following the documented first-run steps, without SSH access to a remote host.
- **FR-003**: The workspace MUST create or reuse a dedicated local data store on first start and keep application records and uploaded files across ordinary stop/start cycles.
- **FR-004**: Starter administrator credentials MUST be documented and MUST work on a freshly initialized workspace.
- **FR-005**: The local workspace MUST expose every installable module in this checkout, including modules that sit directly under `addons/` and modules that sit one folder deeper inside the marketing and education product checkouts.
- **FR-006**: After an app-list refresh, ISD Menu Manager, ISD Payment, ISD Marketing Template, ISD Marketing, ISD Profile Management, ISD Chatbot, ISD MCP PhotoApp, ISD AI Dashboard, and OpenEduCat Core MUST be installable and MUST complete install without missing-module errors.
- **FR-007**: After those addons are installed, an administrator MUST be able to open at least one configuration or home screen from each.
- **FR-008**: Extra libraries required to *load* the addons that this workspace claims to support MUST be present in the running application (chatbot language model, marketing cloud SDK, dashboard AI client).
- **FR-009**: Workspace documentation MUST list each addon, its purpose, its product dependencies, and that local install is supported in this repository as it stands.
- **FR-010**: Documentation MUST state that live payment-provider, AI-vendor, and public data-connector credentials are optional after install, not required to start the workspace.
- **FR-011**: Developers MUST be able to edit files in the repository addon folders and have those edits visible in the local workspace after a documented reload step (no remote deploy).
- **FR-012**: Secrets and local overrides (published address, master password, extra API keys) MUST stay on the developer's machine; a committed example MUST show every supported setting.
- **FR-013**: Stopping the workspace MUST leave persisted data in place unless the developer explicitly requests a reset.
- **FR-014**: A documented reset path MUST destroy local records and uploaded files and return the workspace to first-run state.
- **FR-015**: Live payment-provider, AI-vendor, and public data-connector credentials MUST be optional. Missing them MUST NOT prevent workspace start or self-contained addon install.
- **FR-016**: First-run documentation MUST name prerequisites, published address, starter credentials, which addons to install first, and the reload path for code changes.

### Key Entities

- **Local workspace**: The private, stoppable application-plus-data-store environment started from this repository.
- **ISD addon**: A business module under `addons/` (flat ISD modules plus nested marketing and education modules). Attributes: purpose, product dependencies, install status (supported or blocked).
- **Starter administrator**: The first user created for a fresh workspace. Attributes: documented login and password, full settings access.
- **Workspace data**: Database records and uploaded files that survive ordinary restarts and are removed only by an explicit reset.
- **External service credential**: Optional key or token for a live payment provider, language-model vendor, or public data connector. Not required for first run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer who already has the documented prerequisites can go from a fresh clone to a successful login in under 15 minutes of unattended startup, excluding first-time download of the workspace pieces.
- **SC-002**: 100% of first-run attempts on a clean machine reach the login screen without any remote server, SSH key, or production database.
- **SC-003**: On a freshly initialized workspace, the documented starter credentials succeed on the first login attempt.
- **SC-004**: After app-list refresh, Menu Manager, Payment, Marketing Template, Profile Management, Chatbot, PhotoApp connector, AI Dashboard, and OpenEduCat Core install successfully on the first attempt.
- **SC-005**: A visible label change in an installed supported addon appears in the local workspace after one documented reload cycle, without pushing to a remote branch.
- **SC-006**: Workspace documentation states that no addon in this checkout is blocked on a missing product, and names the optional live credentials separately.
- **SC-007**: 90% of new developers can complete first run, install Menu Manager and Payment plus one other ISD addon, and open one screen from each without asking a teammate for missing steps.
- **SC-008**: Ordinary stop/start preserves previously created records; only the documented reset path wipes them.

## Assumptions

- Target application version is **Odoo 18 Community**, matching every addon manifest (`18.0.1.0.0`) and the existing remote hosts (`/odoo18`). Enterprise-only apps are out of scope.
- The requested packaging is a **containerized Compose stack** (application + data store). Planning will choose images, ports, and mount layout; this spec does not prescribe file names.
- **Supported local installs in this repository today** (Community 18 standard apps assumed present: `mail`, `web_editor`, `mass_mailing`, `crm`, `calendar`, `survey`, `portal`, `board`, `hr`, `website`, `account`, `product`, `base_automation`):
  - `isd_menu` — `base`, `web`.
  - `isd_payment` — `base`, `web`. Live payment providers optional.
  - `isd_marketing_template` — `base`, `mail`, `web`, `web_editor`; extra library `boto3` (S3 optional at runtime).
  - `isd_marketing` — `mass_mailing`.
  - `isd_profile_management` — `isd_payment` + `isd_marketing_template`.
  - `isd_chatbot` — `openeducat_core` plus CRM/Calendar/Survey; extra library spaCy + English language model.
  - `isd_mcp_photoapp` — `base`, `web`. Live PhotoApp sync optional.
  - `isd_dashboard` — `board` + `isd_mcp_photoapp`; extra library `anthropic`. Live prompts need an API key and a public connector URL.
  - `openeducat_core` and the rest of the OpenEduCat suite (`activity`, `facility`, `parent`, `fees`, `classroom`, `assignment`, `admission`, `exam`, `timetable`, `attendance`, `library`, `erp`, `theme_web_openeducat`) — all product deps are inside this checkout.
- **No addon is product-blocked.** Remaining gaps are extra libraries and optional live credentials.
- Marketing and OpenEduCat are **nested product checkouts** (`addons/isd_marketing/<module>`, `addons/openeducat/<module>`). PhotoApp is a **flat** checkout (`addons/isd_mcp_photoapp`). A workspace that only looks at the top of `addons/` will miss the nested modules and will falsely report Chatbot and Profile Management as blocked.
- Root `requirements.txt` already pins spaCy, `en_core_web_sm`, `boto3`, and `paramiko`. Dashboard's `anthropic>=0.40.0` is declared by the addon but **missing** from that file; planning must add it so Dashboard can load.
- Default published address is `http://localhost:8069`. Starter credentials default to the platform's usual administrator pair unless planning chooses otherwise; they must be written down either way.
- Existing GitHub deploy workflows (BloomPod, VFO, ehub-demo) stay unchanged. This feature is local-only.
- Addons remain git submodules. The local workspace mounts the checkout as-is; it does not rewrite submodule URLs.
- One workspace instance per machine is enough for v1. Multi-instance isolation is documentation-only if mentioned.
- Constitution file is still a placeholder; no extra governance constraints apply beyond this spec.
