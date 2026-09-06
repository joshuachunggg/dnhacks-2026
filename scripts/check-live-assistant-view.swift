import Foundation

@main
struct LiveAssistantViewCheck {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sourceURL = root.appendingPathComponent("apps/ios/LiveAssistantView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        precondition(source.contains("AVCaptureVideoPreviewLayer"), "The live assistant must render a regular camera preview.")
        precondition(source.contains("AVCapturePhotoOutput"), "The live assistant must capture still evidence frames.")
        precondition(source.contains("startListening()"), "The live assistant must retain tap-to-talk Realtime input.")
        precondition(source.contains("finishListening()"), "The live assistant must commit a tap-to-stop Realtime turn.")
        precondition(source.contains("realtime.isListening ? \"Stop talking\" : (realtime.isGuideSpeaking ? \"Interrupt & talk\" : \"Talk\")"), "The Talk control must expose interruption while the guide is speaking.")
        precondition(source.contains("@ObservedObject private var realtime: RealtimeSessionClient"), "The Live Assistant must redraw immediately when Realtime connection, Talk, and camera-tool state changes.")
        precondition(source.contains("_realtime = ObservedObject(wrappedValue: viewModel.realtime)"), "The Live Assistant must subscribe to its view model's Realtime client.")
        precondition(source.contains("realtime.isConnecting ? \"Connecting…\""), "The Connect control must show an in-flight connection state.")
        precondition(source.contains(".disabled(realtime.isConnecting)"), "The Connect control must prevent overlapping connection attempts.")
        precondition(source.contains("recordPanelFrame"), "Captured photos must enter the typed panel-evidence path.")
        precondition(source.contains("ScrollViewReader"), "Long Realtime transcripts must remain scrollable while audio is streaming.")
        precondition(source.contains("live-response-end"), "Streaming transcripts must follow the newest spoken text.")
        precondition(source.contains("hasSpatialCapture"), "The live assistant must require a completed RoomPlan capture.")
        precondition(source.contains("AssessmentDetailsSheet"), "The live assistant must expose editable typed assessment details.")
        precondition(!source.contains("PanelFactConfirmationForm"), "Panel facts must be collected conversationally; do not render a manual text-entry form.")
        precondition(source.contains("recordPanelFact"), "The live assistant must persist agent-confirmed panel facts through the typed evidence path.")
        precondition(source.contains("recordSpatialPlacement"), "Selected panel and EVSE locations must be durably recorded before returning to the guide.")
        precondition(source.contains("previewSpatialPlacement"), "Selected panel and EVSE locations must render locally before the asynchronous save completes.")
        precondition(source.contains("recordRouteWaypoints"), "Selected route points must be durably recorded before returning to the guide.")
        precondition(source.contains("Finish route (\\(realtime.routeWaypointCount) points)"), "The live assistant must let the user finish a custom multi-point route.")
        precondition(source.contains("spatialVisuals: viewModel.spatialVisuals"), "The room model must receive the persisted conceptual panel, EVSE, and route references.")
        let roomModelSource = try String(contentsOf: root.appendingPathComponent("apps/ios/RoomModelQuickLookPreview.swift"), encoding: .utf8)
        precondition(roomModelSource.contains("worldPrismNode"), "Panel and EVSE must use the same SceneKit world-coordinate path as route waypoints.")
        precondition(roomModelSource.contains("placementPreviews"), "Panel and EVSE world prisms must remain visible together after consecutive placements.")
        precondition(!roomModelSource.contains("showPlacementBadge"), "Panel and EVSE markers must not be screen overlays.")
        precondition(source.contains("candidateOpeningPose"), "The live assistant must render a user-selected conceptual room-opening reference.")
        precondition(source.contains(".allowsHitTesting(realtime.spatialPlacementRequest == nil)"), "Placement mode must let the user tap the complete SceneKit canvas without transcript controls intercepting the touch.")
        precondition(source.contains("Close live assistant"), "The live assistant must retain its explicit close button.")
        precondition(source.contains("Finish and review"), "The live assistant must provide an explicit deterministic assessment completion action.")
        precondition(source.contains("guard await viewModel.runEngineeringScenario() else { return }"), "Finish and review must remain blocked until the deterministic assessment gate is ready.")
        print("Live assistant camera and Realtime composition check passed.")
    }
}
