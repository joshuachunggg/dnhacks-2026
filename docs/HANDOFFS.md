# Handoffs

## Open handoffs
- **Engineering/server -> API + iOS lanes**: wire the completed pure engineering calculator into the validated assessment flow and render the typed result.
  - Available: `runEngineeringScenario(input)` accepts only SiteGraph v0 and returns a validated result with provenance, status, handoff, disclaimer, and explicit insufficient-data outcome.
  - Required caller update: capture the calculation timestamp at invocation and call `applyEngineeringScenario(graph, result, capturedTimestamp)`; do not derive it from `result`. The old two-argument API path is temporary compatibility only and lacks an external timestamp trust anchor.
  - Acceptance: a changed SiteGraph input yields the newly computed result in the iPhone with status and warnings.

- **Cost/server -> API + iOS lanes**: wire the completed separate deterministic cost contract into the validated assessment flow and render its typed status.
  - Available: `runCostScenario(input)` and `applyCostScenario(graph, result, capturedTimestamp)` accept SiteGraph v0 only and return/record source-limited Austin provenance, fixture-scoped non-quote line items, explicit range status, handoff, and insufficient-data behavior.
  - Required caller update: when invoking with a controlled non-epoch timestamp, pass the invocation-captured timestamp to application; never trust result-origin or ToolRun timestamps as the expected value. The two-argument form is temporary compatibility only and lacks an external timestamp trust anchor.
  - Acceptance: iOS distinguishes `preliminary_range`, `partial_range` (unpriced panel/service upgrade), and `insufficient_data`; it must not label an allowance as a quote.

- **Sprint 2 -> Realtime + iOS lanes**: add a server-owned Realtime session that asks for one missing fact and submits it through the existing `observation.added` boundary.
  - Need: no long-lived phone API key and typed agent/tool messages.
  - Acceptance: the agent asks one question; the phone confirms the result; the existing validated state flow renders it.

- **Main/orchestrator -> research lane**: collect one narrow source-backed jurisdiction card and one cost assumption fixture.
  - Need: source URLs, jurisdiction, effective date, and limitations.
  - Acceptance: claims-to-source rows in `research/SOURCES.md`.

- **Demo lane -> iOS + API lanes**: integrate the rehearsal artifacts into the executable demo.
  - Available: resettable modern/constrained/insufficient-data rehearsal assets, a network/capture fallback script, and provenance-bound judge Q&A in `docs/DEMO.md` and `demo/`.
  - Need: in-app fixture selection, a one-action reset, deterministic engineering/cost API-to-iPhone rendering, and a clearly labeled missing-data UI.
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
- Deterministic engineering contract completed in `apps/server/src/engineering-calculator.ts`; all three SiteGraph fixtures and a changed-input case pass typed tests, with no API or iOS integration yet.
- Deterministic cost contract completed in `apps/server/src/cost-calculator.ts`; modern, constrained/route-change, insufficient-data, no-spare-space uncertainty, and stale/tampered/duplicate adapter boundaries pass typed tests, with no API or iOS integration yet.
- Demo lane scaffold created in `demo/` with seeded assessment assets and reset notes.
- Research lane source card added in `research/` with Austin / Austin Energy cost anchors.
