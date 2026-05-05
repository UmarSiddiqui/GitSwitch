import SwiftUI

struct ScanResultsView: View {
    @State var results: [ScannedProfile]
    let onImport: ([ScannedProfile]) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(24)

            Divider()

            if results.isEmpty {
                emptyState
                    .padding(24)
            } else {
                List($results) { $profile in
                    ScanResultRow(profile: $profile)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Divider()

            actionButtons
                .padding(24)
        }
        .frame(minWidth: 540, minHeight: 400)
        .tint(GitSwitchTheme.brandIndigo)
        .background(scanBackground)
    }

    private var scanBackground: some View {
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

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            GitSwitchBrandTile(size: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("Scan results")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Found \(results.count) candidate\(results.count == 1 ? "" : "s"). Select which identities to import.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(GitSwitchTheme.brandIndigo.opacity(0.85))
                .symbolRenderingMode(.hierarchical)

            Text("No accounts found")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text("We could not detect GitHub CLI logins, SSH keys, or Git config. Add a profile manually in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
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
                let selected = results.filter(\.isSelected)
                onImport(selected)
                dismiss()
            } label: {
                Label("Import \(results.filter(\.isSelected).count) profile\(results.filter(\.isSelected).count == 1 ? "" : "s")", systemImage: "arrow.down.doc")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(results.filter(\.isSelected).isEmpty)
        }
    }
}

// MARK: - Row

struct ScanResultRow: View {
    @Binding var profile: ScannedProfile
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $profile.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: profile.source.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(GitSwitchTheme.brandIndigo)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                if !profile.username.isEmpty {
                    Text("@\(profile.username)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(GitSwitchTheme.brandIndigo)
                }

                HStack(spacing: 4) {
                    Text(profile.gitName)
                        .font(.system(size: 11))
                    if !profile.gitEmail.isEmpty {
                        Text("<\(profile.gitEmail)>")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(.secondary)

                Text(profile.sshPrivateKeyPath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(profile.source.rawValue)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(GitSwitchTheme.brandIndigo.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GitSwitchTheme.brandIndigo.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: GitSwitchTheme.cornerRow, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: GitSwitchTheme.cornerRow, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.07), lineWidth: 1)
        }
    }
}
