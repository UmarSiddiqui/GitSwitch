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

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
