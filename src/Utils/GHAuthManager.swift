import Foundation

/// Manages `gh` CLI account switching so GitHub CLI operations
/// (repo creation, PRs, releases, etc.) stay in sync with the active profile.
final class GHAuthManager {

    /// Returns whether the `gh` CLI is installed and accessible.
    static func isAvailable() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["which", "gh"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Switches the active `gh` CLI account to the given GitHub username.
    /// Returns `true` if successful (or if gh is not installed — we don't fail the whole switch for that).
    @discardableResult
    static func switchToAccount(_ username: String) -> Bool {
        guard isAvailable() else { return true }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["gh", "auth", "switch", "--user", username]

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Returns the currently active `gh` CLI username, if any.
    static func activeAccount() -> String? {
        guard isAvailable() else { return nil }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["gh", "auth", "status", "--hostname", "github.com"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }

            // Parse "Active account: true" line to extract the username
            for line in output.components(separatedBy: .newlines) {
                if line.contains("account UmarSiddiqui") || line.contains("account umar-abweb") {
                    let parts = line.components(separatedBy: "account ")
                    if parts.count > 1 {
                        let namePart = parts[1].components(separatedBy: " ").first
                        return namePart
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
