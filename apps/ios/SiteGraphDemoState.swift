import Foundation
import SwiftUI

enum DemoValueStatus: String, Codable {
    case proposed
    case confirmed
    case contradicted
    case superseded
    case professionallyVerified = "professionally_verified"
    case calculated

    var displayName: String {
        humanized(rawValue)
    }
}

enum DemoSourceType: String, Codable {
    case measured
    case visuallyObserved = "visually_observed"
    case ocrExtracted = "ocr_extracted"
    case userSupplied = "user_supplied"
    case externallyRetrieved = "externally_retrieved"
    case inferred
    case calculated
    case assumed
    case professionallyVerified = "professionally_verified"

    var displayName: String {
        humanized(rawValue)
    }
}

enum DemoAssessmentStatus: String, Codable {
    case pass
    case conditional
    case insufficientData = "insufficient_data"
    case professionalVerificationRequired = "professional_verification_required"

    var displayName: String {
        humanized(rawValue)
    }
}

struct SiteGraphDemoSnapshot: Codable {
    let schemaVersion: String
    let assessmentId: String
    let site: DemoSite
    let proposedEvseLocation: DemoProposedEvseLocation
    let electricalPanel: DemoElectricalPanel
    let measurements: [DemoMeasurement]
    let observations: [DemoObservation]
    let engineeringScenarios: [DemoEngineeringScenario]
    let toolRuns: [DemoToolRun]
    let costScenarios: [DemoCostScenario]
    let finalAssessment: DemoFinalAssessment

    var sourceSummary: String {
        "Bundled fixture: modern-200a.json"
    }

    var storySummary: String {
        finalAssessment.summary
    }
}

struct DemoSite: Codable {
    let id: String
    let label: String
    let address: String
    let jurisdiction: DemoJurisdiction
    let utility: String?
}

struct DemoJurisdiction: Codable {
    let city: String
    let county: String
    let state: String
    let ahj: String
}

struct DemoProposedEvseLocation: Codable {
    let id: String
    let label: String
    let wall: String
    let status: DemoValueStatus
    let sourceType: DemoSourceType
    let confidence: Double?
    let evidenceIds: [String]
    let timestamp: String
    let producer: String
    let assumptions: [String]
    let notes: [String]
}

struct DemoElectricalPanel: Codable {
    let id: String
    let label: String
    let status: DemoValueStatus
    let sourceType: DemoSourceType
    let confidence: Double?
    let evidenceIds: [String]
    let timestamp: String
    let producer: String
    let manufacturer: String?
    let modelFamily: String?
    let serviceVoltage: Double?
    let serviceAmps: Int?
    let busRatingAmps: Int?
    let breakerSpaceCount: Int?
    let spareBreakerSpaces: Int?
    let visibleConditionNotes: [String]
    let assumptions: [String]
    let notes: [String]
}

struct DemoMeasurement: Codable, Identifiable {
    let id: String
    let kind: String
    let value: Double
    let unit: String
    let status: DemoValueStatus
    let sourceType: DemoSourceType
    let confidence: Double?
    let evidenceIds: [String]
    let timestamp: String
    let producer: String
    let assumptions: [String]
    let notes: [String]
}

struct DemoObservation: Codable, Identifiable {
    let id: String
    let kind: String
    let field: String
    let value: DemoObservationValue
    let unit: String?
    let status: DemoValueStatus
    let sourceType: DemoSourceType
    let confidence: Double?
    let evidenceIds: [String]
    let timestamp: String
    let producer: String
    let assumptions: [String]
    let notes: [String]
}

enum DemoObservationValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        if let number = try? container.decode(Double.self) {
            self = .number(number)
            return
        }
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported observation value")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .number(let number):
            try container.encode(number)
        case .bool(let bool):
            try container.encode(bool)
        }
    }

    var displayText: String {
        switch self {
        case .string(let string):
            return string
        case .number(let number):
            return number.formatted(.number.precision(.fractionLength(0...2)))
        case .bool(let bool):
            return bool ? "true" : "false"
        }
    }
}

struct DemoEngineeringScenario: Codable, Identifiable {
    let id: String
    let label: String
    let chargerCurrentAmps: Int?
    let status: String
    let resultSummary: String
    let requirements: [String]
    let warnings: [String]
    let assumptions: [String]
    let evidenceIds: [String]
    let timestamp: String
}

struct DemoToolRun: Codable, Identifiable {
    let id: String
    let toolName: String
    let version: String
    let inputSummary: String
    let resultStatus: String
    let warnings: [String]
    let assumptions: [String]
    let evidenceIds: [String]
    let output: [String: DemoJSONValue]
    let timestamp: String
}

enum DemoJSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([DemoJSONValue])
    case object([String: DemoJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([DemoJSONValue].self) { self = .array(value) }
        else if let value = try? container.decode([String: DemoJSONValue].self) { self = .object(value) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported tool output value") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    var stringArrayValue: [String]? {
        guard case .array(let values) = self else { return nil }
        return values.compactMap(\.stringValue)
    }
}

struct DemoCostScenario: Codable, Identifiable {
    let id: String
    let label: String
    let status: String
    let totalLow: Double
    let totalExpected: Double
    let totalHigh: Double
    let currency: String
    let lineItems: [DemoCostLineItem]
    let assumptions: [String]
    let warnings: [String]
    let evidenceIds: [String]
}

struct DemoCostLineItem: Codable, Identifiable {
    let id: String
    let label: String
    let quantity: Double
    let unit: String
    let low: Double
    let expected: Double
    let high: Double
    let currency: String
    let source: String
    let assumptions: [String]
}

struct DemoFinalAssessment: Codable {
    let status: DemoAssessmentStatus
    let summary: String
    let unresolvedRequirements: [String]
    let professionalVerificationItems: [String]
    let installerHandoff: DemoInstallerHandoff
    let timestamp: String
}

struct DemoInstallerHandoff: Codable {
    let title: String
    let bullets: [String]
}

@MainActor
final class SiteGraphDemoViewModel: ObservableObject {
    private static let demoServerBaseURL = "http://192.168.1.121:3000"
    let realtime = RealtimeSessionClient()
    @Published private(set) var snapshot: SiteGraphDemoSnapshot?
    @Published private(set) var loadError: String?
    @Published var serverBaseURL: String
    @Published var propertyAddress: String
    @Published var vehicleIntent: String
    @Published var chargingIntent: String
    @Published var realtimeDemoToken: String
    @Published private(set) var engineeringStatus = "Fixture fallback active. Connect a server to run the deterministic assessment."
    @Published private(set) var engineeringStatusIsError = false
    @Published private(set) var isRunningEngineeringScenario = false
    @Published private(set) var isUsingFixtureFallback = true
    @Published private(set) var spatialCaptureStatus = "Capture a room to add spatial metadata to the live assessment."
    @Published private(set) var visionStatus = "Capture a panel frame after scanning the room to create reviewable visual evidence."

    private let fixtureName = "modern-200a"
    private var fixtureData: Data?
    private var liveAssessmentId: String?
    private var latestSpatialCapture: SpatialCapturePayload?

    var roomModelURL: URL? {
        latestSpatialCapture?.artifacts.first(where: { $0.kind == .roomUSDZ })?.localFileURL
    }

    var spatialCapturePayload: SpatialCapturePayload? {
        latestSpatialCapture
    }

    var detectedRoomObjectTypes: [RoomPlanObjectType] {
        latestSpatialCapture?.detectedObjectTypes ?? []
    }
    private let defaults: UserDefaults
    private enum PreferenceKey {
        static let serverBaseURL = "engineering.serverBaseURL"
        static let realtimeDemoToken = "realtime.demoToken"
        static let latestSpatialCapture = "spatialCapture.latest.v1"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        serverBaseURL = defaults.string(forKey: PreferenceKey.serverBaseURL) ?? Self.demoServerBaseURL
        propertyAddress = ""
        vehicleIntent = ""
        chargingIntent = ""
        realtimeDemoToken = defaults.string(forKey: PreferenceKey.realtimeDemoToken) ?? ""
        latestSpatialCapture = Self.loadSavedSpatialCapture(from: defaults)
        clearAssessment()
    }

    var actionTitle: String { snapshot == nil ? "Load demo fixture" : "Clear assessment" }

    var hasSpatialCapture: Bool { latestSpatialCapture != nil }

    var actionSubtitle: String {
        snapshot == nil
            ? "Load the bundled modern-200A fixture only when you need the demo fallback."
            : "Remove the current assessment data and return to the blank start state."
    }

    func saveEngineeringIntent() {
        defaults.set(serverBaseURL, forKey: PreferenceKey.serverBaseURL)
        defaults.set(realtimeDemoToken, forKey: PreferenceKey.realtimeDemoToken)
    }

    func connectRealtime() async {
        guard let fixtureData, let baseURL = normalizedServerURL else {
            realtime.connectionFailed("Start an assessment and configure a reachable server before connecting the guide.")
            return
        }
        do {
            let assessmentId = try await ensureLiveAssessment(baseURL: baseURL, fixtureData: fixtureData)
            saveEngineeringIntent()
            let address = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            await realtime.connect(
                serverBaseURL: baseURL,
                demoToken: realtimeDemoToken,
                assessmentId: assessmentId,
                assessmentContext: RealtimeAssessmentContext(
                    propertyAddress: address.isEmpty ? snapshot?.site.address ?? "Not provided" : address,
                    vehicleIntent: vehicleIntent,
                    chargingIntent: chargingIntent
                )
            )
        } catch {
            realtime.connectionFailed("Could not prepare the live assessment: \(error.localizedDescription)")
        }
    }

    func toggleDemoFixture() {
        if snapshot == nil {
            loadSeededAssessment()
            return
        }
        clearAssessment()
    }

    func startAssessmentFromAddress() {
        let address = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            loadError = "Enter the property address before starting an assessment."
            return
        }
        do {
            let data = try Self.blankAssessmentData(address: address)
            snapshot = try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: data)
            fixtureData = data
            loadError = nil
            liveAssessmentId = nil
            latestSpatialCapture = nil
            isUsingFixtureFallback = false
            engineeringStatus = "Property address recorded as user-supplied. Capture the room and panel before requesting an assessment."
            engineeringStatusIsError = false
            saveEngineeringIntent()
        } catch {
            loadError = "Could not start a blank assessment: \(error.localizedDescription)"
        }
    }

    private func clearAssessment() {
        snapshot = nil
        fixtureData = nil
        loadError = nil
        liveAssessmentId = nil
        propertyAddress = ""
        vehicleIntent = ""
        chargingIntent = ""
        spatialCaptureStatus = latestSpatialCapture == nil
            ? "Capture a room to add spatial metadata to the live assessment."
            : "Saved RoomPlan model restored on this device."
        visionStatus = "Capture a panel frame after scanning the room to create reviewable visual evidence."
        isUsingFixtureFallback = false
        engineeringStatus = "Start by entering the property address. Load demo fixture remains available as an explicit fallback."
        engineeringStatusIsError = false
    }

    func loadSeededAssessment() {
        do {
            let data = try Self.loadFixtureData(named: fixtureName)
            snapshot = try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: data)
            fixtureData = data
            propertyAddress = snapshot?.site.address ?? ""
            loadError = nil
            isUsingFixtureFallback = true
            liveAssessmentId = nil
            engineeringStatus = "Fixture fallback active. The bundled seeded assessment is shown until a server tool run succeeds."
            engineeringStatusIsError = false
        } catch {
            snapshot = nil
            loadError = error.localizedDescription
            fixtureData = nil
            isUsingFixtureFallback = true
            engineeringStatus = "Fixture load failed: \(error.localizedDescription)"
            engineeringStatusIsError = true
        }
    }

    func runEngineeringScenario() async {
        guard snapshot != nil, let fixtureData else {
            setEngineeringError("The seeded assessment must load before a server tool run can be requested.")
            return
        }
        guard let baseURL = normalizedServerURL else {
            setEngineeringError("Enter a reachable server URL. The fixture fallback remains visible.")
            return
        }

        saveEngineeringIntent()
        isRunningEngineeringScenario = true
        defer { isRunningEngineeringScenario = false }

        do {
            let assessmentId = try await ensureLiveAssessment(baseURL: baseURL, fixtureData: fixtureData)
            let response: LiveAssessmentResponse = try await send(
                EngineeringRequestBuilder.engineeringToolRunRequest(
                    baseURL: baseURL,
                    assessmentId: assessmentId
                )
            )
            let costResponse: LiveAssessmentResponse = try await send(
                EngineeringRequestBuilder.costToolRunRequest(
                    baseURL: baseURL,
                    assessmentId: response.assessment.assessmentId
                )
            )
            self.snapshot = costResponse.assessment
            isUsingFixtureFallback = false
            engineeringStatus = "Server engineering and cost tool runs returned the current assessment. Results below are server-provided."
            engineeringStatusIsError = false
        } catch {
            restoreFixtureFallback(after: error)
        }
    }

    func recordSpatialCapture(_ payload: SpatialCapturePayload) async {
        saveSpatialCapture(payload)
        guard let fixtureData else {
            spatialCaptureStatus = "Room model saved on this device. Start an assessment to record its metadata."
            return
        }
        guard let baseURL = normalizedServerURL else {
            spatialCaptureStatus = "Room model saved locally. Enter a reachable server URL to record its metadata."
            return
        }

        do {
            let assessmentId = try await ensureLiveAssessment(baseURL: baseURL, fixtureData: fixtureData)
            let serverPayload = try await uploadRoomModel(in: payload, baseURL: baseURL, assessmentId: assessmentId)
            let event = SpatialCaptureEvent(
                eventId: "event-\(UUID().uuidString.lowercased())",
                eventName: .captureRecorded,
                timestamp: payload.timestamp,
                producer: "ios-roomplan",
                payload: serverPayload
            )
            let response: LiveAssessmentResponse = try await send(
                SpatialCaptureRequestBuilder.eventRequest(
                    baseURL: baseURL,
                    assessmentId: assessmentId,
                    event: event
                )
            )
            snapshot = response.assessment
            isUsingFixtureFallback = false
            spatialCaptureStatus = "Spatial metadata recorded and the USDZ is backed up to the local Mac. The phone keeps its copy for room inspection."
        } catch {
            spatialCaptureStatus = "Room model saved locally; Mac backup or metadata recording failed: \(error.localizedDescription). Confirm the phone and Mac share Wi-Fi, then use the Mac LAN URL—not localhost—in the Panel server field."
        }
    }

    private func uploadRoomModel(
        in payload: SpatialCapturePayload,
        baseURL: URL,
        assessmentId: String
    ) async throws -> SpatialCapturePayload {
        guard let localArtifact = payload.artifacts.first(where: { $0.kind == .roomUSDZ }),
              let localURL = localArtifact.localFileURL else {
            throw NSError(domain: "SiteGraphDemo", code: 4, userInfo: [NSLocalizedDescriptionKey: "The local RoomPlan USDZ is unavailable for backup."])
        }
        let request = try SpatialCaptureRequestBuilder.artifactUploadRequest(
            baseURL: baseURL,
            assessmentId: assessmentId,
            artifact: localArtifact
        )
        let (data, response) = try await URLSession.shared.upload(for: request, from: Data(contentsOf: localURL))
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SiteGraphDemo", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "The local Mac could not save the RoomPlan USDZ."])
        }
        let uploaded = try JSONDecoder().decode(LocalArtifactUploadResponse.self, from: data).artifact
        guard uploaded.id == localArtifact.id, uploaded.byteLength == localArtifact.byteLength, uploaded.sha256.caseInsensitiveCompare(localArtifact.sha256) == .orderedSame else {
            throw NSError(domain: "SiteGraphDemo", code: 5, userInfo: [NSLocalizedDescriptionKey: "The local Mac returned a RoomPlan artifact that does not match the phone copy."])
        }
        return SpatialCapturePayload(
            id: payload.id,
            kind: payload.kind,
            status: payload.status,
            coordinateSpaceId: payload.coordinateSpaceId,
            timestamp: payload.timestamp,
            producer: payload.producer,
            detectedObjectTypes: payload.detectedObjectTypes,
            artifacts: payload.artifacts.map { $0.id == uploaded.id ? uploaded : $0 },
            evidence: payload.evidence.map { evidence in
                evidence.uri == localArtifact.uri
                    ? SpatialEvidence(id: evidence.id, type: evidence.type, label: evidence.label, uri: uploaded.uri)
                    : evidence
            }
        )
    }

    func forgetSavedSpatialCapture() {
        defaults.removeObject(forKey: PreferenceKey.latestSpatialCapture)
        latestSpatialCapture = nil
        spatialCaptureStatus = "Saved RoomPlan model removed from this device."
    }

    func restoreSavedSpatialCaptureFromMac() async {
        guard let capture = latestSpatialCapture,
              let artifact = capture.artifacts.first(where: { $0.kind == .roomUSDZ }),
              let remoteURI = capture.evidence.first(where: { $0.type == .roomModel })?.uri,
              let baseURL = normalizedServerURL else {
            spatialCaptureStatus = "Enter the Mac's reachable LAN server URL before restoring the saved room scan."
            return
        }
        spatialCaptureStatus = "Restoring the verified RoomPlan USDZ from the local Mac…"
        do {
            let request = try SpatialCaptureRequestBuilder.artifactRestoreRequest(baseURL: baseURL, remoteURI: remoteURI)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  data.count == artifact.byteLength,
                  httpResponse.value(forHTTPHeaderField: "x-content-sha256")?.caseInsensitiveCompare(artifact.sha256) == .orderedSame else {
                throw NSError(domain: "SiteGraphDemo", code: 6, userInfo: [NSLocalizedDescriptionKey: "The local Mac backup is missing or does not match the saved RoomPlan descriptor."])
            }
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("SpatialCaptures", isDirectory: true)
            let restored = try LocalSpatialArtifactStore(directoryURL: directory).persist(data: data, id: artifact.id, kind: .roomUSDZ, contentType: artifact.contentType)
            guard restored.sha256.caseInsensitiveCompare(artifact.sha256) == .orderedSame else {
                throw NSError(domain: "SiteGraphDemo", code: 7, userInfo: [NSLocalizedDescriptionKey: "The restored RoomPlan USDZ failed local integrity verification."])
            }
            let restoredPayload = SpatialCapturePayload(id: capture.id, kind: capture.kind, status: capture.status, coordinateSpaceId: capture.coordinateSpaceId, timestamp: capture.timestamp, producer: capture.producer, detectedObjectTypes: capture.detectedObjectTypes, artifacts: capture.artifacts.map { $0.id == artifact.id ? restored : $0 }, evidence: capture.evidence)
            saveSpatialCapture(restoredPayload)
            spatialCaptureStatus = "RoomPlan USDZ restored from the local Mac and verified against its saved SHA-256."
        } catch {
            spatialCaptureStatus = "Could not restore the RoomPlan backup: \(error.localizedDescription)"
        }
    }

    func recordPanelFrame(imageData: Data, rectangleCount: Int) async {
        guard let capture = latestSpatialCapture else {
            visionStatus = "Scan and save a RoomPlan space before recording a panel frame, so the evidence can reference its coordinate space."
            return
        }
        guard let fixtureData else {
            visionStatus = "The seeded assessment must load before visual evidence can be recorded."
            return
        }
        guard let baseURL = normalizedServerURL else {
            visionStatus = "Panel image saved only after a reachable server URL is configured."
            return
        }

        do {
            let artifactId = "artifact-panel-\(UUID().uuidString.lowercased())"
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("SpatialCaptures", isDirectory: true)
            let artifact = try LocalSpatialArtifactStore(directoryURL: directory).persist(
                data: imageData,
                id: artifactId,
                kind: .panelImage,
                contentType: "image/jpeg"
            )
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let frameId = "frame-panel-\(UUID().uuidString.lowercased())"
            let evidence = SpatialEvidence(
                id: "evidence-\(frameId)",
                type: .imageFrame,
                label: "Panel evidence frame \(frameId)",
                uri: artifact.uri
            )
            let payload = VisualFramePayload(
                id: frameId,
                captureId: capture.id,
                coordinateSpaceId: capture.coordinateSpaceId,
                timestamp: timestamp,
                producer: "ios-vision",
                artifact: artifact,
                evidence: evidence
            )
            let assessmentId = try await ensureLiveAssessment(baseURL: baseURL, fixtureData: fixtureData)
            let event = VisualFrameRecordedEvent(
                eventId: "event-\(UUID().uuidString.lowercased())",
                timestamp: timestamp,
                producer: "ios-vision",
                payload: payload
            )
            let response: LiveAssessmentResponse = try await send(
                SpatialCaptureRequestBuilder.eventRequest(
                    baseURL: baseURL,
                    assessmentId: assessmentId,
                    event: event
                )
            )
            snapshot = response.assessment
            isUsingFixtureFallback = false
            visionStatus = "Panel frame recorded with \(rectangleCount) local Vision rectangle candidate\(rectangleCount == 1 ? "" : "s"). It remains proposed evidence until review."
            realtime.sendPanelImage(imageData)
        } catch {
            visionStatus = "Panel-frame recording failed: \(error.localizedDescription). The fixture fallback remains available."
        }
    }

    private func ensureLiveAssessment(baseURL: URL, fixtureData: Data) async throws -> String {
        if let liveAssessmentId {
            return liveAssessmentId
        }
        let created: LiveAssessmentResponse = try await send(
            EngineeringRequestBuilder.createAssessmentRequest(
                baseURL: baseURL,
                fixtureData: fixtureData
            )
        )
        liveAssessmentId = created.assessment.assessmentId
        return created.assessment.assessmentId
    }

    private func restoreFixtureFallback(after error: Error) {
        do {
            guard let fixtureData else {
                throw NSError(domain: "SiteGraphDemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "No bundled fixture is loaded"])
            }
            snapshot = try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: fixtureData)
            isUsingFixtureFallback = true
            engineeringStatus = "Server tool run unavailable: \(error.localizedDescription). Showing the bundled fixture fallback."
            engineeringStatusIsError = true
        } catch {
            snapshot = nil
            isUsingFixtureFallback = true
            engineeringStatus = "Server tool run failed and the fixture fallback could not be restored: \(error.localizedDescription)"
            engineeringStatusIsError = true
        }
    }

    private func saveSpatialCapture(_ payload: SpatialCapturePayload) {
        latestSpatialCapture = payload
        do {
            defaults.set(try JSONEncoder().encode(payload), forKey: PreferenceKey.latestSpatialCapture)
        } catch {
            spatialCaptureStatus = "Room model is available for this session, but its saved scan record could not be stored: \(error.localizedDescription)"
        }
    }

    private static func loadSavedSpatialCapture(from defaults: UserDefaults) -> SpatialCapturePayload? {
        guard let data = defaults.data(forKey: PreferenceKey.latestSpatialCapture) else { return nil }
        return try? JSONDecoder().decode(SpatialCapturePayload.self, from: data)
    }

    private var normalizedServerURL: URL? {
        let trimmed = serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            return nil
        }
        return url
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "SiteGraphDemo", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func setEngineeringError(_ message: String) {
        isUsingFixtureFallback = true
        engineeringStatus = message
        engineeringStatusIsError = true
    }

    private static func loadFixtureData(named name: String) throws -> Data {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "SiteGraphDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled fixture \(name).json"])
        }
        return try Data(contentsOf: url)
    }

    private static func blankAssessmentData(address: String) throws -> Data {
        let template = try loadFixtureData(named: "modern-200a")
        guard var assessment = try JSONSerialization.jsonObject(with: template) as? [String: Any] else {
            throw NSError(domain: "SiteGraphDemo", code: 3, userInfo: [NSLocalizedDescriptionKey: "The assessment template is not a JSON object."])
        }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        assessment["assessmentId"] = "assessment-\(UUID().uuidString.lowercased())"
        assessment["evidence"] = []
        assessment["spatialCaptures"] = []
        assessment["visualFrames"] = []
        assessment["spatialObjects"] = []
        assessment["site"] = [
            "id": "site-\(UUID().uuidString.lowercased())",
            "label": "Property assessment",
            "address": address,
            "jurisdiction": ["city": "Unknown", "county": "Unknown", "state": "Unknown", "ahj": "Unknown"],
        ]
        assessment["proposedEvseLocation"] = [
            "id": "evse-\(UUID().uuidString.lowercased())",
            "label": "Proposed charger location not yet collected",
            "wall": "unknown",
            "status": "proposed",
            "sourceType": "assumed",
            "evidenceIds": [],
            "timestamp": timestamp,
            "producer": "ios-assessment-start",
            "assumptions": ["Collect the charger position after the room scan."],
            "notes": [],
        ]
        assessment["electricalPanel"] = [
            "id": "panel-\(UUID().uuidString.lowercased())",
            "label": "Panel not yet observed",
            "status": "proposed",
            "sourceType": "assumed",
            "evidenceIds": [],
            "timestamp": timestamp,
            "producer": "ios-assessment-start",
            "visibleConditionNotes": ["Capture or select a panel image to collect visible evidence."],
            "assumptions": [],
            "notes": [],
        ]
        assessment["measurements"] = []
        assessment["observations"] = []
        assessment["engineeringScenarios"] = []
        assessment["toolRuns"] = []
        assessment["costScenarios"] = []
        assessment["finalAssessment"] = [
            "status": "insufficient_data",
            "summary": "Collect panel and route evidence before assessing EV charger feasibility.",
            "unresolvedRequirements": ["Panel evidence", "Room scan and route measurement", "Proposed charger location"],
            "professionalVerificationItems": [],
            "installerHandoff": ["title": "Assessment not ready", "bullets": []],
            "timestamp": timestamp,
        ]
        return try JSONSerialization.data(withJSONObject: assessment)
    }
}

private struct LiveAssessmentResponse: Decodable {
    let assessment: SiteGraphDemoSnapshot
}

private struct LocalArtifactUploadResponse: Decodable {
    let artifact: SpatialArtifact
}

private func humanized(_ rawValue: String) -> String {
    rawValue
        .replacingOccurrences(of: "_", with: " ")
        .split(separator: " ")
        .map { word -> String in
            let lower = word.lowercased()
            if lower == "ocr" { return "OCR" }
            if lower == "evse" { return "EVSE" }
            return word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        .joined(separator: " ")
}
