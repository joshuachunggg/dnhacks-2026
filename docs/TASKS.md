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
| R-02 | Verify toolchain versions (`git`, `gh`, `node`, `pnpm`) | Hermes | DONE | main worktree | none | Version output recorded |
| R-03 | Confirm GitHub auth status | Hermes | DONE | main worktree | none | `gh auth status` succeeds |
| R-04 | Create the local repository scaffold | Hermes | DONE | `dnhacks-2026` | none | Required files exist |
| R-05 | Write documentation and workflow infrastructure | Hermes | DONE | `dnhacks-2026` | R-04 | Docs are present and concise |
| R-06 | Initialize Git and create the initial commit | Hermes | TODO | `dnhacks-2026` | R-04, R-05 | Clean commit on `main` |
| R-07 | Create and push the private GitHub repository | Hermes | TODO | `dnhacks-2026` | R-06 | Remote exists and push succeeds |

## Pre-hackathon readiness
- [x] Inspect current directory and Git/GitHub state
- [x] Verify `git`, `gh`, `node`, and `pnpm` versions
- [x] Confirm `gh auth status` succeeds
- [x] Create the local scaffold
- [x] Write docs and generic verification tooling
- [ ] Create the GitHub repo and push the initial commit

## First 2 hours
- TODO: Freeze the challenge scope.
- TODO: Define the first interface contract.
- TODO: Decide which steps are live versus fixture-backed.
- TODO: Confirm the demo happy path on a phone.

## Core build
- TODO: Implement the survey entry flow.
- TODO: Implement structured observation output.
- TODO: Implement deterministic calculators.
- TODO: Implement the proposal UI.

## Integration
- TODO: Wire the model boundary to typed tools.
- TODO: Wire fallback states and cached fixtures.
- TODO: Validate the critical flow end to end.

## Demo / polish
- TODO: Polish mobile layout and copy.
- TODO: Verify backup screenshots and prerecorded fallback.
- TODO: Tighten error messages and loading states.

## Submission
- TODO: Final pass on docs and demo contract.
- TODO: Confirm deployment URL and repo state.
- TODO: Record commit SHA and final notes.

## Handoff template
- Changed files:
- Commands run:
- Result:
- Remaining risks:
- Commit SHA:
