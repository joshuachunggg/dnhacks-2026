# iOS lane scaffold

This directory is the native SwiftUI assessment shell starting point.

## What is here
- `SiteGraphShellApp.swift` — SwiftUI app entry point
- `ContentView.swift` — four-tab guided demo shell
- `SiteGraphDemoState.swift` — fixture-backed SiteGraph v0 models and loader
- `Resources/modern-200a.json` — bundled seeded demo fixture

## Demo flow
- Site
- Panel
- Charger Location
- Results

The app starts with the bundled modern-200A fixture loaded, and the top card toggles between:
- `Reset demo` when seeded data is visible
- `Use demo data` when the demo has been cleared

## Status
- Seeded demo scaffold only
- No realtime, LiDAR, or live tool calls yet
- Keep this lane isolated from shared contracts until the native target is wired up

## Intended demo state
The first native shell should render a SiteGraph v0 assessment summary, including:
- assessment identity
- site and jurisdiction metadata
- panel facts with provenance labels
- charger location evidence and route measurement
- final results with unresolved items and installer handoff
