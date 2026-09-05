# Status

## Snapshot
- Repo is a clean `main` worktree with `origin` configured.
- Current app shell is still the default Next.js scaffold, but the repo docs now reflect the real DNHacks thesis.
- Shared contract work is moving to SiteGraph v0 plus golden fixtures.
- iOS and backend directories exist conceptually, but their implementations are still pending.

## Completed
- Inspected Git state, branch, remote, and toolchain availability.
- Confirmed the repo is already initialized and connected to GitHub.
- Updated the repo front door and operating docs.
- Added the plan, architecture, contracts, decisions, safety, and handoff scaffolding.
- Added SiteGraph v0 schemas and three golden fixtures.
- Verified TypeScript and Swift can decode the canonical fixture.
- Scaffolded the iOS lane with a native SwiftUI starter state.
- Scaffolded the backend lane with a typed placeholder manifest and draft envelope.
- Scaffolded the demo lane with seeded fallback assets and reset notes.
- Added the Austin/Austin Energy source card and cost anchor notes in `research/`.
- Pushed commit `2f9811c` to `origin/main`.

## Current work
- Build the first thin vertical slice.
- Stand up backend and demo lane scaffolds.
- Add the backend API and typed tools.

## Blockers
- The iOS lane is scaffold-only until an Xcode project/workspace is created; `xcodebuild` is unavailable on this host because only Command Line Tools are installed.
- The repo still needs the actual iPhone shell and backend service implementations.
- Jurisdiction and cost data are still fixture-backed only.

## Next integration point
- A single SiteGraph fixture should decode cleanly in TypeScript and Swift.
- After that, the first vertical slice should send one observation through the validated state boundary and render it back in the UI.

## Demo readiness
- Status: not ready yet
- Reason: the shared contract exists only in docs so far, not in runtime code.
