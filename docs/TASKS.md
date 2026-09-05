# Tasks

## Status legend
- TODO
- IN PROGRESS
- BLOCKED
- REVIEW
- DONE

## Rules
- Only one person or agent owns a task and its branch/worktree at a time.
- Pre-hackathon readiness tasks may be checked off only if they are actually complete.
- All implementation tasks must remain TODO until the hacking window begins.

## Board
| ID | Task | Owner | Status | Branch / worktree | Dependencies | Acceptance test |
| --- | --- | --- | --- | --- | --- | --- |
| R-01 | Inspect current directory, Git, and GitHub state | Hermes | DONE | main worktree | none | Versions and auth status captured |
| R-02 | Verify toolchain versions (`git`, `gh`, `node`, `pnpm`, `swift`, `xcodebuild`) | Hermes | DONE | main worktree | none | Version output recorded |
| R-03 | Update repo thesis, docs, and monorepo scaffold | Hermes | DONE | `dnhacks-2026` | R-01 | Docs and directories exist |
| R-04 | Define SiteGraph v0 and fixture set | Hermes | DONE | `dnhacks-2026` | R-03 | Schema + three fixtures exist |
| R-05 | Validate fixtures in TypeScript and Swift | Hermes | DONE | `dnhacks-2026` | R-04 | Both checks run successfully |
| R-06 | Create the first thin vertical slice | Hermes | DONE | `dnhacks-2026` | R-04, R-05 | One seeded observation round-trips through the physical iPhone, validated API, in-memory SiteGraph, and rendered UI |
| R-07 | Stand up backend and iOS workstreams | Hermes | IN PROGRESS | `dnhacks-2026` | R-04 | iOS seeded demo and local API round-trip are device-accepted; Realtime and deterministic-tool contracts remain |
| R-08 | Create and push the initial GitHub commit | Hermes | DONE | `dnhacks-2026` | R-03, R-04, R-05 | Clean commit on `main` and remote push succeeds |

## Current focus
- [x] Repo inspection complete.
- [x] Docs updated to the real DNHacks thesis.
- [x] Monorepo scaffold directories created.
- [x] Golden fixture payloads created.
- [x] iOS lane scaffold created.
- [x] Buildable iOS target and fixture-backed four-tab demo created.
- [x] Backend lane scaffold created.
- [x] Demo lane scaffold created.
- [x] Current four-tab demo accepted on a physical iPhone.
- [x] First seeded vertical slice is wired and accepted on a physical iPhone.

## Next 2 hours
- [x] Define and test the deterministic engineering tool contract against all three SiteGraph fixtures.
- TODO: define the separate cost tool contract and render deterministic engineering results through the API/iOS flow.
- TODO: add the Realtime agent only after the deterministic tool boundary is stable.

## Demo readiness
- Not ready yet.
- The seeded phone-to-server vertical slice works; deterministic result generation is the next missing demo capability.

## Handoff template
- Changed files:
- Commands run:
- Result:
- Remaining risks:
- Commit SHA:
