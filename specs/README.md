# Specs

Functional and technical specifications — the source of truth for all implementation work.

## Contents

| File | Purpose |
|------|---------|
| `functional-spec-v1.2.md` | Full functional specification: user types, use cases, data model, alert modes, broadcasting |
| `technical-spec-v1.2.md` | API contracts, microservice responsibilities, data codes, mobile architecture, i18n integration |

## Rules

- No code is written without a corresponding entry in these specs.
- When modifying a spec, increment the version number in the file header.
- API contract changes must be committed in the same commit as the implementation change.
- Every new endpoint or screen requires a test scenario documented in `testing-scenarios/` *(create the folder when first needed)*.
