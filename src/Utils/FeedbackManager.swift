import Foundation
import AppKit
import UserNotifications

/// Provides user feedback when switching profiles: notifications, sound, and haptics.
final class FeedbackManager {

    static let shared = FeedbackManager()

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifySwitchSuccess(profileName: String) {
        let content = UNMutableNotificationContent()
        content.title = "GitSwitch"
        content.body = "Switched to \(profileName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "gitswitch-switch-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notifySwitchFailure(profileName: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "GitSwitch — Switch Failed"
        content.body = "Could not switch to \(profileName): \(error)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "gitswitch-fail-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Sound

    func playSuccessSound() {
        NSSound(named: "Glass")?.play()
    }

    func playFailureSound() {
        NSSound(named: "Basso")?.play()
    }

    // MARK: - Haptic

    func performHapticFeedback() {
        if #available(macOS 10.11, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(
                NSHapticFeedbackManager.FeedbackPattern.alignment,
                performanceTime: .now
            )
        }
    }
}
