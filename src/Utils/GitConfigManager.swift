import Foundation

/// Shells out to `git config --global` to read and write Git user settings.
final class GitConfigManager {

    private init() {}

    // MARK: - Public API

    /// Reads a global Git config value by key.
    static func getGlobalConfig(key: String) async -> String? {
        let (output, _) = await ShellRunner.run(["git", "config", "--global", key])
        return output
    }

    /// Writes a global Git config value.
    static func setGlobalConfig(key: String, value: String) async -> Bool {
        await ShellRunner.runSuccess(["git", "config", "--global", key, value])
    }

    /// Returns the currently configured Git user name and email.
    static func getCurrentUser() async -> (name: String?, email: String?) {
        async let name = getGlobalConfig(key: "user.name")
        async let email = getGlobalConfig(key: "user.email")
        return (await name, await email)
    }

    /// Applies a profile by setting both `user.name` and `user.email` globally.
    static func applyProfile(gitName: String, gitEmail: String) async -> Bool {
        let nameSuccess = await setGlobalConfig(key: "user.name", value: gitName)
        let emailSuccess = await setGlobalConfig(key: "user.email", value: gitEmail)
        return nameSuccess && emailSuccess
    }

    /// Ensures HTTPS GitHub URLs are automatically rewritten to SSH.
    static func ensureSSHInsteadOf() async {
        _ = await setGlobalConfig(key: "url.git@github.com:.insteadOf", value: "https://github.com/")
    }
}
