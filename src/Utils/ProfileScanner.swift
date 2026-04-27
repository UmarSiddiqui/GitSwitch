import Foundation

/// Represents a GitHub profile discovered by scanning the local system.
struct ScannedProfile: Identifiable {
    let id = UUID()
    var name: String
    var username: String
    var gitName: String
    var gitEmail: String
    var sshPrivateKeyPath: String
    var sshPublicKeyPath: String?
    var source: DiscoverySource
    var isSelected: Bool = true
    var ghAccount: String?
}

enum DiscoverySource: String, CaseIterable {
    case gitConfig = "Git Config"
    case sshConfig = "SSH Config"
    case ghCLI = "GitHub CLI"
    case sshKey = "SSH Key"

    var icon: String {
        switch self {
        case .gitConfig: return "gearshape.fill"
        case .sshConfig: return "lock.shield.fill"
        case .ghCLI: return "terminal.fill"
        case .sshKey: return "key.fill"
        }
    }
}

/// Scans the local machine for existing Git configurations, SSH keys,
/// GitHub CLI accounts, and SSH config entries to suggest profiles.
final class ProfileScanner {

    // MARK: - Public API

    static func scan() async -> [ScannedProfile] {
        var results: [ScannedProfile] = []

        // 1. Detect gh CLI accounts (most authoritative for GitHub username)
        let ghAccounts = await scanGHAccounts()

        // 2. Detect SSH config entries for github.com
        let sshConfigEntries = scanSSHConfig()

        // 3. Detect SSH key files in ~/.ssh
        let sshKeys = scanSSHKeys()

        // 4. Detect current git global config
        let gitUser = await GitConfigManager.getCurrentUser()

        // Cross-reference gh accounts with SSH configs and keys
        for gh in ghAccounts {
            let matchingSSHConfig = sshConfigEntries.first { $0.identityFile.contains(gh.username) }
                ?? sshConfigEntries.first

            let privateKey = matchingSSHConfig?.identityFile
                ?? sshKeys.first?.privatePath
                ?? "~/.ssh/id_ed25519"

            results.append(ScannedProfile(
                name: gh.username.capitalized + " (GitHub)",
                username: gh.username,
                gitName: gitUser.name ?? gh.username,
                gitEmail: gitUser.email ?? "",
                sshPrivateKeyPath: privateKey,
                sshPublicKeyPath: findPublicKey(for: privateKey),
                source: .ghCLI,
                isSelected: true,
                ghAccount: gh.username
            ))
        }

        // If no gh accounts, suggest profiles from SSH config entries
        for entry in sshConfigEntries where !results.contains(where: { $0.sshPrivateKeyPath == entry.identityFile }) {
            let guessedName = guessName(from: entry.identityFile)
            results.append(ScannedProfile(
                name: guessedName,
                username: "",
                gitName: gitUser.name ?? "",
                gitEmail: gitUser.email ?? "",
                sshPrivateKeyPath: entry.identityFile,
                sshPublicKeyPath: findPublicKey(for: entry.identityFile),
                source: .sshConfig,
                isSelected: true
            ))
        }

        // Suggest profiles from loose SSH keys not already matched
        for key in sshKeys where !results.contains(where: { $0.sshPrivateKeyPath == key.privatePath }) {
            let guessedName = guessName(from: key.privatePath)
            results.append(ScannedProfile(
                name: guessedName,
                username: key.comment ?? "",
                gitName: gitUser.name ?? "",
                gitEmail: gitUser.email ?? "",
                sshPrivateKeyPath: key.privatePath,
                sshPublicKeyPath: key.publicPath,
                source: .sshKey,
                isSelected: false // unmapped keys are less certain
            ))
        }

        // If absolutely nothing found, at least offer current git config
        if results.isEmpty, (gitUser.name != nil || gitUser.email != nil) {
            results.append(ScannedProfile(
                name: "Current Git User",
                username: "",
                gitName: gitUser.name ?? "",
                gitEmail: gitUser.email ?? "",
                sshPrivateKeyPath: "~/.ssh/id_ed25519",
                sshPublicKeyPath: nil,
                source: .gitConfig,
                isSelected: true
            ))
        }

        return results
    }

    // MARK: - Sub-scans

    private static func scanGHAccounts() async -> [(username: String, email: String?)] {
        guard await GHAuthManager.isAvailable() else { return [] }
        let accounts = await GHAuthManager.listAccounts()
        return accounts.map { (username: $0, email: nil) }
    }

    private static func scanSSHConfig() -> [(host: String, identityFile: String)] {
        let manager = SSHConfigManager()
        let configPath = manager.sshConfigPath
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return []
        }

        var entries: [(host: String, identityFile: String)] = []
        let lines = content.components(separatedBy: .newlines)
        var currentHost: String?
        var currentIdentity: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("host ") {
                if let host = currentHost, let identity = currentIdentity {
                    entries.append((host: host, identityFile: identity))
                }
                currentHost = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                currentIdentity = nil
            } else if trimmed.lowercased().hasPrefix("identityfile "), currentHost != nil {
                let path = trimmed.dropFirst(13).trimmingCharacters(in: .whitespaces)
                currentIdentity = String(path)
            }
        }
        // flush last
        if let host = currentHost, let identity = currentIdentity {
            entries.append((host: host, identityFile: identity))
        }

        // Only include GitHub-related hosts
        return entries.filter { $0.host.contains("github") }
    }

    private static func scanSSHKeys() -> [(privatePath: String, publicPath: String?, comment: String?)] {
        let sshDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: sshDir.path) else {
            return []
        }

        let ignored = ["known_hosts", "authorized_keys", "config", "id_rsa.pub", "id_ed25519.pub", "id_ecdsa.pub", "id_dsa.pub"]
        var keys: [(privatePath: String, publicPath: String?, comment: String?)] = []

        for item in contents where !item.hasSuffix(".pub") && !ignored.contains(item) {
            let privatePath = sshDir.appendingPathComponent(item).path
            let publicPath = sshDir.appendingPathComponent(item + ".pub").path
            let hasPublic = FileManager.default.fileExists(atPath: publicPath)

            var comment: String?
            if hasPublic, let pubContent = try? String(contentsOfFile: publicPath, encoding: .utf8) {
                let parts = pubContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                if parts.count >= 3 {
                    comment = parts[2]
                }
            }

            keys.append((privatePath: privatePath, publicPath: hasPublic ? publicPath : nil, comment: comment))
        }

        return keys
    }

    private static func findPublicKey(for privatePath: String) -> String? {
        let publicPath = privatePath + ".pub"
        if FileManager.default.fileExists(atPath: publicPath) {
            return publicPath
        }
        return nil
    }

    private static func guessName(from path: String) -> String {
        let filename = (path as NSString).lastPathComponent
        let name = filename
            .replacingOccurrences(of: "id_", with: "")
            .replacingOccurrences(of: "rsa", with: "")
            .replacingOccurrences(of: "ed25519", with: "")
            .replacingOccurrences(of: "ecdsa", with: "")
            .replacingOccurrences(of: "dsa", with: "")
            .replacingOccurrences(of: "github", with: "")
            .replacingOccurrences(of: "__", with: "_")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)

        if name.isEmpty { return "GitHub Profile" }
        return name.capitalized
    }
}
