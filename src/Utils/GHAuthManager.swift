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
            // gh auth status lines look like:
            // "  ✓ Logged in to github.com as umarsiddiqui (...)"
            if line.contains("Logged in to github.com as ") {
                if let range = line.range(of: "as ") {
                    let after = line[range.upperBound...]
                    let username = after.components(separatedBy: .whitespaces).first
                    return username?.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }

    /// Returns all GitHub accounts known to `gh` CLI.
    static func listAccounts() async -> [String] {
        guard await isAvailable() else { return [] }

        let (output, exitCode) = await ShellRunner.run(["gh", "auth", "status", "--hostname", "github.com"])
        guard exitCode == 0, let output = output else { return [] }

        var accounts: [String] = []
        for line in output.components(separatedBy: .newlines) {
            if line.contains("Logged in to github.com as ") {
                if let range = line.range(of: "as ") {
                    let after = line[range.upperBound...]
                    if let username = after.components(separatedBy: .whitespaces).first {
                        accounts.append(String(username))
                    }
                }
            }
        }
        return accounts
    }

    /// Opens a browser-based GitHub login flow via `gh auth login --web`.
    static func loginWithBrowser() async {
        guard await isAvailable() else { return }
        _ = await ShellRunner.run(["gh", "auth", "login", "--web", "--hostname", "github.com"])
    }
}
