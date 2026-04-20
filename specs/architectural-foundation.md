# GeoSaveMe — Architectural Foundations

> **Status** Approved — foundational  
> **Version** 1.0  
> **Date** April 2026  
> **Supersedes** Architectural principles previously embedded in `specs/functional-specification.md` §1.3 and `specs/technical-specification.md` §0  
> **Relationship to other documents** This document is the reference frame within which `technical-architecture.md`, `technical-specification.md`, and `functional-specification.md` are written. Those documents specify *how* the system is built; this document specifies *what kind of system it is* and *why that shape was chosen*.

---

## Table of Contents

1. [Purpose and Scope](#1-purpose-and-scope)
2. [The Communication Channel Principle](#2-the-communication-channel-principle)
3. [Agent Autonomy and Event-Driven Lifecycle](#3-agent-autonomy-and-event-driven-lifecycle)
4. [Event Sourcing with Server-Side Projection](#4-event-sourcing-with-server-side-projection)
5. [Cells as the Primary Addressing Layer](#5-cells-as-the-primary-addressing-layer)
6. [The Three Kinds of Things in the System](#6-the-three-kinds-of-things-in-the-system)
7. [Human Agency and Correlation as Event](#7-human-agency-and-correlation-as-event)
8. [Affordance Parity](#8-affordance-parity)
9. [Victim Spine and Witness Branches](#9-victim-spine-and-witness-branches)
10. [What the System Never Does](#10-what-the-system-never-does)
11. [Relationship to the Phase Ahead](#11-relationship-to-the-phase-ahead)

---

## 1. Purpose and Scope

This document records the foundational principles on which GeoSaveMe is built. It is short by design. Each principle is stated, explained, and situated against the alternatives that were considered and rejected.

The principles here are not implementation guidance. They do not describe endpoints, data schemas, or screen flows. They describe the *shape* of the system — the assumptions the architecture rests on, the boundaries it enforces, the values it makes operational. Implementation documents rest on this document; they do not contradict it.

This document changes rarely. A change here implies a fundamental reconsideration of what GeoSaveMe is. Changes to implementation documents — the functional specification, the technical architecture, the technical specification — are expected and frequent, but they operate within the frame this document defines.

**Reading order across the document set:**

1. `architectural-foundations.md` (this document) — what the system is
2. `functional-specification.md` — what the system does
3. `technical-architecture.md` — why the system is built the way it is
4. `technical-specification.md` — how to build it

A reader encountering the system for the first time should read this document in full before opening any other document in the set.

---

## 2. The Communication Channel Principle

**GeoSaveMe is a communication channel for human agents on the ground. It is not an interpretive system.**

This is the root principle from which most others follow. The system exists to enable humans to signal, be heard, respond, and coordinate. It does not exist to decide what is happening, to adjudicate between conflicting reports, or to infer meaning beyond what the humans involved have expressed.

**Ground truth lives with humans.** The system's job is to be a faithful conduit for what humans on the ground are saying, seeing, and doing. When a user emits an alert, the system registers that signal and makes it available to those who need to see it. It does not evaluate whether the situation "really" warrants the alert. That is the emitter's judgement, and the participants' judgement, and — when involved — the officials' judgement. The system records and transmits; it does not adjudicate.

**Interpretation is a human act, not a system act.** If two alerts are emitted near each other at nearly the same time, the system does not decide whether they describe the same incident. It presents both signals honestly and allows participants, on the ground, to correlate them if they have the context to do so. The correlation is itself a human signal that the system then records and transmits.

**Why this matters.** A safety system that interprets too much will, at some point, interpret wrongly. It will merge alerts that should have remained separate, or suppress signals it judges redundant, or impose a narrative that erases the actual experience of someone in danger. The cost of that error, in this domain, is unacceptable. A system that is humble about its interpretive role — that surfaces signals faithfully and lets humans make meaning of them — is structurally safer, even at the cost of more visible noise.

**What the system does do.** It routes signals to the right people based on geography, role, and relationship. It preserves the history of every signal immutably. It offers participants opportunities to act — to correlate, to contextualise, to confirm. It applies well-defined server-side rules to lifecycle events (principally, when a situation is considered closed). These are mechanical functions, not interpretive ones.

The distinction may seem subtle, but it governs every subsequent decision. Whenever a design choice would have the system infer, merge, suppress, or interpret on behalf of the humans involved, the principle above reminds us that the choice must be reframed: the system surfaces the signal and the option; the humans decide.

---

## 3. Agent Autonomy and Event-Driven Lifecycle

**Every mobile device is an autonomous agent. The central system is a rule engine over a stream of events.**

This principle governs the operational model of the platform — the direction of information flow, the responsibilities of each tier, and the resilience guarantees the system makes.

**Agents are autonomous.** Every mobile device participating in the GeoSaveMe network — whether emitter, follower, watcher, or official — maintains a local state snapshot of the situations it is associated with. This snapshot is sufficient to render a coherent user interface and support basic interactions without a network connection. An agent that loses connectivity degrades gracefully and re-synchronises from the server on reconnection. This is not a convenience feature; it is a safety requirement. A victim in a tunnel, a building basement, or an area of network congestion must not lose the functional state of their alert.

**All agent-to-server communications are events.** An event is a structured signal emitted by an agent that describes a change in the agent's assessment of or relationship to a situation. There is no semantic distinction between "opening" and "closing" from the agent's perspective. Both are events. A victim emitting `secure` is sending an event, not a command. What the server does with that event is governed by the rule engine.

**Two families of events.** Events fall into two clean families, which are kept distinct in the data model and in the API:

| Family | Emitted by | Examples |
|---|---|---|
| **Alert events** | Emitters and witnesses | `unsecure`, `danger`, `police`, `fire`, `secure` |
| **Participation events** | Followers, watchers, officials, first responders | `acknowledge`, `position_update`, `qualification`, `response_update`, `correlation`, `departure` |

Alert events carry a situation assessment. Participation events carry presence, position, or a participant action. The two families share a common envelope but are processed independently by the server.

**The central system is a rule engine.** The server receives events, applies configurable rules, and publishes state updates. It does not push instructions to agents. It does not issue commands. It publishes projected state; agents subscribe and update their local snapshot if the incoming version is newer than their own.

**Rules evolve; agents do not need to change.** Because the rule engine lives entirely on the server, rules can be refined over time without any client update. The MVP starts with a minimal rule set — principally, that a `secure` alert event from the original emitter signals the end of a situation. Later phases will layer additional rules (official qualification, participant quorum, inactivity timeouts) without requiring mobile clients to change.

**Offline tolerance is a first-class property.** The architecture must never assume an agent is online. An emitter who loses signal must still see a coherent UI for their own alert. A follower who was notified before losing signal must still be able to reach the hotspot location from their local cache. When connectivity returns, the agent re-synchronises and applies any state updates newer than its local snapshot.

---

## 4. Event Sourcing with Server-Side Projection

**The event stream is the canonical, immutable ground truth. The server maintains a derived projection for fast queries. Interpretive logic lives on the server.**

This is the data architecture of the system, stated as a principle rather than a pattern.

**The event stream is immutable and canonical.** Every alert, every participation, every contextualisation, every correlation is an event, appended to the log, never modified, never deleted. The event stream is the system's memory. If all derived state were lost, the system could be reconstructed entirely from the event stream. Nothing else has that property.

**The server maintains a projection.** A projection is a materialised view derived from the event stream, optimised for fast query. It answers questions like "what situations are currently active in this district?" or "what is the current participant count for this situation?" without replaying the event stream from scratch on every query. The projection is a cache; it is derivative, not authoritative. If it is lost, it can be rebuilt by replaying events.

**Interpretive logic lives on the server.** Rules that transform events into projected state — closure rules, participant counting, visibility rules, correlation surfacing — live in the server's rule engine, not in mobile clients. Mobile clients consume projections; they do not re-run interpretation. This keeps all interpretive logic in one place, versioned and testable, and prevents two clients on different versions from reaching different conclusions about the same event stream.

**Clients render projections for speed; they can access the event stream for depth.** In ordinary use, an agent reads the server's projection and renders a fast, coherent UI from it. When an agent needs historical context — to reconstruct the evolution of a situation, to audit a sequence of events, to render a full timeline — it can query the event stream directly for the relevant cells and time window.

**The "situation" is a projection concept, not a stored entity.** What appears in the UI as a current situation — the grouping of alerts and participations that a user sees on the map — is a view computed by the server from the event stream, published to clients, and rendered locally. It is not a stored object that is created, mutated, and destroyed. It is the server's current best rendering of "what is happening here, now." When the situation is considered closed by the rule engine, the projection reflects that; the underlying events remain untouched.

**Why this model.**

| Property | Consequence |
|---|---|
| **Immutability** | Perfect auditability. Nothing is overwritten. The system's memory is trustworthy. |
| **Canonical stream, derived projection** | Projection bugs are recoverable. Projection can be rebuilt at any time from the events. |
| **Server-side interpretation** | One place for logic. No client drift. Rules evolve without client updates. |
| **Client reads projection** | Fast rendering. No replay on every query. UI is responsive. |
| **Client can reach the event stream** | Deep context available when needed. Historical reconstruction is possible. |

**What this is not.** This is not pure event sourcing on the client. Clients do not replay event streams to render their UI in ordinary use. Pure client-side event sourcing would fragment interpretation across versions and devices, and is operationally fragile. The projection sits between the event stream and the client for good reason: it is where interpretation is canonical, performant, and consistent.

---

## 5. Cells as the Primary Addressing Layer

**Cells are the unit of addressing for both events and members. The territory is a grid of cells, and everything that happens in the system happens in a cell.**

GeoSaveMe uses a discrete global grid system — specifically, H3, Uber's open-source hexagonal grid — as its primary spatial addressing layer. This is a foundational architectural choice, not an implementation detail.

**What cells are.** A cell is a hexagonal region of the Earth's surface with a stable, globally unique identifier. The grid is hierarchical: every cell at a given resolution has a parent cell at a coarser resolution and children at finer resolutions. The identifier is a 64-bit integer, cheap to store and index, and the same cell has the same identifier forever — across markets, across time, across deployments.

**Cells address events.** Every alert, every participation, every position update resolves to a cell. The lat/lng coordinates are preserved for precision, but the cell is the addressing unit. Queries are expressed in terms of cells: "what events happened in this cell in this time window?", "which cells are adjacent to this one?", "which member cells fall within the reach of this alert?".

**Cells address members.** An agent's last known cold position resolves to a cell; the agent is a sleeping member of that cell. When a cell is activated by an alert, its sleeping members — and the sleeping members of neighbouring cells, per the broadcast policy — are woken. Matching becomes a set-membership query on an indexed integer column, not a spatial computation.

**Cells accumulate metadata progressively.** A cell at first is nearly empty — just its identifier and its administrative parent. Over time, cells accumulate: historical event counts, known POI overlays, enriched context from OSM or other sources, local conventions. Most cells in a new market will remain nearly empty; some — stadiums, stations, venues — will be enriched manually; others will accumulate through activity. The system must work correctly with empty cells and benefit from enriched ones, without requiring enrichment.

**POIs are a semantic overlay on cells.** A Point of Interest — a stadium, a station, a venue — is a named reference that overlays one or more cells. POIs ease human communication (a dispatcher understands "Gare du Nord concourse" more readily than a cell identifier) but carry no operational authority. A cell behaves the same whether or not it has a POI overlay. POI data is optional, progressively enrichable, and sourced per market.

**Administrative parent chains are a structural overlay on cells.** Each cell has a parent chain — commune, département, région, or the market's equivalent — which determines statistical reporting frames and force district assignment. Administrative data is ingested per market from open data sources (OSM, national open data providers) and is stable once ingested.

**Resolution is a parameter, not a given.** The MVP ships with a fixed uniform resolution across the grid. The choice of resolution balances granularity against data volume: finer resolutions give sharper localisation but produce more cells, more sparse data, and more complex queries. Resolution choice can be revisited in later phases. Because H3 is hierarchical, historical data at one resolution re-aggregates cleanly to coarser resolutions; finer resolutions subdivide cleanly from coarser ones.

**Broadcast reach is adapted, not cell size.** An early deployment in a sparse market must still feel alive to early adopters. This is achieved not by making cells larger, but by widening the broadcast ring — the number of neighbour rings around an alerting cell that receive the notification — when network density is low. Cells stay uniform; reach adapts to density. This is a query-time parameter, simpler operationally than adaptive cells, and it preserves the cleanness of the grid.

**Why H3 specifically.** Hexagons tile the plane with a property squares do not share: every neighbour is the same distance away. This matters for proximity work and for propagation tracking. H3 is open source, has mature bindings in every serious language, has been operationally proven at large scale by Uber and others, and is free to use without licensing constraints. A custom grid would be a worse H3.

---

## 6. The Three Kinds of Things in the System

**Events, projections, and views. Each has a different lifetime, a different owner, and a different role.**

Clarity about these three concepts is essential. Confusing them is the most common architectural error in systems of this type.

### 6.1 Events

Events are immutable records of things that happened. They are written once, appended to the log, and never modified. The event log is the system's ground truth — the authoritative record of what agents on the ground signalled.

Events are attached to cells. A cell is the event's address. A cell's event log is the full history of everything that happened in that cell, in chronological order.

Events come in the two families established in §3: alert events and participation events. The content of an event is whatever the emitting agent signalled — a situation assessment, a position, a context, a correlation, a departure. The event does not carry interpretation; it carries what was said, by whom, when, where.

### 6.2 Projections

Projections are server-side materialised views derived from events. A projection answers a question — "what is currently active in this district?", "who are the participants in this situation?", "what is the stress level of this situation?" — by maintaining a current, queryable state that reflects the event stream up to the most recent event applied.

Projections are not authoritative. They are derived. They can be rebuilt at any time by replaying events. They exist for performance: reading a projection is fast; replaying events is slower.

Projections are where interpretation lives. The rule that "a `secure` event from the emitter closes the situation" is applied by the projection engine: when it consumes that event, it updates the projected situation's status. The rule is in the projection engine; the event is unchanged in the log.

The projection layer is where "the current situation" exists as a coherent object. In the projection, there is a situation with a status, a cell set, a participant count, a stress level, a version timestamp. In the event log, there are just events. The situation is constructed by interpretation.

### 6.3 Views

Views are what a client renders. A view is shaped by the role of the user, the actions available to them, and the context of their current activity. Different users see different views of the same underlying projection; the same user sees different views at different moments.

Views are computed on the client from the projection data the server delivers. The server may filter or tailor its delivery per role (a bystander's projection is leaner than a dispatcher's), but the final rendering is a client concern.

A view is not a source of truth about anything. It is a presentation of data. It disappears when the screen closes and is recomputed when the screen opens.

### 6.4 Summary

| Concept | Lifetime | Owner | Role |
|---|---|---|---|
| **Event** | Immutable, permanent | Server (log) | Ground truth of what was signalled |
| **Projection** | Derived, rebuildable | Server (rule engine) | Fast queryable interpretation of the event stream |
| **View** | Transient | Client | Role-appropriate rendering for the user |

**The rule of thumb.** If you are tempted to mutate something, you are probably thinking about a projection. If you are tempted to delete something, you are probably thinking about a view. Events are never mutated or deleted; the event log only grows.

---

## 7. Human Agency and Correlation as Event

**Correlation between alerts is a human act, recorded as an event. The system surfaces correlation opportunities; it does not perform correlation automatically.**

This principle operationalises the communication channel principle (§2) in the specific case of alerts that appear to describe the same incident.

**The problem.** Two alerts fire close together in space and time. Perhaps they describe the same incident; perhaps they describe two separate incidents happening near each other. The system has no reliable way to tell the difference — that judgement requires context only humans on the ground possess.

**The wrong answer.** Automatic merging. The system decides the alerts describe the same incident, combines them into a single record, and renders them as one. This suppresses signal. If the system is wrong, one of the alerts is effectively erased; the emitter is silenced; responders may miss a separate event. In a safety context, this cost is unacceptable.

**The right answer.** The alerts are preserved as two events, in two cells (or the same cell), with two distinct records. Both are visible to whoever receives them. A participant with ground-level context — a witness who can see both situations, a dispatcher who can compare call details — may identify that the alerts describe the same incident, and may signal that correlation. The correlation itself is a participation event, appended to the log, which the projection engine then honours when computing views.

**What the system does.** The system surfaces correlation candidates. When a participant opens an app view and sees two alerts close together, the UI may render them as grouped-but-distinct ("two alerts, here"), may offer an action ("are these the same incident?"), and may render the result of a correlation event when one is made ("witness A has indicated these are the same incident"). The underlying alert events remain distinct; the correlation sits as a layer over them.

**What the system never does.** It never merges alerts silently. It never suppresses one alert on the basis of another. It never decides correlation automatically. Correlation is always traceable to a specific human agent who made the call, at a specific time, with accountability for their judgement.

**Why this matters.** The pattern is general. Whenever the system is tempted to interpret across signals — to merge, to deduplicate, to infer a common cause — the principle is the same: surface the candidate to a human, record the human's judgement as an event, let the projection honour that judgement. This preserves the integrity of the event stream as a record of what humans actually signalled, and keeps the interpretive authority where it belongs.

---

## 8. Affordance Parity

**A user sees only information tied to an action they can take. What is rendered is what they can do something about.**

This is a design principle with architectural consequences.

**The principle.** Every element of information presented to a user corresponds to an action available to that user. A bystander sees a nearby alert because they can respond to it — flee, assist, call for help, acknowledge. A dispatcher sees detailed alert context because they can dispatch resources, correlate calls, broadcast messages. An official on scene sees phone numbers and stress levels because they can use them. The UI is not an information dashboard; it is an action surface.

**Why.** Three reasons. First, information without corresponding action is noise — it burdens the user without helping them. Second, in a safety context, noise is dangerous; it dilutes the signals that require attention. Third, limiting what a user sees to what they can act on is a natural, principled filter that prevents surveillance creep — the system cannot accidentally become a tool for watching others, because the view layer only renders what the role's actions warrant.

**Architectural consequence.** Role is not merely a display filter applied client-side. Role is a query parameter applied server-side when projections are delivered. The server computes what a bystander needs to see given their current context and delivers exactly that; it computes what a dispatcher needs and delivers that; it does not send a superset of data and let the client filter. This keeps sensitive details (precise emitter location, phone numbers, credibility scores) out of the hands of clients that have no action to take with them.

**Consequence for API design.** The API surface is shaped by the action surface. "What can each role do?" determines "what does the server need to expose?" This is why the personas phase precedes the rewrite of the technical architecture: without the list of actions per role, the API would be either oversized (exposing information no role can act on) or undersized (missing information some role needs).

**Consequence for client logic.** Clients are lean. They receive tailored projections and render them. They do not hold large unused datasets. This also aligns with the offline-tolerance property: what a client needs to function is small and role-appropriate, and can be cached locally without bloating device storage.

---

## 9. Victim Spine and Witness Branches

**A victim's presence in a situation is continuous; a witness's contribution is episodic. This asymmetry shapes the temporal structure of every situation the system handles.**

This principle distinguishes two fundamentally different kinds of agent contribution and clarifies what the system does with each.

**The victim.** A victim is the person the situation is happening to. Their relationship to the situation is continuous: they emit an opening alert, they remain the emitter throughout, their position updates track the situation's movement (at walking pace, the cells traverse naturally), and they eventually emit a `secure` event when the situation is resolved from their perspective. The victim's event stream is the spine of the situation — the chronological backbone against which everything else is attached.

**The witness.** A witness is a person who observed the situation from outside. Their contribution is episodic: they report what they saw, perhaps add context, perhaps confirm a classification, perhaps correlate alerts. Their contribution happens at specific moments and has fixed duration. They may remain as a participant (receiving updates about the situation) but they do not continue to generate the situation's narrative spine. A witness contribution is a branch attached to the spine at the time it was made.

**Consequence for situation closure.** If a situation has a victim — a spine — the primary closure signal is the victim's own `secure` event, evaluated by the rule engine alongside any other applicable rules. The spine ends when the victim signals it ends (subject to server rules that may extend or override closure in specific cases).

**Situations without a spine.** A situation with no victim — a witness-only situation, for example a reported fire in an empty street or a road accident observed by passers-by — has no continuous emitter. Its structure is a cluster of episodic contributions without a spine to anchor them. Closure rules for such situations must necessarily be different: inactivity timeouts, official qualification on scene, or participant quorum take the place of the absent victim's `secure` signal. The existence of these two structural shapes — with spine, without spine — is a first-class consideration for the rule engine, not an edge case.

**Consequence for temporal tracking.** Because the spine is continuous, the situation's cell set naturally evolves over time as the victim moves. A situation that began in one cell may traverse several cells during its lifetime. The projection engine tracks this movement not by inferring across multiple emitters but by following the single continuous stream of the victim's position updates. Witness branches remain anchored to the time and cell of their creation.

**Consequence for rendering.** When a client renders a situation, the spine is the temporal backbone of the view: the sequence of the victim's alert events and position updates, in order, over time. Witness branches appear as attached contributions at their points in time. Correlations appear as cross-links. The whole structure is a graph of events anchored on the victim's continuous presence — or, in a situation without a spine, a cluster without a backbone, rendered accordingly.

---

## 10. What the System Never Does

This section is deliberately explicit. It enumerates behaviours the system must never exhibit. These are non-goals that would be tempting to implement for user convenience or operator control, and that must be resisted because they would violate one or more of the principles above.

**The system never issues commands to agents.** It does not tell an agent to stop alerting, to change alert type, to go offline, or to alter its behaviour in any way. The server publishes projected state; agents subscribe and adapt their local snapshot. An emitter in a dangerous situation must never have their alert suppressed by a remote actor, whether that actor is an administrator, a rule, or another user. Endpoints that would accept an agent identifier as a target and modify the agent's behaviour do not exist in the API.

**The system never merges alerts automatically.** Two alerts that appear to describe the same incident are preserved as two events unless a human agent — a witness, a participant, an official — signals a correlation. Correlation is always traceable to a specific human decision, recorded as a participation event with accountability.

**The system never suppresses alerts based on credibility or rate.** Credibility scores and rate heuristics may influence how alerts are surfaced — they may be filtered for certain roles, de-emphasised in certain views — but the underlying event is always recorded, always transmitted to those whose role entitles them to see it, and always preserved in the event log. The filtering is a delivery-layer concern, not a data-layer concern.

**The system never mutates events.** Events in the log are immutable. Corrections, updates, and refinements are new events appended to the log, not modifications of existing events. If an emitter amends a context, the amendment is a new event; the original context event remains.

**The system never sends user-facing strings on behalf of agents.** Server-to-client messages carry codes, identifiers, and data. String rendering happens on the client, from locale files. This keeps user-facing content under the client's control and makes internationalisation a client concern.

**The system never assumes an agent is online.** Every interaction is designed with offline tolerance in mind. Agents cache their state locally, function from cache during disconnection, and re-synchronise on reconnection. No flow requires continuous connectivity.

**The system never renders information a user cannot act on.** The affordance parity principle (§8) is enforced: what a user sees corresponds to actions available in their role. Surveillance-style views — rich information about others with no associated actions — are not built.

**The system never stores personal profiles of anonymous users.** Anonymous users are identified by a hashed device identifier. No account, no profile, no behavioural history. Cold location history is not persisted — only the last known position per device is retained, overwritten on update. The event log retains the fact that an anonymous identifier emitted an event at a time and place; it retains nothing else about that identifier.

**The system never relies on a map provider as a source of truth.** Map providers (Google Maps, Mapbox, OSM tiles, IGN) render visuals but do not provide authoritative territorial data. The authoritative territory is the cell grid (H3), augmented by administrative overlays and POI overlays ingested from open data sources per market. Map providers are replaceable at the rendering layer without any data-model consequence.

---

## 11. Relationship to the Phase Ahead

This document completes the architectural foundation of GeoSaveMe. The next phase of work — the personas phase — builds on these foundations.

**What the personas phase produces.** The personas phase articulates, for each user role, the specific actions available to that role in each context the system supports. Its output is a structured enumeration: for a bystander, the actions are X, Y, Z; for a dispatcher, A, B, C, D; for a victim actively emitting, P, Q, R; for a victim in cool-down after `secure`, S, T. Each action corresponds to an event type the client can emit or a projection the server can deliver. The personas phase is the bridge between the foundations here and the technical architecture that follows.

**Why personas precede the technical architecture rewrite.** Affordance parity (§8) makes the action surface the shape of the API surface. Without the action list, the API would be speculative. The technical architecture document is rewritten after the personas phase, once the action surface is concrete and the projections each role requires are specified.

**Why this document precedes the personas phase.** The foundations here frame the personas work. When the personas phase considers "what can a witness do with two alerts that look related?", the answer is bounded by the human agency and correlation principle (§7) — the witness signals correlation; the system records the signal; alerts are not merged. When the personas phase considers "what does a bystander see?", the answer is bounded by affordance parity (§8) — whatever they can act on, and no more. The foundations give the personas phase its frame; the personas phase gives the technical architecture its content.

**Documents that will be written or revised after personas.**

| Document | Status after personas phase |
|---|---|
| `architectural-foundations.md` | Stable — revisited only if a principle proves unworkable |
| `functional-specification.md` | Rewritten substantially, incorporating the personas action surface |
| `technical-architecture.md` | Rewritten from scratch, resting on these foundations |
| `technical-specification.md` | Rewritten in parallel with the technical architecture |

**Open questions deliberately carried forward.** Several architectural questions are not resolved here and are deliberately deferred. They are listed below so they are not forgotten.

| Question | Phase for resolution |
|---|---|
| Cell resolution for the MVP grid | Technical architecture rewrite |
| Default broadcast reach (neighbour ring policy) per alert type | Technical architecture rewrite, informed by personas |
| Adaptive broadcast reach by network density | Phase 2 — when real density data is available |
| Projection storage technology (relational, key-value, specialised) | Technical architecture rewrite |
| POI data sources per market | Market entry checklist, per market |
| Administrative boundary ingestion per market | Market entry checklist, per market |
| Closure rules beyond victim `secure` | Phase 2 onwards, rule engine evolution |
| Situation shapes without a victim spine | Technical architecture rewrite |

**A note on re-reading.** Foundations documents are where architectural mistakes get baked in. The document should be re-read with fresh eyes at least once — ideally a day or more after it was written — and challenged. If a principle does not hold up under a second reading, now is the time to revise it. Once the personas phase builds on these foundations, and the technical documents rest on them, revisions become much more expensive.

---

*End of document.*
