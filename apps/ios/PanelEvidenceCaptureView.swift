import SwiftUI
import UIKit
import Vision
import PhotosUI

struct PanelEvidenceCaptureCard: View {
    @ObservedObject var viewModel: SiteGraphDemoViewModel
    @State private var isPresentingCamera = false
    @State private var isRecording = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var localPreview: UIImage?
    @State private var captureError: String?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text("Capture one straight-on, well-lit panel image. The phone retains the original and records evidence metadata; visual detections remain proposals.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let localPreview {
                    Image(uiImage: localPreview)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Captured panel evidence frame")
                }

                Text(viewModel.visionStatus)
                    .font(.footnote)
                    .foregroundStyle(captureError == nil ? Color.secondary : Color.red)

                if let captureError {
                    Text(captureError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(localPreview == nil ? "Take panel photo" : "Retake panel photo") {
                    captureError = nil
                    isPresentingCamera = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRecording)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose existing photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
                .disabled(isRecording)
            }
        } label: {
            Label("Panel vision evidence", systemImage: "camera.viewfinder")
        }
        .sheet(isPresented: $isPresentingCamera) {
            PanelCameraPicker { result in
                isPresentingCamera = false
                switch result {
                case .success(let image):
                    localPreview = image
                    submit(image)
                case .failure(let error):
                    captureError = error.localizedDescription
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            Task {
                do {
                    guard let data = try await photo.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                        captureError = "The selected photo could not be read."
                        return
                    }
                    localPreview = image
                    submit(image)
                } catch {
                    captureError = "Could not load the selected photo: \(error.localizedDescription)"
                }
                selectedPhoto = nil
            }
        }
    }

    private func submit(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.82) else {
            captureError = "Could not encode the captured panel image."
            return
        }
        isRecording = true
        let rectangleCount = PanelRectangleAnalyzer.rectangleCount(in: image)
        Task {
            await viewModel.recordPanelFrame(imageData: imageData, rectangleCount: rectangleCount)
            isRecording = false
        }
    }
}

enum PanelRectangleAnalyzer {
    static func rectangleCount(in image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 8
        request.minimumConfidence = 0.5
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation)
        do {
            try handler.perform([request])
            return request.results?.count ?? 0
        } catch {
            return 0
        }
    }
}

private struct PanelCameraPicker: UIViewControllerRepresentable {
    let completion: (Result<UIImage, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let completion: (Result<UIImage, Error>) -> Void

        init(completion: @escaping (Result<UIImage, Error>) -> Void) {
            self.completion = completion
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(.failure(NSError(domain: "PanelCameraPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Panel capture was cancelled."])))
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                completion(.failure(NSError(domain: "PanelCameraPicker", code: 2, userInfo: [NSLocalizedDescriptionKey: "The camera did not return an image."])))
                return
            }
            completion(.success(image))
        }
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
