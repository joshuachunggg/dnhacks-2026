# Demo rehearsal artifacts

These assets support the resettable, disclosed fallback rehearsal in [`../docs/DEMO.md`](../docs/DEMO.md). They are demo-only SiteGraph v0 payloads; the canonical contract remains in `packages/schemas` and the canonical test fixtures remain in `packages/fixtures`.

## Assets

- [`assets/seeded-assessment-modern-200a.json`](assets/seeded-assessment-modern-200a.json) — primary modern 200 A walkthrough. The native iOS shell bundles its corresponding modern fixture.
- [`assets/seeded-assessment-constrained-100a.json`](assets/seeded-assessment-constrained-100a.json) — older 100 A / detached-garage contrast. Artifact fallback only until the app adds fixture selection.
- [`assets/seeded-assessment-insufficient-data.json`](assets/seeded-assessment-insufficient-data.json) — explicit missing-data outcome. Artifact fallback only until the app adds fixture selection.
- [`reset.md`](reset.md) — presenter reset and recovery steps.
- [`judge-checklist.md`](judge-checklist.md) — compact preflight and Q&A claim boundaries.

## Rules

- Label every fixture as seeded demo data; do not call it live capture, a live calculation, or an accepted device flow.
- Preserve source type, status, evidence IDs, assumptions, warnings, and professional-verification requirements during narration.
- The iOS shell currently has a bundled modern fixture and a fallback-preserving live observation control. It does **not** currently provide capture, Realtime, engineering/cost execution, all-fixture selection, a one-action reset, persistence, or handoff export.
- Use the insufficient-data fixture rather than inventing panel, route, load, or price facts.
- Do not instruct consumers to open panels, touch energized equipment, bypass permit/inspection requirements, or perform electrical work.
