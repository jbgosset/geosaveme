# Operations

Everything related to running GeoSaveMe in production.

## Contents

| Folder | Purpose |
|--------|---------|
| `deployment/` | Deployment runbooks, rollback procedures, environment promotion |
| `monitoring/` | Alerts, dashboards, SLA definitions, incident response |
| `support/` | Customer support templates, escalation paths, FAQ |
| `bugs/` | Bug reports — filed here before moving to implementation backlog |
| `change-requests/` | Feature change requests from users or officials |

## Bug Filing Convention

File: `bugs/BUG-{number}-{short-description}.md`

```markdown
# BUG-001 — Short description

**Reported:** 2026-03-21
**Severity:** critical | high | medium | low
**Status:** open | in-progress | resolved

## Description
...

## Steps to Reproduce
...

## Expected vs Actual
...

## Linked Spec
`3-implementation/functional-specs/...`
```
