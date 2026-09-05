# Demo

## Objective
Show a live, believable end-to-end flow that turns a phone-based assessment into structured SiteGraph state, deterministic feasibility calculations, and an installer handoff.

## Exact demo story
1. Open the app on iPhone or the demo shell.
2. Start a new assessment.
3. Mark the proposed charger wall or location.
4. Capture the electrical panel or use the seeded fallback frame.
5. Let the app surface one or two visible observations with confidence and evidence.
6. Fill the structured form for vehicle and charging needs.
7. Run the deterministic charger / load / cost scenarios.
8. Show the results with clear pass / conditional / insufficient-data status.
9. Open the installer handoff view.
10. If live capture fails, switch to the disclosed fixture path and keep going.

## What must stay visible
- Proposed EVSE location.
- At least one evidence-backed observation.
- One measurement or route estimate.
- One deterministic engineering result.
- One cost range with line items.
- The status reason and unresolved questions.
- The fallback indicator when a fixture is used.

## Seeded demo data
- Modern 200 A home fixture.
- Constrained 100 A older home fixture.
- Insufficient-data fixture.
- One jurisdiction card fixture.
- One cost-rate assumption fixture.

## Failure ladder
1. Live phone capture.
2. Seeded fixture with the same schema.
3. Cached observation / assessment replay.
4. Screenshot or prerecorded walkthrough.

## Reset requirement
There should be a one-action reset that restores the seeded assessment and clears transient demo state.

## Judge Q&A
Be ready to answer:
- What facts were actually observed?
- Which values were user-supplied?
- Which outputs were calculated deterministically?
- What remains professional-verification-required?
- What happens when the house is older or constrained?
- What is the demo hiding, if anything?

## Anti-goals
- No fake scanning animation without typed state.
- No hardcoded final answer unrelated to the captured data.
- No hidden manual jump into the last screen.
- No claim that the app certifies electrical safety.
