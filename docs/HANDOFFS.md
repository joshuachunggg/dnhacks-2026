# Handoffs

## Open handoffs
- **Main/orchestrator -> future schema lane**: implement `packages/schemas/src/sitegraph.ts` and fixture validation.
  - Need: canonical SiteGraph v0 and shared enums.
  - Acceptance: TypeScript can validate the golden fixture.

- **Main/orchestrator -> future iOS lane**: create `apps/ios` shell and a minimal fixture-backed render path.
  - Need: native app target or placeholder project structure.
  - Acceptance: iOS can decode the same canonical fixture.

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
