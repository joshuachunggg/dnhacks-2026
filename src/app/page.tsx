const assessmentSteps = [
  {
    number: '01',
    title: 'Capture the site',
    description: 'Start with the panel, proposed charger location, and a safe route observation.',
    detail: 'Inputs are labeled as observed, user-supplied, or still missing.',
  },
  {
    number: '02',
    title: 'Confirm the evidence',
    description: 'Review the facts that shape the assessment before asking for a recommendation.',
    detail: 'Panel capacity, available spaces, route distance, and source confidence stay visible.',
  },
  {
    number: '03',
    title: 'Run the assessment',
    description: 'Deterministic tools compare feasible charging options and a planning cost range.',
    detail: 'The agent explains the result; it does not invent electrical facts or calculations.',
  },
  {
    number: '04',
    title: 'Review the handoff',
    description: 'See the recommended path, open questions, and what a licensed electrician must verify.',
    detail: 'Every result remains a preliminary assessment, not an approval or a quote.',
  },
];

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
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(16,185,129,0.14),_transparent_30%),linear-gradient(180deg,#fafafa_0%,#ffffff_100%)] px-6 py-10 text-zinc-950">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-8">
        <section className="rounded-[2rem] border border-zinc-200 bg-white/90 p-8 shadow-[0_18px_50px_rgba(15,23,42,0.08)] backdrop-blur">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div className="max-w-3xl">
              <p className="text-sm font-semibold uppercase tracking-[0.28em] text-zinc-500">DNHacks 2026 · SiteGraph v0</p>
              <h1 className="mt-4 text-4xl font-semibold tracking-tight sm:text-5xl">A clear path to an EV charger assessment</h1>
              <p className="mt-4 max-w-2xl text-lg leading-8 text-zinc-600">
                Gather the site facts, validate what is known, run deterministic checks, then leave with a
                documented handoff for the electrician.
              </p>
            </div>
            <div className="shrink-0 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
              <div className="font-semibold">Start here</div>
              <div className="mt-1">Step 1 · capture the site</div>
            </div>
          </div>
        </section>

        <section aria-labelledby="assessment-path-heading">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.22em] text-emerald-700">Assessment path</p>
              <h2 id="assessment-path-heading" className="mt-2 text-3xl font-semibold tracking-tight">Follow the steps in order</h2>
            </div>
            <p className="text-sm text-zinc-500">Each step makes the next one more reliable.</p>
          </div>

          <ol className="mt-5 grid gap-4 lg:grid-cols-4">
            {assessmentSteps.map((step, index) => (
              <li key={step.number} className="relative">
                {index < assessmentSteps.length - 1 ? (
                  <div className="absolute left-[calc(50%+2rem)] right-[-1.1rem] top-8 hidden h-px bg-emerald-200 lg:block" aria-hidden="true" />
                ) : null}
                <article className="relative h-full rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
                  <div className="flex items-center justify-between gap-3">
                    <span className="flex size-11 items-center justify-center rounded-2xl bg-zinc-950 text-sm font-semibold text-white">{step.number}</span>
                    {index === 0 ? <span className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-800">Start</span> : null}
                  </div>
                  <h3 className="mt-6 text-xl font-semibold tracking-tight">{step.title}</h3>
                  <p className="mt-3 text-sm leading-7 text-zinc-600">{step.description}</p>
                  <p className="mt-4 border-t border-zinc-100 pt-4 text-xs leading-6 text-zinc-500">{step.detail}</p>
                </article>
              </li>
            ))}
          </ol>
        </section>

        <section className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
          <article className="rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold uppercase tracking-[0.22em] text-zinc-500">What the system checks</p>
            <ul className="mt-4 space-y-3 text-sm leading-7 text-zinc-700">
              <li>• The panel, proposed charger location, and route are collected as structured evidence.</li>
              <li>• Missing or uncertain facts remain visible instead of being filled in by the model.</li>
              <li>• Deterministic tools own feasibility and planning-range calculations.</li>
              <li>• The final handoff identifies the checks still reserved for a licensed electrician.</li>
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

        <section aria-labelledby="scenario-heading">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-[0.22em] text-zinc-500">Demo scenarios</p>
              <h2 id="scenario-heading" className="mt-2 text-2xl font-semibold tracking-tight">The same path handles different outcomes</h2>
            </div>
            <p className="text-sm text-zinc-500">Fixture-backed examples for the demo.</p>
          </div>
          <div className="mt-5 grid gap-4 lg:grid-cols-3">
            {fixtureCards.map((card) => (
              <article key={card.title} className="rounded-3xl border border-zinc-200 bg-white p-6 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-zinc-500">Golden fixture</p>
                <h3 className="mt-3 text-2xl font-semibold tracking-tight">{card.title}</h3>
                <p className="mt-3 text-sm leading-7 text-zinc-600">{card.summary}</p>
              </article>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
