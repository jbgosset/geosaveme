# GeoSaveMe

> A bottom-up civilian vigilance network — geolocated alert platform connecting civilians, witnesses, and official security forces.

## Repository Structure

| Folder | Purpose |
|--------|---------|
| `1-strategy/` | Market analysis, competition, legislation, violence exposure by region |
| `2-design/` | Project framing — customers, functional scope, UX, architecture, legal, schedule |
| `3-implementation/` | Detailed specs, technical guidelines, CI/CD rules, agent instructions for AI coders |
| `4-code/` | Source code — API, database, screens, i18n, config |
| `5-operations/` | Deployment, monitoring, support, bugs, change requests |

## Key Principles

- **English-first** — all code, docs, agent instructions in English
- **i18n from day one** — all user-facing strings in `4-code/i18n/`, never hardcoded
- **Market-configurable** — emergency numbers, official labels, distance units via env config
- **Git as source of truth** — all AI-generated content is committed; human corrections tracked via git diff
- **Agent-aware** — `3-implementation/agent-instructions/` contains strict guidelines for any AI agent working on this codebase

## Working with AI Agents

Any AI agent (Claude, Copilot, etc.) contributing to this repo **must**:
1. Read `3-implementation/agent-instructions/AGENT.md` before any task
2. Never hardcode locale strings — use `4-code/i18n/en.json` keys
3. Never hardcode market config — use `4-code/config/market.ts`
4. Open a branch per task, never commit directly to `main`
5. Reference the relevant spec file in every commit message

## Getting Started

```bash
git clone https://github.com/YOUR_ORG/geosaveme.git
cd geosaveme
# See 3-implementation/agent-instructions/AGENT.md for contributor onboarding
```

## Versioning

- `main` — stable, human-reviewed
- `ai/` prefix branches — AI-generated, pending human review
- Tags: `vMAJOR.MINOR.PATCH` following semver

---

*Version 0.1.0 — repository initialized*
