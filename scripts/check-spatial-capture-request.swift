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
        print("Spatial capture request construction check passed.")
    }

    private static func XCTUnwrap<T>(_ value: T?) throws -> T {
        guard let value else { throw NSError(domain: "SpatialCaptureRequestCheck", code: 1) }
        return value
    }
}
