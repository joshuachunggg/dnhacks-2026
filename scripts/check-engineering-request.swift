import Foundation

@main
struct EngineeringRequestCheck {
    static func main() throws {
        let baseURL = URL(string: "http://localhost:3000")!
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fixtureURL = root.appendingPathComponent("apps/ios/Resources/modern-200a.json")
        let fixtureData = try Data(contentsOf: fixtureURL)

        let createRequest = EngineeringRequestBuilder.createAssessmentRequest(
            baseURL: baseURL,
            fixtureData: fixtureData
        )
        precondition(createRequest.url?.absoluteString == "http://localhost:3000/api/assessments")
        precondition(createRequest.httpMethod == "POST")
        precondition(createRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        precondition(createRequest.httpBody == fixtureData)

        let toolRequest = EngineeringRequestBuilder.engineeringToolRunRequest(
            baseURL: baseURL,
            assessmentId: "created-assessment-id"
        )
        precondition(toolRequest.url?.absoluteString == "http://localhost:3000/api/assessments/created-assessment-id/tools/runEngineeringScenario")
        precondition(toolRequest.httpMethod == "POST")
        precondition(toolRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        precondition(toolRequest.httpBody == Data("{}".utf8))

        let costRequest = EngineeringRequestBuilder.costToolRunRequest(
            baseURL: baseURL,
            assessmentId: "created-assessment-id"
        )
        precondition(costRequest.url?.absoluteString == "http://localhost:3000/api/assessments/created-assessment-id/tools/runCostScenario")
        precondition(costRequest.httpMethod == "POST")
        precondition(costRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        precondition(costRequest.httpBody == Data("{}".utf8))

        print("Engineering and cost request construction check passed.")
    }
}
