# AGENTS.md — DNHacks 2026 operating guide

## Context
- DNHacks 2026, two-person team, 24-hour build.
- Hermes/Codex are development tools only; they are not part of the shipped product.
- This repo starts as a pre-hackathon scaffold. Product scope stays tentative until the official prompt is confirmed.

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
- `docs/ARCHITECTURE.md` — source of truth for boundaries and data flow.
- `docs/DECISIONS.md` — append-only record of consequential choices.
- `docs/DEMO.md` — protects the judging path.
- `docs/TASKS.md` — lightweight coordination board.

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
- `pnpm build`
- `pnpm check`

## Documentation rules
- Update `docs/ARCHITECTURE.md` when boundaries change.
- Update `docs/DECISIONS.md` for consequential choices.
- Update `docs/DEMO.md` when the critical flow changes.
- Update `docs/TASKS.md` when work status changes.

## Hackathon rule
- Working demo > robustness > elegance > theoretical completeness.
- If a choice threatens the demo path, choose the demo path.
