import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @State private var selectedStep = 0

    var body: some View {
        TabView(selection: $selectedStep) {
            NavigationStack {
                SiteScreen(viewModel: viewModel, onNext: { selectedStep = 1 })
            }
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                CaptureScreen(viewModel: viewModel, onNext: { selectedStep = 2 })
            }
            .tabItem {
                Label("Capture", systemImage: "view.3d")
            }
            .tag(1)

            NavigationStack {
                ResultsScreen(viewModel: viewModel)
            }
            .tabItem {
                Label("Results", systemImage: "checkmark.seal.fill")
            }
            .tag(2)
        }
        .tint(.siteForest)
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

private struct SiteScreen: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    let onNext: () -> Void

    var body: some View {
        AssessmentScrollContainer {
            VStack(spacing: 16) {
                AssessmentStepCard(
                    step: 1,
                    title: "Start the assessment",
                    instruction: "Enter the property address, then scan the relevant room or garage.",
                    nextTitle: "Next: scan space",
                    onNext: onNext
                )

                if viewModel.snapshot == nil {
                    PropertyAddressCard(viewModel: viewModel)
                }

                if let snapshot = viewModel.snapshot {
                    DemoCard(title: "Assessment site", subtitle: "Details for this assessment", systemImage: "house.fill") {
                        VStack(spacing: 14) {
                            SiteDetailRow(title: "Address", value: snapshot.site.address, systemImage: "mappin.and.ellipse")
                            SiteDetailRow(title: "Jurisdiction", value: "\(snapshot.site.jurisdiction.ahj), \(snapshot.site.jurisdiction.city), \(snapshot.site.jurisdiction.state)", systemImage: "building.2")
                            SiteDetailRow(title: "Utility", value: snapshot.site.utility ?? "To be confirmed", systemImage: "bolt.fill")
                        }
                    }
                } else {
                    DemoEmptyState(
                        title: viewModel.loadError == nil ? "Start a property assessment" : "Assessment start failed",
                        message: viewModel.loadError ?? "Enter the property address to begin."
                    )
                }
            }
        }
        .navigationTitle("Start")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct SiteDetailRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.siteForest)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct CaptureScreen: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    let onNext: () -> Void

    var body: some View {
        AssessmentScrollContainer {
            VStack(spacing: 16) {
                AssessmentStepCard(
                    step: 2,
                    title: "Scan and talk with the guide",
                    instruction: "Capture the room, then use the live assistant to provide the facts and evidence it requests.",
                    nextTitle: "Next: review results",
                    onNext: onNext
                )
                RoomPlanCaptureCard(viewModel: viewModel)
                LiveAssistantEntryCard(viewModel: viewModel, onFinish: { onNext() })

                if let snapshot = viewModel.snapshot,
                   viewModel.realtime.isLevel2EVChargerAssessmentActive || viewModel.spatialVisuals.evsePose != nil || snapshot.measurements.contains(where: { $0.kind == "route_length" }) {
                    CaptureTechnicalDetails(snapshot: snapshot)
                }
            }
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct CaptureTechnicalDetails: View {
    let snapshot: SiteGraphDemoSnapshot

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 14) {
                FactRow(
                    title: "Recorded EVSE label",
                    value: snapshot.proposedEvseLocation.label,
                    provenance: snapshot.proposedEvseLocation.sourceType.displayName,
                    evidence: evidenceList(snapshot.proposedEvseLocation.evidenceIds)
                )
                if let route = snapshot.measurements.first(where: { $0.kind == "route_length" }) {
                    FactRow(
                        title: "Route length",
                        value: measurementString(route),
                        provenance: "\(route.status.displayName) · \(route.sourceType.displayName)",
                        evidence: evidenceList(route.evidenceIds)
                    )
                    Text("The route length is used as a planning input for the route-dependent installation allowance. It does not establish final electrical scope or price.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12)
        } label: {
            Label("Capture details", systemImage: "info.circle")
                .font(.headline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.siteBorder))
    }
}

private struct ResultsScreen: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        AssessmentScrollContainer {
            VStack(spacing: 16) {
                AssessmentStepCard(
                    step: 3,
                    title: "Review the handoff",
                    instruction: "See the recommended next step, then share the clear handoff with an electrician."
                )

                if let roomExpansionSummary = viewModel.realtime.roomExpansionSummary {
                    DemoCard(title: "Adjacent-room expansion", subtitle: "Conceptual scan visualization", systemImage: "rectangle.3.group") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(roomExpansionSummary)
                                .font(.subheadline)
                            Text("The highlighted opening is a user-selected concept on the captured model. It is not a structural finding, demolition instruction, permit approval, or feasibility conclusion.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let snapshot = viewModel.snapshot {
                    AssessmentOutcomeCard(assessment: snapshot.finalAssessment)
                    RecommendedChargerCard(snapshot: snapshot)
                    NextStepsCard(assessment: snapshot.finalAssessment)

                    CostResultsCard(
                        cost: snapshot.costScenarios.first,
                        toolRun: snapshot.toolRuns.last(where: { $0.toolName == "runCostScenario" }),
                        isUsingFixtureFallback: viewModel.isUsingFixtureFallback
                    )

                    DemoCard(title: "Installer handoff", subtitle: snapshot.finalAssessment.installerHandoff.title, systemImage: "square.and.arrow.up") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(snapshot.finalAssessment.installerHandoff.bullets, id: \.self) { bullet in
                                Label(bullet, systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                            }
                        }
                    }

                    ResultsTechnicalDetails(snapshot: snapshot, viewModel: viewModel)
                    StartNewAssessmentButton(viewModel: viewModel)
                } else {
                    DemoEmptyState(
                        title: viewModel.loadError == nil ? "No results yet" : "Assessment unavailable",
                        message: viewModel.loadError ?? "Complete the capture and assessment steps to see the outcome and installer handoff."
                    )
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct AssessmentOutcomeCard: View {
    let assessment: DemoFinalAssessment

    private var headline: String {
        switch assessment.status {
        case .pass: return "An option is ready for electrician confirmation"
        case .conditional: return "A charger looks plausible — verify before installing"
        case .insufficientData: return "More information is needed before choosing a charger"
        case .professionalVerificationRequired: return "An electrician needs to review this assessment"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("YOUR ASSESSMENT", systemImage: "bolt.car.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.siteForest)
                Spacer()
                StatusBadge(status: assessment.status)
            }
            Text(headline)
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(assessment.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.siteSage, Color.siteMist], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.siteForest.opacity(0.16)))
    }
}

private struct RecommendedChargerCard: View {
    let snapshot: SiteGraphDemoSnapshot

    private var recommendedScenario: DemoEngineeringScenario? {
        let recommendedLabel = snapshot.toolRuns.last?.output["recommendedScenario"]?.stringValue
        return snapshot.engineeringScenarios.first(where: { $0.label == recommendedLabel })
            ?? snapshot.engineeringScenarios.first(where: { $0.status == "pass" })
    }

    var body: some View {
        if let scenario = recommendedScenario {
            DemoCard(title: "Best current option", subtitle: "Preliminary recommendation", systemImage: "bolt.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(scenario.label).font(.title3.weight(.bold))
                        Spacer()
                        ScenarioBadge(text: scenario.status)
                    }
                    Text(scenario.resultSummary)
                        .font(.subheadline)
                    if !scenario.requirements.isEmpty {
                        Text("Still required: \(scenario.requirements.joined(separator: " "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct NextStepsCard: View {
    let assessment: DemoFinalAssessment

    var body: some View {
        DemoCard(title: "What to do next", subtitle: "No installation approval is implied", systemImage: "arrow.right.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(assessment.unresolvedRequirements, id: \.self) { item in
                    NextStepRow(item: item, systemImage: "checkmark.circle")
                }
                ForEach(assessment.professionalVerificationItems, id: \.self) { item in
                    NextStepRow(item: item, systemImage: "person.crop.circle.badge.checkmark")
                }
            }
        }
    }
}

private struct NextStepRow: View {
    let item: String
    let systemImage: String

    var body: some View {
        Label {
            Text(item).font(.subheadline)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Color.siteForest)
        }
    }
}

private struct ResultsTechnicalDetails: View {
    let snapshot: SiteGraphDemoSnapshot
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 16) {
                EngineeringRunStatusCard(viewModel: viewModel)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Engineering scenarios").font(.subheadline.weight(.semibold))
                    ForEach(snapshot.engineeringScenarios) { scenario in
                        EngineeringScenarioDetail(scenario: scenario)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tool runs and evidence").font(.subheadline.weight(.semibold))
                    ForEach(snapshot.toolRuns) { toolRun in
                        ToolRunRow(toolRun: toolRun)
                    }
                }
            }
            .padding(.top, 12)
        } label: {
            Label("Technical details", systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.headline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.siteBorder))
    }
}

private struct EngineeringScenarioDetail: View {
    let scenario: DemoEngineeringScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(scenario.label).font(.subheadline.weight(.semibold))
                Spacer()
                ScenarioBadge(text: scenario.status)
            }
            Text(scenario.resultSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !scenario.requirements.isEmpty {
                Text("Requirements: \(scenario.requirements.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Evidence: \(evidenceList(scenario.evidenceIds)) · \(scenario.timestamp)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }
}

private struct AssessmentScrollContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ViewBuilder let content: Content

    private var maximumContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 16
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: maximumContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 96)
        }
        .scrollIndicators(.hidden)
        .background(
            LinearGradient(
                colors: [.siteCanvas, Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct CostResultsCard: View {
    let cost: DemoCostScenario?
    let toolRun: DemoToolRun?
    let isUsingFixtureFallback: Bool

    private var status: CostPresentationStatus {
        guard let rawStatus = toolRun?.output["costStatus"]?.stringValue else {
            return isUsingFixtureFallback ? .fixtureRange : .unavailable
        }
        return CostPresentationStatus(rawValue: rawStatus) ?? .unavailable
    }

    private var missingInputs: [String] {
        toolRun?.output["missingInputs"]?.stringArrayValue ?? []
    }

    var body: some View {
        DemoCard(title: "Cost result", subtitle: status.subtitle, systemImage: "dollarsign.circle.fill") {
            VStack(alignment: .leading, spacing: 14) {
                if let cost, status.showsNumericRange {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL PLANNING RANGE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.siteForest)
                        Text(rangeString(low: cost.totalLow, expected: cost.totalExpected, high: cost.totalHigh, currency: cost.currency))
                            .font(.title3.weight(.bold).monospacedDigit())
                        Text("Planning range only — not an installer quote. Final scope and price require electrician and AHJ review.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(cost.lineItems) { item in
                        CostLineItemRow(item: item)
                    }

                    DisclosureGroup("Cost details") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(status.explanation)
                            if !cost.assumptions.isEmpty {
                                Text("Assessment assumptions: \(cost.assumptions.joined(separator: " "))")
                            }
                            if let toolRun, !toolRun.warnings.isEmpty {
                                ForEach(toolRun.warnings, id: \.self) { warning in
                                    Text(warning)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                    .font(.subheadline.weight(.semibold))
                } else if status == .insufficientData {
                    Text("No numeric cost is available yet.")
                        .font(.headline)
                    ForEach(missingInputs, id: \.self) { item in
                        Label(item, systemImage: "questionmark.circle.fill")
                            .font(.subheadline)
                    }
                } else {
                    Text(status.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CostLineItemRow: View {
    let item: DemoCostLineItem

    private var mainFactor: String {
        let label = item.label.lowercased()
        if label.contains("route") || label.contains("conduit") || label.contains("wire") {
            return "Route length and access"
        }
        if label.contains("panel") || label.contains("breaker") || label.contains("service") {
            return "Panel capacity and available space"
        }
        if label.contains("permit") || label.contains("inspection") {
            return "Local permit and inspection requirements"
        }
        return "Site conditions and installation scope"
    }

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(quantityString(item.quantity)) \(item.unit) · \(item.source)")
                if !item.assumptions.isEmpty {
                    Text(item.assumptions.joined(separator: " "))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.label)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(rangeString(low: item.low, expected: item.expected, high: item.high, currency: item.currency))
                        .font(.footnote.monospacedDigit())
                }
                Text("Main factor: \(mainFactor)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.siteMist))
    }
}

private enum CostPresentationStatus: String {
    case preliminaryRange = "preliminary_range"
    case partialRange = "partial_range"
    case insufficientData = "insufficient_data"
    case fixtureRange = "fixture_range"
    case unavailable

    var subtitle: String {
        switch self {
        case .preliminaryRange: return "Preliminary range"
        case .partialRange: return "Partial range"
        case .insufficientData: return "Insufficient data"
        case .fixtureRange: return "Fixture planning range"
        case .unavailable: return "Cost tool result unavailable"
        }
    }

    var explanation: String {
        switch self {
        case .preliminaryRange:
            return "This is a preliminary fixture-scoped planning range, not a whole-project quote. Licensed-electrician and AHJ confirmation can change scope and cost."
        case .partialRange:
            return "This is a partial range only. Panel, subpanel, or service-upgrade scope is excluded and unpriced; it is not the whole-project total."
        case .insufficientData:
            return "Required route, panel-space, or jurisdiction facts are insufficient, so the server did not calculate a numeric cost."
        case .fixtureRange:
            return "The bundled fixture shows a demo planning range. Run the server tools for the current cost status and provenance."
        case .unavailable:
            return "The server assessment did not include a recognized cost result. No local cost calculation was performed."
        }
    }

    var showsNumericRange: Bool {
        self == .preliminaryRange || self == .partialRange || self == .fixtureRange
    }
}

private struct StartNewAssessmentButton: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        Button(action: viewModel.startNewAssessment) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.16)))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start a new assessment")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Clear this assessment and return to the property address step.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [.siteForest, .siteForest.opacity(0.86)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AssessmentStepCard: View {
    let step: Int
    let title: String
    let instruction: String
    var nextTitle: String?
    var onNext: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text("STEP \(step) OF 3")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.siteForest)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color.siteSage))
                Spacer()
                if step < 3 {
                    Text("Complete in order")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.title3.weight(.semibold))
            Text(instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let nextTitle, let onNext {
                Button(nextTitle, action: onNext)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .tint(.siteForest)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.siteMist))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.siteForest.opacity(0.12)))
    }
}

private struct PropertyAddressCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        DemoCard(title: "Property address", subtitle: "User-supplied site location", systemImage: "house.and.flag") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Street address, city, state", text: $viewModel.propertyAddress)
                    .textContentType(.fullStreetAddress)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.propertyAddress) { _, _ in viewModel.saveEngineeringIntent() }

                Text("The address is recorded as user-supplied. Jurisdiction, utility, equipment position, route, and panel facts are not inferred from it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Start blank assessment", action: viewModel.startAssessmentFromAddress)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct EngineeringIntentCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        DemoCard(title: "Vehicle and charging intent", subtitle: "Saved locally and restored on reset; not sent to the current server calculator", systemImage: "car.fill") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Vehicle (optional), e.g. 2025 EV", text: $viewModel.vehicleIntent)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.vehicleIntent) { _, _ in viewModel.saveEngineeringIntent() }

                Picker("Charging intent", selection: $viewModel.chargingIntent) {
                    Text("Select charging intent").tag("")
                    Text("Hardwired home charging").tag("Hardwired home charging")
                    Text("Plug-in home charging").tag("Plug-in home charging")
                    Text("I need installer guidance").tag("I need installer guidance")
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.chargingIntent) { _, _ in viewModel.saveEngineeringIntent() }

                TextField("Server URL, e.g. http://192.168.1.10:3000", text: $viewModel.serverBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.serverBaseURL) { _, _ in viewModel.saveEngineeringIntent() }

                Text("The bundled fixture is posted to create the server assessment, then {} runs engineering followed by cost. Vehicle and charging intent remains local and is not sent to or used by the current deterministic calculations. No electrical calculation runs on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await viewModel.runEngineeringScenario() }
                } label: {
                    HStack {
                        if viewModel.isRunningEngineeringScenario { ProgressView() }
                        Text(viewModel.isRunningEngineeringScenario ? "Requesting engineering and cost results…" : "Run deterministic engineering and cost scenarios")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.snapshot == nil || viewModel.isRunningEngineeringScenario)
            }
        }
    }
}

private struct EngineeringRunStatusCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        DemoCard(
            title: viewModel.isUsingFixtureFallback ? "Fixture fallback active" : "Server assessment active",
            subtitle: "Assessment source",
            systemImage: viewModel.isUsingFixtureFallback ? "exclamationmark.triangle.fill" : "checkmark.icloud.fill"
        ) {
            Text(viewModel.engineeringStatus)
                .font(.subheadline)
                .foregroundStyle(viewModel.engineeringStatusIsError ? .red : .primary)
        }
    }
}

private struct ToolRunRow: View {
    let toolRun: DemoToolRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(toolRun.toolName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                ScenarioBadge(text: toolRun.resultStatus)
            }
            Text("Version \(toolRun.version) · \(toolRun.timestamp)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(toolRun.inputSummary)
                .font(.footnote)
            Text("Evidence: \(evidenceList(toolRun.evidenceIds))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !toolRun.assumptions.isEmpty {
                Text("Assumptions: \(toolRun.assumptions.joined(separator: " "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !toolRun.warnings.isEmpty {
                Text("Warnings: \(toolRun.warnings.joined(separator: " "))")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }
}

private struct DemoCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let content: Content

    init(title: String, subtitle: String? = nil, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(Color.siteForest)
                    .frame(width: 22)
                    .padding(9)
                    .background(Color.siteSage, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.siteBorder))
        .shadow(color: .black.opacity(0.035), radius: 10, y: 4)
    }
}

private struct DemoEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        DemoCard(title: title, subtitle: "Assessment status", systemImage: "tray") {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FactRow: View {
    let title: String
    let value: String
    let provenance: String
    let evidence: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(provenance)
                .font(.caption)
                .foregroundStyle(Color.siteForest)
            Text("Evidence: \(evidence)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

private struct ObservationRow: View {
    let observation: DemoObservation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(observation.field)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(text: observation.status.displayName)
            }
            Text(observation.value.displayText + observationUnitSuffix)
                .font(.subheadline)
            Text("source: \(observation.sourceType.displayName) · confidence: \(confidenceString(observation.confidence))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("evidence: \(evidenceList(observation.evidenceIds))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    private var observationUnitSuffix: String {
        guard let unit = observation.unit, !unit.isEmpty else { return "" }
        return " \(unit)"
    }
}

private struct StatusBadge: View {
    let text: String

    init(status: DemoAssessmentStatus) {
        self.text = status.displayName
    }

    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .foregroundStyle(.white)
            .background(Capsule().fill(Color.siteForest))
    }
}

private struct ScenarioBadge: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .foregroundStyle(.white)
            .background(Capsule().fill(color))
    }

    private var color: Color {
        switch text {
        case "pass": return .green
        case "conditional": return .orange
        case "fail": return .red
        case "insufficient_data": return .gray
        default: return .siteForest
        }
    }
}

private func evidenceList(_ ids: [String]) -> String {
    ids.isEmpty ? "none" : ids.joined(separator: ", ")
}

private func serviceSummary(_ panel: DemoElectricalPanel) -> String {
    guard let amps = panel.serviceAmps else { return "Unknown" }
    var parts = ["\(amps) A"]
    if let voltage = panel.serviceVoltage {
        parts.append("\(Int(voltage)) V")
    }
    return parts.joined(separator: " · ")
}

private func spacesSummary(_ panel: DemoElectricalPanel) -> String {
    guard let count = panel.breakerSpaceCount else { return "Unknown" }
    let spare = panel.spareBreakerSpaces.map { " / \($0) spares" } ?? ""
    return "\(count) spaces\(spare)"
}

private func measurementString(_ measurement: DemoMeasurement) -> String {
    "\(measurement.value.formatted(.number.precision(.fractionLength(0...2)))) \(measurement.unit)"
}

private func confidenceString(_ confidence: Double?) -> String {
    guard let confidence else { return "n/a" }
    return String(format: "%.0f%%", confidence * 100)
}

private func quantityString(_ quantity: Double) -> String {
    quantity.formatted(.number.precision(.fractionLength(0...1)))
}

private func rangeString(low: Double, expected: Double, high: Double, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    let lowString = formatter.string(from: NSNumber(value: low)) ?? "\(low)"
    let expectedString = formatter.string(from: NSNumber(value: expected)) ?? "\(expected)"
    let highString = formatter.string(from: NSNumber(value: high)) ?? "\(high)"
    return "\(lowString) — \(expectedString) — \(highString)"
}

private extension Color {
    static let siteForest = Color(red: 0.09, green: 0.25, blue: 0.19)
    static let siteSage = Color(red: 0.88, green: 0.94, blue: 0.89)
    static let siteMist = Color(red: 0.93, green: 0.96, blue: 0.93)
    static let siteCanvas = Color(red: 0.97, green: 0.98, blue: 0.96)
    static let siteBorder = Color(red: 0.83, green: 0.87, blue: 0.83)
}
