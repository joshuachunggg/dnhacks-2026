# Demo reset

1. Reload the demo lane state from `demo/assets/seeded-assessment-modern-200a.json`.
2. If the walkthrough needs the fallback path, swap to `demo/assets/seeded-assessment-insufficient-data.json`.
3. Clear any transient capture state, in-progress prompts, and unsaved draft notes.
4. Restart the walkthrough at the proposed EVSE location step.

## Reset target
- Primary path: modern 200 A seeded assessment.
- Fallback path: insufficient-data seeded assessment.

## Operator note
The reset should restore the seeded assessment only; it should not modify the root app or shared schema files.
