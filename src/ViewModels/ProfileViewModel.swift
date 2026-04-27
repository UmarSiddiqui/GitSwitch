import Foundation
import Combine
import AppKit

/// Manages the collection of Git profiles, persists them via `UserDefaults`,
/// and handles activation (switching Git & SSH configs).
final class ProfileViewModel: ObservableObject {

    @Published var profiles: [GitProfile] = []
    @Published var activeProfileID: UUID?
    @Published var isSwitching: Bool = false
    @Published var lastError: String?
    @Published var lastSwitchedDate: Date?
    @Published var isScanning: Bool = false

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
            // First launch — leave empty so the user can scan or add profiles
            profiles = []
            saveProfiles()
        }

        Task { @MainActor in
            await detectActiveProfile()
        }
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
        Task { @MainActor in
            await performSwitch(to: profile)
        }
    }

    @MainActor
    private func performSwitch(to profile: GitProfile) async {
        isSwitching = true
        lastError = nil

        let sshManager = SSHConfigManager()

        // Validate SSH key exists before doing anything
        guard sshManager.keyExists(at: profile.sshKeyPath) else {
            lastError = "SSH key not found: \(profile.sshKeyPath)\nPlease check the path in Settings."
            isSwitching = false
            FeedbackManager.shared.notifySwitchFailure(profileName: profile.name, error: "SSH key missing")
            FeedbackManager.shared.playFailureSound()
            return
        }

        let gitSuccess = await GitConfigManager.applyProfile(gitName: profile.gitName, gitEmail: profile.gitEmail)
        guard gitSuccess else {
            lastError = "Failed to apply Git configuration."
            isSwitching = false
            FeedbackManager.shared.notifySwitchFailure(profileName: profile.name, error: "Git config failed")
            FeedbackManager.shared.playFailureSound()
            return
        }

        // Ensure HTTPS URLs are rewritten to SSH so profile switching works for all clones
        await GitConfigManager.ensureSSHInsteadOf()

        // Switch gh CLI account to match this profile
        await GHAuthManager.switchToAccount(profile.username)

        let sshSuccess = sshManager.applyIdentity(keyPath: profile.sshKeyPath)
        guard sshSuccess else {
            lastError = "Failed to update SSH configuration."
            isSwitching = false
            FeedbackManager.shared.notifySwitchFailure(profileName: profile.name, error: "SSH config failed")
            FeedbackManager.shared.playFailureSound()
            return
        }

        let agentSuccess = await sshManager.addKeyToAgent(keyPath: profile.sshKeyPath)
        guard agentSuccess else {
            lastError = "Failed to add SSH key to agent. Make sure the key is valid and the passphrase (if any) is cached."
            isSwitching = false
            FeedbackManager.shared.notifySwitchFailure(profileName: profile.name, error: "SSH agent failed")
            FeedbackManager.shared.playFailureSound()
            return
        }

        activeProfileID = profile.id
        isSwitching = false
        lastSwitchedDate = Date()

        FeedbackManager.shared.notifySwitchSuccess(profileName: profile.name)
        FeedbackManager.shared.playSuccessSound()
        FeedbackManager.shared.performHapticFeedback()
    }

    // MARK: - CRUD

    func addProfile(_ profile: GitProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func addProfiles(_ newProfiles: [GitProfile]) {
        profiles.append(contentsOf: newProfiles)
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

    // MARK: - Scanning

    @MainActor
    func scanForProfiles() async -> [ScannedProfile] {
        isScanning = true
        defer { isScanning = false }
        return await ProfileScanner.scan()
    }

    @MainActor
    func importScannedProfiles(_ scanned: [ScannedProfile]) {
        let newProfiles = scanned.map { s in
            GitProfile(
                id: UUID(),
                name: s.name,
                username: s.username,
                gitName: s.gitName,
                gitEmail: s.gitEmail,
                sshKeyPath: s.sshPrivateKeyPath,
                isDefault: false
            )
        }
        addProfiles(newProfiles)
    }

    // MARK: - Detection

    /// Inspects the current Git user name, email, and SSH identity to infer the active profile.
    func detectActiveProfile() async {
        let current = await GitConfigManager.getCurrentUser()
        let sshManager = SSHConfigManager()
        let currentIdentity = sshManager.readCurrentIdentity()

        await MainActor.run {
            activeProfileID = profiles.first(where: { profile in
                let nameMatches = profile.gitName == current.name
                let emailMatches = profile.gitEmail == current.email
                let identityMatches = matchIdentity(profile.sshKeyPath, currentIdentity)
                return nameMatches && emailMatches && identityMatches
            })?.id
        }
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
