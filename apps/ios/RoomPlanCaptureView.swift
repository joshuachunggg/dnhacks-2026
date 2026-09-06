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
                    Text("For EV placement, scan the relevant garage or room. For room expansion, scan both adjacent rooms and their shared divider in one continuous capture.")
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
                            .presentationDragIndicator(.visible)
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
    private var roomCaptureView: RoomCaptureView?
    private let onComplete: (Result<SpatialCapturePayload, Error>) -> Void
    private var didStartCapture = false
    private var isFinishingCapture = false
    private var didDeliverResult = false
    private var isCapturePaused = false
    private let stopButton = UIButton(type: .system)

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
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCaptureIfVisible()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseCaptureForInterruption()
    }

    private func startCaptureIfVisible() {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  UIApplication.shared.applicationState == .active,
                  self.viewIfLoaded?.window != nil,
                  !self.didStartCapture,
                  !self.isFinishingCapture,
                  !self.didDeliverResult
            else { return }
            self.isCapturePaused = false
            self.installCaptureView()
            self.didStartCapture = true
            self.roomCaptureView?.captureSession.run(configuration: RoomCaptureSession.Configuration())
            self.stopButton.isEnabled = true
            self.stopButton.alpha = 1
        }
    }

    private func installCaptureView() {
        guard roomCaptureView == nil else { return }
        let captureView = RoomCaptureView(frame: .zero)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        captureView.delegate = self
        view.insertSubview(captureView, at: 0)
        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        roomCaptureView = captureView
    }

    @objc private func finishCapture() {
        guard didStartCapture, !isFinishingCapture, !didDeliverResult else { return }
        isFinishingCapture = true
        didStartCapture = false
        stopButton.isEnabled = false
        roomCaptureView?.captureSession.stop(pauseARSession: true)
    }

    @objc private func applicationDidEnterBackground() {
        pauseCaptureForInterruption()
    }

    @objc private func applicationWillResignActive() {
        pauseCaptureForInterruption()
    }

    private func pauseCaptureForInterruption() {
        guard didStartCapture, !isFinishingCapture, !didDeliverResult else { return }
        isCapturePaused = true
        releaseCaptureResources()
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
    }

    private func releaseCaptureResources() {
        guard let roomCaptureView else { return }
        if didStartCapture {
            roomCaptureView.captureSession.stop(pauseARSession: true)
        }
        roomCaptureView.delegate = nil
        roomCaptureView.removeFromSuperview()
        self.roomCaptureView = nil
        didStartCapture = false
    }

    @objc private func applicationDidBecomeActive() {
        startCaptureIfVisible()
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        guard !isCapturePaused else { return false }
        if let error {
            didDeliverResult = true
            releaseCaptureResources()
            DispatchQueue.main.async { self.onComplete(.failure(error)) }
            return false
        }
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        guard !didDeliverResult else { return }
        didDeliverResult = true

        do {
            if let error { throw error }
            let payload = try exportCapture(processedResult)
            releaseCaptureResources()
            DispatchQueue.main.async { self.onComplete(.success(payload)) }
        } catch {
            releaseCaptureResources()
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
