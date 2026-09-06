import Foundation

@main
struct LiveAssistantViewCheck {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sourceURL = root.appendingPathComponent("apps/ios/LiveAssistantView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        precondition(source.contains("AVCaptureVideoPreviewLayer"), "The live assistant must render a regular camera preview.")
        precondition(source.contains("AVCapturePhotoOutput"), "The live assistant must capture still evidence frames.")
        precondition(source.contains("startListening()"), "The live assistant must retain tap-to-talk Realtime input.")
        precondition(source.contains("finishListening()"), "The live assistant must commit a tap-to-stop Realtime turn.")
        precondition(source.contains("realtime.isListening ? \"Stop talking\" : \"Talk\""), "The Talk control must change to Stop talking while recording.")
        precondition(source.contains("@ObservedObject private var realtime: RealtimeSessionClient"), "The Live Assistant must redraw immediately when Realtime connection, Talk, and camera-tool state changes.")
        precondition(source.contains("_realtime = ObservedObject(wrappedValue: viewModel.realtime)"), "The Live Assistant must subscribe to its view model's Realtime client.")
        precondition(source.contains("realtime.isConnecting ? \"Connecting…\""), "The Connect control must show an in-flight connection state.")
        precondition(source.contains(".disabled(realtime.isConnecting)"), "The Connect control must prevent overlapping connection attempts.")
        precondition(source.contains("recordPanelFrame"), "Captured photos must enter the typed panel-evidence path.")
        precondition(source.contains("ScrollViewReader"), "Long Realtime transcripts must remain scrollable while audio is streaming.")
        precondition(source.contains("live-response-end"), "Streaming transcripts must follow the newest spoken text.")
        precondition(source.contains("hasSpatialCapture"), "The live assistant must require a completed RoomPlan capture.")
        precondition(source.contains("AssessmentDetailsSheet"), "The live assistant must expose editable typed assessment details.")
        precondition(source.contains("Finish and review"), "The live assistant must provide an explicit deterministic assessment completion action.")
        print("Live assistant camera and Realtime composition check passed.")
    }
}
