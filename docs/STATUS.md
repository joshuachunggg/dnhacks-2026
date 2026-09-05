# Status

## Snapshot
- `main` includes the native iOS target and `origin` is configured.
- Current app shell is still the default Next.js scaffold, but the repo docs now reflect the real DNHacks thesis.
- Shared contract work is moving to SiteGraph v0 plus golden fixtures.
- The iOS shell is an iOS 17+ SwiftUI target and has been run on a physical iPhone; backend implementation is still pending.

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
- Scaffolded the backend lane with a typed placeholder manifest and draft envelope.
- Scaffolded the demo lane with seeded fallback assets and reset notes.
- Added the Austin/Austin Energy source card and cost anchor notes in `research/`.
- Pushed commit `2f9811c` to `origin/main`.

## Current work
- Sprint 1: build the guided seeded assessment flow and Swift fixture boundary.
- Then build the live agent plus first observation round-trip through a typed backend API.

## Blockers
- The repo still needs the guided iPhone workflow, live agent, backend service, and one end-to-end observation path.
- Simulator services are unavailable to this terminal environment; physical-device deployment is verified instead.
- Jurisdiction and cost data are still fixture-backed only.

## Next integration point
- The first vertical slice should send one observation through the validated state boundary and render it back in the iOS UI.

## Demo readiness
- Status: not ready yet
- Reason: the native shell runs, but capture, realtime intelligence, validated server round-trip, deterministic results, and installer handoff are not yet connected.
