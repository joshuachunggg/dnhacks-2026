# Demo rehearsal

## Purpose and claim boundary

Show a structured **preliminary** EV-charger assessment: evidence and user input are kept separate, deterministic fixture outputs are visible, and the handoff states what an electrician or AHJ must still verify. A second live-assistant focus demonstrates a conceptual adjacent-room expansion: after a bounded interview, the user selects the divider wall and sees a conceptual opening on the captured model. It is not a structural finding, demolition instruction, permit approval, or feasibility conclusion; a licensed structural professional and the applicable permit authority must verify any removal. Unsupported consumer systems such as a Tesla Powerwall 3 remain declined.

Do not describe this as a live end-to-end field assessment. The native shell creates the bundled modern fixture assessment, runs deterministic engineering and cost tools through the validated API, and renders returned provenance, requirements, handoff, and cost status. The local HTTP sequence and simulator build are verified; this updated flow is not yet accepted on a physical device. RoomPlan capture, panel-photo selection, and direct Realtime PCM voice are implemented but still require physical-device acceptance; durable persistence and handoff export remain future work. This rehearsal uses seeded SiteGraph v0 artifacts and fixture-scoped assumptions; do not claim they are current field observations or quotes.

Safety language to read if asked: “This assessment is preliminary and based on visible evidence, user input, and deterministic checks. Final electrical decisions require a licensed electrician or the authority having jurisdiction.” Do not direct a consumer to open a panel, remove a dead front, touch wiring, bypass permitting, or perform electrical work.

### Adjacent-room expansion contrast — 45 seconds

Select **Adjacent-room expansion** in Live assistant details after scanning the two adjacent rooms in one capture. Ask how to make one room larger. The guide asks about intended use, permissions, visible utilities/openings, and whether a structural professional has reviewed the divider wall. When it requests a candidate opening, tap the divider wall: the 3D view draws an outlined opening and Results repeats the required structural and permit verification. Do not say that the scan establishes wall construction, load path, hidden utilities, demolition scope, or approval. This path compiles and has session-policy coverage; its live Realtime and physical-device acceptance remain pending.

## Fixtures and what each proves

| Path | Rehearsal use | Current availability | Required integration before a live claim |
| --- | --- | --- | --- |
| [`../demo/assets/seeded-assessment-modern-200a.json`](../demo/assets/seeded-assessment-modern-200a.json) | Primary 200 A modern-home story: 32 A preliminary option; 48 A conditional. | The native shell creates this fixture on the local API, runs engineering then cost, and renders the returned assessment. The path is HTTP- and simulator-verified. | Updated physical-device acceptance; live capture and Realtime remain separate work. |
| [`../demo/assets/seeded-assessment-constrained-100a.json`](../demo/assets/seeded-assessment-constrained-100a.json) | Older 100 A / detached-garage contrast: constrained lower-current path; higher-power option is not recommended as-is. | Rehearsal artifact only; it is not selectable in the current native shell. | Fixture picker/import and result rendering in the app. |
| [`../demo/assets/seeded-assessment-insufficient-data.json`](../demo/assets/seeded-assessment-insufficient-data.json) | Honest missing-data outcome: no recommendation or invented price. | Rehearsal artifact only; it is not selectable in the current native shell. | Fixture picker/import and missing-data UI in the app. |

All three are seeded demo data, not field observations. Their source, status, evidence IDs, assumptions, and professional-verification requirements must remain visible in the narration.

## Reset before every run

1. Start on the native shell’s **Site** tab and tap **Reset demo** to restore the bundled modern fixture and clear transient state.
2. Leave the shell on **Site** and clear the Server URL/status only if the network-failure branch was rehearsed. The local modern fixture must remain loaded before proceeding.
3. Keep the three files above open locally in this order: modern, constrained, insufficient-data. They are the disclosed artifact fallback; do not edit them during a run.
4. State the run mode before speaking: **native fixture shell**, **validated observation round trip**, or **artifact fallback**. Never call artifact fallback live capture or a live calculation.

One-action reset and local-fixture preservation are implemented for the modern fixture. In-app switching among all three fixtures remains integration work and is not accepted device behavior.

## 4-minute primary rehearsal — modern 200 A

| Time | Presenter action | Say / show | Provenance boundary |
| --- | --- | --- | --- |
| 0:00 | Declare **seeded live-tool demo** and open **Site**. | “This shell creates a seeded SiteGraph assessment, then runs deterministic engineering and cost tools on the local server. Live capture and Realtime are not wired here.” Show assessment ID and jurisdiction. | Address/jurisdiction are seeded fixture fields, not current retrieval. |
| 0:25 | Open **Panel**. | Show Square D / QO, 200 A, 12 visible spare spaces, confidence, source types, and evidence IDs. “Visible spaces do not establish load capacity.” | Panel facts are proposed/visually observed or OCR-extracted fixture values. |
| 0:55 | Open **Charger Location**. | Show the user-supplied garage-west-wall anchor and 31 ft calculated route estimate. | Location is user-supplied; route is a calculated estimate with evidence and assumptions. |
| 1:20 | Run the tool flow and open **Results**. | Compare the preliminary option with the conditional path. Point to the returned tool run, assumptions, warnings, and unresolved electrician checks. | Inputs are seeded; the result is calculated by the local server in this session. |
| 1:55 | Show cost range and line items. | “This is a fixture-scoped planning range, not a quote; panel or service upgrades are excluded if the range is partial.” | Cost is calculated by the local server from seeded fixture inputs; it is not a contractor quote. |
| 2:20 | Show installer handoff. | Read the proposed wall, panel identity, best current demo option, and professional-verification items. | Handoff is seeded assessment content; export is not implemented. |
| 2:45 | Point to tool provenance and local/fallback indicator. | “The calculations are server-side and deterministic; local intent is not used in the current calculator.” | Live capture and Realtime are not implied. |
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

The current iOS control explicitly preserves the bundled fixture when the server is unreachable. That is a disclosed fallback, not evidence that capture, engineering, or cost execution succeeded during that failed request.

### Capture failure or unavailable capture

Live capture is not implemented in the current native shell. Do not stage a camera failure as if capture had run. Say: “Live capture is outside this build; I am using a disclosed seeded SiteGraph assessment.” Continue with the modern artifact, then the constrained or insufficient-data artifact as needed. Never substitute an unlabeled screenshot, fabricated observation, or a fake scanning animation.

## Judge Q&A provenance card

| Question | Answer from this rehearsal | Where to point |
| --- | --- | --- |
| What was observed? | In the seed, panel make/visible spaces and route evidence are labeled visual/OCR/measured with confidence and evidence IDs. In the currently integrated path, only one confirmed panel-label observation has a validated server round trip. | Panel fields/observations and `toolRuns` in the modern fixture. |
| What was user-supplied? | The proposed EVSE wall/location is user-supplied in the modern and constrained seeds. | `proposedEvseLocation.sourceType`. |
| What was calculated? | The local server calculates deterministic feasibility and cost outputs from seeded SiteGraph inputs, with assumptions and tool provenance. | `measurements`, `engineeringScenarios`, `toolRuns`, and `costScenarios`. |
| What still needs a professional? | True load calculation, breaker/conductor compatibility, service/panel confirmation, routing, and permit/inspection path as applicable. | `finalAssessment.professionalVerificationItems` and unresolved requirements. |
| What changes for an older or constrained home? | The constrained fixture keeps the lower-current path conditional and rejects a 40 A option as-is; it does not certify capacity. | Constrained fixture scenarios and warnings. |
| What happens when data is missing? | The system returns `insufficient_data`, names what is missing, and does not invent a recommendation or cost. | Insufficient-data fixture. |
| Can it help with a Tesla Powerwall 3? | No. The current typed consumer capability is only a new Level 2 EV charger assessment. The agent says it is not equipped to help with that yet and redirects to the supported charger assessment. | Realtime session capability policy. |
| What is hidden? | Live capture, Realtime, persistence, multi-fixture selection, updated physical-device acceptance, and handoff export are not complete. | This document’s availability table and the app’s fixture labels. |

## Rehearsal exit criteria

Before presenting, successfully perform the reset/reload sequence, read each fixture’s status and provenance labels aloud, rehearse both failure branches without claiming a live result, and answer the provenance card without using unsafe consumer instructions. Do not claim physical-device acceptance for any behavior except the separately documented native fixture shell and one validated observation round trip.
