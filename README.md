# DNHacks 2026

**Provisional description:** pre-hackathon scaffold for the DNHacks 2026 build.

## Current status
- Pre-hackathon scaffold only.
- No product implementation yet.
- Final scope stays tentative until the official challenge is released.

## Working hypothesis
This project is currently scoped as a phone-camera-and-conversation survey that creates structured equipment observations, evaluates retrofit options with deterministic energy/cost/grid tools, and renders an interactive proposal. The survey path would collect image and voice context, turn it into typed observations, and hand off to deterministic calculators for repeatable outputs. The UI would then show a proposal that can be adjusted live when assumptions change. This is a working hypothesis, not a committed product claim.

## Setup prerequisites
Verified in this repo:
- `git --version`
- `gh auth status`
- `node --version`
- `pnpm --version`

Local setup commands:
```bash
pnpm install
pnpm dev
```

Validation commands:
```bash
pnpm lint
pnpm typecheck
pnpm smoke
pnpm build
pnpm check
```

## Environment variables
| Variable | Purpose | Required now |
| --- | --- | --- |
| `OPENAI_API_KEY` | Future OpenAI model access for the eventual app | No, but likely needed later |
| `OPENAI_BASE_URL` | Optional compatible OpenAI-style endpoint | No |
| `VERCEL_URL` | Optional deployment origin in preview/deployment contexts | No |

## Available scripts
| Script | Command | Notes |
| --- | --- | --- |
| `dev` | `pnpm dev` | Local Next.js development server |
| `build` | `pnpm build` | Production build |
| `start` | `pnpm start` | Run the production server after build |
| `lint` | `pnpm lint` | ESLint over the repo |
| `typecheck` | `pnpm typecheck` | TypeScript no-emit check |
| `smoke` | `pnpm smoke` | Noninteractive scaffold verification |
| `check` | `pnpm check` | Runs lint, typecheck, and smoke |

## Repository map
- `AGENTS.md` — operating guide for coding agents
- `README.md` — human front door
- `docs/ARCHITECTURE.md` — tentative source of truth for boundaries
- `docs/DECISIONS.md` — append-only decision log
- `docs/DEMO.md` — critical judging path contract
- `docs/TASKS.md` — coordination board
- `scripts/smoke-test.mjs` — generic verification script
- `src/` — minimal app scaffold
- `public/` — default assets only

## Related docs
- [Architecture](docs/ARCHITECTURE.md)
- [Decisions](docs/DECISIONS.md)
- [Demo](docs/DEMO.md)
- [Tasks](docs/TASKS.md)

## Deployment
Vercel is the intended deployment target, but it is not configured yet. No deployment workflow, secrets, or environment wiring is committed here.

## Notes
- This repository intentionally stays generic until the official challenge is released.
- The final problem statement, architecture, and demo path will be updated after scope is frozen.
