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

    private let fixtureName = "modern-200a"

    init() {
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
    }

    func loadDemoData() {
        do {
            snapshot = try Self.loadFixture(named: fixtureName)
            loadError = nil
        } catch {
            snapshot = nil
            loadError = error.localizedDescription
        }
    }

    private static func loadFixture(named name: String) throws -> SiteGraphDemoSnapshot {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "SiteGraphDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled fixture \(name).json"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SiteGraphDemoSnapshot.self, from: data)
    }
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
