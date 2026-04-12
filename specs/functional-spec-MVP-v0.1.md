# SAVE ME — MVP Functional Scope v0.1

> **Version** 0.1  
> **Project** Réseau mobile de vigilance citoyenne  
> **Date** April 2026  
> **Status** Draft — for review

---

## Table of Contents

1. [Why This Scope](#1-why-this-scope)
2. [MVP Scope in One Sentence](#2-mvp-scope-in-one-sentence)
3. [User Types](#3-user-types-mvp)
4. [Use Cases](#4-use-cases-mvp)
5. [Alert Data Model](#5-alert-data-model-mvp-subset)
6. [Screens](#6-screens-mvp)
7. [Hotspot & Broadcasting](#7-hotspot--broadcasting-mvp)
8. [Explicitly Out of Scope](#8-explicitly-out-of-scope-mvp)
9. [Acceptance Criteria](#9-mvp-acceptance-criteria)
10. [Open Questions](#10-open-questions-deferred)
- [Appendix — Full Spec Cross-Reference](#appendix--full-spec-cross-reference)

---

## 1. Why This Scope

The full SAVE ME specification covers a rich feature set: credibility scoring, ghost alerts, security groups, stealth mode, surveillance web dashboards, freemium statistics, and more. Before investing in any of that, three foundational capabilities must be proven on real devices:

| Challenge | Why It Must Be Validated First |
|---|---|
| Cold location tracking | Background geolocation behaves very differently on iOS vs Android; battery optimisation, permission models and wake-up constraints vary significantly between OS versions. |
| Alert emission & hotspot creation | The real-time event pipeline (mobile → API → broadcast) must be proven end-to-end before any secondary feature is layered on top. |
| Cross-platform alert reception | iOS push + Android push have different delivery guarantees. A follower on the opposite OS from the emitter is the hardest integration case. |

Everything else — qualification forms, stress meters, security groups, web dashboards, credibility scores — is deferred to Phase 2 and beyond.

---

## 2. MVP Scope in One Sentence

> Two users (one iOS, one Android) can each act as emitter or follower: the emitter opens an alert that creates a geolocated hotspot; the follower, nearby, receives a push notification, sees the hotspot on a map, and can acknowledge it. Cold location runs silently in the background to enable proximity matching.

---

## 3. User Types (MVP)

Only two roles exist in the MVP. All other user types (Officials, Security Groups, Surveillance Center) are excluded.

| Role | Description | Included in MVP |
|---|---|---|
| Emitter (Victim / Witness) | Opens the app and triggers an alert. A hotspot is created at their GPS position. | Yes |
| Follower (Bystander) | Receives a push notification when a nearby hotspot opens. Can acknowledge and see the map. | Yes |
| Official (Patrol / Dispatch) | Verified professional with district-level access. | No — Phase 2 |
| Security Group (Friend / Family) | Receives alerts from a specific emitter regardless of location. | No — Phase 2 |

> Both test users will swap roles during testing — the iOS user emits, Android follows; then vice versa.

---

## 4. Use Cases (MVP)

### 4.1 UC-01 — Emit an Alert

| Field | Value |
|---|---|
| Actor | Emitter (victim or witness) |
| Precondition | App installed, location permission granted (foreground + background), push permission granted |
| Trigger | User taps an alert type button |
| Main flow | 1. User opens app  2. Selects role: Victim or Witness  3. Taps alert type (Unsecure / Danger / Police / Fire)  4. App captures GPS position with high accuracy  5. Hotspot created server-side  6. Push notification sent to all users within radius  7. Status band shows elapsed time and connection status |
| Post-condition | Hotspot is active and visible to nearby followers |
| Excluded | Context / qualification form, stress meter input, ghost mode, security group broadcast |

### 4.2 UC-02 — Receive an Alert (Follower)

| Field | Value |
|---|---|
| Actor | Follower (bystander) |
| Precondition | App installed, background location running (cold), push notifications granted |
| Trigger | A hotspot is created within the follower proximity radius |
| Main flow | 1. System matches follower cold position to hotspot perimeter  2. Push notification delivered: alert type + distance  3. Follower opens app  4. Map view shows hotspot (approximate emitter position)  5. Follower taps Acknowledge — their position is shared (hot, approximate)  6. Emitter sees follower count increment |
| Post-condition | Follower is registered as a watcher on the hotspot |
| Excluded | Response options (Flee / Assist / Call), follower-to-emitter messaging, credibility update |

### 4.3 UC-03 — Close an Alert

| Field | Value |
|---|---|
| Actor | Emitter |
| Trigger | User taps Safe / Secure button (hold 2 s to confirm) |
| Main flow | 1. Alert status set to closed  2. Hotspot deactivated server-side  3. Push sent to followers: hotspot resolved  4. Location tracking reverts to cold mode |
| Post-condition | Hotspot archived; no more notifications sent |
| Excluded | Post-event qualification, duration statistics export |

### 4.4 UC-04 — Background Cold Location

| Field | Value |
|---|---|
| Actor | Any user (passive) |
| Trigger | App running in background |
| Main flow | 1. OS wakes app periodically  2. Position sent only if user has moved > 50 m since last update  3. Server stores last known position (not history)  4. On new hotspot creation, server queries users within radius and dispatches push |
| Post-condition | User is reachable for hotspot notifications without foreground activity |
| Notes | iOS: uses significant-change location API. Android: WorkManager + FusedLocationProvider. Battery-friendly: approximate accuracy (NETWORK_PROVIDER), not GPS. |

---

## 5. Alert Data Model (MVP Subset)

### 5.1 Alert Types

Four types available in the MVP UI. Context / qualification is deferred.

| Key | Label | Severity | Color |
|---|---|---|---|
| `unsecure` | Unsecure | 1 — Low | Orange |
| `danger` | Danger | 2 — High | Purple |
| `police` | Police Call | 3 — Emergency | Blue |
| `fire` | Fire / Rescue Call | 3 — Emergency | Red |
| `secure` | Secure (close alert) | 0 | Green |

> Alert qualification (gravity, target, fact, aggravating factors) is fully excluded from MVP. The type button is the only input.

### 5.2 Alert Status

| Status | Description |
|---|---|
| `sent` | Alert created on device, awaiting server confirmation |
| `delivered` | Server has received and stored the alert |
| `read` | At least one follower has acknowledged the notification |
| `closed` | Emitter has tapped Secure to close the alert |

### 5.3 Geolocation Payload (MVP)

Both cold and hot positions use the same payload shape:

```json
{
  "mobileID":  "hash(deviceID)",
  "hotspotID": "hash(deviceID + timestamp)",
  "source":    "base | alert | follower",
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

> `hotspotID` is `null` for cold background updates.

---

## 6. Screens (MVP)

Exactly four screens are in scope. All others (History, Statistics, Profile, Surveillance Web UI) are deferred.

| Screen | Actor | Key Components | Excluded |
|---|---|---|---|
| S-01 Alert Emission | Emitter | Role toggle (Victim/Witness), Alert type grid (4 buttons + Secure), Status band (connection + timer), Map preview (hotspot radius + GPS tag), Responder count | Context bar, stress meter, ghost mode, security group toggle |
| S-02 Alert Reception (notification) | Follower | Push notification card: type, distance, elapsed time | Response options beyond Acknowledge |
| S-03 Map / Hotspot View | Both | Map centred on hotspot, approximate emitter pin, follower count, Acknowledge button | Follower-to-emitter chat, official layers, heatmap |
| S-04 Onboarding / Permissions | Both | Location permission request (background), Push notification permission, Anonymous ID generation | Account creation, Watcher/Official authentication, QR code security group |

---

## 7. Hotspot & Broadcasting (MVP)

### 7.1 Hotspot Creation

- Created server-side on receipt of the first alert from an emitter
- Perimeter radius: fixed at 500 m for MVP (configurable in Phase 2)
- All users whose last cold position falls within the perimeter receive a push notification
- Hotspot persists until emitter closes it or a server timeout (30 min inactivity)

### 7.2 Hot Location (Active Emitter & Follower)

| Actor | Update Frequency | Accuracy | Provider |
|---|---|---|---|
| Emitter (while alert open) | Every 30 s | High (GPS) | GPS_PROVIDER |
| Follower (after acknowledge) | Every 30 s | Approximate | NETWORK_PROVIDER |

### 7.3 Cold Location (Background)

| Condition | Behaviour |
|---|---|
| Still (< 50 m since last) | No update sent |
| Slow move (< 30 km/h) | Update every 10 min |
| Fast move (> 30 km/h) | No update until still for 5 min, then one update |

> Cold location history is never persisted — only the last known position is stored per device.

---

## 8. Explicitly Out of Scope (MVP)

The following items from the full specification are deferred and must not be designed or implemented in the MVP:

| Feature | Phase |
|---|---|
| Alert qualification (gravity, target, fact, perception, aggravating factors) | Phase 2 |
| Stress meter (button-press frequency logging) | Phase 2 |
| Ghost mode (alert visible to forces only) | Phase 2 |
| Security groups (My Group, Extended Group, QR code joining) | Phase 2 |
| Official / Patrol mobile app | Phase 2 |
| Surveillance Center web dashboard | Phase 2 |
| Credibility scoring | Phase 2 |
| Stealth mode for officials | Phase 2 |
| Post-event / delayed alerts | Phase 2 |
| Media attachments (photo / audio) | Phase 3 |
| Freemium statistics (J+1, M+1, A+1) | Phase 3 |
| Broadcast messages from officials to hotspot | Phase 2 |
| Phone number matching for dispatch centers | Phase 2 |
| Watcher / First Responder authentication | Phase 2 |
| Safe escort / guardian angel | Phase 3 |
| Tracker registration | Phase 3 |

---

## 9. MVP Acceptance Criteria

The MVP is considered successful when all of the following can be demonstrated in a single session with two physical devices (one iOS, one Android):

| # | Criterion | Measurable By |
|---|---|---|
| AC-01 | Emitter (iOS) opens an alert → follower (Android) receives a push notification within 10 seconds | Stopwatch + notification log |
| AC-02 | Emitter (Android) opens an alert → follower (iOS) receives a push notification within 10 seconds | Stopwatch + notification log |
| AC-03 | Follower acknowledges → emitter sees follower count increment to 1 within 5 seconds | Screen observation |
| AC-04 | Emitter closes alert → follower receives a resolution push within 15 seconds | Notification log |
| AC-05 | Cold location update is received server-side when either device moves > 50 m | Server log |
| AC-06 | App does not drain > 1% battery/hour in background cold-location mode (30 min test) | iOS/Android battery stats |
| AC-07 | Onboarding completes (permissions granted) in < 3 taps on both platforms | Tap count observation |

---

## 10. Open Questions (Deferred)

These questions from the full specification do not need resolution before MVP development begins:

- Mandatory qualification for Vigilance / Alert levels?
- Should a usage charter be required before first use?
- Should media attachments (photo/audio) be shareable with forces only?
- Should user gender be recorded for sexual assault qualification?
- What is the value of post-event (cold) statistical alerts?
- What is the optimal hotspot timeout (currently 30 min — to be validated with field data)?

> **One question to resolve before MVP:** which push notification infrastructure? FCM for Android is confirmed; for iOS — decide between APNs direct or FCM universal gateway.

---

## Appendix — Full Spec Cross-Reference

Sections of `functional-spec-v2.1.md` and their MVP coverage:

| Full Spec Section | MVP Coverage |
|---|---|
| §1 Context & Vision — Core Principle and Lifecycle | Fully covered (steps 1–6) |
| §2.1 Victim or Witness | Partial — emit only, no stress meter, no group notify |
| §2.4 Private Individual (Bystander) | Partial — acknowledge only, no response options |
| §3.1 Victim | Partial — alert emission, no qualification |
| §3.2 Witness | Partial — alert emission + follower confirmation |
| §4.1 Alert Types | Partial — 4 types, no qualification dimensions |
| §4.2 Alert Status | Fully covered (sent / delivered / read / closed) |
| §4.8 Geolocation | Fully covered (cold + hot modes) |
| §5.2 Hotspot | Partial — creation + broadcast, no collaborative thread |
| §6.1 Onboarding | Partial — anonymous only, no watcher/official auth |
| §6.3 Alert Emission | Partial — grid + status band + map preview only |
| §6.4 Alert Reception | Partial — notification + map + acknowledge only |
| §2.2 Official | **EXCLUDED** — Phase 2 |
| §2.3 Security Group | **EXCLUDED** — Phase 2 |
| §4.4 Alert Modes (ghost/stealth/private) | **EXCLUDED** — Phase 2 |
| §4.6 User Credibility | **EXCLUDED** — Phase 2 |
| §5.1 Groups | **EXCLUDED** — Phase 2 |
| §6.5 Perimeter Surveillance (Web) | **EXCLUDED** — Phase 2 |
| §7 Statistics & Reporting | **EXCLUDED** — Phase 3 |
