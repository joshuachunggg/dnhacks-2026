# Handoffs

## Open handoffs
- **iOS lane -> device owner**: accept the four-screen modern-200A demo on a physical iPhone.
  - Need: run `SiteGraphShell` from Xcode and tap Site, Panel, Charger Location, Results, Reset demo, and Use demo data.
  - Acceptance: all fixture-backed screens render; reset clears state and reload restores it.

- **Sprint 2 -> server, realtime, and iOS lanes**: define the `observation.added` boundary, then ship one Realtime-guided observation round-trip.
  - Need: server-owned OpenAI Agents SDK Realtime session, typed API validation, and an iOS client connection with no long-lived API key.
  - Acceptance: the agent asks for one fact; the phone submits one observation; the validated result reloads with evidence and status.

- **Main/orchestrator -> future backend lane**: create `apps/server` with typed assessment storage and tool endpoints.
  - Need: event and tool contracts from `docs/CONTRACTS.md`.
  - Acceptance: one observation can persist and round-trip through the API.

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
- Demo lane scaffold created in `demo/` with seeded assessment assets and reset notes.
- Research lane source card added in `research/` with Austin / Austin Energy cost anchors.
