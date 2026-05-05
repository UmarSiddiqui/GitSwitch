import Foundation

/// Manages `gh` CLI account switching so GitHub CLI operations
/// (repo creation, PRs, releases, etc.) stay in sync with the active profile.
final class GHAuthManager {

    private struct AuthStatusJSON: Decodable {
        let hosts: [String: [HostAccount]]
    }

    private struct HostAccount: Decodable {
        let login: String
        let active: Bool
    }

    /// Returns whether the `gh` CLI is installed and accessible.
    static func isAvailable() async -> Bool {
        await ShellRunner.runSuccess(["which", "gh"])
    }

    /// Switches the active `gh` CLI account to the given GitHub username.
    static func switchToAccount(_ username: String) async {
        guard await isAvailable() else { return }
        guard !username.isEmpty else { return }
        _ = await ShellRunner.run(["gh", "auth", "switch", "--user", username])
    }

    /// Returns the currently active `gh` CLI username for github.com, if any.
    static func activeAccount() async -> String? {
        guard await isAvailable() else { return nil }

        if let fromJSON = await activeAccountFromJSONStatus() {
            return fromJSON
        }

        // Fallback: token-backed API reflects whichever account is active.
        let r = await ShellRunner.run(["gh", "api", "user", "-q", ".login"])
        guard r.exitCode == 0, let output = r.standardOutput, !output.isEmpty else { return nil }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func activeAccountFromJSONStatus() async -> String? {
        let r = await ShellRunner.run(["gh", "auth", "status", "--json", "hosts"])
        guard r.exitCode == 0, let output = r.standardOutput, let data = output.data(using: .utf8) else { return nil }

        guard let parsed = try? JSONDecoder().decode(AuthStatusJSON.self, from: data),
              let accounts = parsed.hosts["github.com"] else {
            return nil
        }

        return accounts.first(where: { $0.active })?.login
    }

    /// Returns all GitHub accounts known to `gh` CLI for github.com.
    static func listAccounts() async -> [String] {
        guard await isAvailable() else { return [] }

        let r = await ShellRunner.run(["gh", "auth", "status", "--json", "hosts"])
        guard r.exitCode == 0, let output = r.standardOutput, let data = output.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(AuthStatusJSON.self, from: data),
              let accounts = parsed.hosts["github.com"] else {
            return []
        }

        return accounts.map(\.login)
    }

    /// Opens a browser-based GitHub login flow via `gh auth login --web`.
    static func loginWithBrowser() async {
        guard await isAvailable() else { return }
        _ = await ShellRunner.run(["gh", "auth", "login", "--web", "--hostname", "github.com"])
    }
}
