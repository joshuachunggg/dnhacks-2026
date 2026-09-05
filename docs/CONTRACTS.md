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

## TypeScript schema
Primary source lives in `packages/schemas/src/sitegraph.ts` and exports:
- `SiteGraphSchema`
- `SiteGraphV0`
- `ObservationSchema`
- `ObservationAddedEventSchema`
- `MeasurementSchema`
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
- `measurement.recorded`
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
- `applyEngineeringScenario(graph, result)` is a typed, validated, pure adapter. It replaces the stable deterministic ToolRun by ID (so applying the same result is idempotent), replaces its deterministic engineering scenario, and updates `finalAssessment` in one returned validated graph. A result contains a typed snapshot plus SHA-256 fingerprint of the calculation-relevant panel and selected-route facts/evidence; application rejects stale results when those current graph inputs no longer match. Since `EngineeringScenario.status` does not permit `professional_verification_required`, it maps that assessment state to scenario `conditional` (or preserves `insufficient_data`).
- Tool provenance contains usable panel and route evidence IDs, source/status in `inputSummary`, and an injected calculation timestamp (default is a deterministic epoch value), never the prior `finalAssessment.timestamp`.

## API boundary
The current first server boundary accepts and returns only validated JSON:
- `POST /api/assessments`
- `GET /api/assessments/:id`
- `POST /api/assessments/:id/events`
- `POST /api/assessments/:id/tools/:toolName`

`POST /api/assessments/:id/events` currently accepts only `ObservationAddedEventSchema` (`eventName: "observation.added"`). It validates before appending the observation and returns `400 validation_error` for malformed input or `404 assessment_not_found` for an unknown assessment.

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
