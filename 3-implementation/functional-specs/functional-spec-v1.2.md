# SAVE ME — Functional Specifications

> **Version** 1.2 — English rewrite for international market flexibility  
> **Original** JB.Gosset (FR) · **Translated & expanded** for EN-first strategy  
> **i18n note** All user-facing strings are keyed. See `i18n/` directory for locale files.

---

## Table of Contents

1. [Context & Vision](#1-context--vision)
2. [User Types](#2-user-types)
3. [Use Cases](#3-use-cases)
4. [Data Model](#4-data-model)
5. [Screens & Flows](#5-screens--flows)
6. [i18n Architecture](#6-i18n-architecture)

---

## 1. Context & Vision

### Problem Statement

A significant gap exists between minor security incidents and formal emergency calls. Many events — harassment, threatening behavior, accidents without casualties — go unreported because the available tools are binary: either do nothing or call emergency services.

SAVE ME fills this gap by providing a **geolocated civilian alert network** that connects:
- People in danger or witnessing an incident
- Nearby civilians who can assist or avoid the area
- Patrol officers who can respond preemptively
- Surveillance centers that can correlate incoming alerts with dispatch calls

### Core Principle

The app operates on **real-time local proximity**. Alerts are never broadcast globally — they are distributed only to users within the relevant geographic perimeter. This prevents media amplification and keeps the system operationally focused.

### Alert Lifecycle

1. A victim or witness opens an alert (danger / police / fire / vigilance)
2. A **hotspot** is created at their location
3. Nearby users receive a push notification and can choose to respond
4. Officials in the district see the hotspot on their map
5. The alert remains open until the emitter closes it (e.g. on arrival of responders)
6. The frequency of "unsecure" button presses is logged to estimate stress level

### Design Constraints

- **Anonymous by default** — public users have no account, no password, no personal profile
- **No social media sharing** — prevents viral amplification and mob behavior
- **Local only** — alerts are geographically scoped
- **Neutral** — the app qualifies the danger of situations, never of individuals
- **Credibility scoring** — a reputation system moderates alert quality without being punitive

---

## 2. User Types

### 2.1 Victim or Witness

A person who feels in danger, is the victim of an aggression, or witnesses an accident. They open the app and emit an alert.

**Key behaviors:**
- Emits an alert with type selection (danger / police / fire / vigilance)
- Optionally adds context if the situation allows
- Keeps the alert open until resolved
- Can notify friends & family via the app or social network of their choice
- Stress is estimated from button press frequency

**Privacy:** fully anonymous. No account required. Identified only by a hashed device ID.

### 2.2 Official (Patrol / Surveillance)

A verified professional from a security or emergency service (police, gendarmerie, fire brigade, SAMU, Red Cross, certified first responder).

**Key behaviors:**
- Authenticated via a verified organizational account
- Receives real-time alerts within their assigned district
- Can see alert details including the emitter's phone number (for emergency call correlation)
- Can qualify a hotspot once on scene
- Can broadcast targeted messages to a hotspot area
- Can operate in **stealth mode** (hidden from public map) to avoid alerting aggressors
- Can emit **ghost alerts** visible only to forces

**Privacy:** not anonymous — accountable to their organization.

### 2.3 Friend or Family Member

A person who has been granted access by a victim or witness to receive alerts about them.

**Key behaviors:**
- Receives push notification via the app OR a social network share link
- Sees basic alert status (type, rough location, open/closed)
- Cannot interact with the hotspot directly

**Privacy:** depends on what the emitter chooses to share.

### 2.4 Private Individual (Bystander)

A member of the public who is geographically near an active hotspot.

**Key behaviors:**
- Receives a push notification when a nearby hotspot opens
- Free to act: flee, stay neutral, offer presence, assist, or call for help
- If they engage, they become a **follower** of the hotspot and share their approximate position
- Their count is displayed to the victim (e.g. "4 watchers nearby") as reassurance

**Privacy:** position shared only approximately, not precisely, to protect their identity.

---

## 3. Use Cases

### 3.1 Witness to an Accident

The user sees a road accident or medical emergency. They open the app, select "Fire" or "Police", optionally add context (e.g. number of people involved, presence of injuries), and emit the alert. Nearby users are notified. Official responders receive the location and can correlate with incoming 112/999/911 calls.

### 3.2 Victim of an Accident

The user is injured and unable to call. They open the app and tap the alert button. The hotspot is created at their GPS position. Officials see the pin on the map. If a call comes in matching the number, the dispatcher clicks the pin to see full context.

### 3.3 Witness to an Assault

The user sees an assault in progress. They emit an alert discreetly. Nearby bystanders are warned. Police patrols nearby receive the hotspot. The user can add context (aggressor description, presence of a weapon) if safe to do so.

### 3.4 Victim of an Assault

The user is being assaulted. They tap rapidly — the frequency of taps is logged as a stress indicator. They may not be able to add context. The hotspot notifies the network. Officials receive the emitter's phone number if they have the patrol subscription.

### 3.5 Friend or Family of a Victim / Witness

The emitter opts to notify their circle. The friend receives a push (if they have the app) or a link. They see the alert status in real time and know help is on the way.

### 3.6 Official on Patrol

The officer receives the hotspot notification on their mobile. They see the type of alert, the number of civilian followers, and (with subscription) the emitter's phone number. They navigate to the scene. Once on site, they can qualify the hotspot and broadcast a localized message.

### 3.7 Official in a Surveillance Center

The dispatcher sees a pin appear on their district map when an alert is emitted. A call comes in simultaneously. They match the phone number on the call to the pin and click it to see all context: alert type, stress level, qualifications, follower count. This replaces the blind "caller says they're somewhere on Rue de Rivoli" problem.

### 3.8 Private Individual Walking Nearby

The user receives a notification: "Alert open 200m from your location." They choose their response. If they engage, they appear as a watcher dot on the map (position approximate). Their presence count is shown to the victim.

### 3.9 Private Individual at Home

The user receives a neighborhood digest (freemium: next-day summary) or a real-time push if a hotspot opens very close to their home. They can check the map to understand what is happening.

---

## 4. Data Model

### 4.1 Alert Types

| Key | Label (EN) | Severity | Description |
|-----|-----------|----------|-------------|
| `vigilance` | Vigilance | 1 | Low-level concern, potential risk, incivility |
| `alert` | Alert | 2 | Explicit request for intervention, danger confirmed |
| `police` | Police | 3 | Requires law enforcement response |
| `fire` | Fire & Rescue | 3 | Requires fire brigade / SAMU response |
| `danger` | Danger | 4 | Immediate high danger, life at risk |

### 4.2 Event Types (Alert Context)

**Severity**
- `insecurity` — Feeling of insecurity (no concrete act)
- `incivility` — Disturbance to public order
- `sanitation` — Sanitation/hygiene issue
- `assault` — Physical assault
- `theft` — Theft or robbery
- `sexual_assault` — Sexual assault
- `accident` — Accident

**Target**
- `verbal` — Verbal (no physical contact)
- `physical` — Physical (with contact)
- `person` — Directed at a person
- `building` — Directed at a building
- `vehicle` — Directed at a vehicle

**Nature of act**
- `insult` — Verbal insult
- `noise` — Noise disturbance
- `exhibitionism` — Exhibitionism
- `groping` — Groping / unwanted touching
- `pickpocketing` — Pickpocketing
- `burglary` — Burglary
- `vandalism` — Vandalism

**Character**
- `sexual` — Sexual character
- `racial` — Racial character
- `religious` — Religious character
- `homophobic` — Homophobic character

**Aggravating factors**
- `threat` — With threat
- `intoxicated` — Suspect intoxicated (alcohol/drugs)
- `group` — Multiple suspects
- `weapon` — Weapon present
- `injuries` — Injuries present

### 4.3 Geolocation

**Cold location** (background, inactive users)
- Approximate accuracy (network-level)
- Updated: every hour if still, every 10 minutes if moving
- Purpose: identify users near a new hotspot to notify them

**Hot location** (foreground, active users / followers)
- High accuracy (GPS)
- Updated: every 30 seconds for helpers, every 10 seconds for officials
- Purpose: real-time tracking within an active hotspot

**Position payload**
```json
{
  "userID": "hash(deviceID)",
  "position": {
    "lat": 48.8566,
    "lng": 2.3522,
    "accuracy": 12.5,
    "timestamp": "2024-03-01T14:32:00Z"
  },
  "provider": "GPS_PROVIDER | NETWORK_PROVIDER | PASSIVE_PROVIDER",
  "status": "still | onslowmove | onfastmove | backin"
}
```

---

## 5. Screens & Flows

### 5.1 Cinematics / Onboarding

- App open → permission requests (location background, notifications)
- Anonymous ID generated from device hash
- Role selection not required at onboarding — determined by context

### 5.2 Profile

- Public users: no profile screen (anonymous)
- Officials: login screen → account dashboard → district / subscription info
- Friends/Family: notification preferences, linked contacts

### 5.3 Alert Emission (Mobile)

**Primary screen — Victim or Witness view**

Components:
- Role toggle: `Victim` / `Witness`
- Status band: connection status + elapsed time since alert opened
- Severity scale: Vigilance → Danger
- Alert type grid: Police / Fire / Alert / Danger / Safe (closes alert)
- Context bar: optional text/voice input
- Stress meter: derived from button press frequency
- Responder stats: watcher count, average distance, official count
- Map preview: hotspot radius, moving responder dots, GPS accuracy

**Interactions:**
- Hold "Danger" for 2s to confirm (prevents accidental triggers)
- Tap "Safe" to close the alert
- Share button → notify friends via app push or social link

### 5.4 Alert Reception (Mobile)

**Bystander / follower view**

Components:
- Notification card: alert type, distance, time elapsed
- Response options: Flee / Neutral / Watch / Assist / Call
- Map showing hotspot (emitter position approximate)
- Watcher count for the hotspot

### 5.5 Perimeter Surveillance (Web / Official)

- Full district map
- Hotspot pins with type icon and severity color
- Click pin → alert details, emitter phone number (subscription), follower list
- Phone number matching: incoming call number highlights the matching pin
- Broadcast message composer for a hotspot area

### 5.6 Perimeter Statistics

- Heatmap of alert density by area and time period
- Filterable by alert type, event type, time range
- Export for institutional reporting

### 5.7 History

- Chronological list of past alerts in a given area
- Per-alert detail: type, duration, follower count, official response time
- Available to freemium users (T+1 day), real-time for officials

---

## 6. i18n Architecture

### Philosophy

The app is built **English-first**. All user-facing strings are externalized into locale files. The UI language is determined at runtime from device locale, with a manual override in settings.

### Directory Structure

```
i18n/
├── en.json          ← source of truth
├── fr.json          ← French (initial secondary locale)
├── es.json          ← Spanish (planned)
├── pt.json          ← Portuguese / Brazil (planned)
├── ar.json          ← Arabic (planned, RTL support required)
└── index.ts         ← locale loader + t() helper
```

### Key Naming Convention

```
{screen}.{component}.{element}
```

Examples:
```json
"alert.type.police":       "Police",
"alert.type.fire":         "Fire & Rescue",
"alert.type.danger":       "Danger",
"alert.type.vigilance":    "Vigilance",
"alert.type.safe":         "I'm Safe",
"alert.status.transmitted": "Alert transmitted · Secure link established",
"alert.stress.label":      "Estimated stress",
"alert.context.placeholder": "Add context to your alert…",
"alert.context.hint":      "Optional · if situation allows",
"alert.responders.watchers": "Nearby watchers",
"alert.responders.distance": "Metres (avg.)",
"alert.responders.officials": "Officials",
"alert.map.gps":           "GPS · High accuracy",
"nav.alert":               "Alert",
"nav.map":                 "Map",
"nav.history":             "History",
"nav.profile":             "Profile",
"role.victim":             "Victim",
"role.witness":            "Witness",
"severity.low":            "Alert",
"severity.high":           "Danger",
"network.active":          "Network active"
```

### Runtime Usage (React Native / Web)

```typescript
// i18n/index.ts
import en from './en.json';
import fr from './fr.json';

const locales: Record<string, typeof en> = { en, fr };

export function t(key: string, locale: string = 'en'): string {
  const dict = locales[locale] ?? locales['en'];
  return key.split('.').reduce((o: any, k) => o?.[k], dict) ?? key;
}
```

```tsx
// Usage in component
import { t } from '@/i18n';
const locale = useLocale(); // 'en' | 'fr' | 'es' ...

<Text>{t('alert.type.police', locale)}</Text>
```

### RTL Support

Arabic and Hebrew locales require RTL layout. Add to root component:

```typescript
import { I18nManager } from 'react-native';
const RTL_LOCALES = ['ar', 'he'];
if (RTL_LOCALES.includes(locale)) {
  I18nManager.forceRTL(true);
}
```

### Market Pivot Checklist

When entering a new market, the following need locale-specific review beyond string translation:

- [ ] Emergency number (`911`, `999`, `112`, `17`, `18`…) — never hardcoded, always from config
- [ ] Official role labels (Police / Gendarmerie / Carabinieri…)
- [ ] Legal disclaimer text
- [ ] Privacy policy
- [ ] Date/time format
- [ ] Units (metric vs imperial for distance display)

```typescript
// config/market.ts
export const MARKET_CONFIG = {
  emergencyNumber: process.env.EMERGENCY_NUMBER ?? '112',
  distanceUnit: process.env.DISTANCE_UNIT ?? 'metric',   // 'metric' | 'imperial'
  officialLabel: process.env.OFFICIAL_LABEL ?? 'Police',
};
```
