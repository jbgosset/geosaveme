# GeoSaveMe

> A bottom-up civilian vigilance network — geolocated alert platform connecting civilians, witnesses, and official security forces.

## Repository Structure

| Folder | Purpose |
|--------|---------|
| `agents/` | Agent instructions, onboarding scripts, and sub-agent definitions |
| `design/` | UX, i18n locale files, market config, screen prototypes |
| `docs/` | Constraints, risks, and values |
| `products/` | Business model, offer matrix, pricing, and added value analysis |
| `specs/` | Functional and technical specifications |
| `scripts/` | Root-level utility scripts |

## Key Principles

- **English-first** — all code, docs, and agent instructions in English
- **i18n from day one** — all user-facing strings in `design/i18n/en.json`, never hardcoded
- **Market-configurable** — emergency numbers, official labels, distance units via `design/config/market.ts` and `.env.{market}`
- **Git as source of truth** — all AI-generated content is committed; human corrections tracked via `git diff`
- **Agent-aware** — `agents/AGENT.md` contains strict guidelines for any AI agent working on this codebase

## Working with AI Agents

Any AI agent (Claude, Copilot, etc.) contributing to this repo **must**:
1. Read `agents/AGENT.md` before any task
2. Never hardcode locale strings — use `design/i18n/en.json` keys
3. Never hardcode market config — use `design/config/market.ts`
4. Open a branch per task, never commit directly to `main`
5. Reference the relevant spec file in every commit message

## Getting Started

```bash
git clone https://github.com/YOUR_ORG/geosaveme.git
cd geosaveme
# See agents/AGENT.md for contributor onboarding
```

## Versioning

- `main` — stable, human-reviewed
- `ai/` prefix branches — AI-generated, pending human review
- Tags: `vMAJOR.MINOR.PATCH` following semver

---

*Version 0.1.0 — repository initialized*
