import RoomPlan
import SwiftUI
import UIKit

struct RoomPlanCaptureCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @State private var isPresentingCapture = false
    @State private var isPresentingModelPreview = false
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
                    if capturePayload.detectedObjectTypes.isEmpty {
                        Text("RoomPlan did not classify any supported objects in this scan.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Detected object types: \(capturePayload.detectedObjectTypes.map { "\($0.count) \($0.category)" }.joined(separator: ", ")).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
                } else if capturePayload != nil {
                    Button("Restore saved scan from Mac") {
                        Task { await viewModel.restoreSavedSpatialCaptureFromMac() }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if capturePayload != nil {
                    Button("Forget saved scan", role: .destructive) {
                        viewModel.forgetSavedSpatialCapture()
                    }
                    .buttonStyle(.bordered)
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

    private var capturePayload: SpatialCapturePayload? {
        viewModel.spatialCapturePayload
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
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let statusLabel = UILabel()

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

        statusLabel.text = "Ready. Tap Start room scan when you are ready to move around the room."
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        statusLabel.layer.cornerRadius = 10
        statusLabel.clipsToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        startButton.setTitle("Start room scan", for: .normal)
        startButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        startButton.tintColor = .white
        startButton.backgroundColor = .systemIndigo
        startButton.layer.cornerRadius = 12
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startCapture), for: .touchUpInside)
        view.addSubview(startButton)

        stopButton.setTitle("Finish room scan", for: .normal)
        stopButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        stopButton.tintColor = .white
        stopButton.backgroundColor = .systemIndigo
        stopButton.layer.cornerRadius = 12
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(finishCapture), for: .touchUpInside)
        view.addSubview(stopButton)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            statusLabel.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -12),
            startButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            startButton.bottomAnchor.constraint(equalTo: stopButton.topAnchor, constant: -12),
            startButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            stopButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stopButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if didStartCapture && !didFinishCapture { roomCaptureView.captureSession.stop(pauseARSession: true) }
    }

    @objc private func startCapture() {
        guard !didStartCapture else { return }
        didStartCapture = true
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        startButton.isEnabled = false
        startButton.alpha = 0.5
        stopButton.isEnabled = true
        stopButton.alpha = 1
        statusLabel.text = "Scanning. Slowly move around the relevant room, then tap Finish room scan."
    }

    @objc private func finishCapture() {
        guard didStartCapture, !didFinishCapture else { return }
        statusLabel.text = "Processing room scan…"
        stopButton.isEnabled = false
        roomCaptureView.captureSession.stop(pauseARSession: false)
    }

    @objc private func applicationDidEnterBackground() {
        guard didStartCapture, !didFinishCapture else { return }
        roomCaptureView.captureSession.stop(pauseARSession: true)
        didStartCapture = false
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
        startButton.isEnabled = true
        startButton.alpha = 1
        statusLabel.text = "Scan paused while the app was inactive. Tap Start room scan to begin a fresh scan."
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error {
            didFinishCapture = true
            DispatchQueue.main.async { self.onComplete(.failure(error)) }
            return false
        }
        return true
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
            detectedObjectTypes: roomPlanObjectTypes(in: room),
            artifacts: [artifact],
            evidence: [SpatialEvidence(
                id: evidenceId,
                type: .roomModel,
                label: "RoomPlan capture \(captureId)",
                uri: artifact.uri
            )]
        )
    }

    private func roomPlanObjectTypes(in room: CapturedRoom) -> [RoomPlanObjectType] {
        Dictionary(grouping: room.objects) { object in
            String(describing: object.category)
        }
        .map { category, objects in
            RoomPlanObjectType(category: category, count: objects.count)
        }
        .sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
    }
}
