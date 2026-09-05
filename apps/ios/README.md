# iOS lane scaffold

This directory is the native SwiftUI assessment shell starting point.

## What is here
- `SiteGraphShellApp.swift` — SwiftUI app entry point
- `ContentView.swift` — scaffold landing screen for the native shell
- `SiteGraphDemoState.swift` — tiny demo-state model/view model for SiteGraph v0

## Status
- Scaffold only
- No Xcode project exists yet, so this lane is not buildable as-is
- Keep this lane isolated from shared contracts until the native target is wired up

## Intended demo state
The first native shell should render a SiteGraph v0 assessment summary, including:
- assessment identity
- site and jurisdiction metadata
- panel status
- a short list of unresolved items for the assessment operator
