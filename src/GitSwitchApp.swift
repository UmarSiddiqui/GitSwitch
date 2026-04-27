import SwiftUI

@main
struct GitSwitchApp: App {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("GitSwitch", systemImage: "arrow.left.arrow.right.circle") {
            MenuBarView()
                .environmentObject(viewModel)
        }

        WindowGroup(id: "settings") {
            ContentView()
                .environmentObject(viewModel)
        }
        .defaultSize(width: 520, height: 480)
    }
}
