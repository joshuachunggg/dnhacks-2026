@preconcurrency import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct LiveAssistantEntryCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    let onFinish: () -> Void
    @State private var isPresentingAssistant = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.hasSpatialCapture
                     ? "The room scan is attached. Open the live assistant to inspect the space and talk with the guide."
                     : "Finish the short RoomPlan scan before opening the live assistant so photos remain linked to the captured room.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Open live assistant") {
                    isPresentingAssistant = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasSpatialCapture)
            }
        } label: {
            Label("Live assistant", systemImage: "waveform")
        }
        .fullScreenCover(isPresented: $isPresentingAssistant) {
            LiveAssistantView(
                viewModel: viewModel,
                dismiss: { isPresentingAssistant = false },
                finishAssessment: {
                    isPresentingAssistant = false
                    onFinish()
                }
            )
        }
    }
}

private struct LiveAssistantView: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @ObservedObject private var realtime: RealtimeSessionClient
    let dismiss: () -> Void
    let finishAssessment: () -> Void
    @StateObject private var camera = LiveAssistantCameraController()
    @State private var isPresentingDetails = false
    @State private var selectedEvidencePhoto: PhotosPickerItem?

    init(
        viewModel: SiteGraphDemoViewModel,
        dismiss: @escaping () -> Void,
        finishAssessment: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        _realtime = ObservedObject(wrappedValue: viewModel.realtime)
        self.dismiss = dismiss
        self.finishAssessment = finishAssessment
    }

    var body: some View {
        ZStack {
            if realtime.evidencePhotoRequest != nil {
                LiveCameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else if let modelURL = viewModel.roomModelURL {
                RoomModelQuickLookPreview(
                    modelURL: modelURL,
                    spatialHighlight: realtime.spatialHighlight,
                    spatialVisuals: viewModel.spatialVisuals,
                    placementRequest: realtime.spatialPlacementRequest,
                    onPoseSelected: { pose in
                        guard let request = realtime.spatialPlacementRequest else { return }
                        viewModel.previewSpatialPlacement(pose, request: request)
                        Task {
                            do {
                                if request.kind == .routePoint {
                                    realtime.addRouteWaypoint(pose)
                                } else if request.kind == .candidateOpening {
                                    viewModel.recordConceptualOpening(at: pose)
                                    realtime.completeConceptualOpening(pose)
                                } else {
                                    try await viewModel.recordSpatialPlacement(pose, request: request)
                                    realtime.completeSpatialPlacement(pose)
                                }
                            } catch {
                                realtime.spatialPlacementFailed("Could not record that placement: \(error.localizedDescription)")
                            }
                        }
                    }
                )
                    .ignoresSafeArea()
            } else {
                Color.black
                    .overlay(Text("Room model unavailable"), alignment: .center)
                    .foregroundStyle(.white)
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if let request = realtime.spatialPlacementRequest {
                VStack {
                    Spacer()
                    Text(request.kind == .routePoint
                         ? "Tap the full cable route on the room model, including bends. Finish when you have at least two points."
                         : "Tap the exact wall location for the \(request.kind.displayName).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(14)
                        .background(.indigo.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            }

            if realtime.spatialPlacementRequest?.kind == .routePoint {
                VStack {
                    Spacer()
                    Button("Finish route (\(realtime.routeWaypointCount) points)") {
                        guard let route = realtime.finishRouteWaypoints() else { return }
                        Task {
                            do {
                                try await viewModel.recordRouteWaypoints(route)
                                realtime.completeRouteWaypoints(route)
                            } catch {
                                realtime.spatialPlacementFailed("Could not record that route: \(error.localizedDescription)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(realtime.routeWaypointCount < 2)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Room scan attached", systemImage: "view.3d")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: Capsule())

                    Spacer()

                    Button("Details") {
                        isPresentingDetails = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .accessibilityLabel("Close live assistant")
                }
                .foregroundStyle(.white)

                if !viewModel.detectedRoomObjectTypes.isEmpty {
                    Text("RoomPlan detected: \(viewModel.detectedRoomObjectTypes.map { "\($0.count) \($0.category)" }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text(realtime.status)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))

                    if !realtime.responseText.isEmpty {
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(realtime.responseText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("live-response-end")
                            }
                            .frame(maxHeight: 112)
                            .onChange(of: realtime.responseText) { _, _ in
                                withAnimation { proxy.scrollTo("live-response-end", anchor: .bottom) }
                            }
                        }
                    }

                    if let request = realtime.evidencePhotoRequest {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Photo requested: \(request.evidenceKind.displayName)", systemImage: "camera.viewfinder")
                                .font(.footnote.weight(.semibold))
                            Text(request.reason)
                                .font(.footnote)
                            HStack {
                                Button("Capture photo") { camera.capturePhoto() }
                                    .buttonStyle(.borderedProminent)
                                PhotosPicker(selection: $selectedEvidencePhoto, matching: .images) {
                                    Label("Upload", systemImage: "photo.on.rectangle")
                                }
                                .buttonStyle(.bordered)
                                Button("Skip") { realtime.cancelEvidencePhotoRequest() }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.indigo.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if let request = realtime.spatialPlacementRequest {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tap-to-place: \(request.kind.displayName)", systemImage: "hand.tap.fill")
                                .font(.footnote.weight(.semibold))
                            Text(request.kind == .routePoint
                                 ? "Tap the cable route start, then tap its end."
                                 : request.instruction)
                                .font(.footnote)
                        }
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.indigo.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
                    }

                    Text("Collected: \(viewModel.collectedSpatialSummary)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))

                    if viewModel.engineeringStatusIsError {
                        Text(viewModel.engineeringStatus)
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    if viewModel.spatialVisuals.candidateOpeningPose != nil {
                        Text("Conceptual opening shown — structural feasibility and approvals remain unverified.")
                            .font(.caption)
                            .foregroundStyle(.mint)
                    }

                    if !realtime.isConnected {
                        SecureField("Realtime demo token", text: $viewModel.realtimeDemoToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                    }

                    if let cameraStatus = camera.status {
                        Text(cameraStatus)
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                    }

                    HStack(spacing: 12) {
                        Button(realtime.isConnected ? "Disconnect" : (realtime.isConnecting ? "Connecting…" : "Connect guide")) {
                            if realtime.isConnected {
                                realtime.disconnect()
                            } else {
                                Task { await viewModel.connectRealtime() }
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .disabled(realtime.isConnecting)
                    }

                    HStack(spacing: 12) {
                        if realtime.isConnected {
                            Button(realtime.isListening ? "Stop talking" : (realtime.isGuideSpeaking ? "Interrupt & talk" : "Talk")) {
                                realtime.isListening ? realtime.finishListening() : realtime.startListening()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(realtime.isListening ? .red : .indigo)
                            .accessibilityHint(realtime.isListening ? "Stops and sends your recorded question" : "Starts recording your question")
                            .frame(maxWidth: .infinity)
                        }

                        Button("Finish and review") {
                            Task {
                                guard await viewModel.runEngineeringScenario() else { return }
                                realtime.disconnect()
                                finishAssessment()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .disabled(viewModel.isRunningEngineeringScenario)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
                .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
            .opacity(realtime.spatialPlacementRequest == nil ? 1 : 0)
            .allowsHitTesting(realtime.spatialPlacementRequest == nil)
        }
        .onChange(of: realtime.evidencePhotoRequest?.id) { _, requestId in
            if requestId == nil {
                camera.stop()
            } else {
                camera.start()
            }
        }
        .onDisappear {
            camera.stop()
            realtime.disconnect()
        }
        .sheet(isPresented: $isPresentingDetails) {
            AssessmentDetailsSheet(viewModel: viewModel)
        }
        .onChange(of: camera.capturedFrame?.id) { _, _ in
            guard let frame = camera.capturedFrame else { return }
            Task {
                await viewModel.recordPanelFrame(
                    imageData: frame.data,
                    rectangleCount: PanelRectangleAnalyzer.rectangleCount(in: frame.image)
                )
                camera.clearStatus()
            }
        }
        .onChange(of: selectedEvidencePhoto) { _, photo in
            guard let photo else { return }
            Task {
                defer { selectedEvidencePhoto = nil }
                guard let data = try? await photo.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                    return
                }
                await viewModel.recordPanelFrame(
                    imageData: data,
                    rectangleCount: PanelRectangleAnalyzer.rectangleCount(in: image)
                )
                camera.clearStatus()
            }
        }
        .onChange(of: realtime.panelFactRequest?.id) { _, _ in
            guard let request = realtime.panelFactRequest else { return }
            Task {
                do {
                    try await viewModel.recordPanelFact(request)
                    realtime.completePanelFactRequest(
                        recorded: true,
                        message: "Recorded the user-confirmed \(request.field.displayName) panel fact."
                    )
                } catch {
                    realtime.completePanelFactRequest(
                        recorded: false,
                        message: "Could not record that panel fact: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
}

private struct AssessmentDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SiteGraphDemoViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Known assessment details") {
                    Picker("Demo focus", selection: $viewModel.assessmentFocus) {
                        ForEach(AssessmentFocus.allCases) { focus in
                            Text(focus.displayName).tag(focus)
                        }
                    }

                    TextField("Property address", text: $viewModel.propertyAddress)
                        .textContentType(.fullStreetAddress)
                        .textInputAutocapitalization(.words)

                    TextField("Vehicle (optional)", text: $viewModel.vehicleIntent)
                        .textInputAutocapitalization(.words)

                    Picker("Charging intent", selection: $viewModel.chargingIntent) {
                        Text("Not provided").tag("")
                        Text("Hardwired home charging").tag("Hardwired home charging")
                        Text("Plug-in home charging").tag("Plug-in home charging")
                        Text("I need installer guidance").tag("I need installer guidance")
                    }
                }

                Section {
                    Text("These typed details are included when the guide connects. Disconnect and reconnect after changing them so the current Realtime session receives the update.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Assessment details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveEngineeringIntent()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct LiveCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

private struct CapturedCameraFrame {
    let id = UUID()
    let data: Data
    let image: UIImage
}

private final class LiveAssistantCameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    @Published private(set) var capturedFrame: CapturedCameraFrame?
    @Published private(set) var isCapturing = false
    @Published private(set) var status: String?

    private let sessionQueue = DispatchQueue(label: "LiveAssistantCameraController.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureAndStart()
                } else {
                    self?.publishStatus("Camera access is required to send requested evidence photos.")
                }
            }
        default:
            publishStatus("Camera access is unavailable. Enable it in Settings to send evidence photos.")
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isConfigured, self.session.isRunning else {
                self.publishStatus("The camera is still starting. Try capturing again in a moment.")
                return
            }
            DispatchQueue.main.async { self.isCapturing = true }
            self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func clearStatus() { status = nil }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo
                defer { self.session.commitConfiguration() }
                do {
                    guard let device = AVCaptureDevice.default(for: .video) else {
                        self.publishStatus("No camera is available on this device.")
                        return
                    }
                    let input = try AVCaptureDeviceInput(device: device)
                    guard self.session.canAddInput(input), self.session.canAddOutput(self.photoOutput) else {
                        self.publishStatus("The camera could not be configured for evidence capture.")
                        return
                    }
                    self.session.addInput(input)
                    self.session.addOutput(self.photoOutput)
                    self.isConfigured = true
                } catch {
                    self.publishStatus("Could not start the camera: \(error.localizedDescription)")
                    return
                }
            }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { DispatchQueue.main.async { self.isCapturing = false } }
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            publishStatus("The camera could not save that photo. Try again.")
            return
        }
        DispatchQueue.main.async {
            self.capturedFrame = CapturedCameraFrame(data: data, image: image)
            self.status = "Photo captured. Recording evidence and sending it to the guide."
        }
    }

    private func publishStatus(_ message: String) {
        DispatchQueue.main.async { self.status = message }
    }
}
