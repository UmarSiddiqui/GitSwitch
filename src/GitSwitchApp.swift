import SwiftUI
import UserNotifications

@main
struct GitSwitchApp: App {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.openWindow) private var openWindow

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        // `.window` is required for custom layouts, materials, and tints. The default `.menu`
        // style renders like an NSMenu and strips most SwiftUI chrome, so the UI looks "stuck"
        // on the old simple list even after code changes.
        MenuBarExtra("GitSwitch", systemImage: "arrow.left.arrow.right.circle") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "settings") {
            ContentView()
                .environmentObject(viewModel)
        }
        .defaultSize(width: 520, height: 480)
        .commands {
            CommandMenu("GitSwitch") {
                Button("Settings…") {
                    openWindow(id: "settings")
                    SettingsWindowSupport.activateAndFocusSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
