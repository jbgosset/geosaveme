# Changelog

All notable changes to GeoSaveMe are documented here.

This file summarises what changed between phases in plain language. For the full detail of every change, see the git log. For the reasoning behind architectural decisions, see `docs/technical-architecture.md`. For the complete current functional state of the system, see `docs/functional-specification.md`.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows `MAJOR.MINOR.PATCH` — phases increment MINOR.

---

## [Unreleased]

> Work in progress toward v0.1.0. Tracks items completed during MVP development.

---

## [Spec] — Architectural Decisions — Pre-MVP — 2026-04-18

### Context

Before MVP implementation begins, two foundational architectural decisions were made that affect the data model, the API contract, and the mobile implementation. They are recorded here because they change the shape of what `[0.1.0]` must build — they are not deferred to a later phase.

These decisions are captured in full in:
- `docs/functional-specification.md` §1.3 and §5
- `docs/technical-specification.md` §0

### Decision 1 — Agent Autonomy and Event-Driven Lifecycle

**What changed:** The system is now explicitly designed around autonomous agents and a server-side rule engine, rather than direct client control of hotspot lifecycle.

**Why it matters:** This is not a refactor of existing code — it is a constraint on how the MVP must be built from the start. Implementing it after the fact would require breaking changes to the API and the mobile state model.

**Specific consequences for MVP implementation:**

- All agent-to-server communications are **events**, not commands. The `secure` signal is an alert event like any other — the mobile client never directly closes a hotspot.
- The server evaluates **closure rules** on receipt of each event. In the MVP, the rule is: a `secure` event from the original emitter closes the hotspot. This rule lives entirely server-side.
- Every hotspot state update broadcast to agents carries a **version timestamp**. Agents apply an incoming update only if its version is newer than their local snapshot.
- Agents maintain a **local state snapshot** per hotspot, making the app functional during brief network loss. This cache must be implemented as part of the MVP, not deferred.
- The `eventType` field is added to the common geolocation envelope so the server rule engine can route events without inspecting payload content.

**What this enables later:** Closure rules (official qualification, participant quorum, inactivity timeout) can be added server-side in Phase 2 and beyond without any client update.

### Decision 2 — Three Distinct Entities: Alert, Hotspot, HotspotParticipation

**What changed:** The data model is restructured around three entities with separate lifecycles, replacing a single alert-centric model.

**Why it matters:** The previous model conflated situation assessment (alerts), lifecycle state (hotspot), and agent presence (followers). This made it impossible to evolve closure rules independently and created ambiguity in the API about who owns what state.

**The three entities:**

- **Alert** — an immutable event record once delivered. Carries a situation assessment from a single agent at a point in time. Its only mutable field is transmission status: `sent` → `delivered`. It carries no information about who read it or what was done with it. `read` and `closed` are **not** alert statuses.
- **Hotspot** — a server-owned aggregate. Its status (`open` / `closed`) is set exclusively by the rule engine. It version-stamps every state broadcast. Participant count is derived from HotspotParticipation records — never stored as a field on the hotspot itself.
- **HotspotParticipation** — a relationship record between an agent and a hotspot, created by a follower's acknowledgement participation event. Carries role, position, response intent, and timestamps. This is a new entity absent from the previous model; follower acknowledgement was previously treated as an alert, which it is not.

**A new API endpoint is required:** `/api/participation` handles participation events (acknowledge, position update, qualification, response update, departure) separately from `/api/alert`.

### Changed (relative to previous spec versions)

- `functional-specification.md` bumped to reflect §1.3 (architectural principle), §5 restructured around three entities, UC-03 reframed from "Close an Alert" to "Signal Resolution (Emitter)"
- `technical-specification.md` bumped to v1.4, §0 added as foundational guiding principle, API objects updated to reflect three-entity model, Agent Cache added as a required MVP implementation concern
- Alert status `read` removed — read state is a hotspot-level concern, not an alert transmission status
- Alert status `closed` removed — closure is a hotspot status, not an alert status
- Hotspot status renamed from `resolved` to `closed` for clarity
- `alert.status.read` i18n key removed from `en.json`
- `alert.type.safe` i18n key renamed to `alert.type.secure` to match data model
- `severity.low` i18n value corrected from `"Alert"` to `"Unsecure"`

---

## [0.1.0] — MVP — Target: TBD

### Context

The MVP is the first deployable slice of the GeoSaveMe platform. Its sole objective is to validate three foundational technical challenges before any secondary feature is built: background geolocation on iOS and Android, the real-time alert emission and hotspot creation pipeline, and cross-platform push notification delivery.

Two test users — one iOS, one Android — can swap roles as emitter and follower.

Full scope decisions and rationale: `docs/decisions/mvp-functional-scope-v0.1.md`.

### Added

**Users**
- Anonymous user — Victim or Witness: can open an alert and create a hotspot
- Anonymous user — Bystander / Follower: receives push notification, acknowledges hotspot

**Use cases**
- UC-01 Emit an alert (unsecure / danger / police / fire)
- UC-02 Receive an alert as a nearby follower
- UC-03 Signal resolution as emitter (Secure event, hold 2s to confirm); server closes hotspot on receipt
- UC-04 Background cold location tracking

**Alert model**
- Alert types: `unsecure`, `danger`, `police`, `fire`, `secure`
- Alert transmission statuses: `sent`, `delivered`
- Hotspot statuses: `open`, `closed`
- HotspotParticipation: created on follower acknowledgement; carries role, position, timestamps
- Common event envelope with `eventType` field for server-side routing
- Geolocation payload: cold and hot position, cinetic state, provider
- Agent local snapshot cache with version-based update logic

**Hotspot**
- Server-side hotspot creation on first alert event
- Server-side closure rule: `secure` event from original emitter closes hotspot
- Fixed 500 m perimeter radius
- Cold position matching to identify nearby users for push dispatch
- Hotspot timeout: 30 min inactivity (server-side rule)
- Hot location updates: emitter every 30s (GPS), follower every 30s (network)
- Version-stamped state broadcasts to agents

**APIs**
- `/api/userlocation` — cold and hot position updates
- `/api/hotspot` — hotspot creation, fetch, state updates
- `/api/alert` — alert event emission and transmission status
- `/api/participation` — follower acknowledgement and position updates (new)

**Screens**
- S-01 Alert Emission: role toggle, alert type grid, status band, map preview, participant count
- S-02 Alert Reception: push notification card with type, distance, elapsed time
- S-03 Map / Hotspot View: hotspot map, approximate emitter pin, acknowledge button
- S-04 Onboarding: anonymous device ID generation, location permission, push permission

**Infrastructure**
- React Native + Expo (iOS + Android)
- Node.js + TypeScript + Fastify backend
- Postgres + PostGIS (geospatial matching)
- Redis (BullMQ async push dispatch queue)
- FCM universal push (Android + iOS via APNs)
- Fly.io deployment, Frankfurt region

### Acceptance criteria

| # | Criterion | Threshold |
|---|---|---|
| AC-01 | Emitter (iOS) → follower (Android) push delivery | < 10 s |
| AC-02 | Emitter (Android) → follower (iOS) push delivery | < 10 s |
| AC-03 | Follower acknowledge → emitter participant count increment | < 5 s |
| AC-04 | Emitter sends `secure` event → server closes hotspot → follower resolution push | < 15 s |
| AC-05 | Cold location update received server-side on > 50 m move | Server log confirmed |
| AC-06 | Background battery drain in cold location mode | < 5% / hour (30 min test) |
| AC-07 | Onboarding completion (permissions granted) | < 3 taps on both platforms |
| AC-08 | Agent resumes correct hotspot state after 60s network loss | Local snapshot matches server state on reconnect |

### Deferred to Phase 2

Alert qualification, stress meter, ghost mode, security groups, official patrol app, surveillance centre web dashboard, credibility scoring, stealth mode, post-event alerts, watcher and first responder authentication, phone number matching, broadcast messages from officials, extended closure rules (official qualification, participant quorum).

### Deferred to Phase 3

Media attachments, freemium statistics, safe escort, tracker registration, quorum-based hotspot closure.

---

## Phase 2 — Planned

> Not yet started. Scope to be defined based on MVP outcomes and early user feedback.  
> Candidate features drawn from `docs/decisions/full-product-vision.md`.

**Likely candidates (to be confirmed):**
- Alert qualification form (gravity, target, fact, aggravating factors)
- Stress meter (button press frequency)
- Ghost mode
- Personal security groups (My Group) with QR code joining
- Official patrol mobile app (authentication, district alerts, hotspot qualification)
- Surveillance centre web dashboard (map, phone number matching, broadcast)
- Extended closure rules: official qualification trigger, inactivity timeout validation
- Credibility scoring
- Watcher authentication
- Post-event alerts
- SSE + Redis pub/sub real-time channel (if MT-05 polling trigger is hit)
- On-push position confirmation (if false positive rate is a measured problem)

---

## Phase 3 — Future

> Not yet designed. See `docs/decisions/full-product-vision.md` for backlog.

**Candidate features:**
- Extended security groups for events and organisations
- Media attachments (photo / audio, forces only)
- Freemium statistics (J+1, M+1, A+1)
- Safe escort / guardian angel
- Tracker registration
- First Responder authentication and validated presence
- Quorum-based hotspot closure (participant `secure` signals)
