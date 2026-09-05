# Bugs

## Status legend
- TODO
- TRIAGED
- IN PROGRESS
- VERIFY
- DONE

## Prioritized ledger
| ID | Severity | Title | Owner | Status | Repro | Suspected component | Workaround | Fix | Verification |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B-001 | high | Canonical SiteGraph not yet implemented | Main | TODO | Load fixture validation path | `packages/schemas` | Use docs-only flow | Add schema and fixtures | TS and Swift decode pass |
| B-002 | high | No iOS app target yet | Frontend | TRIAGED | Open `apps/ios` | iOS shell | Use demo shell | Create native app scaffold; xcodebuild currently unavailable without Xcode | Can launch on device or simulator |
| B-003 | high | No backend tool service yet | Backend | TODO | Call `/api/assessments` | `apps/server` | Fixture-only demo | Add typed endpoints | One observation round-trips |
| B-004 | medium | No source-backed jurisdiction card | Research | TODO | Open demo card | `research/SOURCES.md` | Mark as sample only | Add a narrow source fixture | Claims map to source rows |
| B-005 | medium | No installer handoff artifact | Demo | TODO | Open handoff view | report/export path | Use status screen | Add report payload | Handoff matches fixture |

## Verification rule
A bug is not done until the reproduction path is exercised and the fix is checked against the exact failing case.
