import Foundation

struct SpatialCaptureEvent: Encodable {
    enum EventName: String, Encodable {
        case captureRecorded = "spatial.capture.recorded"
    }

    let eventId: String
    let eventName: EventName
    let timestamp: String
    let producer: String
    let schemaVersion = "0.1.0"
    let payload: SpatialCapturePayload
}

struct SpatialCapturePayload: Encodable {
    let id: String
    let kind = "roomplan_room"
    let status = "confirmed"
    let coordinateSpaceId: String
    let timestamp: String
    let producer: String
    let artifacts: [SpatialArtifact]
    let evidence: [SpatialEvidence]
}

struct SpatialArtifact: Encodable {
    enum Kind: String, Encodable {
        case roomPlanJSON = "roomplan_json"
        case roomUSDZ = "room_usdz"
        case panelImage = "panel_image"
        case roomPreview = "room_preview"
    }

    let id: String
    let kind: Kind
    let uri: String
    let contentType: String
    let byteLength: Int
    let sha256: String

    var localFileURL: URL? {
        guard let url = URL(string: uri), url.isFileURL else { return nil }
        return url
    }
}

struct SpatialEvidence: Encodable {
    enum Kind: String, Encodable {
        case roomModel = "room_model"
    }

    let id: String
    let type: Kind
    let label: String
    let uri: String
}

enum SpatialCaptureRequestBuilder {
    static func eventRequest(baseURL: URL, assessmentId: String, event: SpatialCaptureEvent) throws -> URLRequest {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let body = try encoder.encode(event)

        var request = URLRequest(
            url: baseURL
                .appendingPathComponent("api/assessments")
                .appendingPathComponent(assessmentId)
                .appendingPathComponent("events")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
}
