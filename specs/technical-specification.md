# SAVE ME — Technical Specifications

> **Version** 1.4 — Added §0: Architectural Guiding Principle (agent autonomy, event-driven lifecycle)  
> **Previous** v1.3 — i18n: added English-first philosophy, key naming convention (moved from functional-spec)  
> **Base** GeoSaveMe Technical Spec v1.0  
> **i18n** All user-facing strings referenced by key — see `i18n/en.json`

---

## Table of Contents

0. [Architectural Guiding Principle](#0-architectural-guiding-principle)
1. [Objectives](#1-objectives)
2. [Functional Description](#2-functional-description)
3. [Technical Architecture](#3-technical-architecture)
4. [i18n Technical Integration](#4-i18n-technical-integration)
5. [Market Configuration](#5-market-configuration)

---

## 0. Architectural Guiding Principle

> This section is foundational. It governs the API contract, the mobile data model, the server's role, and the data model entity boundaries across all phases. All subsequent technical decisions should be read in light of it.

### 0.1 Agents Are Autonomous; the Central System Is the Rule Engine

Every mobile device participating in the GeoSaveMe network — whether emitter, follower, watcher, or official — is an **autonomous agent**. It maintains a local state snapshot of every hotspot it is associated with, including the last known alert type, participant count, and a version timestamp. This snapshot is sufficient to render a coherent UI and support basic interactions without a network connection.

The central system does not push instructions to agents. It receives **events** from agents, applies rules, and pushes **state updates** back. Agents consuming an update replace their local snapshot only if the incoming version timestamp is more recent than their own.

The platform is therefore **offline-tolerant by design**: an agent that loses connectivity degrades gracefully and re-syncs from server state on reconnection. This is not a nice-to-have — it is a safety requirement. A victim in a tunnel, a building basement, or an area of network congestion must not lose the functional state of their alert.

### 0.2 All Agent-to-Server Communications Are Events

An **event** is any structured signal emitted by an agent that describes a change in the agent's assessment of or relationship to a situation. Events fall into two distinct families, which must remain separate in the data model and in the API:

**Alert events** — situation assessments emitted by emitters and witnesses:

| Event type | Description |
|---|---|
| `unsecure` | Low-level concern, potential risk |
| `danger` | Explicit request for intervention |
| `police` | Law enforcement response required |
| `fire` | Fire brigade or SAMU response required |
| `secure` | Emitter signals the situation is resolved |

**Participation events** — presence and position signals emitted by followers, watchers, officials, and first responders:

| Event type | Description |
|---|---|
| `acknowledge` | Agent has seen the hotspot and engages as a participant |
| `position_update` | Periodic hot location refresh from an active participant |
| `qualification` | On-scene assessment submitted by a participant |
| `response_update` | Change in declared response intent (flee / assist / call…) |
| `departure` | Agent disengages from the hotspot |

All events share a common envelope (see §3.1 geolocation payload). The `eventType` field enables the server rule engine to route and process events without inspecting payload content.

**Critical:** `secure` is an alert event like any other — it is not a control command. The agent emitting `secure` is updating its situation assessment. What happens next is entirely the server's decision.

### 0.3 Hotspot Lifecycle Is Owned by the Central System

The central system is the sole authority over hotspot lifecycle. It receives alert events and participation events from all associated agents and applies **configurable closure rules** to decide when a hotspot transitions from `open` to `closed`.

Because the rule engine lives entirely on the server and agents only emit events, **closure rules can evolve without any client update**. The MVP starts with a single rule:

> *A `secure` alert event from the original emitter closes the hotspot.*

Later phases will layer additional rules without touching the mobile clients:

- Official on-scene qualification triggers closure
- Quorum of participant `secure` signals triggers closure
- Configurable inactivity timeout triggers closure
- Server keeps a hotspot open despite an emitter `secure` signal if an official has escalated severity (the emitter may no longer be in a position to assess the situation reliably)

### 0.4 Three Distinct Entities — Not One

The state of an active security situation is represented by three entities with separate lifecycles. Conflating them is the most common architectural error in systems of this type.

**Alert** — an event record. Immutable once delivered. Carries a situation assessment from a single agent at a point in time. Its only mutable field is its transmission status (`sent` → `delivered`). It knows nothing about who read it or what was done with it.

**Hotspot** — a server-owned aggregate. Mutable. Its status (`open` / `closed`) is determined by the rule engine, never by a single alert event. It aggregates all alert events and participation events raised within its perimeter and version-stamps every state change it broadcasts to agents.

**HotspotParticipation** — a relationship record between an agent and a hotspot. Created by a participation event. Updated by subsequent participation events from the same agent. Carries position, role, response intent, and timestamps. The participant count visible to the emitter is a live query on these records — it is never a stored field on the hotspot.

### 0.5 What the Central System Never Does

The central system never issues commands to agents. It does not tell an agent to stop alerting, change alert type, or go offline. It publishes state — agents subscribe and update their local snapshot accordingly.

This boundary is operationally critical and must be enforced at the API design level: **no endpoint on the server should accept an agent ID as a target and modify that agent's behaviour**. An emitter in a dangerous situation must never have their alert suppressed by a remote actor, whether that actor is a server administrator, a rule, or another user.

---

## 1. Objectives

SAVE ME builds a **bottom-up civilian vigilance network** connecting:
- Local civilian watchers
- People emitting alerts
- Official security forces

The core insight: most security incidents go unreported because existing tools are binary (do nothing or call emergency services). By surfacing these events into a structured, geolocated network, GEOSAVEME enables proportional responses at every severity level.

The network operates on two location modes:
- **Cold** — background, approximate, for inactive users (identifying who is near a new hotspot)
- **Hot** — foreground, precise, for active users and followers (real-time tracking within a hotspot and its vigilance area)

When a user emits an alert event, a **hotspot** is created server-side. The hotspot links all actors: the emitter, nearby civilian followers, and official forces within the district.

---

## 2. Functional Description

### 2.1 Requirements

- User location tracking
  - Cold location: for hotspot location matching. Every n hours and if move is detected.
  - Hot location: for hotspot, vigilance or district area tracking
- Alert event emission:
  - `anonymous` / `watcher` / `first responder` / `official`
  - `victim` / `witness`
  - `unsecure` / `danger` / `police` / `fire` / `secure`
- Participation event emission: `acknowledge` / `qualification` / `position_update` / `response_update` / `departure`
- Hotspot lifecycle management: `open` → `closed` (server-side rule engine only)
- Alert transmission status: `sent` → `delivered`
- Official district management
- Market-configurable emergency number and official labels

### 2.2 Business Microservices

#### HotSpot Service

Responsibilities:
- Create a hotspot when a first alert event is posted at a location with no existing active hotspot
- Evaluate closure rules on receipt of each alert event or participation event; transition hotspot to `closed` when rules are met
- Broadcast hotspot to all relevant recipients:
  - Users inside the hotspot perimeter
  - Users near the perimeter (vigilance area — likely to enter)
  - Official forces whose district contains the hotspot
- Orchestrate positions, messages, and alert broadcasts to all participants
- Update participants when hotspot state changes (statistics, perimeter, status)
- Version-stamp every outbound state update

#### Alerts Service

Responsibilities:
- Receive and store alert events from agents
- Maintain alert types: `unsecure` / `danger` / `police` / `fire` / `secure`
- Maintain alert transmission status: `sent` / `delivered`
- Attach incoming alert events to the relevant hotspot
- Forward events to the HotSpot Service for rule evaluation
- Update hotspot perimeter when the emitter's position moves

#### Followers Location Service ("Hot")

Responsibilities:
- Manage HotspotParticipation records per hotspot
- Typed by role: `follower` / `watcher` / `first_responder` / `official`
- Prioritise participants by zone: hotspot vs. vigilance area
- Update participant positions at high throughput
- Broadcast participation state to relevant actors (emitter sees count; officials see positions)

#### Users Location Service ("Cold")

Responsibilities:
- Manage all registered users' last known positions
- Register approximate background positions
- Identify users inside hotspot or vigilance perimeters → promote to participants
- Trigger participation event flow on proximity match

#### Forces Management Service

Responsibilities:
- Maintain the registry of official officers
- Maintain police/fire/rescue stations and their associated district polygons

#### Forces Web UI Service

Responsibilities:
- Serve the surveillance center web interface
- Server-side page fragment composition
- Client-side UI composition for district map and hotspot management

### 2.3 Technical Microservices

#### API Gateway

- Single entry point for all mobile client communication
- Authentication routing (anonymous users vs. verified officials)
- Rate limiting and abuse protection

#### Settings Service

- Administration parameters
- **Market configuration** (see §5): emergency number, distance units, official labels, locale defaults

#### Forces Authentication Service

- Authenticate official users against their organization's identity provider
- Issue and validate session tokens for patrol and surveillance roles

#### Messaging Service

- Support push notification delivery (FCM / APNs)
- Support in-app messaging for hotspot broadcasts
- Support top-down official messaging to hotspot areas

### 2.4 Mobile Application

#### Helper App (Civilian)

**Initialization**
- Send `Hello` to Unity services
- Request permissions:
  - `ACCESS_COARSE_LOCATION`
  - `ACCESS_BACKGROUND_LOCATION`
  - `POST_NOTIFICATIONS`

**Cold location sending**
- Permission level: `PRIORITY_BALANCED_POWER_ACCURACY`
- **Still** (status: `still`): no update if less than 50m from last recorded position
- **Slow move** (status: `onslowmove`):
  - Every 60s if on foot (velocity < 6 km/h)
  - Every 30s if on bicycle (velocity < 30 km/h)
- **Fast move** (status: `onfastmove`):
  - Triggered at velocity > 30 km/h (scooter / car / train)
  - No update while moving; on stop (still for 5 min), status → `backin`
  - On `backin`: fetch nearby hotspots to check if arrived in alert area

**Hot location sending**
- Permission level: `PRIORITY_HIGH_ACCURACY`
- Permissions: `ACCESS_FINE_LOCATION` + `ACCESS_FOREGROUND_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` also requested for short-window alert emission
- When associated to a hotspot: send position every **30 seconds**

**Alert emission**
- First alert event → server creates a new hotspot
- Subsequent alert event → server attaches to existing hotspot if within perimeter
- Receives transmission callbacks: `sent` / `delivered`

**Hotspot reception**
- Receive new hotspot notification if inside hotspot or vigilance area
- Subscribe to hotspot state updates (version-stamped); apply only if newer than local snapshot

#### Police / Official App

**Authentication**
- Login via Forces Authentication Service

**Cold location sending**
- If not still: send position every **60 seconds**

**Hot location sending**
- When associated to a hotspot: send position every **10 seconds**

**Alert emission**
- Can emit alert events (qualification, ghost alert, broadcast message)

**Hotspot reception**
- Receive all hotspots within their assigned district polygon
- Receive hotspot state updates in real time

---

## 3. Technical Architecture

### 3.1 Microservices

#### Users Location API

```
Endpoint: /api/userlocation
Methods:  POST (create) / PUT (update)
```

**Request payload:**
```json
{
  "userID":   "hash(deviceID)",
  "position": {
    "lat":       48.8566,
    "lng":       2.3522,
    "accuracy":  22.0,
    "timestamp": "2024-03-01T14:32:00Z"
  },
  "provider": "NETWORK_PROVIDER | GPS_PROVIDER | PASSIVE_PROVIDER",
  "status":   "still | onslowmove | onfastmove | backin"
}
```

#### Hotspot API

```
Endpoint: /api/hotspot
Methods:  POST (create) / GET (fetch for area) / PUT (update) / DELETE (close)
```

**Hotspot object:**
```json
{
  "hotspotID":        "uuid-v4",
  "position":         { "lat": 48.8566, "lng": 2.3522 },
  "radius":           150,
  "lastAlertType":    "unsecure | danger | police | fire | secure",
  "status":           "open | closed",
  "emitterID":        "hash(deviceID)",
  "phone":            "+33XXXXXXXXX",
  "stressLevel":      62,
  "participantCount": { "civilians": 4, "forces": 2 },
  "version":          "2024-03-01T14:32:00Z",
  "createdAt":        "2024-03-01T14:30:00Z",
  "updatedAt":        "2024-03-01T14:32:00Z"
}
```

> `version` is the timestamp agents use to decide whether to apply an incoming state update. `participantCount` is derived from HotspotParticipation records — never stored as a mutable field.

#### Alert API

```
Endpoint: /api/alert
Methods:  POST (emit event) / PUT (update transmission status) / GET (list for hotspot)
```

**Alert object:**
```json
{
  "alertID":   "uuid-v4",
  "hotspotID": "uuid-v4",
  "emitterID": "hash(deviceID)",
  "eventType": "unsecure | danger | police | fire | secure",
  "status":    "sent | delivered",
  "context":   "optional free text or structured qualification keys",
  "emittedAt": "2024-03-01T14:30:00Z"
}
```

#### Participation API

```
Endpoint: /api/participation
Methods:  POST (acknowledge / join) / PUT (update position or response) / DELETE (depart)
```

**HotspotParticipation object:**
```json
{
  "participationID": "uuid-v4",
  "hotspotID":       "uuid-v4",
  "agentID":         "hash(deviceID)",
  "role":            "follower | watcher | first_responder | official",
  "position":        { "lat": 48.8566, "lng": 2.3522, "accuracy": 22.0 },
  "response":        "acknowledge | flee | neutral | assist | call",
  "joinedAt":        "2024-03-01T14:31:00Z",
  "lastSeenAt":      "2024-03-01T14:32:00Z"
}
```

### 3.2 Common Event Envelope

All agent-to-server communications — both alert events and participation events — share a common geolocation envelope. The `eventType` field enables the server rule engine to route events without inspecting payload content.

```json
{
  "mobileID":  "hash(deviceID)",
  "hotspotID": "hash(deviceID + timestamp)",
  "source":    "base | alert | follower | official",
  "eventType": "unsecure | danger | police | fire | secure | acknowledge | position_update | qualification | response_update | departure",
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

### 3.3 Mobile Architecture

#### Cold Location — Android Components

**Service: `ColdLocationService`**
- Background service running independently of UI
- Implements motion state machine: `still` / `onslowmove` / `onfastmove` / `backin`
- Posts to `/api/userlocation` on state change or timer

**Content Provider: `ColdLocationProvider`**
- Logs position records locally for debugging and audit
- Schema: `(timestamp, lat, lng, accuracy, provider, status)`

**Activity: `ColdLocationLogActivity`**
- Debug view of cold location logs (dev/QA builds only)

#### Hot Location — Active Tracking

When a user becomes a hotspot participant (helper or force):
- `HotLocationService` starts in foreground with persistent notification
- Polls GPS at configured interval (30s helper / 10s force)
- Posts participation event to `/api/participation` with `PRIORITY_HIGH_ACCURACY`
- Stops when hotspot closes or agent disengages

#### Local State Snapshot — Agent Cache

Each agent maintains a local cache of hotspot state snapshots:

- Keyed by `hotspotID`
- Each snapshot carries the `version` timestamp from the last server update
- On receiving a hotspot update, agent compares incoming `version` to local `version`; applies only if newer
- On reconnection after offline period, agent requests a full state refresh for each active hotspot it is associated with

This cache is the mechanism that makes agents offline-tolerant. It must be implemented before any other hotspot UI feature.

#### Push Notification Architecture

```
HotSpot Service
      │
      ▼
Messaging Service ──► FCM (Android) ──► Helper App
                  └──► APNs (iOS)   ──► Helper App
                  └──► WebSocket    ──► Forces Web UI
```

Notification payload:
```json
{
  "type":      "new_hotspot | hotspot_update | hotspot_closed | official_broadcast",
  "hotspotID": "uuid-v4",
  "alertType": "danger",
  "distance":  142,
  "version":   "2026-04-01T14:32:00Z",
  "locale":    "en"
}
```

The `locale` field drives which string keys are resolved on the receiving device, not on the server — **server never sends user-facing strings, only keys and data.**

---

## 4. i18n Technical Integration

### Core Principle

**The server sends data and keys. The client renders strings.**

This means:
- All API responses contain `type` codes, not labels
- Alert types are `"danger"`, not `"Danger"` or `"Gefahr"`
- The mobile app and web UI resolve display strings from locale files at render time
- Adding a new language requires zero backend changes

The app is built **English-first**. The active locale is determined at runtime from device locale, with a manual override available in settings. All user-facing strings must be externalized — never hardcoded in component code.

### Key Naming Convention

Keys follow the pattern `{screen}.{component}.{element}`:

```
alert.type.police        → "Police"
alert.type.danger        → "Danger"
alert.status.transmitted → "Alert transmitted · Secure link established"
alert.stress.label       → "Estimated stress"
alert.context.placeholder → "Add context to your alert…"
nav.alert                → "Alert"
role.victim              → "Victim"
```

Add new keys at the bottom of the relevant section in `en.json`. Never rename or remove existing keys — they are public contracts.

### Locale File Structure

```
i18n/
├── en.json          ← source of truth (English)
├── fr.json
├── es.json
├── pt.json
├── ar.json          ← RTL, requires layout mirror
└── index.ts
```

### Key Schema

```json
{
  "alert": {
    "type": {
      "police":    "Police",
      "fire":      "Fire & Rescue",
      "unsecure":  "Unsecure",
      "danger":    "Danger",
      "secure":    "I'm Safe"
    },
    "status": {
      "transmitted": "Alert transmitted · Secure link established",
      "sent":        "Sent",
      "delivered":   "Delivered"
    },
    "stress": {
      "label": "Estimated stress"
    },
    "context": {
      "placeholder": "Add context to your alert…",
      "hint":        "Optional · if situation allows"
    },
    "responders": {
      "watchers":   "Nearby watchers",
      "distance":   "Metres (avg.)",
      "officials":  "Officials"
    },
    "map": {
      "gps": "GPS · High accuracy"
    }
  },
  "nav": {
    "alert":   "Alert",
    "map":     "Map",
    "history": "History",
    "profile": "Profile"
  },
  "role": {
    "victim":  "Victim",
    "witness": "Witness"
  },
  "severity": {
    "low":  "Unsecure",
    "high": "Danger"
  },
  "network": {
    "active": "Network active"
  }
}
```

> Note: the `alert.status.read` key has been removed. Read state is a hotspot-level concern (which participants have seen the hotspot), not an alert transmission status.

### TypeScript Helper

```typescript
// i18n/index.ts
import en from './en.json';
import fr from './fr.json';
import es from './es.json';

type LocaleKey = keyof typeof en;
const locales: Record<string, typeof en> = { en, fr, es };

export function t(key: string, locale: string = 'en'): string {
  const dict = locales[locale] ?? locales['en'];
  return key.split('.').reduce((o: any, k) => o?.[k], dict) ?? key;
}

export function useTranslation(locale: string) {
  return { t: (key: string) => t(key, locale) };
}
```

### RTL Support

```typescript
// app/i18n/rtl.ts
import { I18nManager } from 'react-native';

const RTL_LOCALES = ['ar', 'he', 'fa', 'ur'];

export function applyRTL(locale: string) {
  const isRTL = RTL_LOCALES.includes(locale);
  if (I18nManager.isRTL !== isRTL) {
    I18nManager.forceRTL(isRTL);
    // App restart required for full RTL layout
  }
}
```

---

## 5. Market Configuration

All market-specific values are externalized into environment config. Never hardcode country-specific data.

### Configuration Schema

```typescript
// config/market.ts
export interface MarketConfig {
  emergencyNumber:   string;   // '911' | '999' | '112' | '17' | '000' ...
  distanceUnit:      'metric' | 'imperial';
  officialLabel:     string;   // 'Police' | 'Gendarmerie' | 'Carabinieri' ...
  defaultLocale:     string;   // 'en' | 'fr' | 'es' ...
  supportedLocales:  string[];
  privacyPolicyUrl:  string;
  termsUrl:          string;
}

export const MARKET_CONFIG: MarketConfig = {
  emergencyNumber:  process.env.EMERGENCY_NUMBER  ?? '112',
  distanceUnit:     (process.env.DISTANCE_UNIT as any) ?? 'metric',
  officialLabel:    process.env.OFFICIAL_LABEL    ?? 'Police',
  defaultLocale:    process.env.DEFAULT_LOCALE    ?? 'en',
  supportedLocales: (process.env.SUPPORTED_LOCALES ?? 'en,fr').split(','),
  privacyPolicyUrl: process.env.PRIVACY_POLICY_URL ?? 'https://saveme.app/privacy',
  termsUrl:         process.env.TERMS_URL          ?? 'https://saveme.app/terms',
};
```

### Environment Files per Market

```
config/
├── .env.default      ← international baseline (EN, 112, metric)
├── .env.uk           ← EN, 999, metric
├── .env.us           ← EN, 911, imperial
├── .env.fr           ← FR, 17/18/15, metric
├── .env.br           ← PT, 190/193, metric
└── .env.za           ← EN, 10111, metric
```

### Market Pivot Checklist

When entering a new market:

- [ ] Create `.env.{market}` with correct emergency numbers
- [ ] Create or commission `i18n/{locale}.json` translation
- [ ] Review privacy policy for local data protection law (GDPR / CCPA / LGPD…)
- [ ] Identify official force partner or operate in civilian-only mode
- [ ] Verify district polygon data availability for the region
- [ ] Test RTL layout if applicable
- [ ] Update app store metadata in target locale
