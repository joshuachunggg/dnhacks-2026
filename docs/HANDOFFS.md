# Handoffs

## Open handoffs

- **Main/orchestrator -> spatial contract, artifact, iOS capture, and guided UX lanes**: implement the reviewed one-room RoomPlan capture path described in [`SPATIAL-CAPTURE.md`](./SPATIAL-CAPTURE.md).
  - Need: a single contract owner first for manifests, artifact references, typed capture events, and error states; consumers must start only after that base is reviewed and reachable.
  - Acceptance: a physical iPhone captures one room, retains RoomPlan JSON/USDZ and panel-image references, confirms a spatial EVSE location and route measurement, then reaches the existing engineering/cost/handoff flow or a visibly labeled fixture fallback.

- **Sprint 2 -> Realtime + iOS lanes**: add a server-owned Realtime session that asks for one missing fact and submits it through the existing `observation.added` boundary.
  - Need: no long-lived phone API key and typed agent/tool messages.
  - Acceptance: the agent asks one question; the phone confirms the result; the existing validated state flow renders it.

- **Main/orchestrator -> research lane**: collect one narrow source-backed jurisdiction card and one cost assumption fixture.
  - Need: source URLs, jurisdiction, effective date, and limitations.
  - Acceptance: claims-to-source rows in `research/SOURCES.md`.

- **Demo lane -> iOS + API lanes**: integrate constrained and insufficient-data rehearsal artifacts into the executable native demo.
  - Available: resettable modern/constrained/insufficient-data rehearsal assets, a network/capture fallback script, and provenance-bound judge Q&A in `docs/DEMO.md` and `demo/`.
  - Need: in-app fixture selection and a clearly labeled missing-data UI; one-action reset and modern-fixture tool rendering are implemented.
  - Acceptance: each scripted path can be selected and reset in the app without representing seeded output as live capture or a live calculation.

## Completed handoffs
- Repo inspection complete.
- Documentation scaffold updated.
- iOS lane scaffold created in `apps/ios` with a scaffold-only SwiftUI state model.
- iOS lane target created in `apps/ios/SiteGraphShell.xcodeproj`; the `SiteGraphShell` scheme wires the scaffold files into an iOS 17+ app and has been run on a physical iPhone.
- Backend lane scaffold created in `apps/server` with typed placeholder contracts.
- First validated observation API created: `POST /api/assessments`, `GET /api/assessments/:id`, and `POST /api/assessments/:id/events` use in-memory state for the demo path.
- iOS live-round-trip control added: it creates the fixture assessment, submits one confirmed panel-label observation, reloads the response, and retains the local fixture on error.
- Physical iPhone acceptance completed: the phone reached the local API, submitted the observation, and rendered the validated response.
- Deterministic engineering contract completed in `apps/server/src/engineering-calculator.ts`; all three SiteGraph fixtures and changed-input cases pass typed tests.
- Deterministic cost contract completed in `apps/server/src/cost-calculator.ts`; modern, constrained/route-change, insufficient-data, no-spare-space uncertainty, and stale/tampered/duplicate adapter boundaries pass typed tests.
- Engineering and cost are available through validated, timestamp-safe `POST /api/assessments/:assessmentId/tools/runEngineeringScenario` and `runCostScenario` routes. A live local HTTP sequence created the modern assessment, persisted both canonical outputs, and returned the expected fixture-scoped cost range.
- The iOS seeded flow creates an assessment, invokes engineering and cost, renders returned provenance/status/requirements/handoff, and labels partial ranges and non-quote allowances. It is simulator-verified; updated physical-device acceptance remains open.
- Local-Mac RoomPlan backup is implemented: `POST /api/assessments/:assessmentId/artifacts/:artifactId` accepts an existing assessment's USDZ, atomically writes an ignored local copy, computes its integrity descriptor, and iOS verifies that descriptor before posting the metadata manifest. The endpoint and `iphoneos` target compile are verified; physical iPhone scan/upload acceptance remains open.
- Demo lane scaffold created in `demo/` with seeded assessment assets and reset notes.
- Research lane source card added in `research/` with Austin / Austin Energy cost anchors.
