# iOS lane scaffold

This directory is the native SwiftUI assessment shell starting point.

## What is here
- `SiteGraphShellApp.swift` — SwiftUI app entry point
- `ContentView.swift` — scaffold landing screen for the native shell
- `SiteGraphDemoState.swift` — tiny demo-state model/view model for SiteGraph v0

## Status
- Buildable SwiftUI target: `SiteGraphShell.xcodeproj`
- Target: `SiteGraphShell` (`com.dnhacks.sitegraphshell`), iOS 17+
- Keep this lane isolated from shared contracts until native integration is wired up

## Intended demo state
The first native shell should render a SiteGraph v0 assessment summary, including:
- assessment identity
- site and jurisdiction metadata
- panel status
- a short list of unresolved items for the assessment operator
