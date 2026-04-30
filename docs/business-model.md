# GeoSaveMe — Business Model

> **Status** Draft — in progress
> **Version** 0.1
> **Date** April 2026
> **Note** This document is being built incrementally. Sections marked *TBD* are placeholders for future elaboration.

---

## Table of Contents

1. [Cost Structure](#1-cost-structure)
   - 1.1 [PSAP / SIP Carrier Integration](#11-psap--sip-carrier-integration)
   - 1.2 [Infrastructure](#12-infrastructure) *(TBD)*
   - 1.3 [Marketing & Growth](#13-marketing--growth) *(TBD)*
2. [Revenue Model](#2-revenue-model) *(TBD)*
3. [Unit Economics](#3-unit-economics) *(TBD)*
4. [Competitive Landscape](#4-competitive-landscape)
   - 4.1 [M7 Citizen Security](#41-m7-citizen-security-spain)
   - 4.2 [Citizen (sp0n Inc.)](#42-citizen-sp0n-inc--united-states)
5. [Market Strategy](#5-market-strategy)
   - 5.1 [Target Market Analysis & Entry Sequencing](#51-target-market-analysis--entry-sequencing)

---

## 1. Cost Structure

### 1.1 PSAP / SIP Carrier Integration

#### Context

When a GeoSaveMe user calls 112 from within the app, the call is routed through a GeoSaveMe-controlled SIP relay before reaching the PSAP. This relay injects the situation token (as a display name) and RFC 7852 Additional Data headers into the SIP INVITE, allowing the call-taker to access live situational data without any prior onboarding to GeoSaveMe.

This architecture requires a commercial SIP carrier with ESInet connectivity in France (and, later, per market). See `specs/integrations/psap-interface.md` for the full technical specification.

#### Why the Cost Is Low

**Volume is naturally small.** GeoSaveMe's core value proposition is that users do not need to call 112 in most cases — the hotspot, follower count, and official notification handles the majority of situations. 112 calls placed from within the app are the last resort: a fraction of alert events, which are themselves a fraction of active users. Even at meaningful scale, call volume is expected to be in the hundreds per month, not thousands.

**112 calls are short.** A PSAP call is typically 1–3 minutes. No hold music, no IVR. The call connects, context is exchanged, call ends.

**Emergency call termination is regulated.** In France and across the EU, termination of calls to emergency numbers (15, 17, 18, 112) is legally required to be free of charge for the originating carrier. The SIP carrier pays nothing to terminate to the PSAP. They may pass a small origination charge, but there is no per-minute termination cost on 112 calls.

#### Expected Costs

| Cost item | Estimate | Notes |
|---|---|---|
| Monthly platform fee (SIP trunk) | €50–200/month | Some providers charge nothing for the trunk and bill on usage only |
| Per-minute usage (112 calls) | €0.01–0.03/min | Many providers zero-rate 112 calls explicitly |
| Usage at 500 calls/month × 2 min avg | €10–30/month | Dominated by platform fee, not per-minute |
| **Total at early scale** | **€100–300/month** | Platform fee is the main driver |

These figures should be revisited once a carrier partner is selected and a contract is in place.

#### The Real Cost Is Engineering, Not Carrier Fees

The SIP relay backend is the primary investment. A developer familiar with SIP should budget several weeks for:

- Correct construction of PIDF-LO location objects from hotspot GPS data
- Routing of 112 to the geographically appropriate PSAP (handled by the carrier's ECRF, but requires a valid location in the INVITE)
- Fail-safe fallback: if the GeoSaveMe relay is unreachable, the call must fall back to the native phone dialer automatically. A silent failure is not acceptable.
- RFC 7852 `Call-Info` header construction and the HTTPS data endpoints they reference

This engineering cost is a one-time build. The ongoing carrier bill is operationally negligible.

#### Carrier Selection Criteria

Two questions determine whether a carrier is viable before signing any contract:

1. Do they support **112 call origination from a third-party SIP relay**? Some carriers restrict emergency call origination for liability reasons.
2. Do they pass the **`From` display name through to the PSAP unmodified**? Some carriers rewrite headers on outbound 112 calls. The display name is the delivery mechanism for the situation token on legacy PSAPs and must not be stripped or altered.

#### Candidate Carriers (France)

| Provider | Notes |
|---|---|
| **OVHcloud Telecom** | French operator, native regulatory familiarity, known emergency call use cases — evaluate first |
| **Twilio** | Well-documented, but has country-by-country emergency call restrictions — read carefully before committing |
| **Vonage / Ericsson** | Enterprise-grade, ESInet experience |
| **Infobip** | Broad EU coverage |

---

### 1.2 Infrastructure

*TBD — to be elaborated. Will cover: backend compute and storage, real-time messaging layer, geolocation services, CDN, monitoring and observability, per-market deployment costs.*

---

### 1.3 Marketing & Growth

*TBD — to be elaborated. Will cover: go-to-market costs per market, partnership and accreditation costs (Red Cross, security associations), PR around PSAP integration, app store presence.*

---

## 2. Revenue Model

*TBD — to be elaborated. Will cover: freemium vs. institutional licensing, municipality and departmental statistics subscriptions (J+1, M+1, A+1 tiers per functional-spec §7.2), extended security group fees for organisations and events, potential official subscription tier.*

---

## 3. Unit Economics

*TBD — to be elaborated once infrastructure and revenue model sections are drafted.*

---

## 4. Competitive Landscape

This section documents competitive analysis conducted during product development. Each entry records what the competitor is, how it compares to GeoSaveMe, and the strategic conclusion.

---

### 4.1 M7 Citizen Security (Spain)

> **Reviewed** April 2026 · **Source** https://w2.m7citizensecurity.com · **Language** Catalan / Spanish

#### What It Is

M7 Citizen Security is a B2G (business-to-government) product developed by Einsmer, based in Cornellà de Llobregat near Barcelona, operating since 2012. The model is: a municipality contracts M7, deploys the app under its local police brand, and uses it as a structured communication channel between the local police force and registered residents.

Current deployment covers approximately 13 municipalities in the Barcelona metropolitan area, including Cornellà, Castelldefels, Gavà, L'Hospitalet de Llobregat, Vic, Sant Boi, Sant Feliu, and others.

It holds CNI-CERT certification (Spain's national cybersecurity centre) and is a member of the Siemens Xcelerator accelerator programme.

#### Features

- **Preventive alert timer** — user sets a journey duration; if not cancelled on arrival, automatically alerts pre-registered contacts and local police
- **Device association** — pre-registered personal contact network
- **Official police broadcasts** — push notifications FROM local police TO citizens (road conditions, fraud warnings, etc.)
- **Incident reporting** — structured channel to report civic or urban incidents to police, with photo attachment and precise location
- **3-second emergency button** — direct alert to local police
- **Emergency calls** — direct call to nearest local police
- **Vulnerable persons protocol** — parents/guardians of minors or people with disabilities can request localisation by police
- **Gender violence protocol** — direct alert integration with local police gender violence response unit
- **Utility information** — duty pharmacies, defibrillator network map, public directory

#### Metrics (as published on their website, April 2026)

| Metric | Value | Interpretation |
|---|---|---|
| Territories | 1 | Likely refers to the network as one system, not individual municipalities |
| Network infrastructures | 3,450 | Internal infrastructure nodes |
| Users | 13,950 | Total registered users across all municipalities |
| Alert views | 7,569,150 | Almost certainly police broadcast push notifications, not citizen-initiated alerts |

13,950 users across 13 municipalities in a combined population of ~1.5–2 million people, after 13 years of operation, represents under 1% penetration in contracted markets where the app is actively promoted by local police. This is the defining weakness of the B2G, non-anonymous model.

#### Feature Comparison vs. GeoSaveMe

| Dimension | M7 Citizen Security | GeoSaveMe |
|---|---|---|
| **Business model** | B2G — sold to municipalities | B2C / B2G — citizen-first network |
| **Who initiates growth** | Requires municipality contract | Citizens adopt independently |
| **User anonymity** | No — users register with local police | Yes — anonymous by default |
| **Civilian solidarity layer** | None — no bystander or watcher concept | Core feature — followers, watchers, hotspot radius |
| **Real-time proximity alerting** | No | Yes — nearby civilians notified on hotspot creation |
| **Network effects** | Bounded to one municipality per contract | Cross-territory, compounds with density |
| **Alert recipients** | Local police and pre-registered contacts only | Nearby civilians + officials + security groups |
| **Peer coordination** | None | Central to the product |
| **Cross-territory operation** | No — municipality-scoped | Yes — any location |
| **Growth without official agreement** | Impossible — requires contract | Fully possible |
| **Stress indicator** | No | Yes — button press frequency |
| **Credibility scoring** | No | Yes — progressive reputation system |
| **Ghost / stealth modes** | No | Yes |
| **Statistics export for institutions** | No mention | Yes — J+1, M+1, A+1 tiers |
| **Open source** | No | Yes |
| **Gender violence protocol** | Yes — explicit feature | Not yet explicit in spec — worth adding |
| **Vulnerable persons protocol** | Yes — explicit feature | Not yet explicit in spec — worth adding |

#### Strategic Conclusion

M7 and GeoSaveMe are **not in the same product category**. M7 is a citizen-to-police reporting tool with a police-to-citizen broadcast channel. GeoSaveMe is a civilian solidarity network that also interfaces with officials. The surface overlap — both involve alerting and safety — conceals fundamentally different architectures, philosophies, and growth models.

M7's B2G model creates a structural ceiling: growth is gated by municipal procurement cycles, and each contract delivers a bounded captive audience rather than a compounding network. The 13-year, 14,000-user trajectory confirms this ceiling is real.

**The anonymity principle in GeoSaveMe's architecture is not a privacy feature alone — it is the feature that makes mass civilian adoption possible.** M7 requires users to register with local police. This single constraint explains why M7 cannot build the solidarity network layer that is GeoSaveMe's core value.

M7 validates that institutions are willing to pay for citizen-police connectivity tools. It does not validate that the B2G, non-anonymous, police-centric model creates user adoption. GeoSaveMe is building the product M7's architecture prevents it from ever becoming.

#### Points to Note for GeoSaveMe's Roadmap

M7's **gender violence protocol** and **vulnerable persons protocol** are institutional-grade features that open procurement conversations with municipalities and NGOs. GeoSaveMe's functional spec does not yet address these populations explicitly. They are worth adding as dedicated qualification dimensions and alert modes in a future spec revision.

#### Partnership Potential

M7's value is not its product — it is its **13 years of municipal relationships and CNI-CERT accreditation in Spain**. If Spain becomes a target market for GeoSaveMe, M7 is worth approaching as a potential integration partner or distribution channel rather than competing with them for municipality contracts. Their institutional access combined with GeoSaveMe's community-network architecture would be complementary.

---

### 4.2 Citizen (sp0n Inc.) — United States

> **Reviewed** April 2026 · **Sources** https://citizen.com · https://en.wikipedia.org/wiki/Citizen_(app) · https://research.contrary.com/company/citizen
> **Availability** US and Canada only — geo-restricted on both App Store and Google Play outside North America, which is why it cannot be downloaded from France.

#### What It Is

Citizen is a US-based mobile safety app developed by sp0n Inc., originally launched in 2016 under the name **Vigilante** before being rebranded and relaunched in March 2017. It is headquartered in New York, with approximately 186 employees. CEO is Andrew Frame, also the founder of Ooma (VoIP).

The core mechanism is passive and broadcast-oriented: Citizen operates a proprietary network of **R1 radio antennas** installed across 60+ US cities, monitoring up to 900 public radio channels per city — local and state police, fire, EMS, transit, airport security. Audio is processed by a custom AI system and interpreted by human employees, who generate geo-tagged incident alerts pushed to nearby users. Users are an audience receiving curated 911 radio, not actors emitting their own alerts.

In April 2025, Citizen announced a partnership with **Axon Fusus**, integrating Citizen with Axon's real-time crime-centre platform, allowing law-enforcement agencies to view live Citizen user videos and push verified alerts directly back to app users.

In July 2025, Citizen announced a partnership with the **NYPD**, granting law enforcement access to Citizen's incident videos and alert infrastructure.

#### Metrics and Financials

| Metric | Value | Notes |
|---|---|---|
| Total downloads | 15 million+ | As of early 2024 |
| Active users | ~9–10 million | As of October 2024 |
| Cities covered | 60+ | US and Canada only |
| Total funding raised | $144 million | Across 4 rounds |
| Latest round | $31.9M Series C-II | December 2024 / January 2025 |
| Estimated annual revenue | ~$35 million | Unverified estimate, as of 2024 |
| Employees | ~186 | As of January 2025 |

Notable investors include Sequoia Capital (resigned from board February 2023 — a significant governance signal), 8VC, Founders Fund, RRE Ventures, Slow Ventures, Greycroft, and Lux Capital.

#### Business Model and Pricing

Citizen operates a freemium model with three tiers:

| Tier | Price | Key features |
|---|---|---|
| **Free** | €0 | Real-time proximity alerts, live incident video, crime map, 24-hour incident history |
| **Citizen Plus** | $5.99/month | Live police and fire radio feeds, 90-day incident history, custom alert zones, historical crime trends |
| **Citizen Premium** | $19.99/month | 24/7 human safety agents reachable by video, voice, or text; GPS monitoring by agent; agent-dispatched first responders |

The Premium tier is the strategic bet: on-demand personal safety agents who monitor a user's situation remotely and can dispatch help. This is closer to a private security concierge than a safety app.

#### Features

- **Real-time 911-derived alerts** — geo-tagged incident notifications from monitored radio channels, filtered by human editors
- **Live incident video** — users can broadcast live from the scene; other users can watch
- **Crime map** — all nearby incidents pinned on a live map, colour-coded by status and severity
- **Incident comments** — public discussion thread on each incident
- **Alert zones** — monitor locations other than current position (office, school, family home)
- **Friend/family safety check** — see if contacts have been sent alerts; direct messaging
- **Missing person alerts** — community-assisted search for missing people or pets
- **Registered sex offenders map** — nationwide overlay
- **Historical crime trends** — 90-day incident history per area (Plus tier)
- **Safety agents** — live human agents on call 24/7 (Premium tier)
- **Incident resolution status** — tracks how events conclude, not just how they start
- **Axon Fusus integration** — law enforcement can view Citizen videos and push alerts (from April 2025)

#### Controversies and Structural Weaknesses

Citizen has a documented pattern of controversy that is directly relevant to GeoSaveMe's strategic positioning.

**Vigilantism origins.** The original Vigilante app was removed from the App Store in November 2016 after it encouraged users to rush to crime scenes. The rebranding to Citizen did not fundamentally change the architecture — it changed the messaging. Academic research published in 2025 characterises the app as reproducing police power dynamics and social domination through civilian deputisation.

**The $30,000 bounty incident (May 2021).** Citizen posted a $30,000 bounty for a suspected arsonist during the LA wildfires, broadcasting the man's photo to its users. The person was innocent. This incident crystallised the mob-alert risk of broadcast safety apps and drew widespread press criticism.

**Aggressive monetisation backlash.** App Store and Google Play reviews consistently criticise the escalating paywall: free users receive alert notifications but cannot see incident details without a subscription. Users describe the experience as being shown a threat and then charged to find out what it is. Sequoia Capital's board resignation in February 2023 occurred around the same period of heavy monetisation pressure.

**Fear amplification.** Multiple critics, including researchers and civil liberties organisations, document that Citizen's constant alerts create a distorted perception of crime levels, generating anxiety disproportionate to actual risk. This is structurally inherent to a model that monetises proximity to danger.

**Racial profiling concerns.** Early versions of both Vigilante and Citizen generated alerts for "suspicious persons" that critics identified as racially coded. The company has revised its editorial policies but the structural tension remains: alert content is curated by employees making fast decisions about what constitutes a public safety concern.

**No anonymity, extensive data collection.** Citizen tracks continuous location. Premium users are monitored by agents with GPS access. The data model is the inverse of GeoSaveMe's minimalism principle.

#### Feature Comparison vs. GeoSaveMe

| Dimension | Citizen | GeoSaveMe |
|---|---|---|
| **Alert origin** | Top-down: 911 radio → Citizen employees → users | Bottom-up: citizen emits, network responds |
| **User role** | Passive audience receiving curated alerts | Active participant — emitter, witness, follower, watcher |
| **Anonymity** | No — account required, continuous location tracking | Yes — anonymous by default, hashed device ID only |
| **Civilian solidarity layer** | None — no bystander coordination concept | Core — follower count, watcher proximity, reassurance |
| **Victim support** | No — no victim/emitter concept | Yes — stress indicator, security group, role toggle |
| **Alert direction** | Officials → platform → citizens | Citizens → officials AND citizens → citizens |
| **PSAP data feed** | Reads FROM 911 radio | Feeds situational data TO PSAP call-takers |
| **Real-time proximity alerting** | Yes — for official incidents | Yes — for citizen-originated hotspots |
| **Live video** | Yes — user broadcast | Not in current spec |
| **Security groups** | Friends list (opt-in contacts upload) | QR-code-based security group with roles |
| **Stress indicator** | No | Yes — button press frequency |
| **Ghost / stealth modes** | No | Yes |
| **Official verified channel** | No — officials consume Citizen data | Yes — authenticated official tier |
| **Open source / auditability** | No | Yes |
| **Privacy model** | Extensive collection, Premium = GPS agent monitoring | Minimalism — no profiles, no location history |
| **Business model** | Freemium B2C, fear-monetisation | Freemium B2C + institutional B2G |
| **Geography** | US and Canada only | Designed for any market |
| **Mob-alert risk** | High — documented incidents | Low — no broadcast of unverified civilian allegations |

#### Strategic Conclusion

Citizen and GeoSaveMe are **architecturally opposite**. Citizen is a 911-scanner app with a social layer, broadcasting curated official incident data to a passive audience. GeoSaveMe is a citizen-originated alert system that coordinates active response and feeds data back to officials. The information flow is reversed.

The most important structural difference: **Citizen reads FROM 911; GeoSaveMe feeds TO 911.** Citizen makes officials more visible to citizens. GeoSaveMe makes citizens more visible to officials. These are complementary functions, not competing ones — which explains why the Axon Fusus partnership is the logical direction for Citizen: it is becoming an official real-time intelligence tool, not a citizen safety tool.

Citizen's documented controversies — the bounty incident, the fear-amplification criticism, the racial profiling concerns, the Sequoia resignation, the aggressive paywall backlash — are not incidental. They are structural consequences of a model that monetises proximity to danger and curates threats for a passive audience. GeoSaveMe's architecture avoids every one of these failure modes by design: anonymity prevents profiling, the no-social-media-sharing constraint prevents viral mob behaviour, the minimalism principle prevents data exploitation, and the institutional B2G revenue model does not depend on keeping users anxious.

**Citizen is not a competitor for GeoSaveMe's primary European markets** — it does not operate outside North America and has no announced international expansion plans. In the US, if GeoSaveMe enters, Citizen's user base and brand recognition are real obstacles, but the product differentiation is sharp enough that direct competition is not the right frame. The audiences are different: Citizen attracts passive observers of urban crime; GeoSaveMe attracts active participants in community safety.

#### Points to Note for GeoSaveMe's Roadmap

Citizen's **live video broadcast** feature has genuine value in incident documentation, particularly for witnesses. GeoSaveMe's spec currently includes optional audio recording shared with officials only. Extending this to optional live video — with the same official-only access constraint — would address a real capability gap without introducing the mob-broadcast dynamic that makes Citizen's video feature controversial.

The **Axon Fusus integration** (law enforcement viewing Citizen videos) is the direction in which Citizen is evolving: toward an official intelligence tool. GeoSaveMe's NG112 PSAP interface (described in `specs/integrations/psap-interface.md`) is already structurally ahead of this — it feeds structured situational data to PSAPs at the moment of a 112 call, not after-the-fact video review.

### 5.1 Target Market Analysis & Entry Sequencing

> **Assessed** April 2026 · *To be revisited when Lean Canvas analysis is completed*

#### The Core Strategic Tension

Two complementary but distinct growth vectors exist in parallel and must be balanced:

**PSAP integration** gives institutional credibility — the ability to state that GeoSaveMe is connected with emergency services. This is a marketing and trust asset. But it requires infrastructure readiness on the PSAP side and, in some markets, administrative negotiation.

**Community autonomy** — the bystander network, follower counts, security groups, stress indicators — delivers day-to-day value with zero dependency on any government relationship. This is the organic growth engine. A market where the community can bootstrap quickly does not need PSAP integration to feel alive.

The risk of PSAP-first thinking is spending 18 months negotiating with resistant administrations before a single user gets value. The risk of community-first thinking is building a network that officials don't trust and can't reference. The target entry market must offer both: a community that can bootstrap organically **and** an administration receptive enough that PSAP integration follows within 12–18 months.

#### Evaluation Framework

Four dimensions were used to rank candidate markets:

**1. NG112 / NG911 technical readiness** — Is AML deployed? Is the ESInet operational? Will the SIP relay and RFC 7852 headers reach a capable PSAP, or be silently ignored by legacy infrastructure?

**2. Regulatory and administrative culture** — Is innovation in civic safety apps welcomed, tolerated, or blocked? Does the government treat security as a sovereign function closed to private actors, or as a domain where civic tech can contribute?

**3. Community density and network effects** — Is there sufficient urban density for the bystander network to feel alive to early adopters? Are there real safety concerns that create demand? Is there civic tech adoption culture?

**4. Open source / open collaboration alignment** — Does the market's public culture align with GeoSaveMe's transparency and auditability values?

#### Country Assessment

**France — Hold, enter with reference case**

France is the origin market and symbolically important, but it is the hardest entry point. French public administration treats security as *régalien* — a sovereign function of the state, not a domain for civic tech. Innovation in this space requires navigating the Ministry of Interior, CNIL, and municipal police structures simultaneously. AML deployment is still EU-funded and incomplete. The legacy PSAP infrastructure means even the display-name SIP hack delivers limited value until NG112 migration progresses.

*Strategic posture:* do not enter France as a pioneer. Enter with a Belgian or Dutch reference case already validated, and use it to open institutional conversations from a position of demonstrated deployment rather than a request for permission to experiment.

**Netherlands — First market, community bootstrapping**

Dense urban population (Amsterdam, Rotterdam), AML fully deployed, progressive administration with no cultural resistance to civic tech, high smartphone penetration, strong tradition of civic self-organisation. No incumbent in this space. Real urban safety concerns provide genuine demand. English widely spoken in tech circles, lowering operational friction. A community network can grow organically in the Randstad while PSAP integration is established with a technically capable counterpart.

*Strategic posture:* primary first market for community adoption and first PSAP integration reference.

**Belgium — First market, bridge to France**

Brussels specifically combines high-profile urban safety concerns, bilingual FR/NL structure, and a politically symbolic context (EU institutions, international press). AML deployed. The French-speaking community in Brussels provides a direct cultural and linguistic bridge back to France — a validated Belgian deployment walks into French institutional conversations carrying genuine weight. The bilingual market also tests GeoSaveMe's i18n architecture in a controlled way.

*Strategic posture:* co-primary first market alongside the Netherlands, with explicit strategic purpose of generating the French-market reference case.

**Estonia — Proof-of-concept reference deployment**

Too small to scale (1.3 million people), but unmatched as a showcase. AML deployed, digital government is the most advanced in the world, the government actively encourages civic tech and is explicitly critical of regulation that stifles innovation, and public trust in digital civic infrastructure is exceptionally high. An Estonian PSAP integration delivers a published, credible reference case with institutional weight disproportionate to the country's size.

E-Residency also allows GeoSaveMe to incorporate in Estonia trivially for EU market access and credibility purposes.

*Strategic posture:* early proof-of-concept deployment and reference case, not a primary growth market. Pursue in parallel with Netherlands/Belgium, not sequentially.

**United Kingdom — Second wave**

English-language, AML deployed, pragmatic regulation, large addressable population, no single incumbent in this space. Post-Brexit simplifies some data governance questions relative to GDPR-heavy EU markets. Ireland is a natural companion, with strong community response traditions and an established tech ecosystem.

*Strategic posture:* second-wave market after Netherlands/Belgium/Estonia reference cases are established.

**United States — Strategic hold**

The FCC NG911 transition mandate (2024) is accelerating infrastructure readiness, but the market is fragmented state-by-state with no single national entry point. The Citizen app (formerly Vigilante) is an established incumbent, venture-backed and operating in the same broad space, with documented controversy around mob-alert dynamics and accuracy. US liability culture is punishing for a safety app. Entry requires competing with a funded incumbent in a legally complex environment.

*Strategic posture:* revisit post-Series A with a European reference portfolio. The NG911 mandate means the infrastructure will be meaningfully more capable by the time GeoSaveMe is ready to enter.

#### Recommended Entry Sequence

| Phase | Markets | Primary goal |
|---|---|---|
| **Phase 1** | Netherlands + Belgium | Community bootstrapping, first PSAP integration, FR/NL reference case |
| **Phase 1 parallel** | Estonia | Technical proof-of-concept, institutional reference, EU entity incorporation |
| **Phase 2** | France | Institutional entry with reference cases in hand |
| **Phase 2** | UK + Ireland | English-language scale, second PSAP integration reference |
| **Phase 3** | US | Scale play, post-Series A, NG911 infrastructure matured |

#### The Autonomy Principle as Market Strategy

The community layer — bystanders, watchers, follower counts, security groups — works on day one with zero PSAP integration and zero government relationship. This is a strategic asset, not just a product feature. It means GeoSaveMe can generate organic user adoption and press coverage in any market before a single official conversation has taken place. PSAP integration then becomes a natural second step that officials are pulled toward by demonstrated community use, rather than a gate that blocks all value until administrative negotiation is complete.

This posture — **community first, PSAP integration as amplification** — is the direct inversion of M7's model, and it is why GeoSaveMe's growth ceiling is structurally higher.
