import Foundation

@main
struct RoomPlanCaptureCheck {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let captureSource = try String(
            contentsOf: root.appendingPathComponent("apps/ios/RoomPlanCaptureView.swift"),
            encoding: .utf8
        )
        let stateSource = try String(
            contentsOf: root.appendingPathComponent("apps/ios/SiteGraphDemoState.swift"),
            encoding: .utf8
        )
        let previewSource = try String(
            contentsOf: root.appendingPathComponent("apps/ios/RoomModelQuickLookPreview.swift"),
            encoding: .utf8
        )
        let appSource = try String(
            contentsOf: root.appendingPathComponent("apps/ios/SiteGraphShellApp.swift"),
            encoding: .utf8
        )
        let schemeSource = try String(
            contentsOf: root.appendingPathComponent("apps/ios/SiteGraphShell.xcodeproj/xcshareddata/xcschemes/SiteGraphShell.xcscheme"),
            encoding: .utf8
        )

        precondition(schemeSource.contains("key = \"MTL_DEBUG_LAYER\"\n            value = \"0\""), "The Debug Run scheme must disable Metal API Validation so Apple's RoomPlan RealityKit shader assertion cannot terminate a scan.")
        precondition(appSource.contains("setenv(\"MTL_DEBUG_LAYER\", \"0\", 1)"), "The app must disable Metal API Validation before SwiftUI creates RoomPlan, even when launched outside the shared Xcode Run scheme.")
        precondition(!captureSource.contains("startButton"), "Room capture must start automatically when its screen opens, not require a second start button.")
        precondition(captureSource.contains("override func viewDidAppear"), "Room capture must start only after its view is visible.")
        precondition(captureSource.contains("UIApplication.willResignActiveNotification"), "Room capture must release AR/camera ownership for every app interruption, not only backgrounding.")
        precondition(captureSource.contains("UIApplication.didBecomeActiveNotification"), "Room capture must restart after the app returns to the foreground.")
        precondition(captureSource.contains("UIApplication.shared.applicationState == .active"), "Room capture must not start an AR session while the app is inactive.")
        precondition(captureSource.contains("private var roomCaptureView: RoomCaptureView?"), "Room capture must not retain a RoomPlan renderer across an interrupted or completed scan.")
        precondition(captureSource.contains("private func releaseCaptureResources()"), "Room capture must explicitly release its RoomPlan/AR resources instead of relying on delayed sheet deallocation.")
        precondition(captureSource.contains("roomCaptureView.delegate = nil"), "Room capture teardown must detach the delegate before discarding an interrupted RoomPlan view.")
        precondition(captureSource.contains("roomCaptureView = nil"), "Room capture teardown must discard the previous RoomPlan view so a foreground restart uses a fresh AR session.")
        precondition(!captureSource.contains("statusLabel"), "Room capture must not place a status dialog over the scanned model; retain only the Finish room scan control.")
        precondition(captureSource.contains("RoomModelQuickLookPreview(modelURL: modelURL)"), "View 3D room model must use the SceneKit renderer shared with the live assistant so its camera and lighting behavior match.")
        precondition(captureSource.contains("presentationDragIndicator(.visible)"), "The passive room-model sheet must expose a clear pull-down dismissal handle.")
        precondition(captureSource.contains("isFinishingCapture = true\n        didStartCapture = false\n        stopButton.isEnabled = false\n        roomCaptureView?.captureSession.stop(pauseARSession: true)"), "A completed one-room scan must stop its AR session before the assistant opens a separate camera session.")
        precondition(captureSource.contains("let payload = try exportCapture(processedResult)\n            releaseCaptureResources()"), "A completed one-room scan must release its RoomPlan renderer after export instead of waiting for sheet deallocation.")
        let disappearanceHandler = captureSource.components(separatedBy: "override func viewWillDisappear").dropFirst().first?.components(separatedBy: "private func startCaptureIfVisible").first ?? ""
        precondition(!disappearanceHandler.contains("didDeliverResult = true"), "Temporary capture-view disappearance must pause the scan instead of permanently terminating it.")
        precondition(previewSource.contains("addModelRelativeWallLabels"), "The RoomPlan model must expose compact model-relative N/E/S/W references at its bounding-wall edges.")
        precondition(previewSource.contains("Model directions N/E/S/W • not compass"), "RoomPlan direction labels must explicitly state that they are not compass-calibrated.")
        precondition(!previewSource.contains("addLabel(text: highlight.label"), "Guide highlights must not render floating labels that obscure direct user placement.")
        precondition(previewSource.contains("spatialVisuals"), "The room preview must render conceptual spatial references from persisted user selections.")
        precondition(previewSource.contains("SCNBox"), "Panel and EVSE references must have three-dimensional enclosure geometry.")
        precondition(previewSource.contains("markerNormal"), "Panel and EVSE prisms must face outward toward the active camera even when a USDZ wall normal is reversed.")
        precondition(previewSource.contains("depth: 0.28"), "Panel and EVSE markers must use a visibly stand-off prism depth.")
        precondition(previewSource.contains("request.kind != .routePoint"), "A route placement request must remain active after its first tap so the user can select an end point.")
        precondition(previewSource.contains("SCNCylinder"), "The selected route must render as three-dimensional conduit geometry.")
        precondition(!previewSource.contains("showPlacementMarker"), "The preview must not show a preliminary yellow placement spot instead of the selected conceptual object.")
        precondition(captureSource.contains("presentationDragIndicator(.visible)"), "View 3D room model must expose the system pull-down dismissal handle.")
        precondition(stateSource.contains("saveSpatialCapture(SpatialCapturePayload(\n            id: capture.id,"), "Spatial capture synchronization must preserve the saved room capture payload.")
        precondition(stateSource.contains("resetVisuals: false"), "Synchronizing capture metadata must not erase panel, EVSE, or route visuals for the same scan.")
        precondition(previewSource.contains("modelBounds(in: scene)"), "The room model camera, lighting, and labels must frame imported USDZ geometry rather than the empty scene root.")
        precondition(previewSource.contains("defaultCameraController.target = center"), "Model camera controls must orbit the imported model's center, not the scene origin.")
        precondition(previewSource.contains("castsShadow = true"), "The shared SceneKit renderer must retain the live assistant's shadow-capable key light.")
        precondition(previewSource.contains("shadowRadius = 12"), "The shared SceneKit renderer must soften shadows instead of producing harsh model contrast.")
        precondition(previewSource.contains("positionWallMountedPreview"), "Immediate panel and EVSE placement previews must use the same wall-mounted geometry positioning as saved markers.")
        precondition(previewSource.contains("wallNormal = SCNVector3(normal.x >= 0 ? 1 : -1, 0, 0)"), "Wall-mounted markers must snap their yaw to a model-relative wall axis rather than follow uneven USDZ triangle normals.")
        precondition(previewSource.contains("labelRadius"), "Model-relative direction labels must sit outside the room radius on the floor plane.")
        precondition(previewSource.contains("SCNVector3(center.x + labelRadius, floorY, center.z)"), "North must use the +X model wall after the corrected room-axis mapping.")
        print("RoomPlan capture lifecycle and orientation UI check passed.")
    }
}
