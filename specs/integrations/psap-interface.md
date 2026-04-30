# GeoSaveMe — PSAP Interface Specification

> **Status** Draft
> **Version** 0.1
> **Date** April 2026
> **Relationship to other documents**
> This document specifies GeoSaveMe's interface with Public Safety Answering Points (PSAPs).
> It sits within the frame established by `architectural-foundations.md` and elaborates on
> the call-to-forces use cases described in `functional-spec.md` §3.4 (Officials) and §6.5
> (Perimeter Surveillance). It does not modify those documents; it extends them for a
> specific external integration.

---

## Table of Contents

1. [Purpose and Scope](#1-purpose-and-scope)
2. [Problem Statement](#2-problem-statement)
3. [Standards Foundation](#3-standards-foundation)
4. [Architecture](#4-architecture)
5. [The Situation Dispatch URI](#5-the-situation-dispatch-uri)
6. [Legacy PSAP Delivery — The Display Name Mechanism](#6-legacy-psap-delivery--the-display-name-mechanism)
7. [NG112 Delivery — RFC 7852 Call-Info Headers](#7-ng112-delivery--rfc-7852-call-info-headers)
8. [Endpoints to Build](#8-endpoints-to-build)
9. [Failure Modes and Constraints](#9-failure-modes-and-constraints)
10. [Carrier Selection and Cost](#10-carrier-selection-and-cost)
11. [France Migration Timeline](#11-france-migration-timeline)
12. [Relationship to Architectural Foundations](#12-relationship-to-architectural-foundations)
13. [References](#13-references)

---

## 1. Purpose and Scope

This document specifies how GeoSaveMe delivers live situational data to PSAP call-takers when a user places a 112 (or equivalent) emergency call from within the application.

The goal is to connect the call-taker to the GeoSaveMe situation already in progress — alert type, severity, GPS location, stress indicator, follower count, elapsed time — without requiring any prior onboarding, contract, or CAD integration on the PSAP side. This is the "no administrative burden" requirement.

This document covers:
- The standards used
- The SIP relay architecture
- The delivery mechanism for legacy PSAPs (France, current state)
- The delivery mechanism for NG112-capable PSAPs (France, migration path)
- The endpoints GeoSaveMe must build
- Carrier selection criteria and cost

This document does not cover:
- The web interface rendered at the dispatch URI (that is a front-end concern, described in `functional-spec.md` §6.5)
- The onboarding of officials who choose to register with GeoSaveMe proactively (described in `functional-spec.md` §2.2)

---

## 2. Problem Statement

When a GeoSaveMe user calls 112, the PSAP dispatcher receives a voice call. On a legacy CAD system — which describes all current French PSAPs — the dispatcher sees the caller's phone number and display name. Nothing else. GeoSaveMe's hotspot data, GPS coordinates, alert type, stress level, and follower count are invisible.

The dispatcher is therefore in exactly the position the platform exists to improve: a caller somewhere on a street, with the dispatcher knowing nothing except the phone number.

The interface described in this document closes that gap without requiring PSAPs to integrate with GeoSaveMe, subscribe to any service, or change their CAD software.

---

## 3. Standards Foundation

### 3.1 SIP (RFC 3261)

The 112 call travels as a SIP INVITE message. SIP headers carry metadata about the call. GeoSaveMe's SIP relay controls the headers it injects into the INVITE before forwarding to the carrier.

### 3.2 PIDF-LO and the Geolocation Header

Location is conveyed in a SIP INVITE either by value (a PIDF-LO XML object embedded in the message body) or by reference (a URI in the `Geolocation` header pointing to an HTTPS endpoint that returns the PIDF-LO). GeoSaveMe uses location-by-reference, serving a HELD-compatible endpoint that returns the hotspot GPS coordinates.

### 3.3 RFC 5985 — HELD (HTTP-Enabled Location Delivery)

HELD defines the protocol for retrieving location from a Location Information Server (LIS) by value or by reference. GeoSaveMe implements a minimal LIS stub that responds to HELD dereference requests with a PIDF-LO containing the hotspot coordinates and a `<provided-by>` element linking to GeoSaveMe's additional data.

### 3.4 RFC 7852 — Additional Data Related to an Emergency Call

RFC 7852 is the primary standard for this integration. It defines:

- A set of structured data blocks (`EmergencyCallData.*`) describing the call, the service, the device, and the subscriber
- A `Call-Info` SIP header mechanism with `purpose=EmergencyCallData.*` for attaching those blocks — by value (CID URI in the SIP body) or by reference (HTTPS URL) — to a 112 call
- An extensible registry of block types, including `Comment`, which GeoSaveMe uses to carry the situation dispatch URI

NG112-compliant CAD systems parse these headers automatically. Legacy CADs ignore them.

### 3.5 ETSI TS 103 479 — NG112 Architecture

ETSI TS 103 479 defines the European Next-Generation 112 architecture: an all-IP emergency network (ESInet) through which calls travel as SIP, fully compatible with RFC 7852. France's transition to this architecture is mandated and under way. GeoSaveMe builds to this standard now so that the integration improves automatically as PSAPs migrate.

---

## 4. Architecture

```
GeoSaveMe app
    │
    │  User taps "Call 112" inside the app
    │
    ▼
GeoSaveMe SIP Relay (GeoSaveMe backend)
    │
    │  Builds the enriched SIP INVITE:
    │  · From display name  →  "SOS GeoSaveMe gsme.io/s/{token}"
    │  · Geolocation header →  URI to GeoSaveMe LIS endpoint
    │  · Call-Info headers  →  RFC 7852 data blocks (ProviderInfo, ServiceInfo, Comment)
    │
    ▼
ESInet-connected SIP carrier (commercial partner)
    │
    ▼
PSAP
    ├── Legacy CAD  →  call-taker reads display name → opens situation URI manually
    └── NG112 CAD   →  parses Call-Info headers → situation data rendered automatically
```

One relay. One call path. Both legacy and NG112 PSAPs are served. The experience improves as France migrates without any code change on GeoSaveMe's side.

---

## 5. The Situation Dispatch URI

When a hotspot is created, GeoSaveMe generates a `situationToken`: a short-lived, cryptographically opaque identifier.

The situation dispatch URI takes the form:

```
https://gsme.io/s/{situationToken}
```

This URI:

- Requires no login. The token is the credential.
- Renders a read-only, live view of the situation: map pin, alert type, severity, stress indicator, follower count, time elapsed, and any qualification data already submitted.
- Is designed for the call-taker context: fast to load, mobile and desktop compatible, no GeoSaveMe account required.
- Expires when the alert emitter closes the alert (emits `secure`), or after a configurable inactivity timeout.
- Must never expose the emitter's precise GPS coordinates to the call-taker via this public page — only approximate location, consistent with `functional-spec.md` §4.7. Precise coordinates are available only to authenticated officials who have onboarded through the official channel.

The short domain `gsme.io` is intentional: it must fit in the SIP display name field (see §6) and be readable over the phone if the call-taker asks the caller to repeat it.

---

## 6. Legacy PSAP Delivery — The Display Name Mechanism

### 6.1 The Constraint

Legacy French CAD systems render one human-readable string from an incoming call: the caller display name. This string is carried in the `From` header's display name component and the `P-Asserted-Identity` header of the SIP INVITE. It is the only user-facing string that a third-party SIP relay can inject and that survives transit through legacy infrastructure to the call-taker screen.

### 6.2 The Mechanism

GeoSaveMe's SIP relay sets the display name to a branded short string containing the situation URI:

```
From: "SOS GeoSaveMe gsme.io/s/X7K2P" <sip:+336XXXXXXXX@geosaveme.io>
P-Asserted-Identity: "SOS GeoSaveMe gsme.io/s/X7K2P" <sip:+336XXXXXXXX@geosaveme.io>
```

The call-taker sees `SOS GeoSaveMe gsme.io/s/X7K2P` on their screen. They open a browser, navigate to the URL, and land on the live situation view with no further action required.

### 6.3 Design Constraints on the Display Name

- **Length**: SIP display names have no hard limit, but many legacy CAD systems truncate at 30–40 characters. The string `SOS GeoSaveMe gsme.io/s/XXXXX` is 30 characters with a 5-character token. Token length should not exceed 6 characters.
- **Characters**: The token must be alphanumeric only. No slashes, dots other than the domain dot, or special characters that could be misread verbally.
- **Readability**: The URI must be legible on a screen and dictatable by phone. `gsme.io` is preferred over `geosaveme.io` for this reason.
- **Carrier passthrough**: The selected carrier must be verified to pass the display name through to the PSAP unmodified. This is a mandatory qualification criterion for carrier selection (see §10).

### 6.4 Caller Phone Number Preservation

The phone number in the `From` header must be the GeoSaveMe user's real MSISDN, not a GeoSaveMe relay number. The PSAP needs the real number for callback purposes. The SIP relay must use the user's number as the calling party identity, not mask it with a relay number.

---

## 7. NG112 Delivery — RFC 7852 Call-Info Headers

For PSAPs running NG112-compliant CAD software, the situation data is delivered automatically via `Call-Info` headers. No manual URL entry is required.

### 7.1 Header Structure

```
Geolocation: <https://lis.geosaveme.io/loc/{token}>; inserted-by="geosaveme.io"
Geolocation-Routing: yes

Call-Info: <https://api.geosaveme.io/ecd/{token}/provider>;
           purpose=EmergencyCallData.ProviderInfo
Call-Info: <https://api.geosaveme.io/ecd/{token}/service>;
           purpose=EmergencyCallData.ServiceInfo
Call-Info: <https://gsme.io/s/{token}>;
           purpose=EmergencyCallData.Comment
```

### 7.2 Block Contents

**EmergencyCallData.ProviderInfo** — identifies GeoSaveMe as a Telematics Provider per the RFC 7852 provider type registry. Includes GeoSaveMe's contact URI and a 24/7 support endpoint.

**EmergencyCallData.ServiceInfo** — serialises the situation data already captured by the platform:

| Field | Source in GeoSaveMe data model |
|---|---|
| Alert type | `functional-spec.md` §4.1 — `unsecure` / `danger` / `police` / `fire` |
| Severity level | §4.1 severity (0–3) |
| Stress indicator | §3.1 — derived from button press frequency |
| Follower count | §5.2 hotspot participant count |
| Witness count | §3.2 |
| Time since alert opened | Derived from hotspot creation timestamp |
| Issuer position | §4.5 — Victim or Witness |
| Alert mode | §4.4 — Public / Ghost / Private |

**EmergencyCallData.Comment** — carries the situation dispatch URI (`https://gsme.io/s/{token}`). NG112 CADs that parse this block can render it as a clickable link directly in the call-taker interface.

### 7.3 Location Endpoint (HELD LIS Stub)

The `Geolocation` header references a GeoSaveMe-hosted HELD endpoint that returns a PIDF-LO:

```xml
<presence xmlns="urn:ietf:params:xml:ns:pidf"
          xmlns:gp="urn:ietf:params:xml:ns:pidf:geopriv10">
  <tuple id="geosaveme">
    <status>
      <gp:geopriv>
        <gp:location-info>
          <gml:Point srsName="urn:ogc:def:crs:EPSG::4326">
            <gml:pos>{lat} {lng}</gml:pos>
          </gml:Point>
        </gp:location-info>
        <gp:usage-rules>
          <gp:retransmission-allowed>yes</gp:retransmission-allowed>
        </gp:usage-rules>
        <gp:provided-by>
          <pi:EmergencyCallData.ServiceInfo
              xmlns:pi="urn:ietf:params:xml:ns:EmergencyCallData">
            <pi:ServiceURI>https://gsme.io/s/{token}</pi:ServiceURI>
          </pi:EmergencyCallData.ServiceInfo>
        </gp:provided-by>
      </gp:geopriv>
    </status>
  </tuple>
</presence>
```

This means a PSAP that dereferences the Geolocation URI to retrieve coordinates also receives the situation dispatch URI in the same response. A single HELD dereference delivers both location and the GeoSaveMe link.

---

## 8. Endpoints to Build

| Endpoint | Path | Purpose | Auth |
|---|---|---|---|
| Situation dispatch page | `https://gsme.io/s/{token}` | Call-taker web view | Token in URL |
| HELD / LIS location | `https://lis.geosaveme.io/loc/{token}` | PIDF-LO for NG112 location dereference | Token in URL |
| RFC 7852 ProviderInfo | `https://api.geosaveme.io/ecd/{token}/provider` | GeoSaveMe provider identity | Token in URL |
| RFC 7852 ServiceInfo | `https://api.geosaveme.io/ecd/{token}/service` | Situation data in structured XML | Token in URL |

All endpoints:
- Return `404` after the situation token expires (alert closed or timed out)
- Must respond within 2 seconds (PSAP CAD dereference timeouts are short)
- Must be served over HTTPS with a valid certificate
- Must not require cookies, sessions, or any browser-side state

---

## 9. Failure Modes and Constraints

### 9.1 SIP Relay Unavailability

If the GeoSaveMe SIP relay is unreachable when the user attempts to call 112, the call must fall back to the device's native dialer immediately and silently. The user must never be left unable to reach 112. This is a hard constraint that overrides all other considerations.

Implementation: the app attempts connection to the relay with a 3-second timeout. On failure, it hands off to the OS native dialer with `tel:112`. The fallback call reaches 112 without any GeoSaveMe data enrichment, which is acceptable. A missed enrichment is a degraded experience; a missed 112 call is a safety failure.

### 9.2 Carrier Header Rewriting

If the carrier strips or rewrites the `From` display name, the legacy delivery mechanism fails silently. The call still reaches 112, but the call-taker sees no GeoSaveMe data. This must be tested explicitly during carrier onboarding, not assumed.

### 9.3 Token Expiry During Active Call

If a call-taker opens the dispatch URI while the situation is still active, then the alert emitter closes the alert before the call ends, the page should show a "situation closed" state rather than returning 404. The call-taker needs to know the situation resolved, not assume the link is broken.

### 9.4 Anonymous User Privacy

The situation dispatch URI is accessible to anyone with the token. The token must be:
- Unguessable (minimum 128 bits of entropy)
- Not derived from the device ID or any persistent user identifier
- Expired immediately and irrecoverably when the alert closes

The page must show approximate location only, consistent with `functional-spec.md` §4.7. Precise GPS coordinates are never exposed via this endpoint.

---

## 10. Carrier Selection and Cost

See `business-model.md` §1.1 for cost estimates.

### Mandatory Qualification Criteria

Before committing to any carrier, verify:

1. **112 origination from a third-party SIP relay is permitted.** Some carriers restrict emergency call origination for liability reasons.
2. **`From` display name is passed through to the PSAP unmodified.** Some carriers rewrite this header on outbound emergency calls. This is a disqualifying constraint for the legacy delivery mechanism.

### Candidate Carriers

| Provider | Notes |
|---|---|
| **OVHcloud Telecom** | French operator, native regulatory context, evaluate first |
| **Twilio** | Well-documented, but verify country-specific emergency call policy |
| **Vonage / Ericsson** | Enterprise-grade, ESInet experience |
| **Infobip** | Broad EU coverage |

---

## 11. France Migration Timeline

All current French PSAPs are legacy. ETSI TS 103 479 compliance is mandated across the EU and France is in active transition. The timeline is PSAP-by-PSAP, driven by the relevant prefecture and ESInet operator.

GeoSaveMe's architecture requires no changes as PSAPs migrate:

| PSAP state | What the call-taker sees | GeoSaveMe action required |
|---|---|---|
| Legacy (current) | Display name with situation URI — manual browser navigation | None |
| Partial NG112 | Display name + some Call-Info headers parsed | None |
| Full NG112 | Situation data rendered automatically in CAD, clickable URI | None |

The integration is built once and improves passively as infrastructure matures.

---

## 12. Relationship to Architectural Foundations

This integration is consistent with the principles in `architectural-foundations.md`:

**§2 — Communication Channel, Not Interpretive System.** The dispatch URI surface presents situation data to the call-taker; it does not instruct the call-taker, route the call, or make decisions. The call-taker acts on what they see.

**§8 — Affordance Parity.** The dispatch page renders what the call-taker can act on: location, alert type, severity, stress, follower count, time elapsed. Nothing else. It does not expose credibility scores, device IDs, or internal event history.

**§10 — What the System Never Does.** The PSAP interface does not expose precise emitter location to a non-authenticated recipient. The situation token provides read access to the call-taker view only, not the official view. The full official interface requires authenticated onboarding per `functional-spec.md` §2.2.

---

## 13. References

All external standards and specifications referenced in this document are listed below. Local copies should be stored in `specs/references/` to ensure long-term availability.

### Standards and RFCs

| Reference | Title | Source | Local copy |
|---|---|---|---|
| **RFC 3261** | SIP: Session Initiation Protocol | https://datatracker.ietf.org/doc/html/rfc3261 | `specs/references/rfc3261-sip.txt` |
| **RFC 5985** | HTTP-Enabled Location Delivery (HELD) | https://datatracker.ietf.org/doc/html/rfc5985 | `specs/references/rfc5985-held.txt` |
| **RFC 7852** | Additional Data Related to an Emergency Call | https://datatracker.ietf.org/doc/html/rfc7852 | `specs/references/rfc7852-additional-data.txt` |
| **ETSI TS 103 479 v1.2.1** | Emergency Communications (EMTEL) — Core elements for network independent access to emergency services (NG112 architecture) | https://www.etsi.org/deliver/etsi_ts/103400_103499/103479/01.02.01_60/ts_103479v010201p.pdf | `specs/references/etsi-ts-103479-v1.2.1.pdf` |
| **CEPT Report** | Next Generation Emergency Communications — transition (covers NG112 adoption across CEPT member states, references ETSI TS 103 479) | https://docdb.cept.org/download/4589 | `specs/references/cept-ng112-transition.pdf` |

### Background Reading

| Reference | Title | Source | Notes |
|---|---|---|---|
| **SIP Overview** | Session Initiation Protocol — what it is and how it works | https://getstream.io/glossary/session-initation-protocol/ | Accessible introduction to SIP concepts; not a normative reference |

### Notes on RFC Availability

RFC 3261, RFC 5985, and RFC 7852 are freely available from the IETF datatracker and the RFC Editor. Plain-text versions (`.txt`) can be downloaded directly from `https://www.rfc-editor.org/rfc/rfcXXXX.txt`. The ETSI and CEPT documents are publicly accessible from their respective organisation portals at the URLs above.

---

*End of document.*
