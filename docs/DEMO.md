# Demo rehearsal

## Purpose and claim boundary

Show a structured **preliminary** EV-charger assessment: evidence and user input are kept separate, deterministic fixture outputs are visible, and the handoff states what an electrician or AHJ must still verify.

Do not describe this as a live end-to-end assessment. The native shell currently renders a bundled modern fixture and can submit one confirmed panel-label observation to the validated API. Live capture, Realtime orchestration, engineering-result API/iPhone rendering, separate cost-tool execution, persistence, and an exportable handoff still require integration. This rehearsal uses seeded SiteGraph v0 artifacts to demonstrate those intended result states without claiming they were computed in the phone during the presentation.

Safety language to read if asked: “This assessment is preliminary and based on visible evidence, user input, and deterministic checks. Final electrical decisions require a licensed electrician or the authority having jurisdiction.” Do not direct a consumer to open a panel, remove a dead front, touch wiring, bypass permitting, or perform electrical work.

## Fixtures and what each proves

| Path | Rehearsal use | Current availability | Required integration before a live claim |
| --- | --- | --- | --- |
| [`../demo/assets/seeded-assessment-modern-200a.json`](../demo/assets/seeded-assessment-modern-200a.json) | Primary 200 A modern-home story: 32 A preliminary option; 48 A conditional. | Bundled modern fixture is rendered by the native shell. A documented physical-iPhone round trip exists only for one panel-label observation. | Run and render the deterministic engineering result and cost tool through the API/iPhone flow. |
| [`../demo/assets/seeded-assessment-constrained-100a.json`](../demo/assets/seeded-assessment-constrained-100a.json) | Older 100 A / detached-garage contrast: constrained lower-current path; higher-power option is not recommended as-is. | Rehearsal artifact only; it is not selectable in the current native shell. | Fixture picker/import and result rendering in the app. |
| [`../demo/assets/seeded-assessment-insufficient-data.json`](../demo/assets/seeded-assessment-insufficient-data.json) | Honest missing-data outcome: no recommendation or invented price. | Rehearsal artifact only; it is not selectable in the current native shell. | Fixture picker/import and missing-data UI in the app. |

All three are seeded demo data, not field observations. Their source, status, evidence IDs, assumptions, and professional-verification requirements must remain visible in the narration.

## Reset before every run

1. Start on the native shell’s **Site** tab. If fixture data is visible, tap **Reset demo**, then **Use demo data**. This is the currently implemented reset/reload sequence for the bundled modern fixture; it is not a one-action restore.
2. Leave the shell on **Site** and clear the Server URL/status only if the network-failure branch was rehearsed. The local modern fixture must remain loaded before proceeding.
3. Keep the three files above open locally in this order: modern, constrained, insufficient-data. They are the disclosed artifact fallback; do not edit them during a run.
4. State the run mode before speaking: **native fixture shell**, **validated observation round trip**, or **artifact fallback**. Never call artifact fallback live capture or a live calculation.

The reset/reload control and local-fixture preservation are the only reset/fallback behavior currently implemented in the iOS shell. A one-action reset and in-app switching among all three fixtures are required integration work, not accepted device behavior.

## 4-minute primary rehearsal — modern 200 A

| Time | Presenter action | Say / show | Provenance boundary |
| --- | --- | --- | --- |
| 0:00 | Declare **native fixture shell** and open **Site**. | “This shell is reading a seeded SiteGraph assessment; the live capture and tool orchestration are not wired here yet.” Show assessment ID and jurisdiction. | Address/jurisdiction are seeded fixture fields, not current retrieval. |
| 0:25 | Open **Panel**. | Show Square D / QO, 200 A, 12 visible spare spaces, confidence, source types, and evidence IDs. “Visible spaces do not establish load capacity.” | Panel facts are proposed/visually observed or OCR-extracted fixture values. |
| 0:55 | Open **Charger Location**. | Show the user-supplied garage-west-wall anchor and 31 ft calculated route estimate. | Location is user-supplied; route is a calculated estimate with evidence and assumptions. |
| 1:20 | Open **Results**. | Compare the 32 A preliminary option with the conditional 48 A option. Point to the load-screen tool run, assumptions, warnings, and unresolved electrician checks. | Results are seeded deterministic-tool output; they are not computed by the current app session. |
| 1:55 | Show cost range and line items. | “This is a fixture-backed estimate, not a quote: $1,400–$3,200 with hardware and labor assumptions.” | Cost scenario is seeded; no separate live cost tool is integrated. |
| 2:20 | Show installer handoff. | Read the proposed wall, panel identity, best current demo option, and professional-verification items. | Handoff is seeded assessment content; export is not implemented. |
| 2:45 | Optionally use **Confirm panel label with live API** with a known reachable local server. | “This confirms one observation, reloads validated state, and is separate from capture or engineering execution.” | The verified path is one observation round trip only. |
| 3:15 | Return to Results. | Repeat the preliminary disclaimer and invite the constrained/missing-data contrasts. | Do not imply approval, certification, or device acceptance beyond the documented observation round trip. |

## Contrast rehearsals

### Constrained older home — 45 seconds

Open `seeded-assessment-constrained-100a.json` as a disclosed artifact, not in the native shell. Show the 100 A legacy panel, two visible spare spaces, 54 ft detached-garage route, and the different outcomes: lower-current/managed charging is conditional; 40 A is not recommended as-is. Say that panel age, true load calculation, routing, breaker selection, permitting, and electrician review remain unresolved. Do not diagnose the panel or suggest a homeowner inspect inside it.

### Insufficient data — 30 seconds

Open `seeded-assessment-insufficient-data.json` as a disclosed artifact. Show that panel/service facts, route measurement, and a confirmed location are absent. The correct result is `insufficient_data`: no charger recommendation and no credible price. Ask only for safe, structured follow-up information or a licensed-electrician review; do not improvise missing electrical facts.

## Failure branches

### Network failure while rehearsing the observation round trip

1. Stop after the app reports the error; do not retry repeatedly or replace the result with a claimed server response.
2. Say: “The live observation request is unavailable. The bundled fixture remains local, so I am continuing in disclosed fixture mode.”
3. Verify the modern fixture is still visible, then continue at **Panel** or **Results**.
4. If the local fixture itself cannot reload, switch to the open modern JSON artifact and label the remainder **artifact fallback**.

The current iOS control explicitly preserves the bundled fixture when the server is unreachable. That is a fallback for one observation round trip, not evidence that capture, engineering, or cost execution succeeded.

### Capture failure or unavailable capture

Live capture is not implemented in the current native shell. Do not stage a camera failure as if capture had run. Say: “Live capture is outside this build; I am using a disclosed seeded SiteGraph assessment.” Continue with the modern artifact, then the constrained or insufficient-data artifact as needed. Never substitute an unlabeled screenshot, fabricated observation, or a fake scanning animation.

## Judge Q&A provenance card

| Question | Answer from this rehearsal | Where to point |
| --- | --- | --- |
| What was observed? | In the seed, panel make/visible spaces and route evidence are labeled visual/OCR/measured with confidence and evidence IDs. In the currently integrated path, only one confirmed panel-label observation has a validated server round trip. | Panel fields/observations and `toolRuns` in the modern fixture. |
| What was user-supplied? | The proposed EVSE wall/location is user-supplied in the modern and constrained seeds. | `proposedEvseLocation.sourceType`. |
| What was calculated? | The seed includes route estimates and deterministic feasibility/cost outputs with assumptions and tool provenance. These outputs are fixture-backed in this rehearsal, not live API/iPhone calculations. | `measurements`, `engineeringScenarios`, `toolRuns`, and `costScenarios`. |
| What still needs a professional? | True load calculation, breaker/conductor compatibility, service/panel confirmation, routing, and permit/inspection path as applicable. | `finalAssessment.professionalVerificationItems` and unresolved requirements. |
| What changes for an older or constrained home? | The constrained fixture keeps the lower-current path conditional and rejects a 40 A option as-is; it does not certify capacity. | Constrained fixture scenarios and warnings. |
| What happens when data is missing? | The system returns `insufficient_data`, names what is missing, and does not invent a recommendation or cost. | Insufficient-data fixture. |
| What is hidden? | Live capture, Realtime, deterministic-result and cost-tool integration, persistence, multi-fixture selection, one-action reset, and handoff export are not complete. | This document’s availability table and the app’s fixture labels. |

## Rehearsal exit criteria

Before presenting, successfully perform the reset/reload sequence, read each fixture’s status and provenance labels aloud, rehearse both failure branches without claiming a live result, and answer the provenance card without using unsafe consumer instructions. Do not claim physical-device acceptance for any behavior except the separately documented native fixture shell and one validated observation round trip.
