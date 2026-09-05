# Architecture

**Status:** active scaffold
**Last updated:** 2026-09-05

## System shape

```mermaid
flowchart LR
  I[iPhone capture + voice] --> U[Guided assessment UI]
  U --> S[Validated SiteGraph]
  S --> A[Primary field-engineer agent]
  A --> T[Deterministic engineering tools]
  A --> C[Deterministic cost tools]
  T --> R[Assessment + handoff]
  C --> R
  R --> V[Native report / installer view]
```

## Boundaries
- **iPhone capture lane**: ARKit anchors, raycasts, route measurements, selected frames, Vision OCR, and user confirmation.
- **Agent lane**: conversation, tool choice, missing-data detection, and explanation.
- **Schema lane**: canonical SiteGraph types, enums, units, status, provenance, and validation.
- **Engineering lane**: deterministic charger sizing, service/load screening, and scenario selection.
- **Cost lane**: typed line items, range math, and assumptions.
- **Demo lane**: seeded property, fallback path, and judge-facing script.
- **Docs lane**: repo map, decisions, plan, safety, and status.

## Canonical state principles
- Every meaningful fact is stored as a typed record.
- Facts keep status, source type, confidence, evidence references, timestamps, producer, assumptions, and supersession links.
- Competing observations are preserved; they are not overwritten silently.
- The model may propose facts, but validated tools own authoritative calculations.
- Professional verification is explicit and distinct from model inference.

## SiteGraph v0
Minimum entities:
- site / property / jurisdiction
- spaces and surfaces
- electrical panel and service facts
- proposed EVSE location
- spatial anchors and measurements
- vehicle / charging requirements
- major household loads
- observations and evidence frames
- assumptions, conflicts, and unknowns
- engineering tool runs and results
- regulatory sources and applicability notes
- cost scenarios and line items
- final assessment and handoff payload

## Data flow
1. The user opens the native or web demo shell.
2. The app creates or loads an assessment.
3. Capture tools produce observations and evidence references.
4. Validation converts model output to typed state.
5. The agent sees missing data and asks for it in a structured way.
6. Deterministic tools compute charger, load, route, and cost outputs.
7. The app renders the assessment and installer handoff.
8. Fallback data keeps the narrative alive if live capture fails.

## Runtime boundaries
- **Next.js root app**: present demo surface and current status.
- **Future `apps/server`**: session state, tools, persistence, and API validation.
- **Future `apps/ios`**: capture, anchors, and mobile workflow.
- **`packages/schemas`**: shared Zod types and JSON fixtures.
- **`packages/fixtures`**: golden demo data.

## Reliability and fallback
- Seeded fixtures are the first backup.
- Deterministic tools should accept explicit insufficient-data results.
- OCR and voice should never directly write unchecked values into authoritative state.
- The demo must still tell the story if live voice, OCR, AR tracking, or network is flaky.

## Non-goals for the hackathon slice
- Nationwide code coverage.
- Production auth or billing.
- General multi-agent orchestration.
- Full-house reconstruction.
- VPP economics beyond schema extension points.
