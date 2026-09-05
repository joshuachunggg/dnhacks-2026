import Foundation

struct SiteGraphDemoState {
    enum AssessmentStatus: String {
        case pass
        case conditional
        case insufficientData = "insufficient_data"
        case professionalVerificationRequired = "professional_verification_required"
    }

    let schemaVersion: String
    let assessmentID: String
    let siteLabel: String
    let siteAddress: String
    let jurisdiction: String
    let panelSummary: String
    let assessmentStatus: AssessmentStatus
    let summary: String
    let openItems: [String]
}

final class SiteGraphDemoViewModel: ObservableObject {
    @Published var state: SiteGraphDemoState

    init(state: SiteGraphDemoState) {
        self.state = state
    }

    static let scaffold = SiteGraphDemoViewModel(
        state: SiteGraphDemoState(
            schemaVersion: "0.1.0",
            assessmentID: "assessment-modern-200a",
            siteLabel: "Residential EV charger assessment",
            siteAddress: "1234 Demo St, Austin, TX",
            jurisdiction: "Austin / Travis County / TX",
            panelSummary: "200 A service, 40 breaker spaces, 6 spares",
            assessmentStatus: .conditional,
            summary: "Scaffold state mirrors a SiteGraph v0 demo: the site is identified, the panel is visible, and one or more items still need operator confirmation before a final pass/fail call.",
            openItems: [
                "Confirm proposed EVSE wall location with field photos",
                "Verify panel label text and breaker space count",
                "Capture any missing measurements before final assessment",
            ]
        )
    )
}
