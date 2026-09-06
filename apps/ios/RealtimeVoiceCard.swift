import SwiftUI

struct RealtimeVoiceCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @ObservedObject private var realtime: RealtimeSessionClient

    init(viewModel: SiteGraphDemoViewModel) {
        self.viewModel = viewModel
        realtime = viewModel.realtime
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                SecureField("Realtime demo token", text: $viewModel.realtimeDemoToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Text(realtime.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !realtime.responseText.isEmpty {
                    Text(realtime.responseText)
                        .font(.subheadline)
                }

                HStack {
                    Button(realtime.isConnected ? "Disconnect guide" : "Connect voice guide") {
                        if realtime.isConnected {
                            realtime.disconnect()
                        } else {
                            Task { await viewModel.connectRealtime() }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if realtime.isConnected {
                        Button(realtime.isListening ? "Stop talking" : "Talk") {
                            realtime.isListening ? realtime.finishListening() : realtime.startListening()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        } label: {
            Label("Live spatial guide", systemImage: "waveform")
        }
    }
}
