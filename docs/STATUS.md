# Status

## Snapshot
- `main` includes the native iOS target and `origin` is configured.
- Current app shell is still the default Next.js scaffold, but the repo docs now reflect the real DNHacks thesis.
- Shared contract work is moving to SiteGraph v0 plus golden fixtures.
- The iOS shell is an iOS 17+ SwiftUI target with a four-screen seeded demo. A physical iPhone has submitted and rendered one validated observation through the local backend API.
- The backend provides an in-memory validated state boundary plus deterministic engineering and cost tool endpoints. A live local HTTP run created the modern fixture assessment, persisted canonical engineering and cost outputs, and returned the expected fixture-scoped cost scenario.
- The iOS shell creates the seeded assessment, runs engineering then cost against the configured server, renders returned provenance, requirements, installer handoff, and explicit cost-range status, and retains visible fixture fallback. The iPhone 17 Pro simulator build passes; this updated flow is not yet accepted on a physical device.

## Completed
- Inspected Git state, branch, remote, and toolchain availability.
- Confirmed the repo is already initialized and connected to GitHub.
- Updated the repo front door and operating docs.
- Added the plan, architecture, contracts, decisions, safety, and handoff scaffolding.
- Added SiteGraph v0 schemas and three golden fixtures.
- Verified TypeScript and Swift can decode the canonical fixture.
- Scaffolded the iOS lane with a native SwiftUI starter state.
- Added `apps/ios/SiteGraphShell.xcodeproj`, the `SiteGraphShell` scheme, and wired the SwiftUI scaffold into the target.
- Verified the native scaffold runs on a physical iPhone.
- Added the bundled modern-200A fixture, local Swift decoder, four-tab assessment demo, reset/reload control, and fixture-backed results/handoff display.
- Scaffolded the backend lane with a typed placeholder manifest and draft envelope.
- Scaffolded the demo lane with seeded fallback assets and reset notes.
- Added the Austin/Austin Energy source card and cost anchor notes in `research/`.
- Fixed the pnpm workspace build-approval placeholder so `pnpm check` can run.
- Added a Zod-validated, in-memory assessment API: create, get, and append one `observation.added` event.
- Added the iOS live-round-trip control with a configurable server URL, explicit failure state, and fixture fallback preservation.
- Aligned the bundled iOS modern-200A fixture with the canonical schema and added a regression test for that boundary.
- Added the pure `runEngineeringScenario` contract with validated input/output, deterministic provenance, explicit insufficient-data handling, and fixture coverage for modern, constrained, and missing-data cases.
- Added the pure `runCostScenario` contract with Zod-validated results, source-limited Austin permit anchor provenance, fixture-scoped non-quote line items, route-sensitive range math, explicit insufficient-data and unpriced-upgrade states, and a safe deterministic application adapter.
- Added a backward-compatible SiteGraph evidence registry and fixture records; deterministic engineering and cost calculations now require their panel/route evidence IDs to resolve in that registry.
- Added timestamp-safe engineering and cost endpoints. Each captures one request-time timestamp, passes it to calculation and application, persists atomically in the in-memory store, and rejects malformed tool bodies.
- Added native server-result rendering for engineering and cost, including provenance, requirements, handoff, disclaimer, `preliminary_range`, `partial_range`, and `insufficient_data` presentation.
- Verified the local HTTP acceptance sequence: create modern fixture → run engineering → run cost. The response contained canonical conditional engineering and cost ToolRuns and the fixture-scoped expected cost of $1,541.99.
- Pushed commit `2f9811c` to `origin/main`.

## Current work
- Add the server-owned Realtime conversation that asks for one missing fact through the validated observation boundary. This requires an `OPENAI_API_KEY` in local `.env.local` before the live path can be exercised.
- Add one real, evidence-backed iPhone capture/proposal path or retain the disclosed fixture fallback when capture is unavailable; validate the merged tool-rendering flow on a physical device when it is online.

## Blockers
- No local `.env.local` / `OPENAI_API_KEY` is configured, so a live Realtime session cannot be exercised.
- `Joshua’s iPhone (26.6.1)` is offline in Xcode tooling, so the newly merged tool-rendering flow has simulator—not physical-device—acceptance.
- Durable persistence remains deferred; assessment data lives only for the local server process lifetime.
- Jurisdiction data and non-government cost allowances are intentionally demo/fixture-scoped; live quotes and jurisdiction expansion remain out of scope.

## Next integration point
- Implement and exercise the one-question server-owned Realtime path, with explicit fixture fallback if credentials or connectivity are unavailable.

## Demo readiness
- Status: partially ready
- Working: seeded assessment → validated local API → deterministic engineering and cost → native server-result rendering, plus a scripted fixture fallback. The local HTTP path and simulator build are verified.
- Not ready to claim: live Realtime conversation, real capture/vision evidence, updated physical-device acceptance, durable persistence, or handoff export.
