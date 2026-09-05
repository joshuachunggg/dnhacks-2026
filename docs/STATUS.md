# Status

## Snapshot
- `main` includes the native iOS target and `origin` is configured.
- Current app shell is still the default Next.js scaffold, but the repo docs now reflect the real DNHacks thesis.
- Shared contract work is moving to SiteGraph v0 plus golden fixtures.
- The iOS shell is an iOS 17+ SwiftUI target with a four-screen seeded demo. A physical iPhone has submitted and rendered one validated observation through the local backend API.
- The backend currently provides an in-memory validated state boundary; Realtime, deterministic tools, and durable persistence remain pending.

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
- Pushed commit `2f9811c` to `origin/main`.

## Current work
- Implement deterministic engineering and cost tool runs against the validated SiteGraph inputs.
- Then add the Realtime agent on top of the validated observation boundary.

## Blockers
- The repo still needs deterministic tool execution, the live agent, and durable backend persistence.
- Simulator services are unavailable to this terminal environment; physical-device deployment is verified instead.
- Jurisdiction and cost data are still fixture-backed only.

## Next integration point
- Run one deterministic engineering scenario from the validated SiteGraph and render its newly computed result on the iPhone.

## Demo readiness
- Status: not ready yet
- Reason: the validated phone-to-server observation path works, but capture, realtime intelligence, deterministic results, durable persistence, and an exportable installer handoff are not yet end-to-end verified.
