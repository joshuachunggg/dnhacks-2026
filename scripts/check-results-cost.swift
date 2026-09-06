import Foundation

@main
struct ResultsCostCheck {
    static func main() throws {
        let sourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("apps/ios/ContentView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        precondition(source.contains("private struct CostLineItemRow"), "Cost line items must have a dedicated compact presentation.")
        precondition(source.contains("private var mainFactor: String"), "Each cost line item must identify its main cost factor.")
        precondition(source.contains("DisclosureGroup"), "Supporting cost line-item detail must be collapsed by default.")
        precondition(source.contains("TOTAL PLANNING RANGE"), "The cost card must foreground the total planning range.")
        precondition(!source.contains("Cost provenance · evidence:"), "Cost provenance must not appear in the primary cost card.")
        print("Results cost presentation check passed.")
    }
}
