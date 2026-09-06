import Foundation

@main
struct SpatialCaptureRequestCheck {
    static func main() throws {
        let event = SpatialCaptureEvent(
            eventId: "event-roomplan-captured",
            eventName: .captureRecorded,
            timestamp: "2026-09-05T14:00:00.000Z",
            producer: "ios-roomplan",
            payload: SpatialCapturePayload(
                id: "capture-garage-001",
                coordinateSpaceId: "roomplan-session-001",
                timestamp: "2026-09-05T14:00:00.000Z",
                producer: "ios-roomplan",
                detectedObjectTypes: [RoomPlanObjectType(category: "storage", count: 2)],
                artifacts: [SpatialArtifact(
                    id: "artifact-garage-usdz",
                    kind: .roomUSDZ,
                    uri: "file:///captures/capture-garage-001.usdz",
                    contentType: "model/vnd.usdz+zip",
                    byteLength: 2048,
                    sha256: String(repeating: "a", count: 64)
                )],
                evidence: [SpatialEvidence(
                    id: "evidence-garage-roomplan",
                    type: .roomModel,
                    label: "Garage RoomPlan capture",
                    uri: "file:///captures/capture-garage-001.usdz"
                )]
            )
        )

        let request = try SpatialCaptureRequestBuilder.eventRequest(
            baseURL: URL(string: "http://localhost:3000")!,
            assessmentId: "assessment-001",
            event: event
        )

        precondition(request.url?.absoluteString == "http://localhost:3000/api/assessments/assessment-001/events")
        precondition(request.httpMethod == "POST")
        precondition(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any]
        precondition(body?["eventName"] as? String == "spatial.capture.recorded")
        precondition(((body?["payload"] as? [String: Any])?["artifacts"] as? [[String: Any]])?.first?["kind"] as? String == "room_usdz")
        precondition(((body?["payload"] as? [String: Any])?["detectedObjectTypes"] as? [[String: Any]])?.first?["category"] as? String == "storage")

        let persistedPayload = try JSONDecoder().decode(SpatialCapturePayload.self, from: JSONEncoder().encode(event.payload))
        precondition(persistedPayload.id == "capture-garage-001")
        precondition(persistedPayload.artifacts.first?.localFileURL?.path == "/captures/capture-garage-001.usdz")

        let artifactUpload = try SpatialCaptureRequestBuilder.artifactUploadRequest(
            baseURL: URL(string: "http://localhost:3000")!,
            assessmentId: "assessment-001",
            artifact: event.payload.artifacts[0]
        )
        precondition(artifactUpload.url?.absoluteString == "http://localhost:3000/api/assessments/assessment-001/artifacts/artifact-garage-usdz")
        precondition(artifactUpload.httpMethod == "POST")
        precondition(artifactUpload.value(forHTTPHeaderField: "Content-Type") == "model/vnd.usdz+zip")

        let visualFrameEvent = VisualFrameRecordedEvent(
            eventId: "event-panel-frame-recorded",
            timestamp: "2026-09-05T14:03:00.000Z",
            producer: "ios-vision",
            payload: VisualFramePayload(
                id: "frame-panel-001",
                captureId: "capture-garage-001",
                coordinateSpaceId: "roomplan-session-001",
                timestamp: "2026-09-05T14:03:00.000Z",
                producer: "ios-vision",
                artifact: SpatialArtifact(
                    id: "artifact-panel-001",
                    kind: .panelImage,
                    uri: "file:///captures/panel-001.jpg",
                    contentType: "image/jpeg",
                    byteLength: 2048,
                    sha256: String(repeating: "b", count: 64)
                ),
                evidence: SpatialEvidence(
                    id: "evidence-panel-frame-001",
                    type: .imageFrame,
                    label: "Electrical panel frame",
                    uri: "file:///captures/panel-001.jpg"
                )
            )
        )
        let visualRequest = try SpatialCaptureRequestBuilder.eventRequest(
            baseURL: URL(string: "http://localhost:3000")!,
            assessmentId: "assessment-001",
            event: visualFrameEvent
        )
        let visualBody = try JSONSerialization.jsonObject(with: try XCTUnwrap(visualRequest.httpBody)) as? [String: Any]
        precondition(visualBody?["eventName"] as? String == "visual.frame.recorded")
        precondition(((visualBody?["payload"] as? [String: Any])?["artifact"] as? [String: Any])?["kind"] as? String == "panel_image")

        let stateURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("apps/ios/SiteGraphDemoState.swift")
        let stateSource = try String(contentsOf: stateURL, encoding: .utf8)
        guard let startRange = stateSource.range(of: "func startAssessmentFromAddress()"),
              let clearRange = stateSource.range(of: "private func clearAssessment()")
        else { preconditionFailure("The blank-assessment transition must remain explicit.") }
        let startAssessment = String(stateSource[startRange.lowerBound..<clearRange.lowerBound])
        precondition(!startAssessment.contains("latestSpatialCapture = nil"), "Starting an address-based assessment must retain the saved RoomPlan model.")
        precondition(startAssessment.contains("spatialCaptureAssessmentId = nil"), "Starting a new assessment must re-associate the retained RoomPlan capture with the new assessment.")
        precondition(stateSource.contains("syncSpatialCaptureIfNeeded"), "A retained RoomPlan model must be synced before evidence uses the new assessment.")
        print("Spatial capture request construction check passed.")
    }

    private static func XCTUnwrap<T>(_ value: T?) throws -> T {
        guard let value else { throw NSError(domain: "SpatialCaptureRequestCheck", code: 1) }
        return value
    }
}
