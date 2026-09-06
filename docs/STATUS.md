# Status

## Snapshot
- `main` includes the native iOS target and `origin` is configured.
- Current app shell is still the default Next.js scaffold, but the repo docs now reflect the real DNHacks thesis.
- Shared contract work is moving to SiteGraph v0 plus golden fixtures.
- The iOS shell is an iOS 17+ SwiftUI target with a four-screen seeded demo. A physical iPhone has submitted and rendered one validated observation through the local backend API.
- The backend provides an in-memory validated state boundary plus deterministic engineering and cost tool endpoints. A live local HTTP run created the modern fixture assessment, persisted canonical engineering and cost outputs, and returned the expected fixture-scoped cost scenario.
- The iOS shell creates the seeded assessment, runs engineering then cost against the configured server, renders returned provenance, requirements, installer handoff, and explicit cost-range status, and retains visible fixture fallback. The iPhone 17 Pro simulator build passes; this updated flow is not yet accepted on a physical device.

## Completed
- Inspected Git state, branch, remote, and toolchain availability.
- Confirmed the repo is already initialized and connected to GitHub.
- Updated the repo front door and operating docs.
- Added the plan, architecture, contracts, decisions, safety, and handoff scaffolding.
- Added SiteGraph v0 schemas and three golden fixtures.
- Verified TypeScript and Swift can decode the canonical fixture.
- Scaffolded the iOS lane with a native SwiftUI starter state.
- Added `apps/ios/SiteGraphShell.xcodeproj`, the `SiteGraphShell` scheme, and wired the SwiftUI scaffold into the target.
- Verified the native scaffold runs on a physical iPhone.
- Added the bundled modern-200A fixture, local Swift decoder, four-tab assessment demo, reset/reload control, and fixture-backed results/handoff display.
- Scaffolded the backend lane with a typed placeholder manifest and draft envelope.
- Scaffolded the demo lane with seeded fallback assets and reset notes.
- Added the Austin/Austin Energy source card and cost anchor notes in `research/`.
- Fixed the pnpm workspace build-approval placeholder so `pnpm check` can run.
- Added a Zod-validated, in-memory assessment API: create, get, and append one `observation.added` event.
- Added the iOS live-round-trip control with a configurable server URL, explicit failure state, and fixture fallback preservation.
- Aligned the bundled iOS modern-200A fixture with the canonical schema and added a regression test for that boundary.
- Added the pure `runEngineeringScenario` contract with validated input/output, deterministic provenance, explicit insufficient-data handling, and fixture coverage for modern, constrained, and missing-data cases.
- Added the pure `runCostScenario` contract with Zod-validated results, source-limited Austin permit anchor provenance, fixture-scoped non-quote line items, route-sensitive range math, explicit insufficient-data and unpriced-upgrade states, and a safe deterministic application adapter.
- Added a backward-compatible SiteGraph evidence registry and fixture records; deterministic engineering and cost calculations now require their panel/route evidence IDs to resolve in that registry.
- Added timestamp-safe engineering and cost endpoints. Each captures one request-time timestamp, passes it to calculation and application, persists atomically in the in-memory store, and rejects malformed tool bodies.
- Added native server-result rendering for engineering and cost, including provenance, requirements, handoff, disclaimer, `preliminary_range`, `partial_range`, and `insufficient_data` presentation.
- Added the first spatial vertical slice: native one-room RoomPlan capture, local USDZ export to app-support storage, SHA-256/byte-count artifact descriptors, and a visible local-only capture card.
- Replaced the RoomPlan preview's system Quick Look surface with an in-app SceneKit USDZ viewer: centered initial framing, rotate/pan/pinch controls, and explicit ambient/key/fill lighting against a dark background.
- Added typed spatial capture, measurement, and EVSE-confirmation events. The in-memory API validates and persists metadata manifests and associated evidence; it intentionally does not accept binary artifact data.
- Added request/persistence regression checks and a full API test for RoomPlan manifest plus confirmed spatial facts.
- Added typed visual-frame and proposed-spatial-object contracts, with a server persistence test that binds a locally retained panel JPEG evidence frame to a RoomPlan coordinate-space ID.
- Added a guarded, tested Realtime client-secret mint boundary. It requires `OPENAI_API_KEY` and a distinct `REALTIME_DEMO_TOKEN`; it returns only an ephemeral secret and hashes the assessment identifier into the OpenAI safety header.
- Added a native panel-photo evidence card. It can take a photo or select an existing image through the system photo picker, retains a JPEG locally, runs Vision rectangle detection, and posts frame evidence only after a RoomPlan scan establishes the coordinate-space ID. The Simulator build passes.
- Added direct Realtime voice transport: the phone mints an ephemeral secret through the local server, streams 24 kHz PCM microphone turns over its Realtime WebSocket connection, and plays returned Realtime PCM audio rather than using on-device speech recognition or text-to-speech. A live server mint was verified; native conversation, mic permission, panel-frame review, and RoomPlan concurrency remain physical-device acceptance work.
- Added a RoomPlan-gated full-screen spatial assistant. After a short room scan, users inspect the captured 3D model while talking to the Realtime guide, tap once to start voice input and again to stop, and switch to camera/upload capture only when photo evidence is requested. The photo follows the existing typed proposed-evidence and Realtime-image path. The iOS Simulator build passes; live camera, audio, and photo delivery still require physical-device acceptance.
- Simplified the mobile flow to Start → Capture → Results. The panel tab is removed; the live assistant carries editable address, vehicle, and charging-intent details into the Realtime mint request, uses the current demo LAN server default, and provides an explicit Finish & review action that disconnects the guide before deterministic engineering and cost execution.
- Added a typed Realtime consumer-capability policy. The conversation is open-ended, while the server instruction permits only a new Level 2 EV charger assessment and explicitly declines unsupported systems such as a Tesla Powerwall 3.
- Added a local-Mac RoomPlan backup slice. After a RoomPlan scan, iOS uploads the USDZ to the configured demo server, verifies the server-calculated byte length and SHA-256 against its phone copy, and then posts the metadata manifest with a `local-mac://` descriptor. The server atomically stores the bytes under ignored `data/spatial-artifacts/` by default (or `SPATIAL_ARTIFACTS_DIR`); it is not agent-readable or production storage.
- Verified the local HTTP acceptance sequence: create modern fixture → run engineering → run cost. The response contained canonical conditional engineering and cost ToolRuns and the fixture-scoped expected cost of $1,541.99.
- Pushed commit `2f9811c` to `origin/main`.

## Current work
- Validate the server-owned Realtime interview on the installed physical-device build. `LiveAssistantView` directly observes the nested Realtime client, scroll-follows streamed audio transcripts, and delays a typed camera request until the guide's response completes. The shared SceneKit room reference labels model-relative N/E/S/W axes, and the typed Realtime highlight tool can mark a requested general area. Those axes are RoomPlan-model-relative rather than compass-calibrated. The agent does not receive the USDZ or room geometry; it receives typed spatial-reference context and captured images only. Explicit user panel placement remains the next native capture slice.
- Validate the implemented RoomPlan scan/export/local-Mac-backup/metadata-post path on a physical device. Then add ARKit EVSE anchor/route capture, panel-image evidence, durable artifact uploads, and the guided capture-to-results UX described in [`SPATIAL-CAPTURE.md`](./SPATIAL-CAPTURE.md).

## Blockers
- The guarded OpenAI-backed client-secret mint was exercised successfully against local configuration. Live conversation acceptance still requires completing a physical-device turn.
- No live iPhone Realtime conversation or image-to-agent call has been exercised yet. The native client has regression checks for the lifecycle and typed panel-photo trigger, but mic permission, WebSocket connection, Realtime PCM audio, the Talk-to-Stop transition, disconnect cleanup, and image review require physical-device acceptance.
- `Joshua’s iPhone (26.6.1)` is connected and now has SiteGraph `0.1.0 (2)` installed, but no tool-triggered camera capture has yet been manually completed on that build.
- Assessment metadata lives only for the local server process lifetime. RoomPlan USDZ backups persist on this Mac's filesystem, but durable provider storage, retention policy, and authorized retrieval remain deferred.
- Jurisdiction data and non-government cost allowances are intentionally demo/fixture-scoped; live quotes and jurisdiction expansion remain out of scope.

## Next integration point
- Physically validate one iPhone RoomPlan scan → local-Mac USDZ backup → metadata manifest round trip, then add ARKit route capture and authorized durable retrieval without changing the frozen capture-manifest event.

## Demo readiness
- Status: partially ready
- Working: seeded assessment → validated local API → deterministic engineering and cost → native server-result rendering, plus a scripted fixture fallback. The local HTTP path and simulator build are verified.
- Not ready to claim: ARKit route capture, panel/vision evidence, updated physical-device RoomPlan backup acceptance, production artifact persistence/retrieval, Realtime conversation, or handoff export.
