import SwiftUI

@main
struct SiteGraphShellApp: App {
    @StateObject private var viewModel = SiteGraphDemoViewModel.scaffold

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
