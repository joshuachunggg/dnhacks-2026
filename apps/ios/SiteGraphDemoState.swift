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
    @Published var vehicleIntent: String
    @Published var chargingIntent: String
    @Published private(set) var engineeringStatus = "Fixture fallback active. Connect a server to run the deterministic assessment."
    @Published private(set) var engineeringStatusIsError = false
    @Published private(set) var isRunningEngineeringScenario = false
    @Published private(set) var isUsingFixtureFallback = true

    private let fixtureName = "modern-200a"
    private var fixtureData: Data?
    private let defaults: UserDefaults
    private enum PreferenceKey {
        static let serverBaseURL = "engineering.serverBaseURL"
        static let vehicleIntent = "engineering.vehicleIntent"
        static let chargingIntent = "engineering.chargingIntent"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        serverBaseURL = defaults.string(forKey: PreferenceKey.serverBaseURL) ?? ProcessInfo.processInfo.environment["DEMO_SERVER_BASE_URL"] ?? ""
        vehicleIntent = defaults.string(forKey: PreferenceKey.vehicleIntent) ?? ""
        chargingIntent = defaults.string(forKey: PreferenceKey.chargingIntent) ?? "Hardwired home charging"
        loadSeededAssessment()
    }

    var actionTitle: String { "Reset seeded assessment" }

    var actionSubtitle: String {
        "Restore modern-200A fixture and clear the saved vehicle and charging intent."
    }

    func saveEngineeringIntent() {
        defaults.set(serverBaseURL, forKey: PreferenceKey.serverBaseURL)
        defaults.set(vehicleIntent, forKey: PreferenceKey.vehicleIntent)
        defaults.set(chargingIntent, forKey: PreferenceKey.chargingIntent)
    }

    func resetToSeededAssessment() {
        defaults.removeObject(forKey: PreferenceKey.vehicleIntent)
        defaults.removeObject(forKey: PreferenceKey.chargingIntent)
        vehicleIntent = ""
        chargingIntent = "Hardwired home charging"
        loadSeededAssessment()
    }

    func loadSeededAssessment() {
        do {
            let data = try Self.loadFixtureData(named: fixtureName)
            snapshot = try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: data)
            fixtureData = data
            loadError = nil
            isUsingFixtureFallback = true
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
        guard let snapshot else {
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
            let response: LiveAssessmentResponse = try await send(
                to: baseURL
                    .appendingPathComponent("api/assessments")
                    .appendingPathComponent(snapshot.assessmentId)
                    .appendingPathComponent("tools")
                    .appendingPathComponent("runEngineeringScenario"),
                body: Data("{}".utf8)
            )
            self.snapshot = response.assessment
            isUsingFixtureFallback = false
            engineeringStatus = "Server tool run returned the current assessment. Results below are server-provided."
            engineeringStatusIsError = false
        } catch {
            restoreFixtureFallback(after: error)
        }
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
