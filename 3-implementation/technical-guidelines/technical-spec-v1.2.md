# SAVE ME — Technical Specifications

> **Version** 1.2 — English rewrite for international market flexibility  
> **Base** GeoSaveMe Technical Spec v1.0  
> **i18n** All user-facing strings referenced by key — see `i18n/en.json`

---

## Table of Contents

1. [Objectives](#1-objectives)
2. [Functional Description](#2-functional-description)
3. [Technical Architecture](#3-technical-architecture)
4. [i18n Technical Integration](#4-i18n-technical-integration)
5. [Market Configuration](#5-market-configuration)

---

## 1. Objectives

SAVE ME builds a **bottom-up civilian vigilance network** connecting:
- Local civilian watchers
- People emitting alerts
- Official security forces

The core insight: most security incidents go unreported because existing tools are binary (do nothing or call emergency services). By surfacing these events into a structured, geolocated network, SAVE ME enables proportional responses at every severity level.

The network operates on two location modes:
- **Cold** — background, approximate, for inactive users (identifying who is near a new hotspot)
- **Hot** — foreground, precise, for active users and followers (real-time tracking within a hotspot)

When a user emits an alert, a **hotspot** is created. The hotspot links all actors: the emitter, nearby civilian followers, and official forces within the district.

---

## 2. Functional Description

### 2.1 Requirements

- User and follower location tracking (cold + hot)
- Hotspot alerting: `rescue` / `danger` / `alert` / `vigilance` / `unsecure` / `action`
- Alert status lifecycle: `sent` → `delivered` → `read`
- Official district management
- Market-configurable emergency number and official labels

### 2.2 Business Microservices

#### HotSpot Service

Responsibilities:
- Create a hotspot when a first alert is posted at a location
- Broadcast hotspot to all relevant recipients:
  - Users inside the hotspot perimeter
  - Users near the perimeter (vigilance area — likely to enter)
  - Official forces whose district contains the hotspot
- Orchestrate positions, messages, and alert broadcasts to all followers
- Update followers when:
  - Hotspot statistics change
  - Perimeter moves or expands (emitter is moving)
- Close hotspot when activity ceases

#### Alerts Service

Responsibilities:
- Manage the list of alerts associated with each hotspot
- Maintain alert types: `rescue` / `danger` / `alert` / `vigilance` / `unsecure` / `action`
- Maintain alert status: `sent` / `delivered` / `read`
- Update hotspot perimeter when the emitter's position moves
- Send alerts to subscribers

#### Followers Location Service ("Hot")

Responsibilities:
- Manage follower list per hotspot, typed as `helper` or `force`
- Prioritize followers: hotspot vs. vigilance area
- Update follower positions at high throughput
- Broadcast positions to relevant actors

#### Users Location Service ("Cold")

Responsibilities:
- Manage all registered users (helpers and forces)
- Register approximate background positions
- Identify users inside hotspot or vigilance perimeters → promote to followers
- Maintain and update the followers list

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
- First alert → initiates a new hotspot
- Subsequent alert → associated to existing hotspot if within perimeter
- Receives status callbacks: `sent` / `delivered` / `read`

**Hotspot reception**
- Receive new hotspot notification if inside hotspot or vigilance area
- Subscribe to hotspot updates (statistics, perimeter changes, follower count)

#### Police / Official App

**Authentication**
- Login via Forces Authentication Service

**Cold location sending**
- If not still: send position every **60 seconds**

**Hot location sending**
- When associated to a hotspot: send position every **10 seconds**

**Alert emission**
- Can emit alerts (qualification, ghost alert, broadcast message)

**Hotspot reception**
- Receive all hotspots within their assigned district polygon
- Receive hotspot updates in real time

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
  "hotspotID":   "uuid-v4",
  "position":    { "lat": 48.8566, "lng": 2.3522 },
  "radius":      150,
  "alertType":   "danger | alert | police | fire | vigilance",
  "status":      "open | resolved",
  "emitterID":   "hash(deviceID)",
  "phone":       "+33XXXXXXXXX",
  "stressLevel": 62,
  "followers":   { "helpers": 4, "forces": 2 },
  "createdAt":   "2024-03-01T14:30:00Z",
  "updatedAt":   "2024-03-01T14:32:00Z"
}
```

#### Alert API

```
Endpoint: /api/alert
Methods:  POST (emit) / PUT (update status) / GET (list for hotspot)
```

**Alert object:**
```json
{
  "alertID":   "uuid-v4",
  "hotspotID": "uuid-v4",
  "type":      "rescue | danger | alert | vigilance | unsecure | action",
  "status":    "sent | delivered | read",
  "context":   "optional free text or structured event type keys",
  "emittedAt": "2024-03-01T14:30:00Z"
}
```

### 3.2 Mobile Architecture

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

When a user becomes a hotspot follower (helper or force):
- `HotLocationService` starts in foreground with persistent notification
- Polls GPS at configured interval (30s helper / 10s force)
- Posts to `/api/userlocation` with `PRIORITY_HIGH_ACCURACY`
- Stops when hotspot closes or user disengages

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
  "type":      "new_hotspot | hotspot_update | official_broadcast",
  "hotspotID": "uuid-v4",
  "alertType": "danger",
  "distance":  142,
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
      "police":     "Police",
      "fire":       "Fire & Rescue",
      "alert":      "Alert",
      "danger":     "Danger",
      "vigilance":  "Vigilance",
      "safe":       "I'm Safe"
    },
    "status": {
      "transmitted": "Alert transmitted · Secure link established",
      "sent":        "Sent",
      "delivered":   "Delivered",
      "read":        "Read"
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
    "low":  "Alert",
    "high": "Danger"
  },
  "network": {
    "active": "Network active"
  }
}
```

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
