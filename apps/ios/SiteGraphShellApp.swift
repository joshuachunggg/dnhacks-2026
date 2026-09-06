import SwiftUI

@main
struct SiteGraphShellApp: App {
    @StateObject private var viewModel = SiteGraphDemoViewModel()

    init() {
        // RoomPlan currently triggers a RealityKit shader assertion under Metal API Validation on device.
        // Set this before SwiftUI can construct any RoomPlan or SceneKit-backed views.
        setenv("MTL_DEBUG_LAYER", "0", 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
