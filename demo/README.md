# Demo lane scaffold

This directory is the demo-only lane for the DNHacks walkthrough.

## What lives here
- `assets/seeded-assessment-modern-200a.json` — primary seeded walkthrough payload.
- `assets/seeded-assessment-insufficient-data.json` — fallback payload for missing capture or stalled demo state.
- `reset.md` — one-action reset steps for the presenter.
- `judge-checklist.md` — judge-facing fallback notes and claim boundaries.

## Demo rule
Use only the seeded SiteGraph v0 payloads here when live capture fails.
Do not treat these as new source-of-truth schemas; the canonical contract stays in `packages/schemas`.
