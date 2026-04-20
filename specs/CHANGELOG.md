# Changelog

All notable changes to GeoSaveMe are documented here.

This file summarises what changed between phases in plain language. For the full detail of every change, see the git log. For the reasoning behind architectural decisions, see `docs/technical-architecture.md`. For the complete current functional state of the system, see `docs/functional-specification.md`.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows `MAJOR.MINOR.PATCH` — phases increment MINOR.

---

## [Unreleased]

> Work in progress toward v0.1.0. Tracks items completed during MVP development.

---

## [Spec] — Architectural Decisions — Session 2 — 2026-04-18

### Context

Second pre-MVP architectural session. Three decisions recorded: fan-out scaling strategy, agent reconciliation protocol, and the rate limiting safety principle. Two items explicitly parked for later design sessions with direction captured.

These decisions are captured in full in:
- `docs/technical-architecture.md` ADR-09, ADR-10, MT-06, DD-12–DD-15
- `docs/technical-specification.md` v1.5 §2.2, §2.3, §3.1, §3.3

### Decision 3 — Fan-out Scaling Strategy (ADR-09)

**What changed:** BullMQ worker horizontal scaling is named as the explicit fan-out strategy. Synchronous dispatch on the request thread is prohibited. Queue partitioning by `hotspotID` is a day-one implementation requirement.

**Why it matters:** Fan-out is the highest-throughput operation in the system. Getting this wrong at MVP has no consequence (two users), but implementing it correctly from the start costs almost nothing and prevents a structural refactor later. BullMQ is already in the stack — this is a configuration and discipline decision, not a new component.

**Specific consequences for MVP implementation:**
- HotSpot Service must enqueue push jobs to BullMQ immediately on hotspot creation — never inline
- BullMQ queue must be partitioned by `hotspotID` from day one
- Worker process is co-located with the app in MVP; extraction to dedicated Fly.io instances is the Phase 2 scaling step (MT-06 trigger)
- MT-06 monitoring trigger added: queue depth > 1,000 jobs sustained > 5 minutes → add worker instances

### Decision 4 — Agent Reconciliation Protocol (ADR-10)

**What changed:** A `POST /api/sync` endpoint contract is defined. The endpoint is not implemented in MVP but the mobile cache data structure must support it from day one.

**Why it matters:** The current spec said "agent requests a full state refresh on reconnection" without defining the mechanism. An agent that was offline when a hotspot closed and a new one opened nearby has a structurally incomplete cache — it cannot ask for hotspots it doesn't know exist. The sync endpoint solves this by combining position + known state into a single pull-on-reconnect request, letting the server compute a complete diff.

**Specific consequences for MVP implementation:**
- Mobile cache must store `{ hotspotID → { state, version } }` pairs, not flat state — required to construct the sync request
- `HotspotCacheEntry` TypeScript interface is defined in `technical-specification.md` §3.3 — implement exactly this structure
- Known MVP limitation documented: agents that go offline during the two-user test must restart the app to re-sync; this is accepted at MVP scale
- `/api/sync` implementation added to Phase 2 scope (DD-14)

### Decision 5 — Rate Limiting Principle

**What changed:** The API Gateway rate limiting behaviour is now specified as throttle-not-suppress. Added to `technical-specification.md` §2.3.

**Why it matters:** A naive rate limiter that silently drops events on threshold breach would violate the safety principle in §0.5 — the server must never suppress an agent's alert, even indirectly. The correct behaviour is `429` with `Retry-After`; the client retries; the event is not lost.

**Specific consequences for MVP implementation:**
- Rate limits applied per `mobileID`, not per IP address
- Alert events and participation events have separate rate limit buckets, with alert events given higher priority headroom
- Mobile client must implement automatic retry on `429` for all event submission endpoints

### Parked — Hotspot Merge Strategy (DD-12)

Direction captured, implementation deferred to Phase 2 design session. The approach is **merge-not-deduplicate**: rather than preventing two hotspots from being created for the same incident, the rule engine will detect overlapping hotspots post-creation and merge them into a unified aggregate. This is consistent with the event-sourcing model, non-destructive (no events are lost), and extensible (merge can later be triggered by official judgment, not just proximity rules). Agents holding a merged hotspot ID receive a redirect state update pointing them to the merged hotspot.

### Parked — Hotspot Closure Safety Guards (DD-13)

Deferred pending persona and security context analysis. Covers: minimum open duration before a `secure` event can trigger closure, and official veto capability. These require functional design decisions about personas and security contexts before they can become ADRs.

---

## [Spec] — Architectural Decisions — Session 1 — 2026-04-18

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
- Agent local snapshot cache (`HotspotCacheEntry` with version) — sync-ready structure required from day one

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
- `/api/participation` — follower acknowledgement and position updates
- `/api/sync` — contract defined (ADR-10); implementation deferred to Phase 2

**Fan-out**
- BullMQ async push dispatch — never synchronous on request thread
- Queue partitioned by `hotspotID` from day one
- Single co-located worker process for MVP; horizontal scaling via MT-06 trigger

**Rate limiting**
- Per `mobileID`, not per IP
- `429` + `Retry-After` on threshold breach — never silent discard
- Alert events given higher priority headroom than participation events

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
| AC-09 | Alert event on `429` rate limit → automatic retry → event delivered | Server log confirms delivery after retry |
| AC-10 | BullMQ fan-out job enqueued within 200ms of hotspot creation | BullMQ job timestamp vs hotspot `createdAt` |

### Known MVP limitations

- `/api/sync` not implemented: agents that go offline and reconnect must restart the app to re-sync hotspot state
- BullMQ worker is co-located with app process: under exceptional load (not expected at two-user scale) worker throughput could affect app instance performance

### Deferred to Phase 2

Alert qualification, stress meter, ghost mode, security groups, official patrol app, surveillance centre web dashboard, credibility scoring, stealth mode, post-event alerts, watcher and first responder authentication, phone number matching, broadcast messages from officials, extended closure rules (official qualification, participant quorum), `/api/sync` implementation, BullMQ dedicated worker processes (MT-06 trigger), hotspot merge strategy design.

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
- `/api/sync` endpoint implementation (ADR-10)
- Hotspot merge strategy design and implementation (DD-12)
- Hotspot closure safety guards design (DD-13, pending persona analysis)
- BullMQ dedicated worker processes if MT-06 triggered
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
