import Foundation

/// Shells out to `git config --global` to read and write Git user settings.
final class GitConfigManager {

    private init() {}

    // MARK: - Public API

    /// Reads a global Git config value by key.
    static func getGlobalConfig(key: String) async -> String? {
        let r = await ShellRunner.run(["git", "config", "--global", key])
        guard r.exitCode == 0 else { return nil }
        return r.standardOutput
    }

    /// Writes a global Git config value. On failure, returns stderr/stdout from `git` when present.
    static func setGlobalConfig(key: String, value: String) async -> (success: Bool, message: String?) {
        let r = await ShellRunner.run(["git", "config", "--global", key, value])
        guard r.exitCode == 0 else {
            let detail = [r.standardError, r.standardOutput]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            if detail.isEmpty {
                return (false, "git config exited with code \(r.exitCode).")
            }
            return (false, detail)
        }
        return (true, nil)
    }

    /// Returns the currently configured Git user name and email.
    static func getCurrentUser() async -> (name: String?, email: String?) {
        async let name = getGlobalConfig(key: "user.name")
        async let email = getGlobalConfig(key: "user.email")
        return (await name, await email)
    }

    /// Applies a profile by setting both `user.name` and `user.email` globally.
    static func applyProfile(gitName: String, gitEmail: String) async -> (success: Bool, message: String?) {
        let nameResult = await setGlobalConfig(key: "user.name", value: gitName)
        let emailResult = await setGlobalConfig(key: "user.email", value: gitEmail)
        if nameResult.success && emailResult.success {
            return (true, nil)
        }
        let parts = [nameResult.message, emailResult.message]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return (false, parts.isEmpty ? "Failed to update global Git user." : parts.joined(separator: "\n"))
    }

    /// Ensures HTTPS GitHub URLs are automatically rewritten to SSH.
    static func ensureSSHInsteadOf() async {
        _ = await setGlobalConfig(key: "url.git@github.com:.insteadOf", value: "https://github.com/")
    }
}
