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

## Current work
- Define SiteGraph v0 in TypeScript.
- Add golden fixtures for modern 200 A, constrained 100 A, and insufficient-data homes.
- Build a TypeScript fixture validator.
- Build a standalone Swift fixture decoder.

## Blockers
- No Xcode project or iOS app target exists yet.
- The repo still needs the actual iPhone shell and backend service implementations.
- Jurisdiction and cost data are still fixture-backed only.

## Next integration point
- A single SiteGraph fixture should decode cleanly in TypeScript and Swift.
- After that, the first vertical slice should send one observation through the validated state boundary and render it back in the UI.

## Demo readiness
- Status: not ready yet
- Reason: the shared contract exists only in docs so far, not in runtime code.
