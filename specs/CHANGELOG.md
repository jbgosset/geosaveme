# Changelog

All notable changes to GeoSaveMe are documented here.

This file summarises what changed between phases in plain language. For the full detail of every change, see the git log. For the reasoning behind architectural decisions, see `docs/technical-architecture.md`. For the complete current functional state of the system, see `docs/functional-specification.md`.

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows `MAJOR.MINOR.PATCH` — phases increment MINOR.

---

## [Unreleased]

> Work in progress toward v0.1.0. Tracks items completed during MVP development.

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
- UC-03 Close an alert (Secure, hold 2s to confirm)
- UC-04 Background cold location tracking

**Alert model**
- Alert types: `unsecure`, `danger`, `police`, `fire`, `secure`
- Alert statuses: `sent`, `delivered`, `read`, `closed`
- Geolocation payload: cold and hot position, cinetic state, provider

**Hotspot**
- Server-side hotspot creation on first alert
- Fixed 500 m perimeter radius
- Cold position matching to identify nearby users for push dispatch
- Hotspot timeout: 30 min inactivity
- Hot location updates: emitter every 30s (GPS), follower every 30s (network)

**Screens**
- S-01 Alert Emission: role toggle, alert type grid, status band, map preview, follower count
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
| AC-03 | Follower acknowledge → emitter follower count increment | < 5 s |
| AC-04 | Emitter closes alert → follower resolution push | < 15 s |
| AC-05 | Cold location update received server-side on > 50 m move | Server log confirmed |
| AC-06 | Background battery drain in cold location mode | < 5% / hour (30 min test) |
| AC-07 | Onboarding completion (permissions granted) | < 3 taps on both platforms |

### Deferred to Phase 2

Alert qualification, stress meter, ghost mode, security groups, official patrol app, surveillance centre web dashboard, credibility scoring, stealth mode, post-event alerts, watcher and first responder authentication, phone number matching, broadcast messages from officials.

### Deferred to Phase 3

Media attachments, freemium statistics, safe escort, tracker registration.

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
