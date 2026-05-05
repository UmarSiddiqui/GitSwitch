import SwiftUI

struct ProfileCardView: View {
    let profile: GitProfile
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var isActive: Bool { profile.id == viewModel.activeProfileID }

    var body: some View {
        HStack(spacing: 16) {
            avatar

            infoColumn

            Spacer(minLength: 8)

            statusIndicator
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: GitSwitchTheme.cornerCard, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: GitSwitchTheme.cornerCard, style: .continuous)
                .strokeBorder(
                    isActive
                        ? GitSwitchTheme.brandIndigo.opacity(colorScheme == .dark ? 0.55 : 0.4)
                        : Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    lineWidth: isActive ? 2 : 1
                )
        }
        .overlay(alignment: .leading) {
            if isActive {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [GitSwitchTheme.brandIndigo, GitSwitchTheme.brandIndigo.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, 12)
                    .padding(.leading, 4)
            }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 12, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.activateProfile(profile)
        }
        .animation(.easeOut(duration: 0.18), value: viewModel.activeProfileID)
    }

    // MARK: - Subviews

    private var avatar: some View {
        ZStack {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            isActive ? GitSwitchTheme.brandIndigo.opacity(0.95) : Color.secondary.opacity(0.25),
                            isActive ? GitSwitchTheme.brandIndigo.opacity(0.25) : Color.secondary.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.85))
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05)))
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            nameRow
            gitIdentityRow
            usernameRow
            sshKeyRow
        }
    }

    private var nameRow: some View {
        HStack(spacing: 8) {
            Text(profile.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            if profile.isDefault {
                Text("Default")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(GitSwitchTheme.brandIndigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(GitSwitchTheme.brandIndigo.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var gitIdentityRow: some View {
        Text("\(profile.gitName) <\(profile.gitEmail)>")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var usernameRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(GitSwitchTheme.brandIndigo.opacity(0.85))

            if !profile.username.isEmpty {
                Text("@\(profile.username)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(GitSwitchTheme.brandIndigo)
            }
        }
    }

    private var sshKeyRow: some View {
        Text(profile.sshKeyPath)
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if viewModel.isSwitching && isActive {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.9)
        } else if isActive {
            Image(systemName: "largecircle.fill.circle")
                .symbolRenderingMode(.palette)
                .foregroundStyle(GitSwitchTheme.brandIndigo, Color.primary.opacity(0.35))
                .font(.system(size: 22, weight: .medium))
                .transition(.scale.combined(with: .opacity))
        }
    }
}
