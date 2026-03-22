# GeoSaveMe — Claude Agent Instructions

> Read this file completely before performing any task on this repository.
> This file is the Claude-specific version of `agents/AGENT.md`, enriched with full project context.

---

## 1. Project Overview

**GeoSaveMe / SAVE ME** is a geolocated civilian alert platform that bridges the gap between minor security incidents and formal emergency calls. It connects:

- **Victims & witnesses** — emit alerts with a single tap
- **Nearby civilians** — receive proximity notifications and can act as watchers
- **Official security forces** — police, fire, SAMU; get real-time district alerts with emitter context

The core mechanic: when an alert is emitted, a **hotspot** is created at the emitter's GPS position. All actors within the geographic perimeter are notified. The hotspot stays open until resolved.

**Key design principles:**
- Anonymous by default (public users identified only by `hash(deviceID)`)
- No social sharing — prevents viral amplification
- Geographically scoped — alerts never broadcast globally
- Credibility scoring — moderates alert quality without being punitive
- Market-configurable — emergency numbers, distance units, official labels via env config

---

## 2. Non-Negotiable Rules

### 2.1 Language

- All code, comments, variable names, function names, API routes → **English**
- All user-facing strings → **never hardcoded**, always a key in `design/i18n/en.json`
- Commit messages → English
- Branch names → English, kebab-case

### 2.2 i18n — Zero Hardcoding

**NEVER write:**
```tsx
<Text>Alert transmitted</Text>
<Button>Police</Button>
```

**ALWAYS write:**
```tsx
<Text>{t('alert.status.transmitted')}</Text>
<Button>{t('alert.type.police')}</Button>
```

Key naming convention: `{screen}.{component}.{element}`

If a new string is needed:
1. Add it to `design/i18n/en.json` first (at the bottom of the relevant section)
2. Never rename or remove existing keys — they are public contracts
3. Then reference the key in code

### 2.3 Market Config — Never Hardcode Country Data

**NEVER write:**
```typescript
const emergencyNumber = '17';   // ❌ France-specific
const unit = 'km';              // ❌ not universal
```

**ALWAYS write:**
```typescript
import { MARKET_CONFIG } from '@/config/market';
const emergencyNumber = MARKET_CONFIG.emergencyNumber;
```

All market config lives in `design/config/market.ts` and `.env.{market}` files.
The `MarketConfig` interface defines: `emergencyNumber`, `policeNumber`, `fireNumber`, `emsNumber`, `distanceUnit` (`metric` | `imperial`), `officialLabel`, `defaultLocale`, `supportedLocales`, `rtlLocales`, `privacyPolicyUrl`, `termsUrl`.

### 2.4 Git Discipline

- **Never commit directly to `main`**
- Branch naming: `ai/{agent-name}/{short-task-description}`
  - Example: `ai/claude/hotspot-api-scaffold`
- Every commit message must reference the source spec:
  ```
  feat(hotspot): create service scaffold [spec: 3-implementation/technical-guidelines/technical-spec-v1.2.md §2.2.1]
  ```
- One logical change per commit

### 2.5 File Placement

| What | Where |
|------|-------|
| Design decisions, UX, i18n, config, screens | `design/` |
| Functional & technical specifications | `specs/` |
| Agent instructions & scripts | `agents/` |
| Product strategy, pricing, business model | `products/` |
| Constraints, risks, values | `docs/` |
| All source code | *(to be created — `src/` or service-named folders)* |
| Deployment, ops, bugs, support | *(to be created — `ops/` or similar)* |

---

## 3. Architecture

### 3.1 Principles

- **Microservices** — each service is independent, communicates via REST or event bus
- **No shared database** between microservices — each owns its data store
- **Server sends codes, never display strings** — e.g. `"type": "danger"` not `"type": "Danger"`
- **All API responses include a `locale` field** — client resolves display strings locally
- **Position data is always anonymized** — `hash(deviceID)` only for public users

### 3.2 Core Services

| Service | Responsibility |
|---------|----------------|
| `hotspot` | Create, broadcast, update, close hotspots |
| `alerts` | Manage alert lifecycle and types |
| `location-hot` | High-frequency follower positioning (every 30s helper / 10s force) |
| `location-cold` | Background approximate positioning |
| `forces` | Official user management and district polygons |
| `messaging` | Push notifications (FCM/APNs) and broadcasts |
| `gateway` | API gateway, auth routing, rate limiting |
| `settings` | Market and admin config |

### 3.3 Key API Contracts

**Users Location API**
```
POST /api/userlocation    ← create
PUT  /api/userlocation    ← update
```
Payload fields: `userID` (hash), `position` (lat/lng/accuracy/timestamp), `provider`, `status`

**Hotspot API**
```
POST   /api/hotspot    ← create
GET    /api/hotspot    ← fetch for area
PUT    /api/hotspot    ← update
DELETE /api/hotspot    ← close
```
Hotspot fields: `hotspotID` (uuid-v4), `position`, `radius`, `alertType`, `status`, `emitterID`, `phone`, `stressLevel`, `followers`

**Alert API**
```
POST /api/alert    ← emit
PUT  /api/alert    ← update status
GET  /api/alert    ← list for hotspot
```
Alert fields: `alertID`, `hotspotID`, `type`, `status`, `context`, `emittedAt`

---

## 4. Canonical Data Codes

### 4.1 Alert Type Codes

| Code | i18n key | Severity |
|------|----------|----------|
| `vigilance` | `alert.type.vigilance` | 1 — Low-level concern, incivility |
| `alert` | `alert.type.alert` | 2 — Explicit request for intervention |
| `police` | `alert.type.police` | 3 — Requires law enforcement |
| `fire` | `alert.type.fire` | 3 — Requires fire/SAMU |
| `danger` | `alert.type.danger` | 4 — Immediate life risk |
| `safe` | `alert.type.safe` | — — "I'm Safe" signal |

Extended alert types (operational): `rescue`, `unsecure`, `action`

**Do not change these codes.**

### 4.2 Alert Status Codes

| Code | Meaning |
|------|---------|
| `sent` | Emitted by client, not yet confirmed |
| `delivered` | Received by server |
| `read` | Opened by a recipient |

### 4.3 Location Status Codes

| Code | Meaning |
|------|---------|
| `still` | No movement, < 50m from last position |
| `onslowmove` | Walking (< 6 km/h every 60s) or cycling (< 30 km/h every 30s) |
| `onfastmove` | Vehicle speed > 30 km/h — no updates while moving |
| `backin` | Stopped after fast move — check for nearby hotspots |

**Do not change these codes.**

### 4.4 Hotspot Status Codes

| Code | Meaning |
|------|---------|
| `open` | Active hotspot |
| `resolved` | Closed by emitter or forces |

### 4.5 Follower Types

| Type | Description |
|------|-------------|
| `helper` | Civilian follower |
| `force` | Official (police, fire, SAMU) |

---

## 5. User Types & Trust

| Type | Description | Anonymous |
|------|-------------|-----------|
| Victim / Witness | Emits alerts | Yes (hash only) |
| Official (Patrol) | Verified professional, receives district alerts | No |
| Official (Surveillance) | PSAP dispatcher, sees hotspot map | No |
| Bystander | Receives proximity alerts, can become watcher | Yes |
| Friend / Family | Notified by emitter | Depends |

**Credibility scores** (transmitted to forces only):
- `Pro` — all certified first responders and officials
- `2` — corroborated alerts confirmed by forces
- `1` — default (new user)
- `0.5` — excessive unverified alerts
- `0` — false alarm confirmed by forces

**User trust levels:** `Anonymous` | `Non-anonymous` | `First responder` | `Security professional`

---

## 6. Alert Modes

| Mode | Description |
|------|-------------|
| `ghost` | Alert sent only to security forces — not broadcast to civilians. Use to avoid counter-aggression. |
| `stealth` *(pro only)* | Force is hidden on the public map near the intervention area. |
| `remote/delayed` | Alert does not immediately create a hotspot — location added after the fact. |

---

## 7. Before Starting Any Task

1. **Read the relevant spec** in `specs/` (`functional-spec-v1.2.md` or `technical-spec-v1.2.md`)
2. **Check existing code** in the source folder — avoid duplication
3. **Check open bugs** in the ops/bugs folder if it exists — your task may be blocked
4. **Confirm scope** — do not start coding before you understand the task boundary

---

## 8. When Modifying Files

- **Spec files** → increment the version number in the file header
- **`en.json`** → add new keys at the bottom of the relevant section; never rename or remove existing keys
- **API contracts** → update the spec file in the same commit
- **Uncertainty** → leave a `// TODO(human-review):` comment; do not commit broken code

---

## 9. Testing Requirements

- Every new API endpoint → test scenario in `specs/testing-scenarios/` *(create the folder if needed)*
- Every new screen → UI test description in `specs/testing-scenarios/`
- No code is "done" without a corresponding test scenario documented

---

## 10. Human Corrections

If a file has been manually edited by a human after AI generation:
- Do **not** overwrite those changes
- Run `git diff main` to understand what was corrected
- Treat the current file state as the source of truth
- If your task conflicts with a human correction, surface the conflict — do not silently resolve it

---

## 11. Asking for Clarification

If a task is ambiguous:
- Do not invent requirements
- State what you know, what is unclear, and what assumption you would make
- Wait for human confirmation before proceeding with uncertain decisions

---

## 12. Key Reference Files

| File | Purpose |
|------|---------|
| `agents/AGENT.md` | Universal agent instructions (all AI agents) |
| `specs/functional-spec-v1.2.md` | Full functional specification |
| `specs/technical-spec-v1.2.md` | API contracts, data models, architecture |
| `design/config/market.ts` | Market config interface and defaults |
| `design/i18n/en.json` | i18n source of truth |
| `docs/limits.md` | Known technical and social constraints |
| `docs/risks.md` | Risk register |
| `products/business_model.md` | Customer segments, cost structure, revenue model |
| `products/offer_and_pricing.md` | Tier matrix and pricing |


---

## 13. Technology Stack

| Tool | Role |
|------|------|
| Claude Code (Opus 4) | Primary AI coding agent |
| LangChain | Orchestration |
| Langfuse | AI auditability |
| SonarQube | Code quality |
| FCM / APNs | Push notifications |
| WebSocket | Forces Web UI real-time updates |

---

*Last updated: 2026-03 — v0.1.0*
