import SwiftUI

struct ScanResultsView: View {
    @State var results: [ScannedProfile]
    let onImport: ([ScannedProfile]) -> Void
    @Environment(\.dismiss) private var dismiss

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
            }

            Divider()

            actionButtons
                .padding(24)
        }
        .frame(minWidth: 520, minHeight: 380)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scan Results")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("We found \(results.filter { $0.isSelected }.count) of \(results.count) possible profiles. Toggle the ones you want to import.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("No accounts found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("We couldn't detect any existing GitHub accounts, SSH keys, or Git configurations. You can still add a profile manually.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var actionButtons: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button {
                let selected = results.filter(\.isSelected)
                onImport(selected)
                dismiss()
            } label: {
                Label("Import \(results.filter { $0.isSelected }.count) Profiles", systemImage: "arrow.down.doc")
                    .font(.system(size: 13, weight: .semibold))
            }
            .keyboardShortcut(.defaultAction)
            .disabled(results.filter { $0.isSelected }.isEmpty)
        }
    }
}

// MARK: - Row

struct ScanResultRow: View {
    @Binding var profile: ScannedProfile

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $profile.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: profile.source.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .semibold))

                if !profile.username.isEmpty {
                    Text("@\(profile.username)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
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
                    .foregroundStyle(.secondary.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            Text(profile.source.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}
