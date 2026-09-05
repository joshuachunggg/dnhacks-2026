# Presenter reset and recovery

Full script: [`../docs/DEMO.md`](../docs/DEMO.md).

## Current native-shell reset

1. On the **Site** tab, tap **Reset demo** if a fixture is visible.
2. Tap **Use demo data** to reload the bundled modern-200A fixture.
3. Confirm that the Site, Panel, Charger Location, and Results tabs show seeded data before beginning.
4. State the mode: **native fixture shell**. Do not call this a live assessment.

This is the implemented two-step reset/reload sequence. A one-action reset is not implemented and must not be claimed.

## Fixture selection for the rehearsal

The current native shell renders only the modern fixture. Keep these artifacts open locally for disclosed fallback narration:

1. Primary: [`assets/seeded-assessment-modern-200a.json`](assets/seeded-assessment-modern-200a.json)
2. Constrained contrast: [`assets/seeded-assessment-constrained-100a.json`](assets/seeded-assessment-constrained-100a.json)
3. Missing-data fallback: [`assets/seeded-assessment-insufficient-data.json`](assets/seeded-assessment-insufficient-data.json)

Do not alter an asset during a run. The constrained and insufficient-data files are not currently selectable in the app.

## Network recovery

If **Confirm panel label with live API** reports an error:

1. Stop and label the branch **fixture fallback**.
2. Confirm the bundled modern fixture is still visible; the current control preserves it when the server is unreachable.
3. Continue the seeded modern story or use the open artifact if the fixture cannot reload.
4. Do not claim that capture, engineering, or cost execution ran.

## Capture recovery

Live capture is not implemented in the current native shell. Do not simulate it. State that the rehearsal is using a disclosed seeded assessment and continue with the applicable artifact. Never ask a consumer to open a panel or perform electrical work.
