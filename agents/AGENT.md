# GeoSaveMe — Agent Instructions

> **Read this file completely before performing any task on this repository.**  
> This applies to all AI agents (Claude, Copilot, GPT, Gemini, etc.) and human contributors.

---

## 1. Project Context

GeoSaveMe is a geolocated civilian alert platform. It connects:
- Victims and witnesses emitting alerts
- Nearby civilians who can assist or avoid
- Official security forces (police, fire, SAMU)

The platform is **English-first**, **internationally deployable**, and **market-configurable**.

---

## 2. Non-Negotiable Rules

### 2.1 Language
- All code, comments, variable names, function names, API routes → **English**
- All user-facing strings → **never hardcoded**, always a key in `4-code/i18n/en.json`
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
If a new string is needed, add it to `4-code/i18n/en.json` first, then use its key.
Key naming: `{screen}.{component}.{element}` — see `4-code/i18n/en.json` for examples.

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
Config lives in `4-code/config/market.ts` and `.env.*` files.

### 2.4 Git Discipline
- Never commit directly to `main`
- Branch naming: `ai/{agent-name}/{short-task-description}` e.g. `ai/claude/hotspot-api-scaffold`
- Every commit message must reference the source spec: `feat(hotspot): create service scaffold [spec: 3-implementation/technical-guidelines/technical-spec-v1.2.md §2.2.1]`
- One logical change per commit

### 2.5 File Placement
| What | Where |
|------|-------|
| Market/competition research | `1-strategy/` |
| Design decisions, UX, legal | `2-design/` |
| Specs, guidelines, test scenarios | `3-implementation/` |
| All source code | `4-code/` |
| Deployment, ops, support | `5-operations/` |

---

## 3. Before Starting Any Task

1. **Read the relevant spec** in `3-implementation/functional-specs/` or `3-implementation/technical-guidelines/`
2. **Check existing code** in `4-code/` to avoid duplication
3. **Check open bugs** in `5-operations/bugs/` — your task may be blocked or context-dependent
4. **Confirm your understanding** of the task scope before writing any code

---

## 4. Architecture Constraints

- **Microservices** — each service is independent, communicates via REST or event bus
- **No shared database** between microservices — each owns its data store
- **Server sends data codes, never display strings** — e.g. `"type": "danger"` not `"type": "Danger"`
- **All API responses include a locale field** — the client resolves display strings locally
- **Position data is always anonymized** for public users — `hash(deviceID)` only

### Core Services (do not rename)
| Service | Responsibility |
|---------|---------------|
| `hotspot` | Create, broadcast, update, close hotspots |
| `alerts` | Manage alert lifecycle and types |
| `location-hot` | High-frequency follower positioning |
| `location-cold` | Background approximate positioning |
| `forces` | Official user management and districts |
| `messaging` | Push notifications and broadcasts |
| `gateway` | API gateway, auth routing |
| `settings` | Market and admin config |

---

## 5. Alert Type Codes (canonical — do not change)

| Code | Display key |
|------|------------|
| `vigilance` | `alert.type.vigilance` |
| `alert` | `alert.type.alert` |
| `police` | `alert.type.police` |
| `fire` | `alert.type.fire` |
| `danger` | `alert.type.danger` |
| `safe` | `alert.type.safe` |

---

## 6. Location Status Codes (canonical — do not change)

| Code | Meaning |
|------|---------|
| `still` | No movement, < 50m from last position |
| `onslowmove` | Walking or cycling |
| `onfastmove` | Vehicle speed |
| `backin` | Arrived after fast move — check for nearby hotspots |

---

## 7. When You Modify a File

- If modifying a spec: increment the version number in the file header
- If modifying `en.json`: add new keys at the bottom of the relevant section, never rename existing keys (breaking change)
- If modifying an API contract: update the spec file in the same PR/commit
- If you are unsure: leave a `// TODO(human-review):` comment and do not commit broken code

---

## 8. Human Corrections Take Precedence

If a file has been manually edited by a human after AI generation:
- Do **not** overwrite those changes
- Read the diff (`git diff main`) to understand what was corrected
- Treat the current file state as the source of truth, not your training data or prior conversation context
- If your task conflicts with a human correction, surface the conflict explicitly rather than silently resolving it

---

## 9. Testing Requirements

- Every new API endpoint needs a test scenario in `3-implementation/testing-scenarios/`
- Every new screen needs a UI test description in `3-implementation/testing-scenarios/`
- No code is "done" without a corresponding test scenario documented

---

## 10. Asking for Clarification

If a task is ambiguous:
- Do not invent requirements
- State what you know, what is unclear, and what assumption you would make
- Wait for human confirmation before proceeding with uncertain decisions

---

*Last updated: 2026-03 — v0.1.0*
