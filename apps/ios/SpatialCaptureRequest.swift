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

struct VisualFrameRecordedEvent: Encodable {
    let eventId: String
    let eventName = "visual.frame.recorded"
    let timestamp: String
    let producer: String
    let schemaVersion = "0.1.0"
    let payload: VisualFramePayload
}

struct SpatialLocationConfirmedEvent: Encodable {
    let eventId: String
    let eventName = "spatial.location.confirmed"
    let timestamp: String
    let producer: String
    let schemaVersion = "0.1.0"
    let payload: SpatialLocationPayload
}

struct RouteWaypointsRecordedEvent: Encodable {
    let eventId: String
    let eventName = "route.waypoints.recorded"
    let timestamp: String
    let producer: String
    let schemaVersion = "0.1.0"
    let payload: RouteWaypointsPayload
}

struct PanelFactsConfirmedEvent: Encodable {
    let eventId: String
    let eventName = "panel.facts.confirmed"
    let timestamp: String
    let producer: String
    let schemaVersion = "0.1.0"
    let payload: PanelFactsPayload
}

struct SpatialPosition: Encodable { let x: Float; let y: Float; let z: Float }

struct SpatialLocationPayload: Encodable {
    let id: String; let kind: String; let label: String; let coordinateSpaceId: String
    let positionMeters: SpatialPosition; let surface: String
    let status = "confirmed"; let sourceType = "measured"; let evidenceIds: [String]
    let timestamp: String; let producer: String; let assumptions: [String]; let notes: [String]
}

struct RouteWaypointPayload: Encodable {
    let id: String; let sequence: Int; let coordinateSpaceId: String
    let positionMeters: SpatialPosition; let surface: String
    let status = "confirmed"; let sourceType = "measured"; let evidenceIds: [String]
    let timestamp: String; let producer: String; let assumptions: [String]; let notes: [String]
}

struct RouteWaypointsPayload: Encodable { let id: String; let waypoints: [RouteWaypointPayload] }

struct PanelFactPayload: Encodable {
    let id: String; let field: String; let value: Int; let unit: String?
    let status = "confirmed"; let sourceType = "user_supplied"; let evidenceIds: [String]
    let timestamp: String; let producer: String; let notes: [String]
}

struct PanelFactsPayload: Encodable { let panelId: String; let facts: [PanelFactPayload] }

struct SpatialCapturePayload: Codable {
    let id: String
    let kind: String
    let status: String
    let coordinateSpaceId: String
    let timestamp: String
    let producer: String
    let detectedObjectTypes: [RoomPlanObjectType]
    let artifacts: [SpatialArtifact]
    let evidence: [SpatialEvidence]

    init(
        id: String,
        kind: String = "roomplan_room",
        status: String = "confirmed",
        coordinateSpaceId: String,
        timestamp: String,
        producer: String,
        detectedObjectTypes: [RoomPlanObjectType],
        artifacts: [SpatialArtifact],
        evidence: [SpatialEvidence]
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.coordinateSpaceId = coordinateSpaceId
        self.timestamp = timestamp
        self.producer = producer
        self.detectedObjectTypes = detectedObjectTypes
        self.artifacts = artifacts
        self.evidence = evidence
    }
}

struct RoomPlanObjectType: Codable, Hashable, Identifiable {
    let category: String
    let count: Int

    var id: String { category }
}

struct VisualFramePayload: Encodable {
    let id: String
    let captureId: String?
    let coordinateSpaceId: String
    let timestamp: String
    let producer: String
    let artifact: SpatialArtifact
    let evidence: SpatialEvidence
}

struct SpatialArtifact: Codable {
    enum Kind: String, Codable {
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

struct SpatialEvidence: Codable {
    enum Kind: String, Codable {
        case roomModel = "room_model"
        case imageFrame = "image_frame"
    }

    let id: String
    let type: Kind
    let label: String
    let uri: String
}

enum SpatialCaptureRequestBuilder {
    static func eventRequest<Event: Encodable>(baseURL: URL, assessmentId: String, event: Event) throws -> URLRequest {
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

    static func artifactUploadRequest(baseURL: URL, assessmentId: String, artifact: SpatialArtifact) throws -> URLRequest {
        guard artifact.kind == .roomUSDZ else {
            throw NSError(domain: "SpatialCaptureRequest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Only RoomPlan USDZ artifacts can be uploaded to the local Mac."])
        }
        guard artifact.localFileURL != nil else {
            throw NSError(domain: "SpatialCaptureRequest", code: 2, userInfo: [NSLocalizedDescriptionKey: "The RoomPlan USDZ is not available on this device."])
        }

        var request = URLRequest(
            url: baseURL
                .appendingPathComponent("api/assessments")
                .appendingPathComponent(assessmentId)
                .appendingPathComponent("artifacts")
                .appendingPathComponent(artifact.id)
        )
        request.httpMethod = "POST"
        request.setValue(artifact.contentType, forHTTPHeaderField: "Content-Type")
        return request
    }

    static func artifactRestoreRequest(baseURL: URL, remoteURI: String) throws -> URLRequest {
        guard let remoteURL = URL(string: remoteURI), remoteURL.scheme == "local-mac", remoteURL.host == "artifacts" else {
            throw NSError(domain: "SpatialCaptureRequest", code: 3, userInfo: [NSLocalizedDescriptionKey: "The saved RoomPlan backup reference is invalid."])
        }
        let components = remoteURL.pathComponents.filter { $0 != "/" }
        guard components.count == 2, components[1].hasSuffix(".usdz") else {
            throw NSError(domain: "SpatialCaptureRequest", code: 4, userInfo: [NSLocalizedDescriptionKey: "The saved RoomPlan backup reference is incomplete."])
        }
        let assessmentId = components[0]
        let artifactId = String(components[1].dropLast(".usdz".count))
        guard !assessmentId.isEmpty, !artifactId.isEmpty else {
            throw NSError(domain: "SpatialCaptureRequest", code: 5, userInfo: [NSLocalizedDescriptionKey: "The saved RoomPlan backup reference is incomplete."])
        }
        return URLRequest(
            url: baseURL
                .appendingPathComponent("api/assessments")
                .appendingPathComponent(assessmentId)
                .appendingPathComponent("artifacts")
                .appendingPathComponent(artifactId)
        )
    }
}
