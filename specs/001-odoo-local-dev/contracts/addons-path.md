# Contract: Addon discovery

**Host bind**: `./addons` → `/mnt/extra-addons`

**`addons_path`** (container):

```text
/mnt/extra-addons
/mnt/extra-addons/isd_marketing
/mnt/extra-addons/openeducat
```

Odoo packaged addons remain on the implicit core path.

## Flat (child of `addons/`)

| technical_name | live extra |
|---|---|
| `isd_menu` | — |
| `isd_payment` | SePay / PayPal / VTC / ACB optional |
| `isd_profile_management` | — (needs payment + marketing template) |
| `isd_chatbot` | spaCy baked in image |
| `isd_dashboard` | `anthropic` baked in; API key optional |
| `isd_mcp_photoapp` | live PhotoApp sync optional |

## Nested (must be on `addons_path`)

| Root | technical_name |
|---|---|
| `addons/isd_marketing/` | `isd_marketing`, `isd_marketing_template` |
| `addons/openeducat/` | `openeducat_core`, `openeducat_activity`, `openeducat_facility`, `openeducat_parent`, `openeducat_fees`, `openeducat_classroom`, `openeducat_assignment`, `openeducat_admission`, `openeducat_exam`, `openeducat_timetable`, `openeducat_attendance`, `openeducat_library`, `openeducat_erp`, `theme_web_openeducat` |

A workspace that only lists `/mnt/extra-addons` **fails** this contract: Chatbot and Profile Management show missing `openeducat_core` / `isd_marketing_template`.

## Host prerequisite

```bash
git submodule update --init --recursive
```

Empty gitlink directories are a contract violation, not an Odoo bug.
