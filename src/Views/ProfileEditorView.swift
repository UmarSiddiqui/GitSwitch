import SwiftUI

struct ProfileEditorView: View {
    let profile: GitProfile?
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var gitName = ""
    @State private var gitEmail = ""
    @State private var sshKeyPath = ""
    @State private var isDefault = false

    private var isEditing: Bool { profile != nil }

    var body: some View {
        VStack(spacing: 0) {
            formContent
                .padding(24)

            Divider()

            actionButtons
                .padding(24)
        }
        .frame(minWidth: 420, minHeight: 340)
        .onAppear {
            if let p = profile {
                name = p.name
                username = p.username
                gitName = p.gitName
                gitEmail = p.gitEmail
                sshKeyPath = p.sshKeyPath
                isDefault = p.isDefault
            }
        }
    }

    // MARK: - Subviews

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Edit Profile" : "New Profile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Configure your Git identity and SSH key")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                formRow("Profile Name", text: $name, placeholder: "e.g. Work")
                formRow("GitHub Username", text: $username, placeholder: "e.g. umar-abweb")
                formRow("Git Name", text: $gitName, placeholder: "e.g. Umar ABWeb")
                formRow("Git Email", text: $gitEmail, placeholder: "e.g. umar@abweb.com.au")

                sshKeyRow

                Toggle("Set as default profile", isOn: $isDefault)
                    .font(.system(size: 13))
            }
        }
    }

    private func formRow(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var sshKeyRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SSH Private Key Path")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("~/.ssh/id_rsa", text: $sshKeyPath)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                Button {
                    browseForSSHKey()
                } label: {
                    Text("Browse…")
                }
                .controlSize(.small)
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button {
                saveProfile()
            } label: {
                Text(isEditing ? "Save" : "Add Profile")
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name.isEmpty || username.isEmpty || gitName.isEmpty || sshKeyPath.isEmpty)
        }
    }

    // MARK: - Actions

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
