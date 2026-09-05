import QuickLook
import SwiftUI
import UIKit

struct RoomModelQuickLookPreview: UIViewControllerRepresentable {
    let modelURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = RoomModelPreviewController(modelURL: modelURL)
        controller.dataSource = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
}

private final class RoomModelPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    private let modelURL: URL

    init(modelURL: URL) {
        self.modelURL = modelURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        modelURL as NSURL
    }
}
