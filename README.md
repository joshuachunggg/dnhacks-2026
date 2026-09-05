# DNHacks 2026

Spatial AI field-engineer demo for residential EV charger feasibility.

## Current state
- Next.js + TypeScript scaffold is live at the repo root.
- Canonical SiteGraph v0, fixtures, and validation scripts are present.
- `apps/ios` contains a buildable iOS 17+ SwiftUI target with a fixture-backed four-screen demo.
- The backend is still a scaffold; no live agent, capture, or end-to-end assessment path exists yet.

## Demo thesis
A phone should turn observations of a physical home into evidence-backed structured state that a realtime agent can reason over, explain, and hand off to an electrician. This is a spatial AI field-engineer demo for residential EV charger assessment. The hackathon demo focuses on one question:

> Can I install a Level 2 EV charger at this location, what are my realistic options, and what might each option cost?

## How the repo is organized
- `apps/ios` — native iPhone seeded demo and future capture/A2UI renderer.
- `apps/server` — TypeScript backend scaffold for the Realtime agent session and deterministic tools.
- `packages/schemas` — canonical SiteGraph and boundary schemas.
- `packages/fixtures` — golden fixture data for demo and contract tests.
- `docs` — plan, architecture, decisions, demo script, safety, and status.
- `research` — source-to-claim ledger.
- `bugs` — prioritized bug ledger.
- `scripts` — smoke and fixture validation helpers.

## Local setup
```bash
pnpm install
pnpm dev
```

## Validation
```bash
pnpm lint
pnpm typecheck
pnpm smoke
pnpm fixtures:check
pnpm swift:check
pnpm check
```

## Environment
Copy `.env.example` to `.env.local` and fill in only what the current work requires. No secrets are committed.

## Notes
- The current app shell is intentionally small.
- Important claims must live in typed state, not only in chat.
- Deterministic tools own numbers; the agent owns conversation and orchestration.
