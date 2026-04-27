import Foundation
import Combine

/// Manages the collection of Git profiles, persists them via `UserDefaults`,
/// and handles activation (switching Git & SSH configs).
final class ProfileViewModel: ObservableObject {

    @Published var profiles: [GitProfile] = []
    @Published var activeProfileID: UUID?
    @Published var isSwitching: Bool = false
    @Published var lastError: String?

    private let profilesKey = "gitswitch_profiles"

    // MARK: - Lifecycle

    init() {
        loadProfiles()
    }

    // MARK: - Persistence

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([GitProfile].self, from: data) {
            profiles = saved
        } else {
            // Seed with sensible defaults on first launch
            profiles = [
                GitProfile(
                    id: UUID(),
                    name: "Personal",
                    username: "umarsiddiqui",
                    gitName: "Umar Siddiqui",
                    gitEmail: "73005527+UmarSiddiqui@users.noreply.github.com",
                    sshKeyPath: "~/.ssh/id_ed25519_github",
                    isDefault: true
                ),
                GitProfile(
                    id: UUID(),
                    name: "Work",
                    username: "umar-abweb",
                    gitName: "Umar ABWeb",
                    gitEmail: "umar@abweb.com.au",
                    sshKeyPath: "~/.ssh/id_ecdsa",
                    isDefault: false
                )
            ]
            saveProfiles()
        }

        detectActiveProfile()
    }

    /// Encodes the profile list and writes it to `UserDefaults`.
    func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            lastError = "Failed to save profiles: \(error.localizedDescription)"
        }
    }

    // MARK: - Activation

    /// Switches the global Git identity and SSH key to match the chosen profile.
    func activateProfile(_ profile: GitProfile) {
        isSwitching = true
        lastError = nil

        let sshManager = SSHConfigManager()

        // Validate SSH key exists before doing anything
        guard sshManager.keyExists(at: profile.sshKeyPath) else {
            lastError = "SSH key not found: \(profile.sshKeyPath)\nPlease check the path in Settings."
            isSwitching = false
            return
        }

        let gitSuccess = GitConfigManager.applyProfile(gitName: profile.gitName, gitEmail: profile.gitEmail)
        guard gitSuccess else {
            lastError = "Failed to apply Git configuration."
            isSwitching = false
            return
        }

        // Ensure HTTPS URLs are rewritten to SSH so profile switching works for all clones
        GitConfigManager.ensureSSHInsteadOf()

        // Switch gh CLI account to match this profile
        GHAuthManager.switchToAccount(profile.username)

        let sshSuccess = sshManager.applyIdentity(keyPath: profile.sshKeyPath)
        guard sshSuccess else {
            lastError = "Failed to update SSH configuration."
            isSwitching = false
            return
        }

        let agentSuccess = sshManager.addKeyToAgent(keyPath: profile.sshKeyPath)
        guard agentSuccess else {
            lastError = "Failed to add SSH key to agent. Make sure the key is valid and the passphrase (if any) is cached."
            isSwitching = false
            return
        }

        activeProfileID = profile.id
        isSwitching = false
    }

    // MARK: - CRUD

    func addProfile(_ profile: GitProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func updateProfile(_ profile: GitProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveProfiles()
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll(where: { $0.id == id })
        if activeProfileID == id {
            activeProfileID = nil
        }
        saveProfiles()
    }

    // MARK: - Detection

    /// Inspects the current Git user name, email, and SSH identity to infer the active profile.
    func detectActiveProfile() {
        let current = GitConfigManager.getCurrentUser()
        let sshManager = SSHConfigManager()
        let currentIdentity = sshManager.readCurrentIdentity()

        activeProfileID = profiles.first(where: { profile in
            let nameMatches = profile.gitName == current.name
            let emailMatches = profile.gitEmail == current.email
            let identityMatches = matchIdentity(profile.sshKeyPath, currentIdentity)
            return nameMatches && emailMatches && identityMatches
        })?.id
    }

    /// Compares two SSH identity paths, resolving a leading `~` to the home directory.
    private func matchIdentity(_ profilePath: String, _ activePath: String?) -> Bool {
        guard let activePath = activePath else { return true }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let resolvedProfile = profilePath.replacingOccurrences(of: "~", with: home)
        let resolvedActive = activePath.replacingOccurrences(of: "~", with: home)
        return resolvedProfile == resolvedActive
    }
}
