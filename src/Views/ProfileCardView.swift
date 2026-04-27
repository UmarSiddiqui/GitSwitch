import SwiftUI

struct ProfileCardView: View {
    let profile: GitProfile
    @EnvironmentObject var viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 16) {
            avatar

            infoColumn

            Spacer()

            statusIndicator
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    profile.id == viewModel.activeProfileID
                        ? Color.green.opacity(0.5)
                        : Color.secondary.opacity(0.15),
                    lineWidth: profile.id == viewModel.activeProfileID ? 2 : 1
                )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.activateProfile(profile)
        }
        .animation(.spring(), value: viewModel.activeProfileID)
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
        .overlay(
            Circle()
                .stroke(
                    profile.id == viewModel.activeProfileID
                        ? Color.green
                        : Color.secondary.opacity(0.2),
                    lineWidth: 2
                )
        )
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            nameRow
            gitIdentityRow
            usernameRow
            sshKeyRow
        }
    }

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(profile.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            if profile.isDefault {
                Text("Default")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var gitIdentityRow: some View {
        Text("\(profile.gitName) <\(profile.gitEmail)>")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var usernameRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "link")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text(profile.username)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var sshKeyRow: some View {
        Text(profile.sshKeyPath)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary.opacity(0.8))
            .lineLimit(1)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if viewModel.isSwitching && profile.id == viewModel.activeProfileID {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.8)
        } else if profile.id == viewModel.activeProfileID {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 22, weight: .semibold))
                .transition(.scale.combined(with: .opacity))
        }
    }
}
