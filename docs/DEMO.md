# Demo

## Objective
Show a live, believable end-to-end flow that turns a phone-based survey into a structured retrofit proposal.

## Tentative 90-second happy path
1. Open the mobile web app.
2. Start the survey.
3. Show or upload a water-heater image.
4. Receive a structured equipment identification.
5. Provide or show electrical-panel context.
6. Generate a retrofit assessment.
7. Adjust one assumption in the interactive proposal.
8. Show the updated cost, savings, and grid-flexibility result.

## What must be live
- The browser app shell.
- The survey entry point.
- The structured observation handoff.
- The proposal view and assumption update path.
- The visible error state if a live step fails.

## What may use deterministic fixtures
- Fixture images.
- Prerecorded voice or survey text.
- Cached sample observations.
- Cached deterministic calculator outputs.
- A prerecorded walkthrough as the final fallback.

## Definition of done
- The demo starts from a clean browser tab on mobile.
- The user can complete the survey path without a hidden manual reset.
- Every number shown to judges comes from a deterministic calculation or a clearly disclosed fixture.
- The proposal updates when one assumption changes.
- The fallback path is ready without editing code during the demo.

## Demo data / fixture checklist
- One water-heater image fixture.
- One electrical-panel context fixture.
- One cached observation payload.
- One cached proposal payload.
- One screenshot or prerecorded backup path.
- No copyrighted or secret material.

## Pre-demo checklist
- Environment variables are set.
- Deployment is reachable.
- Phone permissions are granted.
- Network is stable.
- Logging is visible.
- Backup assets are loaded.
- The demo browser tab is already open.

## Failure ladder
1. Try the live flow.
2. Retry once if the failure is transient.
3. Switch to fixture input.
4. Switch to the prerecorded walkthrough or screenshots.

Do not fake results. If a fixture is used, say so explicitly.

## Known risks
- Live image capture may fail on the device. Owner: @TBD
- The model step may return an invalid schema. Owner: @TBD
- Deterministic calculators may need one more input than expected. Owner: @TBD
- Deployment or network latency may slow the first load. Owner: @TBD

## Judge questions
Be ready to answer:
- What is actually happening under the hood?
- Which parts are model-driven?
- Which parts are deterministic?
- Where do assumptions come from?
- What is the latency budget?
- What are the limitations?
- What is the next production step?
