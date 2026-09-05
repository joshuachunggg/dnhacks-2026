import Foundation

struct SiteGraph: Decodable {
    let schemaVersion: String
    let assessmentId: String
    let site: Site
    let proposedEvseLocation: ProposedEvseLocation
    let electricalPanel: ElectricalPanel
    let measurements: [Measurement]
    let observations: [Observation]
    let engineeringScenarios: [EngineeringScenario]
    let toolRuns: [ToolRun]
    let costScenarios: [CostScenario]
    let finalAssessment: FinalAssessment
}

struct Site: Decodable {
    let id: String
    let label: String
    let address: String
    let jurisdiction: Jurisdiction
}

struct Jurisdiction: Decodable {
    let city: String
    let county: String
    let state: String
    let ahj: String
}

struct ProposedEvseLocation: Decodable {
    let id: String
    let label: String
    let wall: String
    let status: String
}

struct ElectricalPanel: Decodable {
    let id: String
    let label: String
    let status: String
    let manufacturer: String?
    let serviceAmps: Int?
    let breakerSpaceCount: Int?
    let spareBreakerSpaces: Int?
}

struct Measurement: Decodable {
    let id: String
    let kind: String
    let value: Double
    let unit: String
}

struct Observation: Decodable {
    let id: String
    let kind: String
    let field: String
    let status: String
}

struct EngineeringScenario: Decodable {
    let id: String
    let label: String
    let status: String
}

struct ToolRun: Decodable {
    let id: String
    let toolName: String
    let resultStatus: String
}

struct CostScenario: Decodable {
    let id: String
    let label: String
    let status: String
    let totalExpected: Double
}

struct FinalAssessment: Decodable {
    let status: String
    let summary: String
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fixtureURL = root.appendingPathComponent("packages/fixtures/sitegraph/modern-200a.json")
let data = try Data(contentsOf: fixtureURL)
let decoder = JSONDecoder()
let siteGraph = try decoder.decode(SiteGraph.self, from: data)

guard siteGraph.schemaVersion == "0.1.0" else {
    fatalError("Unexpected schema version: \(siteGraph.schemaVersion)")
}

guard siteGraph.site.jurisdiction.state == "TX" else {
    fatalError("Expected TX jurisdiction")
}

print("Swift fixture check passed for \(siteGraph.assessmentId) with panel \(siteGraph.electricalPanel.label).")
