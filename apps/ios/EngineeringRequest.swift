import Foundation

enum EngineeringRequestBuilder {
    static func createAssessmentRequest(baseURL: URL, fixtureData: Data) -> URLRequest {
        makePOSTRequest(
            url: baseURL.appendingPathComponent("api/assessments"),
            body: fixtureData
        )
    }

    static func engineeringToolRunRequest(baseURL: URL, assessmentId: String) -> URLRequest {
        makePOSTRequest(
            url: baseURL
                .appendingPathComponent("api/assessments")
                .appendingPathComponent(assessmentId)
                .appendingPathComponent("tools")
                .appendingPathComponent("runEngineeringScenario"),
            body: Data("{}".utf8)
        )
    }

    private static func makePOSTRequest(url: URL, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
}
