# GeoSaveMe — Market Analysis

> Comprehensive document consolidating customer segmentation, value propositions, offer structure, pricing strategy, and business model.
> Compiled from: `added_value.md`, `business_model.md`, `offer_and_pricing.md`
> Last updated: 2026-03

---

## 1. Market Segmentation

GeoSaveMe addresses two distinct market layers: **institutional customers** (B2B) who pay for real-time operational access, and **end users** (B2C/B2B2C) who are the network's primary value driver.

### 1.1 Institutional Customers (B2B)

| Segment | Role in the Platform |
|---|---|
| Police, Gendarmerie | Core institutional partners; Pro service subscribers |
| Fire service, SAMU | Pro service subscribers |
| Private security agencies | Pro service subscribers |
| Municipalities | Data and statistics clients; potential public service partners |
| Victim support associations | Community partners and distribution channels |
| First responder associations | Accreditation partners (Red Cross, VISOV…) |
| Real estate agencies | Annual data contract clients |
| Insurers | Annual data contract clients |

### 1.2 End Users (B2C)

Anonymous end users form the mass audience. They are the primary value driver of the network — without their alerts and geolocation data, the platform has no value for institutional clients. Alert emission is free for all end users across all tiers.

---

## 2. Value Proposition by Segment

### 2.1 PSAP (Public Safety Answering Points)

- **Decongestion** of the PSAP bottleneck through a decoupled alert-emission process, with the possibility of lowering the usual alert threshold.
- **Infrastructure resilience** — bypasses the PSAP's obsolescent communication infrastructure, with improved resilience in the event of an outage.
- **Improved situation qualification** through localised, real-time cross-referencing of alerts.
- **Reduction in duplicate calls** — users who can see that a call has already been placed on a hotspot may choose to emit an alert without calling again.

### 2.2 Patrols

- **Proactive deployment** on the basis of live alerts, ahead of emergency calls.
- **Patrol planning** informed by statistics and predictive models.
- **Targeted communication** — ability to broadcast messages directly to intervention zones.

### 2.3 Public Services

- **Situational prevention** through broadcast of targeted messages adapted to situations reported on the platform (e.g. support association numbers, assault prevention contacts).
- **Public education** — online instruction and training on appropriate behaviours for each type of situation.

### 2.4 First Responders

- **Equipment localisation** — nearby rescue equipment (defibrillators, fire extinguishers, etc.) with the ability for first responders to update their status.

### 2.5 End Users

- **Fills the severity gap** — some situations lack the severity to justify an emergency call yet still merit being flagged to the neighbourhood.
- **Collective vigilance** — by emitting an alert, the user actively promotes local vigilance and secures at least passive support from the network.
- **Group safety** — as a parent or group leader (event, leisure, sport), the user is notified of any danger to a group member at the same time as the alert is broadcast to locally-positioned bystanders.
- **Recognition of discriminatory assaults** — as a woman, a racialised person, or a person of faith, the user can contribute to the recognition of the incivilities and discriminatory assaults they experience — whether sexual, racial, or religious in nature.

---

## 3. Offer Structure

The platform offers four product tiers across two categories: **Freemium** (community access) and **Pro Service** (operational real-time access).

| Tier | Product | Alert emission | Mobile/web access to all alerts | Stealth intervention & hotspot qualification | Broadcast message on hotspot | Monthly statistics | Annual statistics |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| | | *mobile* | *mobile / desktop* | *mobile* | *desktop* | *mobile / desktop* | *mobile / desktop* |
| **Freemium** | Neighbourhood alerts J+1 | ✓ | ✓ (J+1) | — | — | ✓ | — |
| **Freemium** | Statistics access A+1 | ✓ | — | — | — | — | ✓ |
| **Pro Service** | Patrol & intervention T+0s | — | ✓ (T+0s) | ✓ | — | — | ✓ |
| **Pro Service** | PSAP operational management T+0s | — | ✓ (T+0s) | ✓ | ✓ | — | ✓ |

**Key differentiator:** Freemium access is delayed (J+1 / A+1), while Pro Service grants real-time access (T+0s). This latency gap is the primary commercial lever.

---

## 4. Pricing Strategy

| Tier | Product | Billing model | Price |
|---|---|---|---|
| **Freemium** | Neighbourhood alerts J+1 | Monthly subscription / user / sector | €1 (city < minimum active zone) |
| **Freemium** | Statistics access A+1 | Annual subscription / user / sector | €39 (city) / €149 (département) |
| **Pro Service** | Patrol & intervention T+0s | Annual subscription / official agent / sector | €229 (city) / €449 (département)… |
| **Pro Service** | PSAP operational management T+0s | Annual subscription / official agent / sector | €39 (city) |
| **On quote** | Access to data for advanced statistics | Dedicated contract | TBD |
| **On quote** | AI-powered patrol prediction tool | Dedicated contract | TBD |

**Pricing principles:**
- Alert emission is **free** for all users in all tiers — this sustains network density.
- Pricing is per-sector (city / département), allowing territorial scoping and progressive expansion.
- Advanced data access may be licensed to insurance companies or real estate agencies under dedicated contracts.

---

## 5. Business Model

### 5.1 Revenue Model (Indicative)

| Line | Product | Volume | Avg. annual price (€) | Annual total (€) |
|---|---|---:|---:|---:|
| Sales | Patrol subscription | 5,000 agents | 228 | 1,140,000 |
| Sales | Neighbourhood alert subscription | 500,000 users | 12 | 6,000,000 |
| Sales | Statistics subscription | 10,000 subscribers | 39 | 390,000 |
| **Total revenue** | | | | **7,530,000** |

The neighbourhood alert subscription (B2C Freemium) dominates revenue at scale, making **mass adoption the primary commercial imperative**.

### 5.2 Cost Structure (Indicative)

| Category | Item | Quantity | Avg. annual cost (€) | Annual total (€) |
|---|---|---:|---:|---:|
| Infrastructure | Servers | 100 | 3,000 | 300,000 |
| Infrastructure | Maps | — | — | TBD |
| People | Technical | 5 | 70,000 | 350,000 |
| People | Marketing | 2 | 50,000 | 100,000 |
| People | Commercial | 1 | 70,000 | 70,000 |
| Overhead | — | — | — | 80,000 |
| EBITDA target | — | — | — | 270,000 |
| **Total cost** | | | | **1,170,000** |

### 5.3 Unit Economics Summary

| Metric | Value |
|---|---|
| Target revenue | €7,530,000 |
| Target cost base | €1,170,000 |
| Gross margin (indicative) | ~84% |
| Break-even driver | Mass end-user adoption (500k+ subscribers) |

---

## 6. Prospective Offerings

Two high-value on-quote products are identified for a later phase:

| Product | Target | Notes |
|---|---|---|
| Advanced statistics data access | Insurers, real estate agencies, municipalities | Fine-grained spatial and temporal incident data |
| AI-powered patrol prediction tool | Police, private security | Predictive deployment based on historical hotspot patterns |

These require a sufficient data volume to be credible and are gated on network maturity.

---

## 7. Strategic Observations

1. **Network effect is the core moat** — the platform's value is zero without end-user density. All commercial and partnership activity should subordinate to growing the anonymous user base.
2. **Institutional B2B locks in recurring revenue** — patrol and PSAP subscriptions are the stable revenue floor; B2C volume is the growth multiplier.
3. **Latency as the pricing lever** — the J+1 vs T+0s distinction is simple to understand, hard to circumvent, and directly tied to operational value for professionals.
4. **Data licensing is the long-term upside** — insurers and real estate players represent a high-margin, low-volume revenue stream that requires no additional infrastructure once the data is collected.
5. **Distribution via victim-support and first-responder associations** is a low-cost, high-trust acquisition channel for both end users and institutional credibility.
