# DNHacks 2026 Plan

> **For Hermes:** Use subagent-driven-development once the shared contracts below are stable.

**Goal:** Build a believable spatial AI demo that turns observations of a home into typed SiteGraph state, deterministic EVSE feasibility calculations, and a concise installer handoff.

**Architecture:** Keep the root Next.js app as the live demo shell for now, while moving canonical types into `packages/schemas` and fixture data into `packages/fixtures`. The backend lane will own typed state ingestion, engineering tools, and cost scenarios; the iOS lane will own capture, anchors, OCR, and the native guided flow. Shared state crosses boundaries only through validated schemas.

**Tech Stack:** Next.js, TypeScript, React, Zod, Swift/SwiftUI, ARKit, Vision OCR, deterministic calculators, pnpm.

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

## Current critical path right now
- Replace the generic scaffold wording with the real thesis.
- Add SiteGraph v0 and fixtures.
- Verify fixture decoding in both languages.
- Then fan out to backend, frontend, research, and demo lanes.
