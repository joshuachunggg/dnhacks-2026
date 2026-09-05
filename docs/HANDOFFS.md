# Handoffs

## Open handoffs
- **Engineering/server -> API + iOS lanes**: wire the completed pure engineering calculator into the validated assessment flow and render the typed result.
  - Available: `runEngineeringScenario(input)` accepts only SiteGraph v0 and returns a validated result with provenance, status, handoff, disclaimer, and explicit insufficient-data outcome.
  - Acceptance: a changed SiteGraph input yields the newly computed result in the iPhone with status and warnings.

- **Main/orchestrator -> engineering + server lanes**: define the separate deterministic cost contract.
  - Need: typed cost inputs, explicit assumptions, and result schema.
  - Acceptance: cost remains a separate tool run from engineering feasibility.

- **Sprint 2 -> Realtime + iOS lanes**: add a server-owned Realtime session that asks for one missing fact and submits it through the existing `observation.added` boundary.
  - Need: no long-lived phone API key and typed agent/tool messages.
  - Acceptance: the agent asks one question; the phone confirms the result; the existing validated state flow renders it.

- **Main/orchestrator -> research lane**: collect one narrow source-backed jurisdiction card and one cost assumption fixture.
  - Need: source URLs, jurisdiction, effective date, and limitations.
  - Acceptance: claims-to-source rows in `research/SOURCES.md`.

- **Main/orchestrator -> demo lane**: script the golden walkthrough and fallback ladder.
  - Need: seeded property, fallback trigger points, and judge Q&A.
  - Acceptance: the demo can run without improvising the flow.

## Completed handoffs
- Repo inspection complete.
- Documentation scaffold updated.
- iOS lane scaffold created in `apps/ios` with a scaffold-only SwiftUI state model.
- iOS lane target created in `apps/ios/SiteGraphShell.xcodeproj`; the `SiteGraphShell` scheme wires the scaffold files into an iOS 17+ app and has been run on a physical iPhone.
- Backend lane scaffold created in `apps/server` with typed placeholder contracts.
- First validated observation API created: `POST /api/assessments`, `GET /api/assessments/:id`, and `POST /api/assessments/:id/events` use in-memory state for the demo path.
- iOS live-round-trip control added: it creates the fixture assessment, submits one confirmed panel-label observation, reloads the response, and retains the local fixture on error.
- Physical iPhone acceptance completed: the phone reached the local API, submitted the observation, and rendered the validated response.
- Deterministic engineering contract completed in `apps/server/src/engineering-calculator.ts`; all three SiteGraph fixtures and a changed-input case pass typed tests, with no API or iOS integration yet.
- Demo lane scaffold created in `demo/` with seeded assessment assets and reset notes.
- Research lane source card added in `research/` with Austin / Austin Energy cost anchors.
