import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.state.siteLabel)
                            .font(.title2.weight(.semibold))
                        Text(viewModel.state.siteAddress)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Assessment") {
                    LabeledContent("Schema", value: viewModel.state.schemaVersion)
                    LabeledContent("Assessment ID", value: viewModel.state.assessmentID)
                    LabeledContent("Status", value: viewModel.state.assessmentStatus.rawValue)
                    LabeledContent("Panel", value: viewModel.state.panelSummary)
                }

                Section("Demo state") {
                    Text(viewModel.state.summary)
                        .foregroundStyle(.primary)
                }

                Section("Open items") {
                    ForEach(viewModel.state.openItems, id: \.self) { item in
                        Label(item, systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .navigationTitle("SiteGraph v0")
            .toolbar {
                Text("Scaffold only")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
