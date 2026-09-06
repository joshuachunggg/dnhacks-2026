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
                Label("1 Start", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                CaptureScreen(viewModel: viewModel, onNext: { selectedStep = 2 })
            }
            .tabItem {
                Label("2 Capture", systemImage: "view.3d")
            }
            .tag(1)

            NavigationStack {
                ResultsScreen(viewModel: viewModel)
            }
            .tabItem {
                Label("3 Results", systemImage: "checkmark.seal.fill")
            }
            .tag(2)
        }
        .tint(.indigo)
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
                    instruction: "Enter the property address or load the explicit demo fixture. Then scan the relevant room or garage.",
                    nextTitle: "Next: scan space",
                    onNext: onNext
                )
                DemoActionCard(viewModel: viewModel)

                if viewModel.snapshot == nil {
                    PropertyAddressCard(viewModel: viewModel)
                }

                if let snapshot = viewModel.snapshot {
                    DemoCard(title: "Site", subtitle: viewModel.isUsingFixtureFallback ? snapshot.sourceSummary : "Server-returned assessment after deterministic tool runs", systemImage: "house.fill") {
                        VStack(spacing: 12) {
                            FactRow(title: "Assessment ID", value: snapshot.assessmentId, provenance: viewModel.isUsingFixtureFallback ? "fixture boundary" : "server-returned assessment", evidence: viewModel.isUsingFixtureFallback ? "modern-200a.json" : "create → engineering → cost tool responses")
                            FactRow(title: "Site label", value: snapshot.site.label, provenance: "user-facing site identity", evidence: snapshot.site.id)
                            FactRow(title: "Address", value: snapshot.site.address, provenance: "seeded demo address", evidence: "loaded from fixture")
                            FactRow(title: "Jurisdiction", value: "\(snapshot.site.jurisdiction.ahj), \(snapshot.site.jurisdiction.city), \(snapshot.site.jurisdiction.state)", provenance: "jurisdictional fixture", evidence: "\(snapshot.site.jurisdiction.county) County")
                            FactRow(title: "Utility", value: snapshot.site.utility ?? "Unknown", provenance: "source-backed demo field", evidence: "site record")
                        }
                    }

                    DemoCard(title: "What this screen proves", subtitle: "Visible provenance and story state", systemImage: "eye.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("The app is reading structured fixture data, not hardcoded labels.", systemImage: "checkmark.circle.fill")
                            Label("Each major fact is tagged with a source type and evidence reference.", systemImage: "checkmark.circle.fill")
                            Label("The seeded assessment is ready to be reset and reloaded on demand.", systemImage: "checkmark.circle.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    }
                } else {
                    DemoEmptyState(
                        title: viewModel.loadError == nil ? "Start a property assessment" : "Assessment start failed",
                        message: viewModel.loadError ?? "Enter the property address to start with a blank assessment, or load the demo fixture explicitly."
                    )
                }
            }
        }
        .navigationTitle("1. Start")
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
                DemoActionCard(viewModel: viewModel)
                RoomPlanCaptureCard(viewModel: viewModel)
                LiveAssistantEntryCard(viewModel: viewModel, onFinish: { onNext() })

                if let snapshot = viewModel.snapshot, viewModel.realtime.isLevel2EVChargerAssessmentActive {
                    DemoCard(title: "Charger location", subtitle: "Proposed EVSE mount point", systemImage: "location.fill") {
                        VStack(spacing: 12) {
                            FactRow(title: "Proposed wall", value: snapshot.proposedEvseLocation.wall, provenance: snapshot.proposedEvseLocation.status.displayName, evidence: evidenceList(snapshot.proposedEvseLocation.evidenceIds))
                            FactRow(title: "Location label", value: snapshot.proposedEvseLocation.label, provenance: snapshot.proposedEvseLocation.sourceType.displayName, evidence: snapshot.proposedEvseLocation.id)
                            FactRow(title: "Confidence", value: confidenceString(snapshot.proposedEvseLocation.confidence), provenance: "seeded user confirmation", evidence: snapshot.proposedEvseLocation.timestamp)
                        }
                    }

                    DemoCard(title: "Route estimate", subtitle: "Typed measurement state", systemImage: "ruler") {
                        VStack(spacing: 12) {
                            if let route = snapshot.measurements.first(where: { $0.kind == "route_length" }) {
                                FactRow(title: "Route length", value: measurementString(route), provenance: route.sourceType.displayName, evidence: evidenceList(route.evidenceIds))
                                FactRow(title: "Measurement status", value: route.status.displayName, provenance: route.producer, evidence: route.assumptions.first ?? "No assumptions recorded")
                            }
                        }
                    }

                    DemoCard(title: "Charger story", subtitle: "What the user can explain in one sentence", systemImage: "quote.bubble") {
                        Text("The proposed charger position is pinned to the garage west wall, the route estimate is stored as typed state, and the location remains linked to seeded evidence instead of transcript-only memory.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle("2. Capture")
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
                    instruction: "Compare the deterministic options, inspect the cost status, and identify what the electrician still needs to verify."
                )
                DemoActionCard(viewModel: viewModel)

                if let snapshot = viewModel.snapshot {
                    DemoCard(title: "Assessment result", subtitle: snapshot.finalAssessment.status.displayName, systemImage: "checkmark.seal.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusBadge(status: snapshot.finalAssessment.status)
                            Text(snapshot.finalAssessment.summary)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }

                    DemoCard(title: "Open items", subtitle: "What still needs operator or electrician confirmation", systemImage: "exclamationmark.triangle.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(snapshot.finalAssessment.unresolvedRequirements, id: \.self) { item in
                                Label(item, systemImage: "questionmark.circle.fill")
                            }
                            ForEach(snapshot.finalAssessment.professionalVerificationItems, id: \.self) { item in
                                Label(item, systemImage: "person.crop.circle.badge.checkmark")
                            }
                        }
                        .font(.subheadline)
                    }

                    EngineeringRunStatusCard(viewModel: viewModel)

                    DemoCard(title: "Tool run provenance", subtitle: "Server-returned deterministic engineering and cost tools", systemImage: "wrench.and.screwdriver.fill") {
                        VStack(spacing: 12) {
                            ForEach(snapshot.toolRuns) { toolRun in
                                ToolRunRow(toolRun: toolRun)
                            }
                        }
                    }

                    DemoCard(title: "Engineering scenarios", subtitle: "Server-returned scenarios; no electrical calculation runs on this device", systemImage: "slider.horizontal.3") {
                        VStack(spacing: 12) {
                            ForEach(snapshot.engineeringScenarios) { scenario in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(scenario.label)
                                            .font(.subheadline.weight(.semibold))
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
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

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
                } else {
                    DemoEmptyState(
                        title: viewModel.loadError == nil ? "No results yet" : "Fixture load failed",
                        message: viewModel.loadError ?? "Reload the demo to show the assessment outcome, scenario comparison, and installer handoff."
                    )
                }
            }
        }
        .navigationTitle("4. Results")
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
        .background(Color(.systemGroupedBackground))
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    ScenarioBadge(text: status.rawValue)
                    Spacer()
                    if let toolRun {
                        Text("Server tool · \(toolRun.timestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Bundled fixture")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(status.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                if let cost, status.showsNumericRange {
                    Text(rangeString(low: cost.totalLow, expected: cost.totalExpected, high: cost.totalHigh, currency: cost.currency))
                        .font(.headline)
                    Text("Planning range only; not an installer quote.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(cost.lineItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.label)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(rangeString(low: item.low, expected: item.expected, high: item.high, currency: item.currency))
                                    .font(.footnote.monospacedDigit())
                            }
                            Text("\(quantityString(item.quantity)) \(item.unit) · source: \(item.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !item.assumptions.isEmpty {
                                Text("Assumptions: \(item.assumptions.joined(separator: " "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if !cost.assumptions.isEmpty {
                        Text("Cost assumptions: \(cost.assumptions.joined(separator: " "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if status == .insufficientData {
                    Text("No numeric cost is available.")
                        .font(.headline)
                    ForEach(missingInputs, id: \.self) { item in
                        Label(item, systemImage: "questionmark.circle.fill")
                            .font(.subheadline)
                    }
                }

                if let toolRun, !toolRun.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cost disclaimer")
                            .font(.subheadline.weight(.semibold))
                        ForEach(toolRun.warnings, id: \.self) { warning in
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if isUsingFixtureFallback {
                    Text("Cost disclaimer: bundled fixture values are demo planning data, not an installer quote.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let toolRun {
                    Text("Cost provenance · evidence: \(evidenceList(toolRun.evidenceIds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
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

private struct DemoActionCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        Button(action: viewModel.toggleDemoFixture) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.indigo.opacity(0.12)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.actionTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(viewModel.actionSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground)))
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
                    .foregroundStyle(.indigo)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color.indigo.opacity(0.12)))
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
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.indigo.opacity(0.08)))
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
                    .foregroundStyle(.indigo)
                    .frame(width: 22)
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
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
}

private struct DemoEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        DemoCard(title: title, subtitle: "Seeded demo is currently cleared", systemImage: "tray") {
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
                .foregroundStyle(.indigo)
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
            .background(Capsule().fill(.indigo))
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
        default: return .indigo
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
