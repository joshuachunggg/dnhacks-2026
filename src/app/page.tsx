const fixtureCards = [
  {
    title: 'modern 200 A',
    summary: 'Likely a straightforward hardwired install with a 32 A default and a 48 A conditional option.',
  },
  {
    title: 'constrained 100 A',
    summary: 'Managed or lower-current charging stays in the story until load and electrician review are complete.',
  },
  {
    title: 'insufficient data',
    summary: 'The app should ask for the panel, route, and load data instead of guessing.',
  },
];

export default function Home() {
  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(244,114,182,0.12),_transparent_28%),linear-gradient(180deg,#fafafa_0%,#ffffff_100%)] px-6 py-10 text-zinc-950">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-6">
        <section className="rounded-[2rem] border border-zinc-200 bg-white/90 p-8 shadow-[0_18px_50px_rgba(15,23,42,0.08)] backdrop-blur">
          <p className="text-sm font-semibold uppercase tracking-[0.28em] text-zinc-500">DNHacks 2026</p>
          <div className="mt-4 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-3xl">
              <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">SiteGraph v0 for residential EV charger assessment</h1>
              <p className="mt-4 max-w-2xl text-lg leading-8 text-zinc-600">
                A phone captures observations, the agent asks for missing facts, and deterministic tools explain
                charger feasibility, route complexity, and cost without pretending the model is the source of truth.
              </p>
            </div>
            <div className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
              <div className="font-semibold">Assessment</div>
              <div className="mt-1">Fixture-first, live-slice next</div>
            </div>
          </div>
        </section>

        <section className="grid gap-4 lg:grid-cols-3">
          {fixtureCards.map((card) => (
            <article key={card.title} className="rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-[0.22em] text-zinc-500">Golden fixture</p>
              <h2 className="mt-3 text-2xl font-semibold tracking-tight">{card.title}</h2>
              <p className="mt-3 text-sm leading-7 text-zinc-600">{card.summary}</p>
            </article>
          ))}
        </section>

        <section className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
          <article className="rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold uppercase tracking-[0.22em] text-zinc-500">Current focus</p>
            <ul className="mt-4 space-y-3 text-sm leading-7 text-zinc-700">
              <li>• Validate the canonical fixture in TypeScript and Swift.</li>
              <li>• Wire one observation through capture, validation, persistence, and render.</li>
              <li>• Keep source-backed facts separate from inference and assumptions.</li>
              <li>• Add the first backend and iOS lanes once contracts are stable.</li>
            </ul>
          </article>

          <article className="rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold uppercase tracking-[0.22em] text-zinc-500">Quick checks</p>
            <div className="mt-4 space-y-3 text-sm text-zinc-700">
              <p><span className="font-medium text-zinc-950">Fixture set:</span> modern 200 A, constrained 100 A, insufficient data</p>
              <p><span className="font-medium text-zinc-950">Schema:</span> SiteGraph v0</p>
              <p><span className="font-medium text-zinc-950">Validation:</span> pnpm smoke, pnpm fixtures:check, pnpm swift:check</p>
            </div>
          </article>
        </section>
      </div>
    </main>
  );
}
