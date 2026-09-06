# Spatial Capture and Artifact Storage

**Status:** first vertical slice implemented on 2026-09-05. One-room RoomPlan capture exports a local USDZ, computes an integrity descriptor, copies the USDZ to the development Mac's local artifact directory, posts a validated metadata manifest to the in-memory assessment API, and opens the phone copy in an in-app SceneKit 3D viewer. ARKit anchors, route capture, panel capture, production artifact storage, and agent-readable retrieval remain unimplemented.

## Purpose

The live assessment must turn a user-guided capture of the relevant room, electrical panel, and proposed EVSE location into reviewable evidence. It must preserve the distinction between a raw capture, a proposed interpretation, a confirmed SiteGraph fact, and a deterministic engineering result.

The first live slice is intentionally one **relevant room or garage area**, not a whole-home reconstruction. It uses RoomPlan for room-scale geometry, ARKit for the EVSE anchor and route evidence, and a camera image for panel evidence. RoomPlan does not certify panel facts and does not replace a panel photo plus user confirmation.

## User experience

The native app is a guided workflow rather than four equal data tabs:

1. **Assessment home** — shows run mode (`live capture`, `seeded demo`, or `fallback`), the current outcome or next required action, and progress through the assessment.
2. **Capture space** — guides one RoomPlan scan, reports completion/failure, saves the spatial artifact, and opens an interactive SceneKit USDZ preview with centered rotation and pinch zoom for inspection.
3. **Live assistant** — opens only after the short RoomPlan scan. Its main canvas is the scanned room model while the user tap-starts/tap-stops a Realtime audio turn. Charger-specific fields and photo requests appear only after the guide has recognized the supported Level 2 EV-charger intent. Captured images use the existing proposed-evidence boundary and are sent to Realtime only after local evidence recording succeeds.
4. **Review and results** — after the user explicitly finishes the supported assessment, separates confirmed evidence, unresolved items, deterministic feasibility/cost scenarios, and electrician/AHJ verification requirements. Detailed IDs, raw tool runs, and provenance remain available behind a Details disclosure.

The primary action always advances the user to the next safe step. Fixture mode follows the same information architecture and explicitly labels that its data is seeded.

## Data model and storage boundary

Spatial data is stored in four layers. Large binary data never enters the SiteGraph JSON document or an in-memory assessment object.

| Layer | Contents | Authority and retention |
| --- | --- | --- |
| SiteGraph | Confirmed/proposed location, route measurement, observations, evidence IDs, provenance, and tool results | Canonical assessment state. Validated at the server boundary. |
| Capture manifest | `captureId`, `assessmentId`, artifact IDs/URIs, MIME type, byte size, SHA-256 hash, capture time, producer/version, coordinate-frame metadata, and lifecycle state | Validated metadata that binds SiteGraph evidence to stored artifacts. |
| Artifacts | Panel image, RoomPlan capture JSON/metadata, exported RoomPlan USDZ, optional preview image | Immutable binary/object storage addressed by artifact ID; never embedded in API responses. |
| Derived spatial evidence | EVSE anchor pose, route anchor/polyline references, normalized feet measurement, confidence, and assumptions | Typed SiteGraph facts linked to the capture manifest and requiring user confirmation before calculation. |

### Required artifact set for the first live room

- `roomplan_json` — RoomPlan serialized room data/metadata when available.
- `room_usdz` — exported room model for on-device preview and later handoff.
- `panel_image` — original captured panel frame.
- `room_preview` — optional generated thumbnail for fast UI display.

Each artifact reference must include an ID, content type, integrity hash, byte length, capture timestamp, producer/version, and access URI or opaque storage key. The manifest stores the capture coordinate-frame identifier so that an EVSE anchor and route evidence can be related to the correct scan. It must not claim that a RoomPlan model establishes electrical capacity or panel internals.

## Persistence strategy

1. **Implemented:** the iPhone writes the exported RoomPlan USDZ into its app-support directory, calculates SHA-256 and byte size, retains the local artifact, and uploads it to the configured Mac server after the assessment exists.
2. **Implemented:** the local Mac accepts only RoomPlan USDZ bytes for an existing assessment, recomputes SHA-256/byte size, atomically writes them under `data/spatial-artifacts/<assessmentId>/` (or `SPATIAL_ARTIFACTS_DIR`), and returns a `local-mac://` descriptor. The iPhone checks the returned descriptor before posting the capture manifest.
3. **Implemented:** the server validates and persists a compact capture manifest in the assessment's process-lifetime state. The manifest includes capture/coordinate-space identifiers and immutable artifact descriptors; it does not contain artifact bytes.
4. **Deferred:** after user approval, the phone uploads artifacts to an environment-configured durable object store through a server-issued upload contract.
5. **Deferred:** the iPhone deletes local originals only after confirmed durable upload; until then it retains a visible local-only state.

The process-lifetime assessment `Map` is not a home for spatial assets or durable canonical references. The current implementation stores raw RoomPlan bytes in a Mac-local directory and only validated metadata in that map. `local-mac://` identifies a development-machine copy but is neither a public URL nor agent-readable storage; introduce authenticated retrieval and a configured durable provider before making that claim.

## Contract requirements

The contract lane owns these additions before capture consumers start:

- **Implemented:** `SpatialCaptureManifest`/`SpatialArtifact` schemas (named `SpatialCaptureSchema`/`SpatialArtifactSchema` in code).
- **Implemented:** validated events for `spatial.capture.recorded`, `measurement.recorded`, and `evse_location.confirmed`.
- **Deferred:** a distinct `evse_location.proposed` event; proposed locations remain the existing SiteGraph state until the user submits the confirmation event.
- A typed panel-image proposal result whose status remains `proposed` until a user action confirms it.
- Server-issued upload authorization/commit payloads that bind each artifact to one assessment and capture ID.
- Explicit error outcomes for unsupported device, denied camera access, RoomPlan failure, incomplete upload, invalid artifact metadata, stale capture, and network fallback.

Calculators consume only confirmed, plausible, evidence-resolved SiteGraph facts. Raw camera frames, RoomPlan geometry, and agent text cannot directly alter calculations.

## Implementation sequence and ownership

### Gate A — shared spatial contract

One owner updates SiteGraph schemas, validation fixtures, state-store operations, API tests, and artifact-store interface. A separate reviewer verifies normal, missing, repeated, stale, tampered, and evidence-free cases. This reviewed base is merged before consumers fan out.

### Wave B — parallel consumers

- **Artifact/server lane:** durable object-store adapter, upload/commit boundary, manifest persistence, retrieval authorization, and test provider.
- **RoomPlan/AR lane:** one-room RoomPlan capture, local JSON/USDZ export, EVSE anchor, route evidence, and local retry state. It owns new capture files, not the primary SwiftUI workflow file.
- **Panel/live-assistant lane:** regular camera preview, tap-to-talk Realtime controls, and reviewable proposed panel observation; no authoritative mutation before confirmation. It must not run concurrently with `RoomCaptureView`, which owns the short RoomPlan scan's camera/AR session.
- **Guided UX lane:** assessment home, progress state, mode labels, review/confirmation surfaces, fixture-equivalent flow, and compact room preview. It is the only lane modifying the main SwiftUI navigation composition.
- **Realtime lane:** server-owned one-question conversation against the frozen typed tools; it must use the same confirmation and fallback contract.
- **QA/rehearsal lane:** contract-derived tests, failure-mode rehearsal, fixture selection, and physical-device test script.

### Gate C — vertical acceptance

On a physical supported iPhone: capture one room → save/upload RoomPlan artifacts → capture one panel frame → place/confirm EVSE anchor → record/confirm a route measurement → run engineering and cost → render handoff. Verify the same assessment reopens with valid artifact references, and prove fixture fallback when capture, upload, or Realtime is unavailable.

## Non-goals

- Whole-house or multi-room reconstruction.
- Treating RoomPlan geometry as an electrical inspection or code approval.
- Automatic OCR/Vision writes to authoritative state.
- Public artifact URLs, production auth/billing, or nationwide jurisdiction data.
- Replacing the fixture fallback before the live capture path has physical-device acceptance.
