# Judge checklist

- Confirm the app shows a typed SiteGraph v0 assessment, not an unstructured mock.
- Confirm the demo can continue with seeded fallback assets if live capture fails.
- Confirm the output labels observed, user-supplied, inferred, calculated, and professional-verification-required values clearly.
- Confirm at least one deterministic engineering result is visible.
- Confirm the reset path restores the seeded assessment quickly.

## Fallback notes
- `seeded-assessment-modern-200a.json` is the happy-path demo seed.
- `seeded-assessment-insufficient-data.json` is the honest fallback when panel or route data is missing.
- The fallback path should explain missing facts instead of inventing them.
