import SwiftUI

struct ProfileEditorView: View {
    let profile: GitProfile?
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var name = ""
    @State private var username = ""
    @State private var gitName = ""
    @State private var gitEmail = ""
    @State private var sshKeyPath = ""
    @State private var isDefault = false
    @State private var isConnectingToGitHub = false

    private var isEditing: Bool { profile != nil }

    var body: some View {
        VStack(spacing: 0) {
            formContent
                .padding(24)

            Divider()

            actionButtons
                .padding(24)
        }
        .frame(minWidth: 440, minHeight: 400)
        .tint(GitSwitchTheme.brandIndigo)
        .background(editorBackground)
        .onAppear {
            if let p = profile {
                name = p.name
                username = p.username
                gitName = p.gitName
                gitEmail = p.gitEmail
                sshKeyPath = p.sshKeyPath
                isDefault = p.isDefault
            } else {
                prefillFromSystem()
            }
        }
    }

    private var editorBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [
                    GitSwitchTheme.brandIndigo.opacity(colorScheme == .dark ? 0.1 : 0.05),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Subviews

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 12) {
                GitSwitchBrandTile(size: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isEditing ? "Edit profile" : "New profile")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Git identity & SSH key for GitSwitch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            GitSwitchTheme.sectionCaption("Identity")
            VStack(alignment: .leading, spacing: 12) {
                formRow("Profile name", text: $name, placeholder: "e.g. Work")
                formRow("GitHub username", text: $username, placeholder: "e.g. umar-abweb")
                formRow("Git author name", text: $gitName, placeholder: "e.g. Umar ABWeb")
                formRow("Git author email", text: $gitEmail, placeholder: "e.g. umar@abweb.com.au")
            }

            GitSwitchTheme.sectionCaption("SSH")
            VStack(alignment: .leading, spacing: 12) {
                sshKeyRow
            }

            if !isEditing {
                GitSwitchTheme.sectionCaption("GitHub")
                connectRow
            }

            Toggle("Set as default profile", isOn: $isDefault)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.top, 4)
        }
    }

    private func formRow(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)

            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .regular))
                .textFieldStyle(.roundedBorder)
        }
    }

    private var sshKeyRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Private key path")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)

            HStack(spacing: 8) {
                TextField("~/.ssh/id_ed25519", text: $sshKeyPath)
                    .font(.system(size: 13, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                Button {
                    browseForSSHKey()
                } label: {
                    Text("Browse…")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .controlSize(.regular)
            }
        }
    }

    private var connectRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    connectToGitHub()
                } label: {
                    Label("Authorize with GitHub", systemImage: "link")
                        .font(.system(size: 12, weight: .medium))
                }
                .controlSize(.small)
                .disabled(isConnectingToGitHub)

                if hasPublicKey {
                    Button {
                        copyPublicKeyAndOpenGitHub()
                    } label: {
                        Label("Copy SSH Key", systemImage: "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .controlSize(.small)
                }
            }

            Text("Use GitHub CLI in the browser, or paste your public key on GitHub.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .controlSize(.large)

            Spacer()

            Button {
                saveProfile()
            } label: {
                Text(isEditing ? "Save changes" : "Add profile")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(name.isEmpty || username.isEmpty || gitName.isEmpty || sshKeyPath.isEmpty)
        }
    }

    // MARK: - Computed

    private var hasPublicKey: Bool {
        let publicPath = sshKeyPath + ".pub"
        return FileManager.default.fileExists(atPath: publicPath)
            || FileManager.default.fileExists(atPath: (publicPath as NSString).expandingTildeInPath)
    }

    // MARK: - Actions

    private func prefillFromSystem() {
        Task { @MainActor in
            let user = await GitConfigManager.getCurrentUser()
            gitName = user.name ?? ""
            gitEmail = user.email ?? ""
        }
    }

    private func browseForSSHKey() {
        let panel = NSOpenPanel()
        panel.title = "Select SSH Private Key"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")

        if panel.runModal() == .OK, let url = panel.url {
            sshKeyPath = url.path
        }
    }

    private func connectToGitHub() {
        isConnectingToGitHub = true
        Task { @MainActor in
            if await GHAuthManager.isAvailable() {
                await GHAuthManager.loginWithBrowser()
                // After login, try to detect the username
                if let account = await GHAuthManager.activeAccount(), username.isEmpty {
                    username = account
                }
            } else {
                // Open GitHub login in browser and guide user to install gh
                if let url = URL(string: "https://github.com/login") {
                    NSWorkspace.shared.open(url)
                }
                viewModel.lastError = "GitHub CLI (gh) not found. Install it with: brew install gh"
            }
            isConnectingToGitHub = false
        }
    }

    private func copyPublicKeyAndOpenGitHub() {
        let publicPath = (sshKeyPath + ".pub" as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: publicPath),
              let content = try? String(contentsOfFile: publicPath, encoding: .utf8) else {
            viewModel.lastError = "Public key not found at \(publicPath)"
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content.trimmingCharacters(in: .whitespacesAndNewlines), forType: .string)

        if let url = URL(string: "https://github.com/settings/keys/new") {
            NSWorkspace.shared.open(url)
        }
    }

    private func saveProfile() {
        let newProfile = GitProfile(
            id: profile?.id ?? UUID(),
            name: name,
            username: username,
            gitName: gitName,
            gitEmail: gitEmail,
            sshKeyPath: sshKeyPath,
            isDefault: isDefault
        )

        if isEditing {
            viewModel.updateProfile(newProfile)
        } else {
            viewModel.addProfile(newProfile)
        }

        dismiss()
    }
}
