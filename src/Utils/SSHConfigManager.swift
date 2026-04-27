import Foundation

/// Reads and writes `~/.ssh/config` to manage the SSH identity for GitHub.
final class SSHConfigManager {

    // MARK: - Paths

    private var sshDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
    }

    var sshConfigPath: String {
        sshDirectory.appendingPathComponent("config").path
    }

    private var sshConfigURL: URL {
        sshDirectory.appendingPathComponent("config")
    }

    /// Expands a leading `~` to the user's home directory.
    private func resolvePath(_ path: String) -> String {
        if path.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return home + path.dropFirst()
        }
        return path
    }

    // MARK: - Public API

    /// Parses `~/.ssh/config` and returns the current `IdentityFile` for `Host github.com`.
    func readCurrentIdentity() -> String? {
        let configPath = sshConfigURL
        guard FileManager.default.fileExists(atPath: configPath.path) else { return nil }

        guard let data = try? Data(contentsOf: configPath),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()

            if lower.hasPrefix("host ") && trimmed.contains("github.com") {
                for j in (index + 1)..<lines.count {
                    let innerLine = lines[j].trimmingCharacters(in: .whitespacesAndNewlines)
                    let innerLower = innerLine.lowercased()

                    if innerLower.hasPrefix("host ") {
                        break
                    }

                    if innerLower.hasPrefix("identityfile ") {
                        let parts = innerLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                        if parts.count > 1 {
                            return String(parts[1])
                        }
                    }
                }
                break
            }
        }

        return nil
    }

    /// Rewrites or adds the `Host github.com` block with the supplied `IdentityFile`.
    func applyIdentity(keyPath: String) -> Bool {
        let sshDir = sshDirectory
        if !FileManager.default.fileExists(atPath: sshDir.path) {
            do {
                try FileManager.default.createDirectory(
                    at: sshDir,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700]
                )
            } catch {
                return false
            }
        }

        let configPath = sshConfigURL
        var content = ""

        if FileManager.default.fileExists(atPath: configPath.path),
           let data = try? Data(contentsOf: configPath),
           let existing = String(data: data, encoding: .utf8) {
            content = existing
        }

        var lines = content.components(separatedBy: .newlines)
        var hostStartIndex: Int?
        var identityLineIndex: Int?

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()

            if lower.hasPrefix("host ") && trimmed.contains("github.com") {
                hostStartIndex = index

                for j in (index + 1)..<lines.count {
                    let innerLine = lines[j].trimmingCharacters(in: .whitespacesAndNewlines)
                    let innerLower = innerLine.lowercased()

                    if innerLower.hasPrefix("host ") {
                        break
                    }
                    if innerLower.hasPrefix("identityfile ") {
                        identityLineIndex = j
                        break
                    }
                }
                break
            }
        }

        let newIdentityLine = "  IdentityFile \(keyPath)"

        if let hostIndex = hostStartIndex {
            if let identityIndex = identityLineIndex {
                lines[identityIndex] = newIdentityLine
            } else {
                lines.insert(newIdentityLine, at: hostIndex + 1)
            }
        } else {
            if !content.isEmpty && !lines.last!.isEmpty {
                lines.append("")
            }
            lines.append("Host github.com")
            lines.append(newIdentityLine)
        }

        let newContent = lines.joined(separator: "\n")

        do {
            try newContent.write(to: configPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Validates that the SSH key file exists on disk.
    func keyExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: resolvePath(path))
    }

    /// Clears all identities from the SSH agent and adds the specified key.
    func addKeyToAgent(keyPath: String) async -> Bool {
        let resolvedPath = resolvePath(keyPath)

        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            return false
        }

        // Remove all existing identities (best-effort)
        _ = await ShellRunner.run(["ssh-add", "-D"])

        // Add the new identity
        return await ShellRunner.runSuccess(["ssh-add", resolvedPath])
    }
}
