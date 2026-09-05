# Decisions

Append-only log template:
- ID: 0000
- Date: YYYY-MM-DD
- Status: tentative | reversible | locked
- Decision: ...
- Context: ...
- Reason: ...
- Consequences: ...
- Revisit trigger: ...

## Entries

### 0001
- ID: 0001
- Date: 2026-09-04
- Status: tentative
- Decision: Use TypeScript and Next.js as the default full-stack path.
- Context: The repo needs a fast hackathon scaffold with a browser-first demo.
- Reason: The team can move quickly with one typed codebase and a familiar App Router structure.
- Consequences: The first implementation path should stay within Next.js unless the prompt forces a change.
- Revisit trigger: The official challenge or required platform makes Next.js a bad fit.

### 0002
- ID: 0002
- Date: 2026-09-04
- Status: tentative
- Decision: Use pnpm as the package manager.
- Context: The scaffold needs a reproducible lockfile and fast installs.
- Reason: pnpm is already available and fits the intended workflow.
- Consequences: Scripts, install commands, and docs should stay pnpm-first.
- Revisit trigger: A challenge constraint or platform dependency requires another package manager.

### 0003
- ID: 0003
- Date: 2026-09-04
- Status: locked for this repository
- Decision: Hermes/Codex are development tools, not the shipped app backend.
- Context: The repo needs a clear boundary between build tooling and product runtime.
- Reason: It avoids confusing internal agent infrastructure with user-facing features.
- Consequences: Product code should not depend on Hermes internals at runtime.
- Revisit trigger: Only if the challenge explicitly asks for an agent-hosted product.

### 0004
- ID: 0004
- Date: 2026-09-04
- Status: tentative
- Decision: Use the OpenAI Agents SDK as the tentative in-app orchestration layer.
- Context: The concept may need a survey agent and tool calls.
- Reason: It is a plausible fit if the challenge expects structured agent orchestration.
- Consequences: The design should keep the orchestration layer swappable.
- Revisit trigger: The prompt suggests a simpler architecture or different agent framework.

### 0005
- ID: 0005
- Date: 2026-09-04
- Status: locked for the demo path
- Decision: Validate structured data with Zod between model and deterministic tools.
- Context: Model outputs need typed boundaries before calculations.
- Reason: It reduces ambiguity and makes failures visible.
- Consequences: Every boundary payload should have a schema and a rejected-path UI.
- Revisit trigger: None expected unless the challenge changes the I/O contract.

### 0006
- ID: 0006
- Date: 2026-09-04
- Status: locked for the demo path
- Decision: Use deterministic functions for cost, incentive, energy, and grid calculations.
- Context: Demo outputs must be repeatable and explainable.
- Reason: Deterministic tools are easier to debug, verify, and defend to judges.
- Consequences: Model calls can propose inputs, but calculators own the numbers.
- Revisit trigger: Only if an official API must supply the final calculation.

### 0007
- ID: 0007
- Date: 2026-09-04
- Status: tentative
- Decision: Build the interactive/generative UI with trusted React components, not MCP Apps or A2UI.
- Context: The repo needs a controllable demo surface.
- Reason: Custom React is easier to reason about and keeps the UX path explicit.
- Consequences: Do not add MCP Apps or A2UI unless the challenge creates a clear need.
- Revisit trigger: The prompt or judging criteria clearly favor one of those systems.

### 0008
- ID: 0008
- Date: 2026-09-04
- Status: locked
- Decision: Keep main deployable and isolate parallel work with branches/worktrees.
- Context: Two people need to move quickly without breaking each other.
- Reason: It reduces merge risk and keeps the demo path stable.
- Consequences: Substantial tasks should not share files without an explicit contract.
- Revisit trigger: None.

### 0009
- ID: 0009
- Date: 2026-09-04
- Status: locked
- Decision: Do not implement product-specific features before the hacking window.
- Context: This repo is still pre-hackathon preparation.
- Reason: The scope is not frozen yet, and premature feature work is likely waste.
- Consequences: Only documentation, workflow infrastructure, generic boilerplate, and harmless verification tooling belong here for now.
- Revisit trigger: The official challenge prompt is released and scope is frozen.

### 0010
- ID: 0010
- Date: 2026-09-05
- Status: locked for the demo path
- Decision: Make SiteGraph v0 the canonical shared state boundary.
- Context: The demo needs one typed state object that can survive camera, agent, and backend transitions.
- Reason: A single schema keeps the story legible and the contract testable.
- Consequences: Every lane should map into SiteGraph instead of inventing its own truth model.
- Revisit trigger: Only if the challenge mandates a different authoritative data model.

### 0011
- ID: 0011
- Date: 2026-09-05
- Status: reversible
- Decision: Add a minimal pnpm workspace scaffold with explicit future lanes.
- Context: The repo needs a place for iOS, backend, schemas, fixtures, and docs without moving the live app immediately.
- Reason: It preserves the current root app while creating a migration path for the larger build.
- Consequences: Future work can land in owned directories without colliding with the demo shell.
- Revisit trigger: If the workspace layout slows the demo path, collapse back to a flatter structure.

### 0012
- ID: 0012
- Date: 2026-09-05
- Status: locked for verification
- Decision: Verify the canonical fixture in both TypeScript and Swift.
- Context: The challenge asks for a shared contract that both languages can decode.
- Reason: Cross-language decoding catches schema drift early.
- Consequences: The repo should include a small TS check and a standalone Swift check script.
- Revisit trigger: None.

### 0013
- ID: 0013
- Date: 2026-09-05
- Status: locked for the demo path
- Decision: Use ARKit/LiDAR and camera/Vision on the iPhone, a server-owned OpenAI Agents SDK Realtime session for intelligence, and A2UI for agent-directed native forms and confirmations.
- Context: The demo must show real spatial and visual evidence while keeping the agent conversational and the UI safe across the network boundary.
- Reason: This preserves native capture quality, keeps API credentials and authoritative tools on the server, and constrains streamed UI to approved SwiftUI components.
- Consequences: Decision 0007 no longer excludes A2UI. Agent output may propose only validated A2UI surfaces and typed tool calls; it never emits arbitrary client code or writes unvalidated facts.
- Revisit trigger: The approved component catalog cannot express a required demo interaction, or Realtime cannot meet the demo's latency/reliability needs.

### 0014
- ID: 0014
- Date: 2026-09-05
- Status: locked for the demo path
- Decision: Keep the first engineering calculator pure and SiteGraph-only, with panel service size, spare breaker spaces, and route measurement as its required evidence.
- Context: The demo needs deterministic, inspectable feasibility guidance before API, iOS, Realtime, or cost integration.
- Reason: A small validated boundary makes missing evidence explicit and prevents the calculator from inventing residential electrical facts.
- Consequences: The calculator returns `insufficient_data` rather than a recommendation when those facts are absent; current recommendations stay preliminary and require professional verification.
- Revisit trigger: A validated load-inventory contract is added as a separate typed input.

### 0015
- ID: 0015
- Date: 2026-09-05
- Status: locked for the deterministic calculator boundary
- Decision: Use a SiteGraph evidence registry and invocation-captured timestamps for deterministic fact and result integrity.
- Context: Nonempty evidence IDs were not resolvable against shared state, and result provenance timestamps could otherwise validate each other without a trusted value.
- Reason: Registry resolution keeps valid non-fixture evidence extensible while rejecting unknown/replaced references; a trusted apply argument rejects both isolated and coordinated result-timestamp tampering.
- Consequences: Panel and route facts must resolve all evidence IDs in `graph.evidence`; non-epoch calculator callers must propagate their captured timestamp into the apply boundary.
- Revisit trigger: A signed evidence/provenance service replaces the in-graph registry or trusted invocation boundary.

### 0016
- ID: 0016
- Date: 2026-09-05
- Status: locked for the first live spatial slice
- Decision: Capture one relevant room or garage area with RoomPlan, retain its JSON/USDZ artifacts outside SiteGraph, and bind them to confirmed ARKit EVSE-anchor and route evidence through validated artifact manifests.
- Context: The fixture-based demo has no real spatial capture, 3D artifact, or durable artifact boundary, while the live demo needs reviewable room geometry without treating it as electrical proof.
- Reason: RoomPlan provides a credible room-scale spatial artifact; ARKit provides placement/measurement context; separating immutable binaries from typed SiteGraph facts keeps API payloads small, calculations reproducible, and provenance explicit.
- Consequences: The spatial contract must add capture manifests, artifact references, typed location/measurement events, and an artifact-store adapter before capture consumers start. Panel images and RoomPlan geometry remain proposed evidence until the user confirms the corresponding facts. Whole-house/multi-room reconstruction remains deferred.
- Revisit trigger: The supported device cannot produce a usable one-room capture within the demo time, or artifact upload materially threatens the fallback path.

### 0017
- ID: 0017
- Date: 2026-09-05
- Status: locked for the first RoomPlan implementation
- Decision: Persist RoomPlan USDZ artifacts locally on the iPhone and submit only their validated metadata manifest to the in-memory assessment API.
- Context: The first live spatial slice needs a real room model and an agent-compatible typed state boundary, but the backend has no durable object storage or authorized binary-upload mechanism.
- Reason: This proves the RoomPlan capture-to-contract path within the hackathon window without making false durability or remote-agent-readability claims.
- Consequences: `local://` artifact references are local-only; the server retains capture metadata, integrity information, and linked evidence but cannot serve model bytes. Durable upload and opaque server-readable references are required before an agent may inspect room geometry remotely.
- Revisit trigger: A durable artifact provider and server-issued upload/commit contract are configured and physically validated.
