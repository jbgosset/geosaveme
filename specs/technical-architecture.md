# SAVE ME — Technical Architecture Document

> **Version** 0.2 — Added ADR-09 (Fan-out scaling), ADR-10 (Agent reconciliation protocol), MT-06 (BullMQ queue depth), DD-12 (hotspot merge strategy); rate limiting principle clarified in §2 API Gateway  
> **Previous** v0.1 — April 2026  
> **Status** Approved — MVP  
> **Derives from** `SAVEME_MVP_Functional_Scope_v0.1.md`

---

## Table of Contents

1. [Document Purpose](#1-document-purpose)
2. [Architectural Decisions](#2-architectural-decisions)
   - [ADR-01 Push Infrastructure](#adr-01-push-infrastructure)
   - [ADR-02 Cold Location Strategy](#adr-02-cold-location-strategy)
   - [ADR-03 Backend Topology & Geospatial Matching](#adr-03-backend-topology--geospatial-matching)
   - [ADR-04 Real-time Channel](#adr-04-real-time-channel)
   - [ADR-05 Mobile Framework](#adr-05-mobile-framework)
   - [ADR-06 Backend Language & Framework](#adr-06-backend-language--framework)
   - [ADR-07 Deployment Infrastructure](#adr-07-deployment-infrastructure)
   - [ADR-08 Location Data Layer](#adr-08-location-data-layer)
   - [ADR-09 Fan-out Scaling Strategy](#adr-09-fan-out-scaling-strategy)
   - [ADR-10 Agent Reconciliation Protocol](#adr-10-agent-reconciliation-protocol)
3. [Monitoring & Trigger Points](#3-monitoring--trigger-points)
4. [Scaling Ladder](#4-scaling-ladder)
5. [Deferred Decisions](#5-deferred-decisions)

---

## 1. Document Purpose

This document records all significant technical architecture decisions made for the SAVE ME platform prior to implementation. For each decision it captures: the options considered, the rationale for the choice made, the tradeoffs accepted, and the conditions under which the decision should be revisited.

This document changes rarely. It is not an implementation guide — that is the role of `technical-specification.md`. It exists so that future team members, investors, and contributors understand *why* the system is built the way it is, not just *how*.

**Reading order before coding anything:**
1. `functional-specification.md` — what we are building
2. `technical-architecture.md` (this document) — why it is built this way
3. `technical-specification.md` — how to build it

---

## 2. Architectural Decisions

Each decision follows a standard structure:

- **Status** — Approved / Under review / Superseded
- **Context** — why this decision was needed
- **Options considered** — what was evaluated
- **Decision** — what was chosen
- **Rationale** — why
- **Tradeoffs accepted** — what we knowingly gave up
- **Revisit trigger** — the specific condition that would reopen this decision

---

### ADR-01 Push Infrastructure

**Status:** Approved — MVP

**Context:**
Alert notifications must reach follower devices even when the app is closed or in background. iOS and Android have separate native push systems (APNs and FCM respectively). A unified vs split approach must be chosen before any backend or mobile code is written.

**Options considered:**

| Option | Description |
|---|---|
| FCM universal | Single Firebase Cloud Messaging integration handling both Android and iOS |
| APNs direct + FCM | Two separate integrations, one per platform |
| Self-hosted push | Operating own push infrastructure (e.g. Gotify) |

**Decision:** FCM universal (Firebase Cloud Messaging for both Android and iOS).

**Rationale:**
- Single integration: one SDK, one set of credentials, one sending endpoint
- FCM acts as a pass-through to APNs for iOS — no meaningful latency added
- Operated by Google at planetary scale — reliability is proven
- React Native + Expo have mature FCM support via `expo-notifications`
- Splitting to APNs direct is a contained backend change if needed — mobile app is unaffected

**Tradeoffs accepted:**
- Reduced visibility into APNs-level delivery receipts for iOS
- iOS background push (content-available: 1) subject to Apple throttling based on device battery state and usage patterns — FCM adds no control over this behavior
- Google infrastructure dependency

**Revisit trigger:**
Measured iOS background push delivery rate falling below 90% in production, sustained over 7 days, confirmed not attributable to device-level settings.

---

### ADR-02 Cold Location Strategy

**Status:** Approved — MVP

**Context:**
To notify nearby users when a hotspot opens, the server must know their approximate position even when the app is in background. iOS and Android have fundamentally different background location APIs with different constraints on frequency and accuracy.

**Options considered:**

| Option | Description |
|---|---|
| iOS significant-change API + Android FusedLocationProvider/WorkManager | OS-native background location, battery-optimised |
| Geofencing | Define virtual perimeters, OS notifies on entry/exit |
| Frequent background polling | App wakes itself on a timer to send position |

**Decision:** iOS significant-change location API + Android FusedLocationProvider via WorkManager. Accept position staleness. Over-notify rather than under-notify.

**Rationale:**
- Significant-change API is the only reliable background location mechanism on iOS that survives battery optimisation — Apple controls the wake-up frequency (~500m movement detected by carrier network)
- Android WorkManager + FusedLocationProvider is the current Google-recommended approach, survives Doze mode and background restrictions across fragmented Android versions
- Staleness is acceptable: the 500m hotspot radius provides a generous buffer, and a false positive push (user has moved away) is a minor annoyance; a missed push (user is genuinely nearby but not notified) is the worse failure mode
- Cold location history is never persisted — only last known position stored per device, minimising privacy exposure

**Tradeoffs accepted:**
- Server cannot assume regular heartbeats from cold devices — last known position may be stale by hours
- Some pushes will reach users who are no longer within the hotspot radius
- No control over iOS update frequency — Apple decides, not the app

**Revisit trigger — Phase 2 refinements (captured for forward planning):**

The following refinements are explicitly deferred but should be evaluated once real-world delivery data is available:

1. **On-push position confirmation (background):** When a push is received, the app wakes briefly, takes a fresh position check, and suppresses the notification if the user is confirmed outside the hotspot radius. Reduces false positive notifications at the cost of implementation complexity and additional battery use.

2. **On-push position confirmation (foreground prompt):** If the user opens the app from a cold-push notification, the app requests a fresh foreground position before fully surfacing the hotspot. Simpler than background confirmation, better UX signal on actual proximity.

3. **Travel profile inference:** Repeated location update patterns (commute times, frequent locations) could be used to predict when a user is likely to be in a given area and pre-warm their notification priority. Requires storing location history, significantly reduces anonymity, and requires explicit user consent. Only appropriate if anonymity tradeoffs are acceptable and user value is clearly demonstrated. Low priority.

---

### ADR-03 Backend Topology & Geospatial Matching

**Status:** Approved — MVP

**Context:**
When a hotspot is created, the server must identify all users whose last known cold position falls within the hotspot radius and dispatch push notifications to them. This geospatial matching query is the most performance-sensitive operation in the system.

**Options considered:**

| Option | Description |
|---|---|
| Postgres + PostGIS | Relational database with geospatial extension, ST_DWithin query on GiST index |
| Redis GEOSEARCH | In-memory geospatial index using sorted sets with geohash encoding |
| Elasticsearch geo_distance | Search engine with native geo queries |

**Decision:** Postgres + PostGIS exclusively for MVP. Redis deferred unless adopted for pub/sub in ADR-04, in which case its geospatial capability is available as a future read layer.

**Rationale:**
- PostGIS ST_DWithin on a GiST-indexed geometry column executes in milliseconds at any realistic user count for this application
- Single database: one thing to back up, monitor, scale, and reason about
- Redis GEOSEARCH would require maintaining a synchronised mirror of Postgres positions — operational complexity with no measurable benefit at MVP scale
- Postgres handles millions of position records comfortably before any tuning is required
- PostGIS is the industry standard for geospatial queries — well documented, mature, and supported by Fly.io managed Postgres

**Tradeoffs accepted:**
- Slightly higher query latency than Redis in-memory reads — imperceptible at MVP scale
- Disk-based storage for what is essentially ephemeral data (cold positions are overwritten continuously)

**Revisit trigger:**
`pg_stat_statements` showing ST_DWithin hotspot matching queries accounting for > 40% of total Postgres query time, sustained, after read replica has been provisioned (Step 3 in scaling ladder). At that point Redis GEOSEARCH as a hot mirror for position reads becomes worth the operational complexity.

---

### ADR-04 Real-time Channel

**Status:** Approved — MVP

**Context:**
Two UI interactions require live updates while the app is in the foreground: the emitter seeing follower count increment, and the follower seeing hotspot status updates. A mechanism must be chosen to deliver these updates without a full page reload.

**Options considered:**

| Option | Description |
|---|---|
| Polling | Client requests updates every N seconds |
| SSE (Server-Sent Events) | Server pushes updates over persistent HTTP connection |
| WebSockets | Bidirectional persistent connection |

**Decision:** Polling at 5-10 second intervals for MVP. SSE + Redis pub/sub defined as the Phase 2 upgrade path.

**Rationale:**
- The initial alert notification is delivered by FCM push (ADR-01) — this is the safety-critical path and is entirely independent of the real-time channel
- Polling serves only live UI updates on already-open screens — follower count, hotspot status — where a 5-10 second lag is imperceptible and acceptable
- Polling is stateless, scales trivially, works behind any proxy or CDN, requires zero additional infrastructure
- SSE requires maintaining persistent connections across server instances, which needs a pub/sub broker — premature complexity for MVP
- WebSockets are bidirectional overkill for a unidirectional server→client update stream

**Tradeoffs accepted:**
- 5-10 second lag on live UI updates (follower count, hotspot status)
- Wasted requests when nothing has changed — acceptable at MVP scale

**Phase 2 upgrade path (defined now, implemented when triggered):**
SSE with Redis pub/sub as the broker. Node.js handles SSE connections well at the scale where polling becomes a measurable load problem. When multiple app instances are running (Step 4 in scaling ladder), SSE connections require sticky sessions or Redis pub/sub to ensure an update on instance A reaches a client connected to instance B. Redis pub/sub is the cleaner solution and uses the same Redis instance potentially added for geospatial (ADR-03).

**Revisit trigger:**
Polling endpoint p99 latency > 500ms sustained over 30 minutes, confirmed attributable to database read load from polling queries. This is the signal that polling is creating meaningful server load and SSE + Redis pub/sub should be implemented.

---

### ADR-05 Mobile Framework

**Status:** Approved — MVP

**Context:**
The MVP must run on both iOS and Android. The two hardest technical problems — background location and push notification handling — are also the areas where cross-platform frameworks are weakest. The development model (solo founder using Claude Code as coding agent) strongly favours a single codebase.

**Options considered:**

| Option | Description |
|---|---|
| React Native + Expo | JavaScript/TypeScript, single codebase, Expo managed workflow |
| Flutter | Dart, single codebase, strong background task support |
| Native Swift + Kotlin | Maximum platform control, two separate codebases |

**Decision:** React Native with Expo managed workflow.

**Rationale:**
- Single codebase for both iOS and Android — critical for solo development with Claude Code
- Expo managed workflow abstracts native configuration for push notifications (`expo-notifications`) and background location (`expo-location`) — the two hardest MVP problems have mature, well-documented Expo modules
- Expo Go enables physical device testing without a full Xcode/Android Studio build initially
- JavaScript/TypeScript aligns with the backend stack (ADR-06) — one language across mobile and backend, shared type definitions for API payloads possible
- Claude Code context efficiency: single language and framework across the full stack
- Expo bare workflow available if deeply custom native modules are required in Phase 2 — not a dead end

**Tradeoffs accepted:**
- Cross-platform frameworks are weakest in background location and push — Expo modules mitigate this but some native edge cases will require native module work
- Expo managed workflow has constraints — some deeply custom native capabilities require ejecting to bare workflow
- Performance ceiling lower than native — not relevant for this application's workload

**Migration path if native becomes necessary (not a rewrite risk):**
- Most likely path is not a full rewrite but a hybrid: React Native for UI and business logic, native modules (Swift/Kotlin) for background location and push handling, bridged into the React Native layer via Expo bare workflow. This is a well-trodden pattern.
- Full native rewrite would be a contained effort at MVP codebase size (4-12 screens): an experienced native developer could complete it in 6-8 weeks. All API contracts, specifications, and UI designs transfer without change.

---

### ADR-06 Backend Language & Framework

**Status:** Approved — MVP

**Context:**
The backend handles four I/O-bound workloads: receiving high-frequency location updates, running geospatial queries on PostGIS, dispatching FCM pushes, and serving polling requests. Language and framework choice must support async I/O, align with the mobile stack, and support lean iteration with Claude Code.

**Options considered:**

| Option | Description |
|---|---|
| Node.js + TypeScript + Fastify | Async I/O, large ecosystem, aligns with React Native stack |
| Python + FastAPI | Excellent async support, strong geospatial libraries |
| Go | Outstanding concurrency, low memory footprint, steeper learning curve |

**Decision:** Node.js + TypeScript + Fastify.

**Rationale:**
- All workloads are I/O-bound — Node.js async model is well suited
- Fastify is significantly faster than Express and built for high-throughput APIs
- TypeScript across mobile (React Native) and backend enables shared type definitions for API payload schemas — single source of truth for data contracts
- One language across the full stack: Claude Code context efficiency, mobile developer can read backend code and vice versa
- Mature ecosystem for all MVP dependencies: FCM (`firebase-admin`), PostGIS (`pg` + `postgis`), Expo push notifications, polling endpoints
- FCM push dispatch must be implemented as a background job queue (BullMQ on Redis) — not on the synchronous request path. Hotspot creation returns immediately; push dispatch happens asynchronously. This is a day-one implementation requirement, not a future optimisation.

**Tradeoffs accepted:**
- Node.js has a lower ceiling than Go for maintaining very large numbers of simultaneous SSE connections — mitigated by the Phase 2 SSE decision being deferred until load justifies it
- Single-threaded event loop — CPU-bound tasks would block; acceptable since all workloads are I/O-bound

**Component-level migration path (not a full rewrite):**
When specific Node.js limits are reached, individual services are replaced rather than the full backend. Natural migration candidates in order of likelihood:

1. SSE connection manager → Go (if event loop lag or memory triggers are hit after SSE is implemented)
2. Location update ingestor → Go or Rust (if write throughput trigger is hit)
3. Everything else → likely stays Node.js indefinitely

---

### ADR-07 Deployment Infrastructure

**Status:** Approved — MVP

**Context:**
The platform handles sensitive location data for anonymous users. Privacy commitments in the functional spec require European data residency. Infrastructure must be lean to operate, cost-effective at near-zero initial traffic, and scalable without architectural changes.

**Options considered:**

| Option | Description |
|---|---|
| Fly.io (European region) | Container deployment on own bare metal, European data centers |
| Railway / Render | Managed platforms on top of AWS/GCP |
| Hetzner VPS (self-hosted) | European-owned bare metal, maximum control, full ops burden |
| AWS / GCP / Azure | Full managed cloud, American companies, US data access laws apply |

**Decision:** Fly.io, Frankfurt region (fra), managed Postgres with PostGIS extension, containerised Node.js backend.

**Rationale:**
- Fly.io runs on its own bare metal in Frankfurt and Amsterdam — genuinely European infrastructure, not a reseller of AWS/GCP
- Aligns with privacy positioning: user location data does not transit American infrastructure
- Native support for managed Postgres, Redis, and container deployments on one platform — minimal ops surface
- Scales to zero when idle: MVP running costs near zero until real traffic arrives
- Supports persistent SSE connections natively — no infrastructure blocker for Phase 2 real-time channel
- Docker containers are portable: migration to Hetzner dedicated servers is straightforward if cost or control requirements change

**MVP deployment topology:**

```
Fly.io Frankfurt (fra)
├── App instance          — Node.js/Fastify backend (containerised)
├── Managed Postgres      — PostGIS extension enabled, primary instance
└── Managed Redis         — BullMQ job queue for FCM push dispatch

FCM (Firebase Cloud Messaging)
└── Push delivery to iOS (via APNs) and Android
```

**Configuration and secrets:**
- FCM credentials stored as Fly.io secrets — never in code or version control
- All traffic over HTTPS — TLS handled automatically by Fly.io
- Environment configuration via Fly.io secrets and `fly.toml`

**Tradeoffs accepted:**
- Frankfurt to France: ~15-25ms round trip — imperceptible for all use cases
- Fly.io is a smaller vendor than AWS/GCP — mitigated by Docker portability
- Managed Postgres has less tuning flexibility than self-hosted — acceptable until scaling Step 3

**Revisit trigger:**
Fly.io managed Postgres reaching its maximum instance tier while Postgres metrics indicate further vertical scaling is needed. At that point migrate to a self-hosted Postgres instance on Hetzner dedicated hardware within the same Frankfurt region.

---

### ADR-08 Location Data Layer

**Status:** Approved — MVP

**Context:**
Cold location (background, infrequent, persistent) and hot location (foreground, high-frequency, ephemeral) have fundamentally different data characteristics. A decision is needed on whether to use a single database for both or separate storage backends optimised for each workload.

**Workload comparison:**

| Characteristic | Cold Location | Hot Location |
|---|---|---|
| Write frequency | Low — only on significant movement | High — every 30s per active user in hotspot |
| Read pattern | One ST_DWithin query at hotspot creation | Continuous polling during active hotspot |
| Data lifetime | Last position only, history discarded | Relevant only while hotspot is active |
| Consistency requirement | Eventual — hours of staleness acceptable | Near real-time |
| Volume | One row per device, overwritten | Small at any moment, write-intensive |

**Options considered:**

| Option | Description |
|---|---|
| Unified Postgres | Both cold and hot location in same database |
| Split: Postgres (cold) + Redis (hot) | Optimised storage per workload from day one |
| Unified Postgres with repository pattern | Single database, abstracted behind interface, split deferred |

**Decision:** Unified Postgres for MVP, with a repository pattern abstraction from day one. Redis hot location as a defined future upgrade triggered by a specific metric.

**Rationale:**
- At MVP scale and well beyond, Postgres handles both workloads without complaint. Even 1,000 simultaneous active hotspots with 10 followers each updating every 30s generates ~333 writes/second — well within Postgres capability on modest hardware
- Operational simplicity of one database is genuinely valuable at early stage
- The repository pattern abstraction means the split, when it becomes necessary, is a swap of one implementation — zero changes to calling code

**Repository pattern (day-one implementation requirement):**

All location reads and writes must go through a repository interface, never directly to the database from business logic:

```typescript
interface LocationRepository {
  updateCold(mobileID: string, position: ColdPosition): Promise<void>
  updateHot(mobileID: string, hotspotID: string, position: HotPosition): Promise<void>
  getLastCold(mobileID: string): Promise<ColdPosition | null>
  getUsersWithinRadius(lat: number, lng: number, radiusMetres: number): Promise<string[]>
  getHotspotFollowers(hotspotID: string): Promise<HotPosition[]>
}
```

For MVP, one implementation: `PostgresLocationRepository`. When the Redis trigger is hit, a second implementation is added: `RedisHotLocationRepository`. The calling code never changes.

**Tradeoffs accepted:**
- Writing ephemeral hot location data to disk (Postgres WAL) when it could live purely in memory — no measurable impact at MVP scale
- Slightly higher hot location read latency than Redis — imperceptible at MVP scale

**Revisit trigger:**
Postgres write throughput > 5,000 writes/second sustained, with hot location updates identified as the dominant source via `pg_stat_statements`. At that point implement `RedisHotLocationRepository` — hot positions stored as Redis hashes with TTL equal to hotspot timeout, auto-expiring on hotspot close. Cold location remains in Postgres unchanged.

---

### ADR-09 Fan-out Scaling Strategy

**Status:** Approved — MVP (contract defined); implementation scales with load

**Context:**
When a hotspot opens, the server must dispatch push notifications to every user whose last cold position falls within the hotspot perimeter. At two-user MVP scale this is trivial. At city scale during a mass incident — a stadium evacuation, a demonstration — a single hotspot could require notifying thousands of devices simultaneously, and hundreds of hotspots could open within minutes of each other.

The fan-out pipeline is the single highest-throughput operation in the system. Its design must be correct from day one, even if it runs at near-zero load during the MVP.

**Options considered:**

| Option | Description |
|---|---|
| Synchronous dispatch on request thread | Notify all users inline during hotspot creation HTTP request |
| Single async worker via BullMQ | Decouple dispatch from request path; single worker processes queue |
| BullMQ with horizontally scalable workers | Same as above, workers are stateless and can be scaled independently |
| Dedicated fan-out service (separate process) | Extract fan-out into its own deployable, independently scalable service |

**Decision:** BullMQ on Redis with stateless, horizontally scalable workers. Synchronous dispatch is explicitly prohibited. Worker count starts at one for MVP and scales with MT-06 trigger.

**Rationale:**
- Synchronous dispatch blocks the hotspot creation response until every push is sent — unacceptable at any meaningful scale and creates a direct coupling between FCM latency and API response time
- BullMQ is already present in the stack (ADR-06) — fan-out is an additional job type on the existing queue infrastructure, not a new component
- Workers are stateless Node.js processes: scaling from one to N workers is a single configuration change with no code modification
- BullMQ provides job retries, dead-letter queues, and visibility into queue depth — all required for a safety-critical notification pipeline
- A dedicated fan-out service (Option 4) is the right long-term architecture but premature at MVP; BullMQ workers are the stepping stone to it

**Queue partitioning — day-one implementation requirement:**
The BullMQ queue must be partitioned by `hotspotID` from day one. All push jobs for a given hotspot are routed to the same logical queue partition. This ensures that fan-out for one hotspot cannot starve or delay fan-out for another — a critical property during multi-hotspot mass incidents. This is a configuration choice within BullMQ, not a new infrastructure component.

**Tradeoffs accepted:**
- BullMQ workers share the Node.js event loop with the main app process at MVP scale — acceptable at low load; the MT-06 trigger prompts extraction to dedicated worker processes before this becomes a problem
- Redis is a single point of failure for the dispatch queue — mitigated by Fly.io managed Redis with automatic failover; a Redis outage delays push dispatch but does not lose jobs (BullMQ persists to Redis before acknowledging)

**Scaling path (no architectural changes required):**

| Stage | Worker configuration | Approximate capacity |
|---|---|---|
| MVP | 1 worker, co-located with app | ~50 concurrent hotspots |
| Phase 2 | 2–4 dedicated worker processes on separate Fly.io instances | ~500 concurrent hotspots |
| Phase 3+ | N workers, auto-scaled on queue depth | Unbounded — linear scaling |

**Revisit trigger:**
MT-06: BullMQ queue depth sustained above 1,000 jobs for more than 5 minutes. At that point add dedicated worker instances (separate from the main app instance) before increasing worker count further.

---

### ADR-10 Agent Reconciliation Protocol

**Status:** Approved — contract defined for MVP; `/api/sync` endpoint implemented in Phase 2

**Context:**
Agents maintain a local state snapshot of every hotspot they are associated with (established in `technical-specification.md` §0.1 and §3.3). This snapshot enables offline-tolerant operation. However, the current spec underspecifies what happens when an agent reconnects after a period of disconnection.

The naive approach — "refresh known hotspot IDs" — is insufficient. An agent that was offline when a hotspot closed and a new one opened nearby will have a stale `open` entry in its cache and will be unaware of the new hotspot entirely. Its local state is not just stale — it is structurally incomplete.

This is a safety issue, not just a UX issue. An emitter whose phone died and recharged during an active hotspot must not silently re-enter an incorrect state.

**Options considered:**

| Option | Description |
|---|---|
| Refresh known hotspot IDs only | Agent sends known hotspot IDs; server returns updated state for each |
| Pull-on-reconnect with position | Agent sends position + known hotspot state map; server returns full diff |
| Server-push on reconnect | Server detects reconnection and pushes relevant state proactively |

**Decision:** Pull-on-reconnect with position via a dedicated `POST /api/sync` endpoint. Contract defined now; implementation deferred to Phase 2. Mobile cache data structure designed for MVP to support this contract from day one.

**Rationale:**
- Option 1 (refresh known IDs only) fails the structural incompleteness case: the agent cannot ask for hotspots it doesn't know exist
- Option 3 (server-push on reconnect) requires the server to detect reconnection events, which is fragile across polling and push architectures — there is no reliable reconnection signal from a cold device
- Option 2 gives the server everything it needs to compute a complete diff: what the agent knew, and where the agent is now
- Defining the contract now constrains the mobile cache data structure to be sync-ready from the start. Retrofitting this later would require a breaking change to the cache schema

**`POST /api/sync` — contract definition:**

Request:
```json
{
  "mobileID": "hash(deviceID)",
  "position": {
    "lat": 48.8566,
    "lng": 2.3522,
    "accuracy": 22.0,
    "timestamp": "2026-04-01T14:32:00Z"
  },
  "knownHotspots": [
    { "hotspotID": "uuid-v4", "version": "2026-04-01T14:30:00Z" },
    { "hotspotID": "uuid-v4", "version": "2026-04-01T14:28:00Z" }
  ]
}
```

Response:
```json
{
  "updates": [
    {
      "hotspotID": "uuid-v4",
      "status": "open | closed",
      "lastAlertType": "danger",
      "version": "2026-04-01T14:35:00Z"
    }
  ],
  "closures": [
    { "hotspotID": "uuid-v4", "closedAt": "2026-04-01T14:33:00Z" }
  ],
  "nearby": [
    {
      "hotspotID": "uuid-v4",
      "alertType": "police",
      "distance": 180,
      "version": "2026-04-01T14:34:00Z"
    }
  ]
}
```

- `updates` — hotspots the agent knew about whose server version is newer than the agent's cached version
- `closures` — hotspots the agent knew about that have since closed
- `nearby` — hotspots that opened near the agent's reported position while it was offline, and that the agent has no record of

**Mobile cache data structure — day-one MVP requirement:**

The mobile cache must store `hotspotID → { state, version }` pairs, not just hotspot state. This is the minimum structure required to construct the `knownHotspots` array in the sync request. If implemented as a flat state map without versions, the sync endpoint cannot be adopted without a cache schema migration.

```typescript
interface HotspotCacheEntry {
  hotspotID:     string
  status:        'open' | 'closed'
  lastAlertType: string
  version:       string   // ISO timestamp — the version of the last server update applied
  participantCount: { civilians: number; forces: number }
  lastUpdatedLocally: string
}

type HotspotCache = Map<string, HotspotCacheEntry>
```

**Tradeoffs accepted:**
- `/api/sync` endpoint is not implemented in MVP — agents that go offline during the two-user MVP test will need to restart the app to re-sync (acceptable at MVP scale; documented as a known limitation)
- The sync response `nearby` field requires a geospatial query at sync time — same PostGIS query as hotspot creation fan-out, no new infrastructure

**Revisit trigger:**
First report of an agent re-entering incorrect hotspot state after a real connectivity loss (not a controlled test). At that point implement the `/api/sync` endpoint as a Phase 2 priority, using the contract defined here.

---

## 3. Monitoring & Trigger Points

All metrics must be exposed via a `/metrics` endpoint on the backend, scraped by a monitoring stack (Fly.io metrics + an external alerting tool such as Grafana Cloud free tier or Uptime Robot for MVP).

Alerts fire when a metric is sustained above threshold for **30 minutes minimum** — not on spikes. Spikes are handled by Fly.io burst capacity automatically.

---

### MT-01 — Node.js Event Loop Lag > 100ms sustained

**Measured by:** `perf_hooks` loop lag monitor exposed on `/metrics`

**Tooling:** `clinic.js` or custom loop lag sampler

**What it signals:** Node process is CPU-saturated. A hot code path is blocking the event loop.

**Response:**
1. Profile with `clinic flame` to identify the blocking path
2. If the SSE connection manager is the source → extract to Go service (ADR-06 migration path)
3. If geospatial computation has leaked into backend code → push back into PostGIS where it belongs

---

### MT-02 — Node.js Memory per Instance > 512MB sustained

**Measured by:** `process.memoryUsage()` exposed on `/metrics`, alert on rising trend over 30 minutes

**What it signals:** SSE connection leak (connections not cleaned up on client disconnect) or unbounded in-memory cache growth

**Response:**
1. Audit SSE connection lifecycle — most common source
2. If structural rather than a bug → extract real-time connection service to Go (goroutine-per-connection model has dramatically lower memory overhead)

---

### MT-03 — Postgres ST_DWithin Query p99 > 200ms

**Measured by:** `pg_stat_statements` extension, slow query log exposed to monitoring stack

**Alert on:** p99 not average — average masks tail latency which is what users experience at scale

**What it signals:** GiST index under pressure from combined high write frequency (location updates) and high read frequency (hotspot matching)

**Response:**
1. Run `EXPLAIN ANALYZE` to confirm GiST index is being used — if not, rebuild index
2. Partition position table by geohash prefix to reduce index size per partition
3. If insufficient → introduce Redis GEOSEARCH as read layer (ADR-03 revisit trigger)

---

### MT-04 — FCM Push Dispatch p99 > 2s

**Measured by:** Instrument FCM dispatch calls with start/end timestamps, expose p99 on `/metrics`

**What it signals:** Either FCM infrastructure degradation (check Firebase status page first) or push dispatch queue backing up

**Response:**
1. Check Firebase status page — if FCM is degraded, no action required beyond monitoring
2. If queue is backing up → confirm BullMQ async dispatch is implemented correctly (this should be a day-one implementation — see ADR-06)
3. Scale BullMQ worker instances if queue depth is growing

---

### MT-05 — Polling Endpoint p99 > 500ms

**Measured by:** Standard HTTP response time metrics on polling routes

**What it signals:** Enough concurrent active users that polling is creating meaningful database read load

**Response:**
Implement SSE + Redis pub/sub (ADR-04 Phase 2 upgrade). Polling endpoints remain as fallback. This is a good problem — it means real user volume.

---

### MT-06 — BullMQ Queue Depth > 1,000 Jobs sustained > 5 minutes

**Measured by:** BullMQ `queue.getWaitingCount()` exposed on `/metrics`; alert on sustained depth, not transient spikes

**What it signals:** Fan-out workers are not keeping pace with push job creation rate. Either a high-volume incident is generating exceptional load, or worker capacity is structurally insufficient.

**Response:**
1. Check whether a single exceptional hotspot is the source (one large-radius hotspot in a dense area) — if so, monitor; this is expected burst behaviour
2. If sustained across multiple hotspots → add dedicated BullMQ worker instances on separate Fly.io machines (see ADR-09 scaling path, Phase 2 configuration)
3. Confirm queue partitioning by `hotspotID` is active — if not, implement immediately (ADR-09 day-one requirement)
4. If queue depth continues to grow after adding workers → escalate to ADR-09 Phase 3 auto-scaling configuration

**Note:** A growing queue does not affect alert emission or hotspot creation — those are synchronous and unaffected by worker throughput. It affects only the time between hotspot creation and follower notification. Monitor `time-to-first-notification` as a secondary metric alongside queue depth.

---

## 4. Scaling Ladder

Each step is triggered by sustained measured metrics, never by projected load. "Sustained" means above threshold for 30 minutes minimum.

---

### Step 1 → Step 2: Vertical Scaling

**From:** Default Fly.io instance sizes  
**To:** Larger Postgres instance + larger app instance  
**Effort:** Configuration only, zero downtime, zero code changes  
**Estimated user volume at trigger:** 5,000–15,000 active users

**Triggers (any one sustained):**

| Metric | Threshold |
|---|---|
| Postgres CPU | > 70% sustained |
| Postgres memory | > 80% — working set no longer fits in shared_buffers |
| App instance CPU | > 60% sustained |
| Event loop lag (MT-01) | Approaching 100ms |
| Location update endpoint p99 | > 300ms |

---

### Step 2 → Step 3: Read Replica

**From:** Single Postgres instance  
**To:** Primary for writes, read replica for cold location queries and polling  
**Effort:** Provision replica (one Fly.io command), update connection pool config to route reads to replica. Minimal code change.  
**Estimated user volume at trigger:** 20,000–50,000 active users

**Triggers (all should be present together):**

| Metric | Threshold |
|---|---|
| Postgres CPU | Consistently > 70% after vertical scaling |
| ST_DWithin query share | > 40% of total Postgres query time (pg_stat_statements) |
| Read/write ratio | > 80% reads — confirms replica would absorb meaningful load |
| Hotspot creation endpoint p99 | > 500ms |

---

### Step 3 → Step 4: Horizontal App Scaling

**From:** Single app instance  
**To:** Multiple app instances behind Fly.io load balancer  
**Effort:** `fly scale count 3` — automatic load balancing. No code changes for stateless endpoints.  
**Estimated user volume at trigger:** 50,000–100,000 active users

**Triggers (any one sustained):**

| Metric | Threshold |
|---|---|
| App instance memory | > 400MB sustained |
| App instance CPU | > 80% after vertical scaling |
| Event loop lag (MT-01) | > 50ms sustained |
| Polling endpoint p99 (MT-05) | > 300ms |

> **Implementation prerequisite:** Before scaling beyond one instance, confirm SSE connections (if Phase 2 real-time channel is implemented) use Redis pub/sub correctly. Stateless polling endpoints scale without any prerequisite.

---

### Step 4 → Step 5: Multi-region

**From:** Single Frankfurt region  
**To:** Second Fly.io region (US-East or Southeast Asia depending on measured growth geography)  
**Effort:** 2–4 weeks engineering. First step requiring meaningful architectural work — regional routing at API gateway level, data residency policy per region, legal review.  
**Estimated user volume at trigger:** 200,000+ active users with confirmed geographic distribution

**Triggers (all three must be present):**

| Metric | Threshold |
|---|---|
| Non-European active users | > 30% of total, sustained over 30 days |
| Alert emission endpoint p99 from non-European users | > 800ms — confirms latency is a real UX problem |
| Legal/compliance review | Confirms data residency requirements for the new region are understood and manageable |

---

## 5. Deferred Decisions

Items explicitly deferred from the architecture discussion. Each has a defined trigger or phase for revisitation.

| ID | Topic | Deferred To | Trigger for Revisitation |
|---|---|---|---|
| DD-01 | iOS APNs direct integration | Phase 2 | Measured iOS background push delivery rate < 90% sustained over 7 days |
| DD-02 | On-push position confirmation (background) | Phase 2 | False positive push rate measurably impacting user trust (qualitative signal from user feedback) |
| DD-03 | On-push position confirmation (foreground) | Phase 2 | As above — evaluate alongside DD-02 |
| DD-04 | Travel profile inference for predictive notifications | Phase 3+ | Requires explicit user consent mechanism and anonymity tradeoff evaluation. Only if user value is clearly demonstrated. |
| DD-05 | Redis GEOSEARCH as geospatial read layer | Phase 2–3 | MT-03 trigger: ST_DWithin queries > 40% of Postgres query time after read replica provisioned |
| DD-06 | SSE + Redis pub/sub real-time channel | Phase 2 | MT-05 trigger: polling endpoint p99 > 500ms sustained |
| DD-07 | Redis hot location repository | Phase 2–3 | Postgres write throughput > 5,000 writes/second with hot location as dominant source |
| DD-08 | Go SSE connection service | Phase 3 | MT-01 + MT-02 both triggered after SSE implemented, confirmed attributable to connection management |
| DD-09 | Self-hosted Postgres on Hetzner | Phase 3 | Fly.io managed Postgres reaching maximum instance tier |
| DD-10 | Multi-region deployment | Phase 4 | Step 4→5 scaling triggers all met simultaneously |
| DD-11 | Sharding | Phase 4+ | Not anticipated. Revisit only if multi-region Step 5 proves insufficient — extremely high bar. |
| DD-12 | Hotspot merge strategy | Phase 2 | Pending dedicated design session. Direction: server-side correlation and merge via rule engine (merge-not-deduplicate), not creation-time prevention. See discussion notes. |
| DD-13 | Hotspot closure safety guards | Phase 2 | Pending persona and security context analysis. Covers: minimum open duration, official veto of emitter `secure` signal. |
| DD-14 | `/api/sync` endpoint implementation | Phase 2 | First confirmed agent reconnection producing incorrect hotspot state in production. Contract defined in ADR-10. |
| DD-15 | BullMQ dedicated worker processes | Phase 2 | MT-06 trigger: queue depth > 1,000 jobs sustained > 5 minutes |
