# AGENTS.md — DNHacks 2026 operating guide

## Context
- DNHacks 2026 is a hackathon build for a spatial AI field engineer.
- The shipped product is not Hermes/Codex; they are development tools only.
- Root status is a Next.js + TypeScript scaffold. The iOS lane has a seeded native demo; the backend lane is still being built.

## Priority order
1. Working end-to-end demo
2. Reliability
3. Technical defensibility
4. Fast iteration
5. Polish
6. Elegance

## Stack and package-manager rules
- Default stack: Next.js App Router, TypeScript, Tailwind, Zod, OpenAI Agents SDK, Vercel.
- Use pnpm for installs, scripts, and lockfile updates.
- Keep changes small and typed. Prefer the smallest dependency set that solves the current problem.
- Do not add dependencies for hypothetical future features.

## Repository map
- `README.md` — product front door.
- `docs/PLAN.md` — P0/P1/P2 scope, stages, dependencies, and acceptance criteria.
- `docs/ARCHITECTURE.md` — current boundaries and data flow.
- `docs/CONTRACTS.md` — canonical schemas and event/tool contracts.
- `docs/DECISIONS.md` — append-only decision log.
- `docs/STATUS.md` — current repo state and next integration point.
- `docs/DEMO.md` — demo script, seeded data, and fallback path.
- `docs/SAFETY.md` — claim boundaries and prohibited actions.
- `docs/HANDOFFS.md` — cross-lane requests and completions.
- `research/SOURCES.md` — claim-to-source ledger.
- `bugs/BUGS.md` — prioritized bug ledger.
- `apps/ios` — native iPhone seeded demo and future capture shell.
- `apps/server` — future backend and deterministic tooling.
- `packages/schemas` — canonical SiteGraph types and validators.
- `packages/fixtures` — golden fixture payloads.
- `scripts` — smoke/fixture validation helpers.

## Required workflow
1. Inspect the relevant files first.
2. State a short plan before changing code.
3. Make the smallest scoped change that solves the task.
4. Validate the change with the repo scripts.
5. Summarize what changed, what is verified, and what remains risky.

## Engineering rules
- Use typed boundaries for data that crosses module or network lines.
- Validate model/tool input and output with Zod at the boundary.
- Keep calculations deterministic.
- Do not swallow errors silently.
- Avoid unnecessary dependencies, abstractions, and refactors.
- Preserve the demo path; do not break the happy path for a cleanup.

## Git rules
- Keep `main` runnable.
- Use one branch/worktree per substantial parallel task.
- Make focused commits.
- Never force-push.
- Never commit secrets.
- Never edit another active agent's worktree.

## Integration rule
- Define interface contracts before parallel implementation.
- Avoid multiple agents changing the same files at once.
- If work overlaps, stop and re-scope before editing.

## Validation commands
Use only scripts that exist in `package.json`:
- `pnpm lint`
- `pnpm typecheck`
- `pnpm smoke`
- `pnpm fixtures:check`
- `pnpm swift:check`
- `pnpm build`
- `pnpm check`

## Documentation rules
- Update `docs/ARCHITECTURE.md` when boundaries change.
- Update `docs/DECISIONS.md` for consequential choices.
- Update `docs/DEMO.md` when the critical flow changes.
- Update `docs/STATUS.md` when repo state changes.
- Update `docs/HANDOFFS.md` when work is handed off.
- Update `docs/PLAN.md` when scope or sequencing changes.

## Hackathon rule
- Working demo > robustness > elegance > theoretical completeness.
- If a choice threatens the demo path, choose the demo path.
