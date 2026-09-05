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
| B-001 | high | Runtime SiteGraph bridge unavailable | Main | DONE | Submit an observation from the iOS demo | iOS-to-server boundary | Fixture-only demo | Added validated observation API and physical-phone round-trip | One seeded observation reloaded with evidence and status on the physical iPhone |
| B-002 | high | No iOS app target yet | Frontend | DONE | Open `apps/ios/SiteGraphShell.xcodeproj` | iOS shell | n/a | Added the iOS 17+ target and fixture-backed four-screen demo | Signing-free device compile passes; original scaffold ran on device |
| B-003 | high | No deterministic backend tool service yet | Backend | DONE | Create a modern fixture assessment, then POST both tool routes | `apps/server` | Fixture-provided results | Added timestamp-safe deterministic engineering and cost routes | Live local HTTP sequence persisted both canonical tool outputs and returned the fixture-scoped cost scenario |
| B-004 | medium | No source-backed jurisdiction card | Research | DONE | Open demo card | `research/SOURCES.md` | Mark as sample only | Added Austin/Austin Energy source fixture | Claims map to source rows |
| B-005 | medium | No installer handoff view | Demo | VERIFY | Run the newly merged iOS tool flow on a physical phone | native results screen | Fixture results | Render server-returned requirements and installer handoff | Simulator build passes; physical-device acceptance of the updated flow remains open |

## Verification rule
A bug is not done until the reproduction path is exercised and the fix is checked against the exact failing case.
