# DNHacks 2026 Plan

> **For Hermes:** Use subagent-driven-development once the shared contracts below are stable.

**Goal:** Build a believable spatial AI demo that turns observations of a home into typed SiteGraph state, deterministic EVSE feasibility calculations, and a concise installer handoff.

**Architecture:** Keep the root Next.js app as the live demo shell for now, while moving canonical types into `packages/schemas` and fixture data into `packages/fixtures`. The backend lane will own typed state ingestion, engineering tools, and cost scenarios; the iOS lane will own capture, anchors, OCR, and the native guided flow. Shared state crosses boundaries only through validated schemas.

**Tech Stack:** Next.js, TypeScript, React, Zod, Swift/SwiftUI, ARKit/LiDAR, Vision, OpenAI Agents SDK Realtime, A2UI, deterministic calculators, pnpm.

## Demo architecture

- **Spatial:** the iPhone owns ARKit/LiDAR anchors, raycasts, route measurements, and camera evidence.
- **Vision:** selected camera frames become proposed observations with evidence; they never become authoritative facts without validation and user confirmation where needed.
- **Intelligence:** `apps/server` owns the live OpenAI Agents SDK Realtime session, typed tool calls, and SiteGraph validation. The phone never contains a long-lived API key.
- **A2UI:** the agent streams only validated declarative surfaces from a small native component catalog (prompt, form, confirmation, result); the iPhone renders those with SwiftUI and returns user actions as typed events.

---

## Scope

### P0 — must work live
- Native iPhone guided assessment shell.
- One primary agent that can drive a stateful conversation.
- Proposed EVSE location captured as spatial state.
- At least one measurement or route estimate in typed state.
- Panel imagery captured and turned into at least one proposed observation.
- Canonical SiteGraph shared across app and backend boundaries.
- Visible status for observed, user-supplied, inferred, calculated, assumed, externally retrieved, and professionally verified values.
- Resumable structured form for vehicle and load information.
- Deterministic charger sizing, service/load screening, and scenario-based cost output.
- Preliminary assessment with pass / conditional / insufficient-data / professional-verification-required status.
- Installer handoff view.
- Fixture-backed fallback if live capture, OCR, voice, or network fails.

### P1 — highly desirable
- Better spatial visualization and route tracing.
- User confirmation / contradiction workflow for OCR.
- One source-backed demo-jurisdiction permit card.
- Load-managed option for constrained service.
- Persist and reopen an assessment.
- Exportable report artifact.
- Compact 2D/3D site view linking panel, route, and charger target.

### P2 — only after P0/P1 are stable
- Utility account / Green Button integration.
- Full-house RoomPlan scan.
- Multiple specialist agents.
- Broad code scraping and nationwide support.
- Contractor marketplace and bidding.
- Production auth, billing, and multi-tenant admin.

## Critical path
1. Freeze the SiteGraph and event contracts.
2. Validate golden fixtures in both TypeScript and Swift.
3. Wire one observation through capture -> validate -> persist -> render.
4. Add the typed form and deterministic calculators.
5. Add the report / installer handoff.
6. Add fallback paths and rehearse the scripted demo.

## Stage gates

### Stage 0 — inventory, rules, and contracts
Exit when:
- repo structure is clear,
- shared contracts exist,
- fixtures decode in TypeScript and Swift,
- and all lanes know their ownership.

### Stage 1 — thin vertical slice
Exit when:
- one captured or seeded observation reaches validated state,
- persists,
- and is rendered back to the user.

### Stage 2 — realtime conversation
Exit when:
- a stateful session can ask for missing data,
- call typed tools,
- and survive reconnect or fallback.

### Stage 3 — spatial capture and perception
Exit when:
- charger target anchoring,
- panel capture,
- and at least one spatial measurement are real and typed.

### Stage 4 — engineering and cost tools
Exit when:
- golden fixtures produce stable, explainable scenario results.

### Stage 5 — declarative UI for missing data
Exit when:
- a structured form can be opened, dismissed, resumed, and submitted without losing state.

### Stage 6 — closed-loop EV workflow
Exit when:
- the golden demo runs from intent to handoff with no hidden manual jump.

### Stage 7 — hardening and presentation
Exit when:
- fallback, reset, rehearsal, and judge Q&A are all ready.

## Acceptance checklist
- [ ] Canonical SiteGraph v0 exists in TypeScript.
- [ ] Modern 200 A, constrained 100 A, and insufficient-data fixtures exist.
- [ ] TypeScript validates the fixtures.
- [ ] Swift decodes the canonical fixture.
- [ ] Root app renders the current status and plan.
- [ ] At least one vertical slice is wired end to end.
- [ ] Deterministic load and cost outputs are tested.
- [ ] Demo fallback path is scripted.

## Dependencies
- Shared contract first, then parallel lane work.
- Backend and iOS should not diverge on schema shape.
- Demo assets must be seeded before the judged walkthrough.

## Sprint execution roadmap

Each sprint ends with its listed acceptance check before the next sprint starts. Agents work in separate worktrees and may parallelize only after the named interface is merged.

### Sprint 1 — guided seeded demo shell

**Goal:** Turn the native scaffold into a coherent, resettable four-step assessment flow: site, panel, charger location, results.

- **iOS lane:** build the guided SwiftUI flow from the modern 200 A seeded assessment and show value provenance / unresolved items.
- **Schema lane:** define the smallest fixture transport and Swift decode boundary without changing SiteGraph v0.
- **Demo lane:** define the visible copy and one-action reset behavior.
- **Dependency:** the fixture transport shape is agreed and merged before iOS wiring begins.
- **Exit:** the physical iPhone shows the seeded flow end to end, reset works, and `pnpm check` passes.

### Sprint 2 — live agent and one validated observation round-trip

**Goal:** Prove one observation can leave the phone, be validated and persisted, then render back with its evidence and status.

- **Realtime lane:** establish one OpenAI Agents SDK Realtime session with typed SiteGraph tools and a secure phone connection.
- **Server lane:** implement the smallest validated assessment / observation API with in-memory persistence.
- **iOS lane:** stream a guided exchange, then submit and reload one seeded observation against that API.
- **Schema lane:** add a boundary check for the request and response payloads.
- **Dependency:** Sprint 1 fixture boundary and the `observation.added` payload are frozen before lanes parallelize.
- **Exit:** the agent asks for one missing fact, one observation round-trips on the phone, invalid payloads return a visible validation error, and `pnpm check` passes.

### Sprint 3 — A2UI assessment and deterministic handoff

**Goal:** Produce an explainable preliminary answer rather than a static summary.

- **Engineering lane:** implement fixture-driven charger/load and cost scenarios with explicit assumptions.
- **Server lane:** expose those deterministic tool runs through the typed assessment boundary.
- **A2UI / iOS lane:** render the minimum missing vehicle/load form from the approved native catalog, return typed user actions, and show results plus installer handoff.
- **Dependency:** tool input/output contract is merged before UI and server integration.
- **Exit:** modern, constrained, and insufficient-data fixtures produce the correct status, visible assumptions, and a handoff view; `pnpm check` passes.

### Sprint 4 — spatial + vision capture and rehearsal

**Goal:** Replace one seeded input with real phone evidence while preserving the fallback demo path.

- **iOS capture lane:** capture a panel photo, record a proposed charger location with ARKit/LiDAR anchoring, and send selected visual evidence for proposed observations.
- **Vision lane:** turn the selected frame into a reviewable proposed panel observation; use A2UI confirmation before it enters authoritative state.
- **Demo / research lane:** wire the disclosed fixture fallback, reset path, and judge rehearsal script.
- **Integration lane:** attach capture output to Sprint 2's observation interface.
- **Dependency:** no capture lane changes the validated observation contract without coordinating with its owner.
- **Exit:** the phone can add one real evidence-backed observation or explicitly switch to the fixture fallback, then complete the same results and handoff flow.

### Deliberately deferred

- Full RoomPlan scans, production persistence/auth, and multi-agent orchestration.
- Better spatial visualization only after the capture-to-result path works.
