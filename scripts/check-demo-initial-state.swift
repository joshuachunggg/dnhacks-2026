import Foundation

@main
struct DemoInitialStateCheck {
    static func main() throws {
        let sourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("apps/ios/SiteGraphDemoState.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        guard let initRange = source.range(of: "    init(defaults: UserDefaults = .standard)")?.lowerBound,
              let actionRange = source.range(of: "    var hasSpatialCapture", range: initRange..<source.endIndex)?.lowerBound else {
            fatalError("Could not locate SiteGraphDemoViewModel initialization.")
        }
        let initialization = String(source[initRange..<actionRange])
        precondition(initialization.contains("clearAssessment()"), "The app must start with an empty assessment state.")
        precondition(!initialization.contains("loadSeededAssessment()"), "The app must not load a demo fixture during initialization.")
        precondition(!source.contains("Load demo fixture"), "The app must not expose a demo-fixture loading action.")
        precondition(source.contains("@Published var propertyAddress: String"), "The blank start state must collect the property address.")
        precondition(source.contains("func startAssessmentFromAddress()"), "The address must create a blank assessment rather than restoring seeded facts.")
        precondition(!source.contains("static let propertyAddress"), "The property address must not survive a blank restart.")
        precondition(!source.contains("static let vehicleIntent"), "Vehicle intent must not survive a blank restart.")
        precondition(!source.contains("static let chargingIntent"), "Charging intent must not survive a blank restart.")
        print("Blank assessment initial-state check passed.")
    }
}
