import Foundation

/// Represents a single GitHub / Git identity profile.
struct GitProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String          // e.g. "Personal"
    var username: String      // e.g. "umarsiddiqui"
    var gitName: String       // e.g. "Umar Siddiqui"
    var gitEmail: String      // e.g. "umar@example.com"
    var sshKeyPath: String    // e.g. "~/.ssh/id_rsa"
    var isDefault: Bool       // whether this is the fallback profile

    /// Returns the GitHub avatar URL for the associated username.
    var avatarURL: URL? {
        URL(string: "https://github.com/\(username).png")
    }
}
