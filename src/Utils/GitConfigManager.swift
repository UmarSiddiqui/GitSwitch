import Foundation

/// Shells out to `git config --global` to read and write Git user settings.
final class GitConfigManager {

    private init() {}

    // MARK: - Low-level helpers

    /// Runs a `git config --global` command and returns the trimmed stdout.
    private static func runGit(arguments: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["git", "config", "--global"] + arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice // suppress "not set" errors

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    /// Runs a `git config --global` command that returns only success/failure.
    private static func runGitSetting(arguments: [String]) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["git", "config", "--global"] + arguments

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Public API

    /// Reads a global Git config value by key.
    static func getGlobalConfig(key: String) -> String? {
        runGit(arguments: [key])
    }

    /// Writes a global Git config value.
    static func setGlobalConfig(key: String, value: String) -> Bool {
        runGitSetting(arguments: [key, value])
    }

    /// Returns the currently configured Git user name and email.
    static func getCurrentUser() -> (name: String?, email: String?) {
        let name = getGlobalConfig(key: "user.name")
        let email = getGlobalConfig(key: "user.email")
        return (name, email)
    }

    /// Applies a profile by setting both `user.name` and `user.email` globally.
    static func applyProfile(gitName: String, gitEmail: String) -> Bool {
        let nameSuccess = setGlobalConfig(key: "user.name", value: gitName)
        let emailSuccess = setGlobalConfig(key: "user.email", value: gitEmail)
        return nameSuccess && emailSuccess
    }
}

extension GitConfigManager {
    /// Ensures HTTPS GitHub URLs are automatically rewritten to SSH.
    /// This is idempotent — safe to call multiple times.
    static func ensureSSHInsteadOf() -> Bool {
        _ = setGlobalConfig(key: "url.git@github.com:.insteadOf", value: "https://github.com/")
        return true
    }
}
