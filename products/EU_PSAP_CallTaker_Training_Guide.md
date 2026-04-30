# 📞 EU PSAP Call-Taker Training Guide
### European Emergency Services — Structured Reference Manual
*Cross-referenced from EENA, French PSE/PSC programmes, EU Regulation, and national PSAP protocols*
*Last updated: April 2026 | Audience: PSAP operators, trainers, SDIS/SAMU supervisors*

---

## Table of Contents

1. [Introduction & Regulatory Framework](#1-introduction--regulatory-framework)
2. [European Emergency Architecture](#2-european-emergency-architecture)
3. [Module A — Call Handling Fundamentals](#module-a--call-handling-fundamentals)
4. [Module B — French PSE1/PSC1 Programme Integration](#module-b--french-pse1psc1-programme-integration)
5. [Module C — eCall Processing](#module-c--ecall-processing)
6. [Module D — Ergonomics & Wellbeing](#module-d--ergonomics--wellbeing)
7. [Module E — Mass Emergency & Multi-Victim Procedures](#module-e--mass-emergency--multi-victim-procedures)
8. [Module F — Stress Management & Psychological Support](#module-f--stress-management--psychological-support)
9. [Checklists](#checklists)
10. [Best Practices Table](#best-practices-table)
11. [Glossary](#glossary)

---

## 1. Introduction & Regulatory Framework

### Overview

A **Public Safety Answering Point (PSAP)** is an organisation under public authority responsible for receiving and processing emergency communications. Across the EU, PSAPs operate under the harmonised number **112**, which serves as the single European emergency number, free of charge from any fixed or mobile network in all 27 Member States.

The EU regulatory framework governing PSAPs includes:

- **European Electronic Communications Code (EECC)** — mandates caller location accuracy and accessibility obligations
- **Delegated Regulation (EU) No 305/2013** — establishes PSAP infrastructure specifications for eCall
- **Delegated Regulation (EU) 2024/1084** — upgrades PSAP infrastructure for IMS packet-switched eCalls (deadline: 1 January 2026)
- **EENA** (European Emergency Number Association) — produces operational guidelines, training frameworks, and best-practice documents
- **Arrêté du 15 juin 2024 (France)** — establishes the national operational first-aid training pathway (PSE1/PSE2 filière)

### PSAP Models in the EU

The EU recognises five main call-handling models (EENA 2024):

| Model | Description | Examples |
|-------|-------------|---------|
| **Model 1** | Single PSAP handles all calls end-to-end | Several Nordic countries |
| **Model 2** | Stage 1 (filtering) + Stage 2 (dispatch) PSAPs | France, UK, Belgium |
| **Model 3** | 112 data-gathering stage 1, dispatch at stage 2 | Germany, Austria |
| **Model 4** | National numbers route direct; 112 to stage 1 | Spain, Italy |
| **Model 5** | Call-taking and dispatch by same organisation | Smaller Member States |

> **France note:** In France, 112 calls are typically routed to either the CTA (sapeurs-pompiers / 18) or the SAMU Centre 15, depending on the département. A pilot single-number experiment has been running since 2021 in the Ain département with promising results.

---

## 2. European Emergency Architecture

### 2.1 The Emergency Response Chain

```
Citizen → 112 Call → Stage 1 PSAP (Filtering/Locating) → Stage 2 PSAP (Dispatching)
                                                        ↓
                          ERO: SAMU / SDIS / Police / Coast Guard / SMUR
```

**Key actors in the French system:**

| Actor | Number | Role |
|-------|--------|------|
| SAMU | 15 | Service d'Aide Médicale Urgente — medical regulation |
| Sapeurs-Pompiers | 18 | Fire & rescue, first response |
| Police / Gendarmerie | 17 | Public order, road accidents |
| European 112 | 112 | Pan-EU routing gateway |
| Deaf/HoH access | 114 | SMS / video / sign language channel |
| Emergency callback | 0 800 112 112 | Free callback number used by services |

### 2.2 Stage 1 vs Stage 2 PSAP Responsibilities

**Stage 1 PSAP (call-taker):**
- Answers the initial 112 call within 10 seconds (benchmark: 22 EU Member States in 2023)
- Locates the caller using AML (Advanced Mobile Location) where available (25 MS + Iceland/Norway as of Sept 2024)
- Identifies type of emergency and required service
- Does NOT conduct detailed clinical assessment at this stage

**Stage 2 PSAP (dispatcher):**
- Receives transfer and full call data from Stage 1
- Dispatches appropriate Emergency Response Organisation (ERO)
- Coordinates multi-agency response for complex incidents

---

## Module A — Call Handling Fundamentals

### A.1 Core Competencies for 112 Call-Takers

Per EENA training guidelines, every call-taker must be trained in:

1. **Emergency service philosophy** — understanding the full service chain across police, fire, and EMS
2. **Legal and regulatory framework** — national and EU obligations
3. **Technical systems** — telephony, Computer-Aided Dispatch (CAD), radio, mapping/GIS
4. **Communication skills** — active listening, assertive speaking, language management
5. **Medical first-aid knowledge** — enough to coach a caller through pre-arrival care
6. **Stress and crisis management** — managing distressed, aggressive, or silent callers
7. **Ergonomics** — safe workstation use and recognition of occupational overuse

### A.2 Call Intake Protocol — Standard Procedure

#### Opening a Call

```
STEP 1 — ANSWER
  → Answer within target time (national standard; EENA benchmark: ≤10 seconds)
  → Identify yourself and your centre: "SAMU 75, bonjour."

STEP 2 — LOCATE
  → Confirm physical location of caller and incident
  → Cross-reference with AML / caller ID data on screen
  → If discrepancy: trust verbal information, flag discrepancy in CAD

STEP 3 — TRIAGE
  → Determine emergency type (medical / fire / police / other)
  → Assess urgency using structured questioning (see Checklist A)
  → Do NOT ask yes/no questions in isolation; use open probes first

STEP 4 — DISPATCH/TRANSFER
  → Transfer to Stage 2 PSAP or notify ERO directly
  → Provide: caller location, nature of emergency, number of victims, hazard status
  → Stay on line if caller requires pre-arrival guidance

STEP 5 — DOCUMENT
  → Complete CAD entry in real time
  → Note any eCall / AML / location data received
  → Log call disposition and handover time
```

### A.3 Difficult Caller Management

| Caller Type | Recommended Approach |
|-------------|----------------------|
| **Silent caller** | Speak slowly; ask to press a key if unable to speak; cross-check location via AML |
| **Aggressive / distressed** | Use de-escalation language; validate emotions before information gathering |
| **Non-native speaker** | Use available translation resource; speak slowly and plainly; avoid jargon |
| **Child caller** | Use simple, reassuring language; avoid technical terms; keep line open |
| **Repeated nuisance caller** | Document and follow SOP; never abandon if doubt about genuine need exists |
| **Caller going silent (medical)** | Assume worst case; dispatch immediately; continue coaching if possible |

### A.4 Pre-Arrival Instruction Protocol

When dispatching is delayed or caller can assist:

1. Confirm scene safety for caller
2. Provide CPR coaching if cardiac arrest suspected (follow ERC guidelines)
3. Guide haemorrhage control (compression, tourniquet if available)
4. Position unconscious breathing victim in PLS (Position Latérale de Sécurité)
5. Maintain caller contact until unit arrival confirmed

---

## Module B — French PSE1/PSC1 Programme Integration

### B.1 Overview of the French Operational First-Aid Pathway

Under the **Arrêté du 15 juin 2024**, France maintains a structured vocational first-aid training pathway for civil security actors (*filière opérationnelle des premiers secours*):

```
PSC1 (7h) → PSE1 (35h) → PSE2 (28h additional) → Formateur PAE
```

| Qualification | Duration | Target Audience | Competence Level |
|---------------|----------|-----------------|-----------------|
| **PSC1** (Prévention & Secours Civiques niv. 1) | ~7 hours | General public, 10+ years | Basic first aid: CPR, AED, PLS, bleeding control |
| **PSE1** (Premiers Secours en Équipe niv. 1) | 35 hours | Security/rescue volunteers, lifeguards | Team-based intervention, assessment, defibrillation |
| **PSE2** (Premiers Secours en Équipe niv. 2) | 28 hours (+ PSE1) | Équipiers secouristes, firefighter volunteers, ambulance crew | Advanced teamwork, complex emergencies, trauma management |

### B.2 PSE1 Core Modules (Relevant to PSAP Context)

The PSE1 curriculum covers content directly relevant to what call-takers coach callers through:

| Module | Duration | Key Content |
|--------|----------|-------------|
| 0 — Introduction | 0.5h | Role of the secouriste in the rescue chain; SAMU/SDIS interconnection |
| 1 — Protection & Safety | 1h | Scene security, individual protective equipment, hazard identification |
| 2 — Alert | 0.5h | Alerting the SAMU (15), SDIS (18), 112; transmission of bilan |
| 3 — Bilan (Assessment) | 2.5h | Circumstantial, vital-signs, complementary assessment; transmission protocol |
| 4 — Vital Emergencies | 17h | Airway obstruction, haemorrhage, cardiac arrest (CPR/AED), respiratory/circulatory distress |
| 5 — Medical Conditions | 1.5h | Hypoglycaemia, illness exacerbation |
| 6 — Specific Conditions | 1.5h | Fever, neurological events |
| 7 — Trauma | 7h | Burns (thermal/chemical/electrical), wounds, head/spine/limb trauma |
| 8 — Moving Victims | 1.5h | Relevage, brancardage, mobility assistance |

> **Note for PSAP trainers:** PSE1 module content defines the exact language and procedures that rescue team members will use when reporting back to PSAP via radio. Call-takers should understand PSE bilan terminology to correctly log incoming team reports and relay them to medical regulators.

### B.3 Bilan Transmission Protocol (PSE Standard)

Rescue teams report to PSAP/SAMU using a structured bilan format:

```
BILAN CIRCONSTANCIEL
  → Nature and mechanism of incident
  → Hazards identified / secured
  → Number of victims

BILAN D'URGENCE VITALE
  → Airway patent? (oui/non)
  → Breathing? Rate / quality
  → Circulation? Pulse / haemorrhage
  → Consciousness? (AVPU scale or Glasgow)

BILAN COMPLÉMENTAIRE
  → History (SAMPLE: Signes, Antécédents, Médicaments, Passé, Lieu/Last meal, Événement)
  → Vital parameters: SpO2, glycaemia, temperature, pain score

TRANSMISSION
  → Call 15 or notify PSAP dispatcher
  → State: who you are, where you are, what you found, what you've done, what you need
```

### B.4 Rescue Chain Integration — French Context

Numbers 15 and 18 are **interconnected** in France. A SAMU medical regulator (15) and the SDIS CODIS (18) operate in parallel and coordinate via dedicated inter-services communication. Call-takers must understand:

- When to involve the **médecin régulateur** (SAMU 15) vs direct dispatch (SDIS 18)
- The **SMUR** (Service Mobile d'Urgence et de Réanimation) is dispatched by SAMU for life-threatening calls requiring physician-level pre-hospital care
- The **CUMP** (Cellule d'Urgence Médico-Psychologique) is activated by SAMU for mass-casualty events involving psychological trauma

---

## Module C — eCall Processing

### C.1 What is eCall?

eCall is a mandatory EU-wide in-vehicle emergency system. Since **31 March 2018**, all new M1 (passenger cars) and N1 (light vans) sold in the EU must be equipped with a 112-eCall system.

When a serious crash is detected by the vehicle's sensors (e.g. airbag deployment), or when a driver manually presses the SOS button:

1. The vehicle automatically dials **112**
2. The call is given **network priority** and routed to the appropriate PSAP
3. A **Minimum Set of Data (MSD)** is transmitted to the PSAP in-band
4. Audio systems reconnect and the call-taker speaks directly with occupants

### C.2 Minimum Set of Data (MSD) Contents

The MSD transmitted to the PSAP call-taker's screen includes:

| Data Field | Description |
|-----------|-------------|
| **Trigger type** | Automatic (crash-detected) or Manual (button press) |
| **Vehicle ID** | Vehicle Identification Number (VIN) |
| **Location (primary)** | GPS coordinates at moment of incident |
| **Location (secondary)** | EN 15722:2020 — two most recent positions before crash |
| **Direction of travel** | Heading in degrees |
| **Timestamp** | Time of incident |
| **Number of seat belts fastened** | Estimate of occupant count |
| **Fuel type** | Petrol, diesel, electric, hydrogen (relevant to rescue approach) |

### C.3 Call-Taker eCall Processing Protocol

```
ON RECEIVING AN eCALL:
  1. Screen alert identifies call as eCall (automatic or manual flag displayed)
  2. Read MSD data immediately — note location, trigger type, direction
  3. Attempt voice contact: "Ici le PSAP 112, pouvez-vous m'entendre ?"
  4. If no voice response — treat as life-threatening; dispatch immediately to GPS coords
  5. If voice contact established — conduct standard injury/hazard assessment
  6. If callback needed — use CLI (Calling Line Identification) from call record
  7. For TPS eCall (third-party, e.g. manufacturer brand) — call may arrive forwarded
     from TPSP with vehicle data already attached; handle as standard eCall
  8. Log: MSD fields, voice contact outcome, dispatch decision, time to dispatch
```

### C.4 Next-Generation eCall (NG-eCall) — 2026 Transition

PSAPs must upgrade by **1 January 2026** (per Delegated Regulation 2024/1084) to handle NG-eCall over IMS packet-switched networks (4G/5G). Key changes:

- MSD transmitted in SIP INVITE (not in-band audio modem)
- Supports multimedia: voice, video, real-time text
- Richer data set possible (crash severity, more location history)
- PSAP requires **MSD reader** to decode ASN.1 PER-encoded data
- Standards referenced: EN16072:2022, EN16062:2023, EN15722:2020, EN16454:2023

> **Training implication:** Call-takers handling NG-eCall need to understand the new data fields displayed on their screen and recognise that vehicle data arrives before or simultaneously with call audio.

### C.5 eCall Statistics & Context (EU 2023)

- **658,392** eCalls placed across 27 EU Member States in 2023
- **56% increase** vs 2021 (421,000 eCalls)
- As of Sept 2024, **25 Member States + Iceland + Norway** are AML-enabled
- Average PSAP answering time: **≤10 seconds** in 22 Member States

---

## Module D — Ergonomics & Wellbeing

### D.1 Workstation Setup — Standard Guidelines

EENA guidelines explicitly require ergonomics training for call-takers, citing **Occupational Overuse Syndrome (OOS)** as a key risk factor from repetitive movements and awkward postures.

#### Monitor

- Top of screen at or just below eye level
- Distance: approximately 50–70 cm from eyes
- Tilt: slight backward tilt (10–15°) to reduce glare
- Multi-monitor setups: primary screen centred; secondary at same height and angle

#### Chair

- Seat height: feet flat on floor, knees at 90°
- Seat depth: 2–3 finger widths between seat edge and back of knees
- Lumbar support: fitted to natural lower-back curve
- Armrests: elbows at 90° when typing

#### Sit-Stand Console (recommended for PSAP environments)

- Alternate sitting and standing: optimal ratio 2:1 (sit:stand) or 1:1
- Use anti-fatigue mat when standing
- Save height presets for each operator (especially in multi-shift settings)

#### Audio / Headset

- Headset volume: must not exceed 85 dB(A) over an 8-hour shift (EU Directive 2003/10/EC)
- Headsets should be monaural or dual-ear with ambient sound filter
- Acoustic shock protection mandatory (recommended: IEC 62368-1 compliant devices)

### D.2 Environmental Standards for PSAP Control Rooms

| Parameter | Recommended Standard |
|-----------|---------------------|
| Lighting | 300–500 lux (avoid glare on screens) |
| Temperature | 20–22°C |
| Noise (ambient) | <45 dB(A) where possible |
| Air quality | Adequate ventilation; CO2 <800 ppm |
| Break zones | Quiet room / decompression space on-site |

### D.3 Shift and Roster Considerations

- Avoid consecutive 12-hour night shifts without recovery days
- Build mandatory break periods into shift structure
- Staffing levels must account for training time for new and existing staff
- Consider a separate **training shift** or "shadow" role for new recruits

---

## Module E — Mass Emergency & Multi-Victim Procedures

### E.1 Overview

PSAPs must be prepared for sudden surges of calls related to mass casualty incidents (MCIs). EENA recommends joint training exercises between PSAP call-takers and rescue service staff for this scenario.

### E.2 French ORSEC & SAMU Coordination

In France, major emergency coordination follows the **plan ORSEC** (Organisation de la Réponse de SEcurité Civile):

| Plan | Trigger | Coordinator |
|------|---------|-------------|
| ORSEC | Major emergency (flooding, MCI, industrial accident) | Préfet |
| Plan BLANC | Hospital saturation / mass casualty | Hôpital / ARS |
| Plan ROUGE | Major accident with mass victims | SAMU + SDIS |
| Plan NOVAE | NRBC (nuclear, radiological, biological, chemical) | SAMU + spécialistes |
| Plan ORSAN | Health emergencies (pandemic, epidemic) | ARS |

**PSAP call-takers during a declared ORSEC event:**
1. Flag all relevant calls with a special incident code in CAD
2. Do not transfer each caller individually — use mass-call triage protocol
3. Relay real-time data to incident commander / CODIS
4. Activate additional call-taker stations per continuity of operations (COOP) plan

### E.3 CUMP Activation

The **Cellule d'Urgence Médico-Psychologique (CUMP)** is France's national psycho-medical response unit for mass-trauma events. It is:

- Activated exclusively at the initiative of the **SAMU (15)**
- Not designed for long-term follow-up — refers onward to specialist practitioners
- Composed of psychiatrists, psychologists, and trained volunteers

PSAP call-takers may be asked to:
- Identify callers with acute psychological distress for CUMP referral
- Log the psychological profile of victims alongside physical injury data
- Provide post-incident debriefing access for their own team

---

## Module F — Stress Management & Psychological Support

### F.1 Occupational Stress Factors (EENA)

EENA identifies the following as primary stress factors for PSAP call-takers:

- **Role tension**: acting immediately vs. not overstepping dispatch authority
- **Inadequate resources**: understaffing, outdated equipment
- **Secondary traumatic stress**: emotional contagion from distressing calls
- **Powerlessness**: inability to directly intervene; dependence on ERO units
- **Cumulative burden**: repeated exposure to trauma without structured debrief

### F.2 Institutional-Level Stress Mitigation

Organisations should embed stress management into human resources strategy:

1. **Annual educational needs analysis** — align training to operational pressures identified
2. **Peer support programmes** — trained peer counsellors available on shift
3. **Critical Incident Stress Management (CISM)** — mandatory debrief protocol after major incidents
4. **Employee Assistance Programme (EAP)** — confidential psychological support
5. **Quiet zones / safe spaces** — designated decompression areas within PSAP
6. **Mindfulness / relaxation training** — voluntary, built into induction programme
7. **Supervisor training** — to recognise stress indicators in staff before escalation

### F.3 Individual Coping Strategies

Call-takers should be introduced to the following evidence-supported techniques during training:

- **Muscle relaxation (PMR)** — progressive muscle relaxation during breaks
- **Cognitive reframing** — identifying unhelpful thought patterns post-incident
- **Controlled breathing** — box breathing (4-4-4-4) for immediate tension reduction
- **Structured debriefing** — structured conversation with supervisor after traumatic call (not informal venting)
- **Biofeedback** (where available) — real-time physiological awareness tools

> **Note:** Finland's PSAP training is university-level and integrates psychological resilience training throughout. This is considered a best-practice model by EENA.

---

## Checklists

### ✅ Checklist A — Incoming Call Assessment

Use this structured triage checklist for every emergency call:

- [ ] Call answered within PSAP target time
- [ ] Caller name confirmed
- [ ] Callback number noted (CLI / stated by caller)
- [ ] Location confirmed (address, landmark, GPS coordinates if mobile)
- [ ] AML data cross-checked on screen
- [ ] Nature of emergency identified (medical / fire / police / other)
- [ ] Number of persons involved established
- [ ] Immediate hazards confirmed (traffic, fire, gas, aggressor, etc.)
- [ ] Urgency level assessed (life-threatening vs. urgent vs. non-urgent)
- [ ] Appropriate ERO selected and dispatch initiated
- [ ] Pre-arrival instructions provided (if appropriate and trained to do so)
- [ ] Call documented in CAD system in real time
- [ ] Handover to Stage 2 PSAP completed with full data

---

### ✅ Checklist B — eCall Processing

- [ ] Call flagged as eCall (automatic or manual trigger) on screen
- [ ] MSD data reviewed: location (primary + secondary), VIN, direction, trigger type
- [ ] Fuel/propulsion type noted (relevant to fire risk: EV, hydrogen, etc.)
- [ ] Voice contact attempted
- [ ] If no voice response: dispatch immediately to MSD coordinates
- [ ] If voice response: conduct standard injury/hazard questions
- [ ] Occupant count estimated from seatbelt data + voice confirmation
- [ ] Callback via CLI if call drops
- [ ] TPS eCall origin verified (manufacturer relay or direct 112)
- [ ] All MSD fields logged in CAD
- [ ] GIS / mapping system used to confirm route for ERO

---

### ✅ Checklist C — Shift Start / Operator Readiness

- [ ] Workstation adjusted to personal ergonomic settings
- [ ] Headset tested (volume, clarity, acoustic protection active)
- [ ] CAD system logged in and responsive
- [ ] eCall MSD display system operational
- [ ] AML/location data feed confirmed active
- [ ] Relevant SOPs accessible (on screen or physical binder)
- [ ] Supervisor/duty manager contact confirmed
- [ ] Fatigue self-assessment: if impaired, notify supervisor before going live
- [ ] Emergency fallback procedures reviewed (system outage protocol)

---

### ✅ Checklist D — Post-Incident / End-of-Shift

- [ ] All active calls formally closed or handed over
- [ ] CAD entries complete and accurate
- [ ] Any anomalous calls (nuisance, aggression, traumatic content) flagged to supervisor
- [ ] Request debrief if handling a significant incident
- [ ] Complete any mandatory post-incident documentation
- [ ] Physical workspace returned to neutral (headset, chair, monitor)
- [ ] Access peer support or EAP if needed

---

## Best Practices Table

| Domain | Best Practice | Source / Evidence |
|--------|---------------|-------------------|
| **Training standardisation** | Every PSAP should maintain a formal training manual, accessible digitally | EENA Training of Call Takers |
| **Training methodology** | Combine theoretical instruction, simulation, role-play, and peer-supported on-job guidance | EENA / Catalonia 112 PSAP model |
| **Continuous education** | Annual refresher linked to needs analysis; financial or professional incentives recommended | EENA Psychological Support Guidelines |
| **Simulation tools** | Use technology-based simulators for scenario training (eCall simulators, mass-casualty scenarios) | EENA NG-eCall guidance |
| **Call triage** | Use structured open-ended questioning before yes/no questions | PSAP SOP best practice |
| **AML / location** | Always cross-reference verbal location with AML screen data | EU 112 Report 2024 |
| **eCall dispatch** | Treat silent eCall (automatic trigger, no voice) as a life-threatening emergency and dispatch immediately | EENA / CEN EN16072 |
| **NG-eCall readiness** | Upgrade MSD reader and IMS infrastructure before 1 Jan 2026 deadline | EU Delegated Reg. 2024/1084 |
| **Ergonomics** | Train call-takers to identify occupational overuse risk factors; provide sit-stand consoles | EENA / EU-OSHA |
| **Acoustic protection** | Mandate headsets compliant with acoustic shock standards; enforce 85 dB(A) daily limit | EU Directive 2003/10/EC |
| **Psychological support** | Embed CISM programme; do not rely on informal debriefing | EENA / WHO occupational health |
| **Mass casualty** | Conduct joint exercises between PSAP and EROs at least annually | EENA / ORSEC framework |
| **French chain integration** | Ensure call-takers understand PSE bilan terminology for team radio transmissions | PSE1 référentiel / SAMU 15 protocol |
| **Inclusive access** | Ensure PSAP handles 114 (deaf/HoH) and RTT (Real Time Text) by June 2025 (EAA requirement) | EU Accessibility Act / EU 112 Report |
| **Quality assurance** | Implement a formal QA/QI programme with regular call audits | EENA / NENA QA best practice |

---

## Glossary

| Term | Definition |
|------|-----------|
| **AML** | Advanced Mobile Location — handset-derived GPS data sent automatically to PSAP |
| **bilan** | French term for structured patient/scene assessment report |
| **CAD** | Computer-Aided Dispatch — software system for logging and managing emergency calls |
| **CODIS** | Centre Opérationnel Départemental d'Incendie et de Secours — SDIS dispatch control |
| **CUMP** | Cellule d'Urgence Médico-Psychologique — French psycho-medical crisis unit |
| **ERO** | Emergency Response Organisation — the service that physically responds (police, fire, EMS) |
| **eCall** | In-vehicle system that automatically dials 112 in a serious crash and sends MSD |
| **EENA** | European Emergency Number Association — EU PSAP standards and advocacy body |
| **GIS** | Geographic Information System — mapping software used to visualise incident locations |
| **IMS** | IP Multimedia Subsystem — the packet-switched network technology underpinning NG-eCall |
| **MSD** | Minimum Set of Data — vehicle and incident data transmitted during an eCall |
| **NG-eCall** | Next-Generation eCall — IMS/4G/5G-based version of eCall (mandatory PSAP support by Jan 2026) |
| **ORSEC** | Organisation de la Réponse de SEcurité Civile — French major emergency coordination framework |
| **PSAP** | Public Safety Answering Point — the emergency call-taking centre |
| **PSC1** | Prévention et Secours Civiques niv. 1 — French public basic first-aid certificate (~7h) |
| **PSE1** | Premiers Secours en Équipe niv. 1 — French team first-aid certificate for rescue volunteers (35h) |
| **PSE2** | Premiers Secours en Équipe niv. 2 — Advanced team first-aid certificate (28h post-PSE1) |
| **SAMU** | Service d'Aide Médicale Urgente — French emergency medical regulation service (15) |
| **SDIS** | Service Départemental d'Incendie et de Secours — French departmental fire and rescue service |
| **SMUR** | Service Mobile d'Urgence et de Réanimation — mobile physician-led pre-hospital care team |
| **TPS eCall** | Third Party Service Provider eCall — manufacturer/brand relay service, optional alongside 112-eCall |
| **VIN** | Vehicle Identification Number — unique vehicle identifier transmitted in eCall MSD |

---

*This guide was compiled from publicly available EENA operational documents, EU Regulations (305/2013, 2024/1084, 2024/1180), French official texts (Légifrance, PSE1 référentiel national), Croix-Rouge française and Protection Civile PSE training materials, and EU Commission 112 implementation reports.*

*For updates, consult: [eena.org](https://eena.org) | [legifrance.gouv.fr](https://www.legifrance.gouv.fr) | [transport.ec.europa.eu](https://transport.ec.europa.eu)*
