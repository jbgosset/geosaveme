# GeoSaveMe — Functional Specification

> **Status** Living document — updated as phases are delivered  
> **Current phase** MVP (v0.1)  
> **Backlog reference** `docs/decisions/full-product-vision.md`  
> **Scope decisions** `docs/decisions/mvp-functional-scope-v0.1.md`  
> **History** See `CHANGELOG.md` and git log for change history between phases

---

## Table of Contents

1. [Context & Vision](#1-context--vision)
2. [Core Values](#2-core-values)
3. [User Types](#3-user-types)
4. [Use Cases](#4-use-cases)
5. [Alert Data Model](#5-alert-data-model)
6. [Hotspot & Broadcasting](#6-hotspot--broadcasting)
7. [Screens & Flows](#7-screens--flows)
8. [Open Questions](#8-open-questions)

---

## How to Read This Document

Sections and subsections are tagged with the phase in which they were introduced or last updated:

- `[MVP]` — implemented in the initial release, two-user proof of concept
- `[Phase 2]` — planned next extension, not yet implemented
- `[Phase 3]` — future consideration, not yet designed in detail
- `[Backlog]` — identified in the full product vision, not yet scheduled

When a phase is delivered, its tags are not removed — they record when each capability entered the system. New capabilities added in a later phase are appended to the relevant section with their own tag.

---

## 1. Context & Vision

### 1.1 Problem Statement

A significant gap exists between minor security incidents and formal emergency calls. Many events — harassment, threatening behaviour, accidents without casualties — go unreported because the available tools are binary: either do nothing or call emergency services.

GeoSaveMe fills this gap by providing a **geolocated civilian alert network** that connects:
- People in danger or witnessing an incident
- Nearby civilians who can assist or avoid the area
- Patrol officers who can respond preemptively
- Surveillance centres that can correlate incoming alerts with dispatch calls

### 1.2 Core Principle and Alert Lifecycle `[MVP]`

The app operates on **real-time local proximity**. Alerts are never broadcast globally — they are distributed only to users within the relevant geographic perimeter. This prevents media amplification and keeps the system operationally focused.

1. A victim or witness opens an alert (unsecure / danger / police / fire)
2. A **hotspot** is created at their GPS location
3. Nearby users receive a push notification and can choose to respond
4. Officials in the district see the hotspot on their map `[Phase 2]`
5. The alert remains open until the server closes the hotspot based on defined rules
6. Button press frequency is logged to estimate stress level `[Phase 2]`

### 1.3 Architectural Principle — Agent Autonomy and Event-Driven Lifecycle `[MVP]`

This principle is foundational. It governs the API contract, the mobile data model, and the server's role across all phases. It must be understood before reading any screen or use case.

#### Agents are autonomous; the central system is the rule engine

Every mobile device participating in the GeoSaveMe network — whether emitter, follower, watcher, or official — is an **autonomous agent**. It maintains a local state snapshot of every hotspot it is associated with, including the last known alert type, participant count, and a version timestamp. This snapshot is sufficient to render a coherent UI and support basic interactions without a network connection.

The central system does not push instructions to agents. It receives **events** from agents, applies rules, and pushes **state updates** back. Agents consuming an update replace their local snapshot only if the incoming version timestamp is more recent than their own. The platform is therefore **offline-tolerant by design**: an agent that loses connectivity degrades gracefully and re-syncs from server state on reconnection.

#### All agent-to-server communications are events

An **event** is any structured signal emitted by an agent that describes a change in the agent's assessment of or relationship to a situation. Events fall into two families:

- **Alert events** — situation assessments emitted by emitters and witnesses: `unsecure`, `danger`, `police`, `fire`, `secure`. The `secure` signal is an alert event like any other — it is not a command to close the hotspot. It is a signal the server receives and evaluates.
- **Participation events** — presence signals emitted by followers, watchers, officials, and first responders: acknowledging a hotspot, updating position, changing response type, departing.

There is no semantic distinction between "opening" and "closing" from the agent's perspective. Both are events transmitted to the server using the same envelope structure.

#### Hotspot lifecycle is owned by the central system

The central system is the sole authority over hotspot lifecycle. It receives alert events and participation events from all associated agents and applies **configurable closure rules** to decide when a hotspot transitions from `open` to `closed`. In the MVP, the rule is:

> *If the original emitter sends a `secure` alert event, the hotspot is closed.*

This rule will evolve without requiring client updates. Future rules may include:

- Hotspot closed when an official on scene emits a `secure` qualification
- Hotspot closed when a quorum of followers independently emit `secure` signals
- Hotspot closed after a configurable inactivity timeout
- Hotspot kept open by the server despite an emitter `secure` signal, if an official has escalated severity

#### What the central system never does

The central system never issues commands to agents. It does not tell an agent to stop alerting, change alert type, or go offline. It publishes state — agents subscribe and update their local snapshot. This boundary is operationally critical: an emitter in a dangerous situation must never have their alert suppressed by a remote actor.

### 1.4 Design Constraints

- **Anonymous by default** — public users have no account, no password, no personal profile
- **No social media sharing** — prevents viral amplification and mob behaviour
- **Local only** — alerts are geographically scoped
- **Neutral** — the app qualifies situations and danger levels, never individuals
- **Minimalist data** — no location history stored, only last known position per device
- **Auditable** — codebase is public for security and trust purposes

---

## 2. Core Values

### Safety
The safety of individuals is the primary objective. Any mechanism that compromises this objective must be corrected or removed.

### Neutrality
The platform must not favour any preconceived notion of aggressors or users. Reinforced by the anonymity principle.

### Anonymity
Users are anonymous — only their devices are identified. The identity of first responders and security forces is known to the platform but never shared publicly.

### Minimalism
No tracking beyond security purposes. No profiling, no hidden marketing. Any personal information required during events is deleted afterward.

### Auditability
The codebase is public for security and confidence purposes.

---

## 3. User Types

### 3.1 Anonymous User — Victim or Witness `[MVP]`

A person who feels in danger, is the victim of an aggression, or witnesses an incident. Opens the app and emits an alert.

**Key behaviours:**
- Selects role: Victim or Witness
- Taps alert type (unsecure / danger / police / fire)
- Keeps the alert open until resolved
- Signals resolution by tapping Secure (hold 2s to confirm), which emits a `secure` alert event

**Privacy:** fully anonymous. No account required. Identified only by a hashed device ID.

**Deferred behaviours:**
- Adds context / qualification to the alert `[Phase 2]`
- Stress estimated from button press frequency `[Phase 2]`
- Notifies friends and family via security group `[Phase 2]`
- Emits alert in ghost mode (forces only) `[Phase 2]`

---

### 3.2 Anonymous User — Bystander / Follower `[MVP]`

A member of the public geographically near an active hotspot.

**Key behaviours:**
- Receives push notification when a nearby hotspot opens
- Opens app from notification, sees hotspot on map
- Taps Acknowledge — emits a participation event, shares approximate position
- Their count is shown to the emitter as reassurance

**Privacy:** position shared only approximately, not precisely.

**Deferred behaviours:**
- Chooses a response beyond acknowledge: flee, neutral, assist, call `[Phase 2]`
- Sends a message to the hotspot thread `[Phase 2]`
- Qualifies the hotspot on arrival `[Phase 2]`

---

### 3.3 Official — Patrol `[Phase 2]`

A verified professional from a security or emergency service (police, gendarmerie, fire brigade, SAMU).

**Key behaviours:**
- Authenticated via a verified organisational account
- Receives real-time alerts within their assigned district
- Sees alert details including emitter phone number (for emergency call correlation)
- Qualifies a hotspot once on scene — emitting a qualification participation event
- Can operate in stealth mode (hidden from public map)
- Can emit ghost alerts visible only to forces

**Privacy:** not anonymous — accountable to their organisation.

---

### 3.4 Official — Surveillance Centre `[Phase 2]`

A dispatcher operating a district-level surveillance dashboard.

**Key behaviours:**
- Views district map with live hotspot pins
- Matches incoming call phone numbers to hotspot pins
- Clicks pin to see alert details, participant count, stress level
- Broadcasts targeted messages to a hotspot area

---

### 3.5 Security Group Member — Friend or Family `[Phase 2]`

A person granted access to an emitter's security group.

**Key behaviours:**
- Receives push notification regardless of geographic proximity when a group member emits an alert
- Sees basic alert status (type, rough location, open/closed)
- Cannot interact with the hotspot directly

**How to join:** scan the emitter's personal QR code.

---

### 3.6 Watcher `[Phase 2]`

A non-anonymous user who has agreed to share their identity, strengthening trust and credibility in the network.

**Key behaviours:**
- Authenticated via a third-party identity provider (Google, Microsoft)
- All follower behaviours plus elevated credibility weighting
- Visible to officials as a verified presence on the hotspot

---

### 3.7 First Responder `[Phase 2]`

A validated member of a recognised civil rescue association (Red Cross, VISOV, physician).

**Key behaviours:**
- Validated via association membership
- Not anonymous — accountable to their association
- Receives accurate emitter location (like officials) for active hotspots

---

### 3.8 User Trust Levels `[Phase 2]`

| Title | Description |
|---|---|
| **Anonymous** | Default. No identity disclosed. |
| **Watcher** | Non-anonymous, identity shared via third-party auth. |
| **First Responder** | Validated via recognised association membership. |
| **Official** | Security professional accredited by a public or private security body. |

---

## 4. Use Cases

### 4.1 UC-01 — Emit an Alert `[MVP]`

| Field | Value |
|---|---|
| Actor | Emitter (victim or witness) |
| Precondition | App installed, location permission granted (foreground + background), push permission granted |
| Trigger | User taps an alert type button |
| Main flow | 1. User opens app  2. Selects role: Victim or Witness  3. Taps alert type (Unsecure / Danger / Police / Fire)  4. App captures GPS position with high accuracy  5. Alert event transmitted to server  6. Server creates hotspot and stores delivered alert  7. Push notification sent to all users within radius  8. Status band shows elapsed time and connection status |
| Post-condition | Hotspot is `open` and visible to nearby followers; alert status is `delivered` |
| Deferred | Context / qualification form `[Phase 2]`, stress meter `[Phase 2]`, ghost mode `[Phase 2]`, security group broadcast `[Phase 2]` |

---

### 4.2 UC-02 — Receive an Alert (Follower) `[MVP]`

| Field | Value |
|---|---|
| Actor | Follower (bystander) |
| Precondition | App installed, background location running (cold), push notifications granted |
| Trigger | A hotspot is created within the follower proximity radius |
| Main flow | 1. Server matches follower cold position to hotspot perimeter  2. Push notification delivered: alert type + distance  3. Follower opens app  4. Map view shows hotspot (approximate emitter position)  5. Follower taps Acknowledge — participation event transmitted (hot, approximate position)  6. Emitter sees participant count increment |
| Post-condition | Follower is registered as a participant on the hotspot via a HotspotParticipation record |
| Deferred | Response options (Flee / Assist / Call) `[Phase 2]`, follower-to-emitter messaging `[Phase 2]`, credibility update `[Phase 2]` |

---

### 4.3 UC-03 — Signal Resolution (Emitter) `[MVP]`

| Field | Value |
|---|---|
| Actor | Emitter |
| Trigger | User taps Secure button (hold 2s to confirm) |
| Main flow | 1. App transmits a `secure` alert event to server  2. Server evaluates active closure rules  3. If rules are met: hotspot status set to `closed`, push sent to all participants — hotspot resolved, location tracking reverts to cold mode for all agents  4. If rules are not met: server acknowledges event; hotspot remains open pending further signals |
| Post-condition | If closed: hotspot archived, no further notifications sent. If not yet closed: emitter UI reflects the signal was received; hotspot remains active. |
| Note | In the MVP, the closure rule is: a `secure` event from the original emitter closes the hotspot. This rule is server-side and will be extended in later phases without requiring client changes. |
| Deferred | Post-event qualification `[Phase 2]`, official-triggered closure `[Phase 2]`, quorum closure `[Phase 3]`, duration statistics export `[Phase 3]` |

---

### 4.4 UC-04 — Background Cold Location `[MVP]`

| Field | Value |
|---|---|
| Actor | Any user (passive) |
| Trigger | App running in background |
| Main flow | 1. OS wakes app periodically  2. Position sent only if user has moved > 50 m since last update  3. Server stores last known position (not history)  4. On new hotspot creation, server queries users within radius and dispatches push |
| Post-condition | User is reachable for hotspot notifications without foreground activity |
| Notes | iOS: significant-change location API. Android: WorkManager + FusedLocationProvider. Approximate accuracy (NETWORK_PROVIDER), battery-optimised. |

---

### 4.5 UC-05 — Qualify an Alert `[Phase 2]`

The emitter or a witness adds structured context to an active alert. Qualification is asynchronous — the alert is emitted immediately, context is added progressively as the situation allows.

**Qualification dimensions:**

| Dimension | Options |
|---|---|
| Severity | Insecurity (perceived), incivility, assault, theft, rape, accident |
| Target | Person or object; if person — verbal (no contact) or physical (with contact) |
| Fact | Insult, noise nuisance, exhibitionism, sexual touching, pickpocketing, burglary, degradation |
| Perception | Sexual, racial, religious, or homophobic dimension |
| Aggravating factors | With threats, intoxicated, in a group, presence of weapon, presence of injured persons |
| Public mission | Security, public order, or sanitation |

---

### 4.6 UC-06 — Official Receives Hotspot (Patrol) `[Phase 2]`

The officer receives a hotspot notification on their mobile within their district. They see alert type, participant count, and emitter phone number (if authorised). They navigate to the scene and emit a qualification participation event on arrival.

---

### 4.7 UC-07 — Official Matches Call to Hotspot (Surveillance Centre) `[Phase 2]`

A call comes in simultaneously with a hotspot pin appearing on the district map. The dispatcher matches the phone number on the call to the pin and clicks it to see full context: alert type, stress level, qualifications, participant count.

---

### 4.8 UC-08 — Security Group Alert `[Phase 2]`

The emitter opts to alert their personal security group. Members receive a push notification regardless of their geographic location. They see alert status in real time.

---

### 4.9 UC-09 — Post-Event Alert `[Phase 2]`

A user reports an event after the fact — because they could not do so safely at the time, or to contribute to statistical awareness. Creates a time-stamped alert record without an active hotspot.

---

### 4.10 UC-10 — Ghost Alert `[Phase 2]`

The emitter activates ghost mode before emitting. The alert event is sent only to security professionals — not broadcast to nearby civilians. Used when local broadcast could provoke counter-aggression.

---

### 4.11 UC-11 — Safe Escort `[Phase 3]`

A user requests a virtual escort for a journey. A security group member or watcher monitors their live position until they confirm arrival safely.

---

### 4.12 UC-12 — Tracker Registration `[Phase 3]`

A user registers a tracking device (AirTag equivalent). They are alerted when the tracker enters an active hotspot area.

---

## 5. Alert Data Model

This section describes the three distinct entities that together represent the state of an active security situation: **Alert**, **Hotspot**, and **HotspotParticipation**. They are separate entities with separate lifecycles, fed by the two families of agent events described in §1.3.

### 5.1 Alert Types `[MVP]`

Alert events are situation assessments emitted by agents. All types share the same event envelope. `secure` is not a control signal — it is an alert type like any other, evaluated by the server's closure rule engine.

| Key | Label | Severity | Phase |
|---|---|---|---|
| `secure` | Secure (signals resolution to server) | 0 | MVP |
| `unsecure` | Unsecure | 1 — Low | MVP |
| `danger` | Danger | 2 — High | MVP |
| `police` | Police Call | 3 — Emergency | MVP |
| `fire` | Fire / Rescue Call | 3 — Emergency | MVP |

### 5.2 Alert Status `[MVP]`

Alert status reflects transmission reliability only — the lifecycle of the situation itself is tracked on the Hotspot entity (§5.3), not on individual alerts.

| Status | Description |
|---|---|
| `sent` | Alert event created on device, transmitted to server, awaiting ACK |
| `delivered` | Server confirmed receipt and attached the event to the hotspot |

There is no `read` status on an alert. Whether and by whom a hotspot's associated alerts have been reviewed is a property of the hotspot and its participation records, not of any individual alert event.

### 5.3 Hotspot Status `[MVP]`

The hotspot is the server-owned lifecycle entity. Its status is determined exclusively by the central system's rule engine, not by any single agent action.

| Status | Description |
|---|---|
| `open` | Hotspot is active; alert events and participation events are being collected; followers are being notified |
| `closed` | Hotspot lifecycle has ended; no further broadcasts; all associated agents receive a closure notification |
| `archived` *(Phase 3)* | Closed hotspot retained in the historical record for statistics and reporting |

Closure rules are server-side and configurable. In the MVP:
- A `secure` alert event from the original emitter closes the hotspot.

In later phases, additional rules will be layered without client changes:
- Official on-scene qualification triggers closure
- Quorum of participant `secure` signals triggers closure
- Configurable inactivity timeout triggers closure

### 5.4 HotspotParticipation `[MVP]`

A participation record represents the relationship between an agent and a hotspot. It is created when a follower acknowledges a hotspot and updated as the agent's position or response changes. It is distinct from an alert event: it carries no situation assessment, only presence and position data.

| Field | Notes | Phase |
|---|---|---|
| `agentID` | Hashed device ID of the participant | MVP |
| `hotspotID` | Linked hotspot | MVP |
| `role` | `follower` \| `watcher` \| `first_responder` \| `official` | MVP / Phase 2 |
| `position` | Hot location snapshot; approximate for followers, precise for officials | MVP |
| `joinedAt` | Timestamp of first acknowledgement event | MVP |
| `lastSeenAt` | Timestamp of last position update event | MVP |
| `response` | `acknowledge` \| `flee` \| `neutral` \| `assist` \| `call` | Phase 2 |
| `qualification` | On-scene hotspot validation emitted by the participant | Phase 2 |

The participant count displayed to the emitter is a live query on HotspotParticipation records for that hotspot — it is derived, never stored as a field on the hotspot itself.

### 5.5 Alert Modes `[Phase 2]`

| Mode | Description |
|---|---|
| **Standard** | Alert broadcast locally to nearby users and officials |
| **Ghost** | Alert event sent to security professionals only — not broadcast locally |
| **Private** | Alert broadcast to security group members only |
| **Stealth** *(pro only)* | Official's participation record not shown on public map near intervention area |
| **Remote / Delayed** | Hotspot created after the fact with a specified time and location |

### 5.6 Issuer Position `[Phase 2]`

| Position | Notes |
|---|---|
| **Witness** *(default)* | Preferred for qualification and assisting responders |
| **Victim** | Personal target — must be explicitly activated by the user |

### 5.7 User Credibility `[Phase 2]`

Credibility scores are transmitted to security forces only. Not shown to the emitter. Not permanent — evolves over time.

| Score | Profile |
|---|---|
| **Pro** | All certified first responders and officials |
| **2** | Alerts corroborated by simultaneous alerts, hotspot confirmed by security services |
| **1** | Default — any user who has not yet interacted with the system |
| **0.5** | Statistically excessive submissions not corroborated by others |
| **0** | Alert on a hotspot subsequently qualified as a false alarm by security forces |

### 5.8 Geolocation Payload `[MVP]`

All agent-to-server communications — both alert events and participation events — share a common geolocation envelope. The `source` field distinguishes event families.

```json
{
  "mobileID":  "hash(deviceID)",
  "hotspotID": "hash(deviceID + timestamp)",
  "source":    "base | alert | follower | official",
  "eventType": "unsecure | danger | police | fire | secure | acknowledge | position_update | qualification",
  "position": {
    "type":      "cold | hot",
    "lat":       48.8566,
    "lng":       2.3522,
    "accuracy":  12.5,
    "timestamp": "2026-04-01T14:32:00Z",
    "provider":  "GPS_PROVIDER | NETWORK_PROVIDER"
  },
  "cinetic":   "still | onslowmove | onfastmove"
}
```

> `hotspotID` is `null` for cold background position updates.  
> `eventType` enables the server rule engine to route and process events without inspecting payload content.

---

## 6. Hotspot & Broadcasting

### 6.1 Hotspot Creation `[MVP]`

A hotspot is created server-side on receipt of the first alert event from an emitter not already associated with an active hotspot. The hotspot is the aggregation point for two independent event streams:

- **Alert events** from emitters and witnesses — carry situation assessment
- **Participation events** from followers, watchers, and officials — carry presence and position

The server processes these streams independently. Hotspot state (status, participant count, stress level, credibility) is computed from both streams but derived separately for each dimension. No single event type has authority over all hotspot state.

**MVP parameters:**
- Perimeter radius: fixed at 500 m
- All users whose last cold position falls within the perimeter receive a push notification
- Hotspot persists until server closure rules are met, or server timeout (30 min inactivity)
- All subsequent alert events raised within the perimeter are attached to the existing hotspot

### 6.2 Hot Location — Active Agents `[MVP]`

| Actor | Update Frequency | Accuracy | Provider |
|---|---|---|---|
| Emitter (while alert open) | Every 30 s | High (GPS) | GPS_PROVIDER |
| Follower (after acknowledge) | Every 30 s | Approximate | NETWORK_PROVIDER |
| Official on patrol `[Phase 2]` | Every 10 s | High (GPS) | GPS_PROVIDER |

### 6.3 Cold Location — Background `[MVP]`

| Condition | Behaviour |
|---|---|
| Still (< 50 m since last update) | No update sent |
| Slow move (< 30 km/h) | Update every 10 min |
| Fast move (> 30 km/h) | No update until still for 5 min, then one update |

> Cold location history is never persisted. Only the last known position is stored per device.

### 6.4 Vigilance Zone `[Phase 2]`

A slightly wider perimeter around the hotspot. Triggers more frequent location updates for users within it, anticipating their movement into the hotspot area.

### 6.5 Security Groups `[Phase 2]`

Groups broadcast alerts independently of location — members receive notifications regardless of geographic proximity.

**Two group types:**

**My Security Group (personal):**
- Every user is the sole owner and administrator of their own security group
- Membership granted by scanning the owner's personal QR code
- Owner can remove or silence any member at any time

**Extended Security Group (organisational):**
- Any user can create a named group and share administrator rights
- Designed for security teams at events, organisations, or associations
- Administrators receive accurate alert location (like officials)
- Joining modes: free (open) or validated (request approval)
- Broadcast modes: to administrators only, or to all members

**General group rules:**
- Members identify themselves within a group by a chosen pseudonym
- All membership levels can emit alerts within the group
- Members can silence or leave any group at any time

### 6.6 Force District `[Phase 2]`

Defines a geographic area within which an official receives all alerts, can broadcast messages, and can emit qualification events on hotspots.

### 6.7 Hotspot Credibility & Collaborative Thread `[Phase 2]`

- Agents arriving at a hotspot can emit a validation participation event, increasing the hotspot's credibility score
- A collaborative communication thread is shared exclusively with professionals and first responders

---

## 7. Screens & Flows

### 7.1 Onboarding `[MVP]`

**MVP scope — anonymous users only:**
- Anonymous device ID generated from device hash (no account, no password)
- Background location permission request (cold tracking)
- Push notification permission request

**Deferred:**
- Watcher authentication via third-party provider (Google, Microsoft) `[Phase 2]`
- Official authentication via dedicated service `[Phase 2]`
- Security group QR code scanning `[Phase 2]`
- Usage charter acceptance `[Phase 2]`

---

### 7.2 Alert Emission — S-01 `[MVP]`

**Primary screen for victim or witness.**

**MVP components:**
- Role toggle: Victim / Witness
- Alert type grid: Police / Fire / Unsecure / Danger
- Secure button (signals resolution, hold 2s to confirm — emits `secure` alert event to server)
- Status band: connection status + elapsed time since alert opened
- Map preview: hotspot radius, GPS accuracy tag, participant count

**Interactions:**
- Hold Danger 2s or confirm to open
- Hold Unsecure 1s or confirm to open
- Hold Secure 2s or confirm — emits `secure` event; server evaluates closure rules

**Deferred:**
- Context bar: optional text input `[Phase 2]`
- Stress meter: derived from button press frequency `[Phase 2]`
- Ghost mode toggle `[Phase 2]`
- Security group toggle `[Phase 2]`

---

### 7.3 Alert Reception — S-02 `[MVP]`

**Push notification card shown to follower.**

**MVP components:**
- Alert type
- Distance from current position
- Time elapsed since alert opened

**Deferred:**
- Response options beyond Acknowledge: Flee / Neutral / Watch / Assist / Call `[Phase 2]`

---

### 7.4 Map / Hotspot View — S-03 `[MVP]`

**Follower view after opening notification.**

**MVP components:**
- Map centred on hotspot
- Approximate emitter pin
- Participant count (live query on HotspotParticipation records)
- Acknowledge button (emits participation event)

**Deferred:**
- Follower-to-emitter messaging `[Phase 2]`
- Official force layer on map `[Phase 2]`
- Heatmap overlay `[Phase 3]`

---

### 7.5 Profile — S-05 `[Phase 2]`

**Standard anonymous user:**
- Hashed device ID (not displayed, internal only)
- App permissions summary
- My Security Group: personal QR code, member list with pseudonyms
- Extended Security Groups I belong to: group list with quiet/leave options

**Watcher additions:**
- Email and name confirmed from third-party auth provider

**First Responder additions:**
- Full name and organisation
- Qualification (physician, rescue volunteer, etc.)

**Official additions:**
- Full name and title
- Department name and address
- District name and area

---

### 7.6 Perimeter Surveillance — Web Dashboard `[Phase 2]`

**Official surveillance centre view.**

- Full district map with live hotspot pins
- Pin icon reflects alert type; pin colour reflects severity
- Click pin → alert details, emitter phone number (subscription), participant list, stress level
- Phone number matching: incoming call number highlights the matching pin
- Broadcast message to all participants of a hotspot area

---

### 7.7 History `[Phase 2]`

- Chronological list of past alerts in a given area
- Per-alert detail: type, duration, participant count, official response time
- Available to freemium users (T+1 day), real-time for officials

---

### 7.8 Statistics `[Phase 3]`

| Product | Scope | Description |
|---|---|---|
| J+1 Daily | Municipality | List of hotspots by day and category with approximate location |
| M+1 Monthly | Municipality | Heatmap of alerts by category over one month |
| A+1 Annual | Department | Heatmap of alerts by category over one year |

---

## 8. Open Questions

Questions not yet resolved, grouped by the phase in which they need an answer.

### Before MVP launch

- Should a usage charter be required and accepted before first use?
- What is the exact server timeout for hotspot inactivity closure? (Proposed: 30 min — to be validated with field data)

### Before Phase 2

- Should alert qualification be mandatory or always optional for Unsecure and Danger levels?
- Should media attachments (photo / audio) be possible, and if so shareable only with security forces?
- What closure rules beyond emitter `secure` should be implemented first: official qualification, inactivity timeout, or participant quorum?
- Should user gender be recorded for sexual assault qualification? Current assessment: limited benefit, opens profiling risk.

### Before Phase 3

- What is the value of post-event (cold) statistical alerts as a data source?
- Should statistics data be made available to insurance or real estate companies under dedicated contracts?
- Should a safe escort feature require a verified watcher or can any follower provide it?
