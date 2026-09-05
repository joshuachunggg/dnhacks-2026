# Judge checklist and Q&A

Use with the full rehearsal in [`../docs/DEMO.md`](../docs/DEMO.md).

## Preflight

- [ ] Reset/reload the bundled modern fixture through the implemented two-step control.
- [ ] Keep modern, constrained, and insufficient-data artifacts open in known order.
- [ ] Label the mode accurately: native fixture shell, validated observation round trip, or artifact fallback.
- [ ] Keep source type, status, confidence, evidence IDs, assumptions, warnings, and professional-verification requirements visible.
- [ ] Rehearse network failure by retaining the local fixture after the live-observation control reports an error.
- [ ] Rehearse unavailable capture as a disclosed fixture path; do not fake a capture attempt.
- [ ] Do not give consumers instructions to open panels, touch wiring, bypass permitting, or perform electrical work.

## Claim boundaries

| Claim | Accurate answer |
| --- | --- |
| What works now? | The native shell renders the bundled modern fixture. A physical iPhone has documented one validated panel-label observation round trip to the local API. |
| Is capture live? | No. Capture is not implemented in this shell. |
| Are engineering and cost results live? | No. They are seeded fixture outputs in this rehearsal; their API/iPhone integration remains required. |
| Is the older-home or missing-data path in the app? | No. Both are disclosed rehearsal artifacts until fixture selection/import is integrated. |
| What happens on network failure? | The live-observation control keeps the bundled fixture available; continue in labeled fixture fallback. |
| What happens with too little evidence? | Show `insufficient_data`, name the missing structured facts, and do not invent feasibility or price. |
| Is this electrical approval? | No. Final decisions require a licensed electrician or AHJ. |

## Provenance prompts

- **Observed/seeded:** panel and route facts identify source type, confidence, evidence IDs, producer, and assumptions.
- **User-supplied:** proposed charger location is marked `user_supplied` where applicable.
- **Calculated:** route estimates and scenario outputs are labeled calculated/tool output with explicit assumptions.
- **Still unresolved:** load calculation, conductor/breaker compatibility, service/panel confirmation, and permit/inspection path remain professional-verification-required.

## Never say

- “The app scanned the panel live” during this build.
- “The phone approved this charger” or “this is code compliant.”
- “The price is a quote.”
- “Open the panel / remove the cover / check the wires.”
