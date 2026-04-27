import Foundation

/// Manages `gh` CLI account switching so GitHub CLI operations
/// (repo creation, PRs, releases, etc.) stay in sync with the active profile.
final class GHAuthManager {

    /// Returns whether the `gh` CLI is installed and accessible.
    static func isAvailable() async -> Bool {
        await ShellRunner.runSuccess(["which", "gh"])
    }

    /// Switches the active `gh` CLI account to the given GitHub username.
    static func switchToAccount(_ username: String) async {
        guard await isAvailable() else { return }
        _ = await ShellRunner.run(["gh", "auth", "switch", "--user", username])
    }

    /// Returns the currently active `gh` CLI username, if any.
    static func activeAccount() async -> String? {
        guard await isAvailable() else { return nil }

        let (output, _) = await ShellRunner.run(["gh", "auth", "status", "--hostname", "github.com"])
        guard let output = output else { return nil }

        for line in output.components(separatedBy: .newlines) {
            if line.contains("account UmarSiddiqui") || line.contains("account umar-abweb") {
                let parts = line.components(separatedBy: "account ")
                if parts.count > 1 {
                    return parts[1].components(separatedBy: " ").first
                }
            }
        }
        return nil
    }
}
