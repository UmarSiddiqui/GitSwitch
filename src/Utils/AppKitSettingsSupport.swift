import AppKit
import SwiftUI

/// LSUIElement apps do not take focus by default; bringing Settings forward requires activation
/// plus ordering the correct `NSWindow` after SwiftUI creates it.
enum SettingsWindowSupport {
    static let windowTitle = "GitSwitch Settings"
    static let windowIdentifier = NSUserInterfaceItemIdentifier("com.gitswitch.settings")

    static func activateAndFocusSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        attemptFocus(attempt: 0)
    }

    private static func attemptFocus(attempt: Int) {
        DispatchQueue.main.async {
            if focusSettingsWindow() {
                return
            }
            if attempt < 12 {
                attemptFocus(attempt: attempt + 1)
            }
        }
    }

    @discardableResult
    private static func focusSettingsWindow() -> Bool {
        if let window = NSApp.windows.first(where: {
            $0.identifier == windowIdentifier || $0.title == windowTitle
        }) {
            window.makeKeyAndOrderFront(nil)
            return true
        }
        return false
    }
}

/// Sets the host `NSWindow` title and a stable identifier so we can focus the Settings window reliably.
struct WindowTitleModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content.background(WindowTitleAccessor(title: title))
    }
}

private struct WindowTitleAccessor: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.title = title
            window.identifier = SettingsWindowSupport.windowIdentifier
        }
    }
}

extension View {
    /// Applies the standard GitSwitch Settings window title and `NSWindow` identifier.
    func settingsWindowTitle(_ title: String = SettingsWindowSupport.windowTitle) -> some View {
        modifier(WindowTitleModifier(title: title))
    }
}
