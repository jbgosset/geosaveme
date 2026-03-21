# Code

All source code for the GeoSaveMe platform.

## Contents

| Folder | Purpose |
|--------|---------|
| `api/` | Backend microservices (hotspot, alerts, location, forces, messaging, gateway) |
| `database/` | Schema definitions, migrations, seed data |
| `screens/` | Mobile and web UI screens (React Native / React) |
| `i18n/` | Locale files — `en.json` is source of truth |
| `config/` | Market config, environment files, feature flags |
| `scripts/` | Build, deploy, seed, and maintenance scripts |

## Critical Rules

- **`i18n/en.json` is the source of truth** — never delete or rename keys
- **`config/market.ts`** is the only place for market-specific values
- **No secrets in this folder** — use `.env.local` (gitignored) or a secrets manager
- All screens must import strings via `t()` — zero hardcoded user-facing text
