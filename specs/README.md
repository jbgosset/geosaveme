# Specs

Functional and technical specifications — the source of truth for all implementation work.

## Contents

| File | Purpose |
|------|---------|
| `functional-specification.md` | Full functional specification: user types, use cases, data model, alert modes, broadcasting |
| `technical-specification.md` | API contracts, microservice responsibilities, data codes, mobile architecture, i18n integration |
| `technical-architecture.md` | Microservice architecture, infrastructure decisions, deployment topology |
| `CHANGELOG.md` | Notable changes between phases, in plain language |
| `decisions/full-product-vision.md` | Complete product vision and long-term roadmap |
| `decisions/mvp-functional-scope-v0.1.md` | Scoped decisions for the MVP phase |

## Rules

- No code is written without a corresponding entry in these specs.
- When modifying a spec, increment the version number in the file header.
- API contract changes must be committed in the same commit as the implementation change.
- Every new endpoint or screen requires a test scenario documented in `testing-scenarios/` *(create the folder when first needed)*.
