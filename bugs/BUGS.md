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
| B-001 | high | No runtime SiteGraph bridge yet | Main | TODO | Submit an observation from the iOS demo | iOS-to-server boundary | Fixture-only demo | Add validated observation API and phone round-trip | One observation reloads with evidence and status |
| B-002 | high | No iOS app target yet | Frontend | DONE | Open `apps/ios/SiteGraphShell.xcodeproj` | iOS shell | n/a | Added the iOS 17+ target and fixture-backed four-screen demo | Signing-free device compile passes; original scaffold ran on device |
| B-003 | high | No backend tool service yet | Backend | TODO | Call `/api/assessments` | `apps/server` | Fixture-only demo | Add typed endpoints | One observation round-trips |
| B-004 | medium | No source-backed jurisdiction card | Research | TODO | Open demo card | `research/SOURCES.md` | Mark as sample only | Add a narrow source fixture | Claims map to source rows |
| B-005 | medium | No installer handoff artifact | Demo | TODO | Open handoff view | report/export path | Use status screen | Add report payload | Handoff matches fixture |

## Verification rule
A bug is not done until the reproduction path is exercised and the fix is checked against the exact failing case.
