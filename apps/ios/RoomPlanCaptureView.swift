import RoomPlan
import SwiftUI
import UIKit

struct RoomPlanCaptureCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @State private var isPresentingCapture = false
    @State private var isPresentingModelPreview = false
    @State private var capturePayload: SpatialCapturePayload?
    @State private var captureError: String?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                if let capturePayload {
                    Label("Room captured locally", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Saved \(capturePayload.artifacts.count) RoomPlan artifact for this device. \(viewModel.spatialCaptureStatus)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Scan the relevant garage or room to retain a local RoomPlan USDZ model for the assessment.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let captureError {
                    Text(captureError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(capturePayload == nil ? "Scan space with RoomPlan" : "Rescan space") {
                    captureError = nil
                    isPresentingCapture = true
                }
                .buttonStyle(.borderedProminent)

                if let modelURL = roomModelURL {
                    Button("View 3D room model") {
                        isPresentingModelPreview = true
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $isPresentingModelPreview) {
                        RoomModelQuickLookPreview(modelURL: modelURL)
                            .ignoresSafeArea()
                    }
                }
            }
        } label: {
            Label("Spatial room capture", systemImage: "view.3d")
        }
        .sheet(isPresented: $isPresentingCapture) {
            RoomPlanCaptureSheet { result in
                isPresentingCapture = false
                switch result {
                case .success(let payload):
                    capturePayload = payload
                    Task { await viewModel.recordSpatialCapture(payload) }
                case .failure(let error):
                    captureError = error.localizedDescription
                }
            }
            .ignoresSafeArea()
        }
    }

    private var roomModelURL: URL? {
        capturePayload?.artifacts.first(where: { $0.kind == .roomUSDZ })?.localFileURL
    }
}

private struct RoomPlanCaptureSheet: UIViewControllerRepresentable {
    let onComplete: (Result<SpatialCapturePayload, Error>) -> Void

    func makeUIViewController(context: Context) -> RoomPlanCaptureViewController {
        RoomPlanCaptureViewController(onComplete: onComplete)
    }

    func updateUIViewController(_ uiViewController: RoomPlanCaptureViewController, context: Context) {}
}

private final class RoomPlanCaptureViewController: UIViewController, RoomCaptureViewDelegate {
    private let roomCaptureView = RoomCaptureView(frame: .zero)
    private let onComplete: (Result<SpatialCapturePayload, Error>) -> Void
    private var didStartCapture = false
    private var didFinishCapture = false

    init(onComplete: @escaping (Result<SpatialCapturePayload, Error>) -> Void) {
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        roomCaptureView.delegate = self
        view.addSubview(roomCaptureView)
        NSLayoutConstraint.activate([
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let stopButton = UIButton(type: .system)
        stopButton.setTitle("Finish room scan", for: .normal)
        stopButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        stopButton.tintColor = .white
        stopButton.backgroundColor = .systemIndigo
        stopButton.layer.cornerRadius = 12
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(finishCapture), for: .touchUpInside)
        view.addSubview(stopButton)
        NSLayoutConstraint.activate([
            stopButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stopButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartCapture else { return }
        didStartCapture = true
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }

    @objc private func finishCapture() {
        roomCaptureView.captureSession.stop(pauseARSession: false)
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        error == nil
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        guard !didFinishCapture else { return }
        didFinishCapture = true

        do {
            if let error { throw error }
            let payload = try exportCapture(processedResult)
            DispatchQueue.main.async { self.onComplete(.success(payload)) }
        } catch {
            DispatchQueue.main.async { self.onComplete(.failure(error)) }
        }
    }

    private func exportCapture(_ room: CapturedRoom) throws -> SpatialCapturePayload {
        let captureId = "capture-roomplan-\(UUID().uuidString.lowercased())"
        let coordinateSpaceId = "roomplan-session-\(UUID().uuidString.lowercased())"
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("SpatialCaptures", isDirectory: true)
        let store = try LocalSpatialArtifactStore(directoryURL: directory)
        let exportURL = directory.appendingPathComponent("\(captureId).usdz")
        try room.export(to: exportURL, exportOptions: .parametric)
        let artifact = try store.persist(
            data: Data(contentsOf: exportURL),
            id: captureId,
            kind: .roomUSDZ,
            contentType: "model/vnd.usdz+zip"
        )
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let evidenceId = "evidence-\(captureId)"

        return SpatialCapturePayload(
            id: captureId,
            coordinateSpaceId: coordinateSpaceId,
            timestamp: timestamp,
            producer: "ios-roomplan",
            artifacts: [artifact],
            evidence: [SpatialEvidence(
                id: evidenceId,
                type: .roomModel,
                label: "RoomPlan capture \(captureId)",
                uri: artifact.uri
            )]
        )
    }
}
