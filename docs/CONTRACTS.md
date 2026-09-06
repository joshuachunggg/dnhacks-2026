# Contracts

## Canonical boundary
The shared contract for the hackathon is **SiteGraph v0**. Every other interface should feed it, read from it, or derive from it. The contract is intentionally small and extensible.

## Data model rules
Every significant field value should support:
- `value`
- `unit` when relevant
- `status`: `proposed | confirmed | contradicted | superseded | professionally_verified`
- `sourceType`: `measured | visually_observed | ocr_extracted | user_supplied | externally_retrieved | inferred | calculated | assumed | professionally_verified`
- `confidence` when applicable
- evidence references
- timestamp
- producer / tool / version
- notes / assumptions
- supersedes relation

`SiteGraph.evidence` is the backward-compatible evidence registry (`EvidenceRefSchema[]`, defaulting to `[]`). Facts used by deterministic calculators are usable only when every referenced `evidenceId` resolves to a registry record; a nonempty arbitrary ID is not evidence.

## TypeScript schema
Primary source lives in `packages/schemas/src/sitegraph.ts` and exports:
- `SiteGraphSchema`
- `SiteGraphV0`
- `ObservationSchema`
- `ObservationAddedEventSchema`
- `MeasurementSchema`
- `SpatialArtifactSchema`
- `SpatialCaptureSchema`
- `SpatialCaptureRecordedEventSchema`
- `VisualFrameSchema`
- `VisualFrameRecordedEventSchema`
- `SpatialObjectSchema`
- `SpatialObjectProposedEventSchema`
- `MeasurementRecordedEventSchema`
- `EvseLocationConfirmedEventSchema`
- `AssessmentEventSchema`
- `ToolRunSchema`
- `CostScenarioSchema`
- `AssessmentStatusSchema`

## Event contracts
Minimum events:
- `assessment.created`
- `assessment.loaded`
- `observation.added`
- `observation.confirmed`
- `observation.contradicted`
- `spatial.capture.recorded`
- `measurement.recorded`
- `evse_location.confirmed`
- `tool.run_requested`
- `tool.run_completed`
- `assessment.updated`
- `assessment.fallback_used`
- `assessment.finalized`

Event payloads should always include:
- `assessmentId`
- `eventId`
- `timestamp`
- `producer`
- `schemaVersion`
- `payload`

## Agent tool interface
The primary agent may call only typed tools:
- `captureAnchor` — record a proposed spatial anchor.
- `recordMeasurement` — store a spatial measurement.
- `addObservation` — add a visual / OCR / user observation.
- `requestStructuredForm` — open a resumable native form.
- `runEngineeringScenario` — execute deterministic charger/load rules.
- `runCostScenario` — compute line-item-based cost ranges.
- `fetchJurisdictionCard` — read the narrow demo-jurisdiction source fixture.
- `finalizeAssessment` — write the assessment result with status and handoff.

Each tool must return:
- `ok: true` with typed payload, or
- `ok: false` with `insufficient_data` / `validation_error` / `not_supported` / `needs_user_confirmation`.

## Deterministic engineering scenario v0
`apps/server/src/engineering-calculator.ts` exports the pure `runEngineeringScenario(input)` calculator and `EngineeringScenarioResultSchema`. The calculator parses SiteGraph v0 at entry and parses its result before return; it performs no I/O, timestamps, network calls, or state writes.

- Input: validated `SiteGraphV0`; no separate user/load input is accepted in this slice.
- Required facts: panel `serviceAmps`, `spareBreakerSpaces`, and a `route_length` measurement.
- Output: assessment status, current recommendation, missing-input list, unresolved and professional-verification requirements, installer handoff, validated `ToolRun` provenance, and the safety disclaimer.
- Missing required or unusable facts return `insufficient_data` with no current recommendation; they are never inferred. A fact is usable only when it is plausible, evidence-backed, not contradicted/superseded, and has an accepted status/source. Service-amperage plausibility uses a conservative 60 A lower bound; lower values require new service-amperage evidence. Route selection is first-in-array among usable positive `ft`/`feet` route measurements.
- Every complete deterministic feasibility result has assessment status `professional_verification_required`: true load calculation, breaker/conductor compatibility, and electrician review remain required. Its `ToolRun.resultStatus` is `conditional`, the closest permitted execution status—not an approval.
- `applyEngineeringScenario(graph, result, expectedCalculationTimestamp)` is a typed, validated, pure adapter. When supplied, the expected timestamp is trusted invocation context, not result-supplied provenance; application requires it to match both the result origin and ToolRun timestamp before canonical recomputation. The optional two-argument form remains only until the API integration passes the captured timestamp, so controlled non-epoch callers must use the third argument. It replaces the stable deterministic ToolRun by ID (so applying the same result is idempotent), replaces its deterministic engineering scenario, and updates `finalAssessment` in one returned validated graph. A result contains a typed snapshot plus SHA-256 fingerprint of the calculation-relevant panel and selected-route facts/evidence; application rejects stale results when those current graph inputs no longer match. Since `EngineeringScenario.status` does not permit `professional_verification_required`, it maps that assessment state to scenario `conditional` (or preserves `insufficient_data`).
- Tool provenance contains usable, registry-resolved panel and route evidence IDs, source/status in `inputSummary`, and an injected calculation timestamp (default is a deterministic epoch value), never the prior `finalAssessment.timestamp`.

## Deterministic cost scenario v0
`apps/server/src/cost-calculator.ts` exports pure `runCostScenario(input)` and `CostScenarioResultSchema`, plus `applyCostScenario(graph, result, expectedCalculationTimestamp)` for a later typed state boundary. Input and output are Zod-validated SiteGraph v0 values; the calculator performs no I/O, network calls, clock reads, or state writes.

- This demo contract only applies the Austin, TX source card in `research/SOURCES.md` when the jurisdiction AHJ is exactly `City of Austin`. It requires usable panel spare-space and positive feet-based route facts whose every evidence ID resolves in `graph.evidence`. Missing, contradicted, superseded, evidence-free, unknown/replaced-evidence, or out-of-boundary facts return `insufficient_data` with `total: null` and no numeric scenario; the calculator does not infer a price.
- For usable inputs, the range is the sum of explicit line-item low/expected/high values: fixture-scoped EVSE and route-install allowances plus the Austin $166.99 advisory residential-electric-fee anchor. Fixture allowances are expressly not vendor, contractor, or installer quotes. The Austin anchor is not EVSE-specific and requires AHJ confirmation.
- Any priced result remains `professional_verification_required` / `conditional`, not an approval. Permit scope/fee, inspection, equipment, routing, conductor/breaker, and electrician review remain open. Zero evidenced spare spaces produces only a `partial_range`: panel/subpanel/service-upgrade scope and cost are explicitly unknown and excluded, never silently included or quoted.
- Result provenance carries the source limitations, inputs/evidence, deterministic timestamp, typed snapshot, and SHA-256 fingerprint. `applyCostScenario(graph, result, expectedCalculationTimestamp)` requires supplied trusted invocation context to match both result timestamps before canonical recomputation; the two-argument compatibility form remains only until callers pass captured timestamps. It rejects assessment mismatch, stale inputs, timestamp changes, and schema-valid result tampering when given trusted context; it replaces only its stable ToolRun/scenario IDs, making a canonical duplicate application idempotent. An insufficient-data result records no synthetic zero-dollar scenario.

## API boundary
The current first server boundary accepts and returns only validated JSON:
- `POST /api/assessments`
- `GET /api/assessments/:id`
- `POST /api/assessments/:id/events`
- `POST /api/assessments/:id/artifacts/:artifactId`
- `POST /api/assessments/:id/tools/:toolName`

`POST /api/assessments/:id/events` accepts the validated `AssessmentEventSchema` union: `observation.added`, `spatial.capture.recorded`, `visual.frame.recorded`, `spatial.object.proposed`, `measurement.recorded`, and `evse_location.confirmed`. A spatial capture stores typed metadata only: capture identity, coordinate-space ID, producer/version, aggregated RoomPlan object categories/counts, and immutable artifact descriptors (kind, content type, byte length, SHA-256, and URI). Object categories are RoomPlan classifications, not electrically authoritative facts. A visual-frame event similarly records a panel-image descriptor and image-frame evidence; it never accepts image bytes. A proposed spatial object records a normalized image detection and a position in the RoomPlan coordinate space, but cannot become an authoritative engineering input until a separate user-confirmation flow is added. The server appends evidence references from capture/frame events and replaces same-ID captures, frames, objects, and measurements idempotently. It returns `400 validation_error` for malformed input or `404 assessment_not_found` for an unknown assessment.

`spatial.location.confirmed` persists a user-selected panel or EVSE pose with one coordinate space, status/source, and resolvable evidence IDs. `route.waypoints.recorded` persists at least two confirmed, evidence-backed user-selected waypoints in one coordinate space and deterministically records a linked `route_length` measurement in feet. `panel.facts.confirmed` records user confirmation of visible service amps, optional bus rating, and spare breaker spaces as individual evidence-linked facts, then updates the calculator-facing panel summary atomically. A panel image remains evidence rather than a trusted rating.

`POST /api/assessments/:id/assessment-gate` returns exactly one typed missing-input action until panel image, confirmed panel facts, confirmed panel/EVSE locations, and a derived feet-based route measurement are present and evidence-resolved. Only then does it invoke and persist the canonical deterministic engineering result, returning it with `finish_and_review`. Realtime receives this endpoint's typed payload through `check_mechanical_assessment_gate` and must explain only that result plus its next action.

An unavailable panel value may be retained as a clearly labeled planning approximation in a future UI, but it is not evidence-backed and must not satisfy the gate or unlock a deterministic feasibility recommendation. This preserves an approximate interview path without presenting a guessed electrical rating as an engineering fact.

`POST /api/assessments/:id/artifacts/:artifactId` accepts only one RoomPlan USDZ (`model/vnd.usdz+zip`) for an existing assessment, rejects empty or over-100 MiB bodies, computes its byte length and SHA-256 on the Mac, and atomically writes it to `data/spatial-artifacts/:assessmentId/:artifactId.usdz` by default (or `SPATIAL_ARTIFACTS_DIR`). It returns a server-owned `local-mac://` descriptor; iOS compares that digest and length with its retained phone copy before posting the metadata manifest. This is a trusted local-development/LAN backup boundary, not production authorization, public artifact hosting, or a Realtime agent retrieval surface.

## Realtime session boundary

`POST /api/realtime/session` mints a short-lived OpenAI Realtime client secret for an assessment. The phone supplies its `assessmentId`, a typed `assessmentContext` (`propertyAddress`, `vehicleIntent`, `chargingIntent`, and selected `assessmentFocus`), and a separate `REALTIME_DEMO_TOKEN`; the server requires that token plus `OPENAI_API_KEY`, hashes the assessment into `OpenAI-Safety-Identifier`, and returns only the ephemeral secret, expiry, and upstream session ID. The API key never reaches the iPhone. The minted session is constrained to `gpt-realtime-2.1-mini` and a direct PCM audio conversation. The session policy treats supplied context as known facts and must not ask the user to repeat them.

Conversation remains open-ended, but consumer capability is an explicit typed allowlist. `SupportedConsumerCapabilitySchema` permits `level_2_ev_charger` and `adjacent_room_expansion`. The room-expansion flow activates through `activate_adjacent_room_expansion_assessment`; it must ask about use, approvals, visible utilities/openings, and structural review before it may request a `candidate_opening` model placement. That placement only renders a user-selected conceptual opening: it is not a structural finding, demolition instruction, permit approval, or feasibility conclusion. A licensed structural professional and applicable permit authority must verify load-bearing conditions, utilities, and approvals before any removal. Unsupported requests, including a Tesla Powerwall 3 installation, must receive the fixed not-equipped-yet response and redirect only to a supported capability. A new consumer capability requires a schema value, reviewed typed tools/events, deterministic or validated implementation, and an instruction/test update before it is exposed.

The only client-native Realtime tool is `request_evidence_photo`. Its strict input is one of `electrical_panel`, `charger_location`, `route_obstacle`, or `equipment_nameplate` plus a concise reason. iOS validates the call, presents camera/upload capture, records typed visual evidence, sends a function-call result, and then requests the next Realtime response. The model must not claim a photo was captured until that result arrives.

This boundary is the future agent-tool read/write surface: agent tools must fetch the validated assessment and may submit only the same event union. Agent code cannot dereference a device-local or `local-mac://` artifact URI; a future authorized artifact-read adapter must resolve an opaque server-issued artifact reference before such bytes become tool-readable.

## Versioning
- `sitegraphVersion: 0.1.0`
- Breaking schema changes require a new version field and a decision log entry.
- Fixtures must pin the schema version they decode against.

## Fixture contract
Golden fixtures live under `packages/fixtures/sitegraph/` and must include:
- a modern 200 A home,
- a constrained 100 A older home,
- an insufficient-data case.

## Validation rule
No tool output may enter authoritative state without schema validation. If validation fails, the app should preserve the raw payload separately and surface the error state.
