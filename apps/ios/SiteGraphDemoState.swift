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
    @Published private(set) var snapshot: SiteGraphDemoSnapshot?
    @Published private(set) var loadError: String?
    @Published var serverBaseURL: String
    @Published private(set) var liveStatus = "Fixture mode: no live observation has been submitted."
    @Published private(set) var liveStatusIsError = false
    @Published private(set) var isSubmittingObservation = false

    private let fixtureName = "modern-200a"
    private var fixtureData: Data?
    private var liveAssessmentId: String?

    init() {
        serverBaseURL = ProcessInfo.processInfo.environment["DEMO_SERVER_BASE_URL"] ?? ""
        loadDemoData()
    }

    var actionTitle: String {
        snapshot == nil ? "Use demo data" : "Reset demo"
    }

    var actionSubtitle: String {
        snapshot == nil
            ? "Load the bundled modern-200A fixture into the native shell."
            : "Clear the seeded state and return to the intro."
    }

    var sourceLine: String {
        snapshot?.sourceSummary ?? "No demo fixture loaded yet."
    }

    func toggleDemoData() {
        if snapshot == nil {
            loadDemoData()
        } else {
            resetDemo()
        }
    }

    func resetDemo() {
        snapshot = nil
        loadError = nil
        fixtureData = nil
        liveAssessmentId = nil
        liveStatus = "Fixture cleared. Use demo data to restore the local fallback."
        liveStatusIsError = false
    }

    func loadDemoData() {
        do {
            let data = try Self.loadFixtureData(named: fixtureName)
            snapshot = try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: data)
            fixtureData = data
            liveAssessmentId = nil
            loadError = nil
            liveStatus = "Fixture mode: no live observation has been submitted."
            liveStatusIsError = false
        } catch {
            snapshot = nil
            loadError = error.localizedDescription
            fixtureData = nil
            liveAssessmentId = nil
            liveStatus = "Fixture load failed: \(error.localizedDescription)"
            liveStatusIsError = true
        }
    }

    func submitConfirmedPanelObservation() async {
        guard let snapshot, let fixtureData else {
            setLiveError("Load the bundled fixture before submitting an observation.")
            return
        }
        guard let baseURL = normalizedServerURL else {
            setLiveError("Enter a reachable server URL before using the live API.")
            return
        }

        isSubmittingObservation = true
        defer { isSubmittingObservation = false }

        do {
            let assessmentId: String
            if let liveAssessmentId {
                assessmentId = liveAssessmentId
            } else {
                let created: LiveAssessmentResponse = try await send(
                    to: baseURL.appendingPathComponent("api/assessments"),
                    body: fixtureData
                )
                assessmentId = created.assessment.assessmentId
                liveAssessmentId = assessmentId
            }

            let timestamp = ISO8601DateFormatter().string(from: Date())
            let event = ObservationAddedEvent(
                eventId: "event-ios-panel-confirmation-\(UUID().uuidString)",
                eventName: "observation.added",
                timestamp: timestamp,
                producer: "ios-demo",
                schemaVersion: snapshot.schemaVersion,
                payload: DemoObservation(
                    id: "obs-ios-panel-confirmation-\(UUID().uuidString)",
                    kind: "label_text",
                    field: "panel_label_confirmation",
                    value: .string("Panel label confirmed by user"),
                    unit: nil,
                    status: .confirmed,
                    sourceType: .userSupplied,
                    confidence: 1,
                    evidenceIds: ["frame-010"],
                    timestamp: timestamp,
                    producer: "ios-demo",
                    assumptions: [],
                    notes: ["Confirmed during the guided demo."]
                )
            )
            let eventData = try JSONEncoder().encode(event)
            let updated: LiveAssessmentResponse = try await send(
                to: baseURL
                    .appendingPathComponent("api/assessments")
                    .appendingPathComponent(assessmentId)
                    .appendingPathComponent("events"),
                body: eventData
            )
            self.snapshot = updated.assessment
            liveStatus = "Live API confirmed one observation and returned validated SiteGraph state."
            liveStatusIsError = false
        } catch {
            setLiveError("Live API unavailable: \(error.localizedDescription). The bundled fixture remains active.")
        }
    }

    private var normalizedServerURL: URL? {
        let trimmed = serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            return nil
        }
        return url
    }

    private func send<Response: Decodable>(to url: URL, body: Data) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

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

    private func setLiveError(_ message: String) {
        liveStatus = message
        liveStatusIsError = true
    }

    private static func loadFixtureData(named name: String) throws -> Data {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "SiteGraphDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled fixture \(name).json"])
        }
        return try Data(contentsOf: url)
    }
}

private struct ObservationAddedEvent: Encodable {
    let eventId: String
    let eventName: String
    let timestamp: String
    let producer: String
    let schemaVersion: String
    let payload: DemoObservation
}

private struct LiveAssessmentResponse: Decodable {
    let assessment: SiteGraphDemoSnapshot
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
