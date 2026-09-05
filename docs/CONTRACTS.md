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

## API boundary
The first server boundary should accept and return only validated JSON:
- `POST /api/assessments`
- `GET /api/assessments/:id`
- `POST /api/assessments/:id/events`
- `POST /api/assessments/:id/tools/:toolName`

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
