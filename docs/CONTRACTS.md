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
- `POST /api/assessments/:id/tools/:toolName`

`POST /api/assessments/:id/events` accepts the validated `AssessmentEventSchema` union: `observation.added`, `spatial.capture.recorded`, `measurement.recorded`, and `evse_location.confirmed`. A spatial capture stores typed metadata only: capture identity, coordinate-space ID, producer/version, and immutable artifact descriptors (kind, content type, byte length, SHA-256, and URI). It never accepts a binary artifact body. The server appends evidence references from the manifest, replaces spatial captures by stable ID, replaces measurements by stable ID, and replaces the proposed EVSE location only through the explicit confirmation event. It returns `400 validation_error` for malformed input or `404 assessment_not_found` for an unknown assessment.

This boundary is the future agent-tool read/write surface: agent tools must fetch the validated assessment and may submit only the same event union. Agent code cannot dereference a device-local artifact URI; a future durable artifact adapter must resolve an opaque server-issued artifact reference before such bytes become tool-readable.

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
