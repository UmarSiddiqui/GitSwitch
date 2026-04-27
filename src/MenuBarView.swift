import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if !viewModel.profiles.isEmpty {
                profileList
                    .padding(.vertical, 4)
            }

            Divider()
                .padding(.horizontal, 12)

            footer
        }
        .frame(minWidth: 260)
        .background(.clear)
    }

    // MARK: - Subviews

    private var header: some View {
        Text("GitSwitch")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    private var profileList: some View {
        ForEach(viewModel.profiles) { profile in
            Button {
                viewModel.activateProfile(profile)
            } label: {
                HStack(spacing: 10) {
                    avatar(for: profile)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(profile.gitName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    statusIndicator(for: profile)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                profile.id == viewModel.activeProfileID
                    ? Color.accentColor.opacity(0.1)
                    : Color.clear
            )
            .animation(.spring(), value: viewModel.activeProfileID)
        }
    }

    private func avatar(for profile: GitProfile) -> some View {
        Group {
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
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func statusIndicator(for profile: GitProfile) -> some View {
        if viewModel.isSwitching && profile.id == viewModel.activeProfileID {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.7)
        } else if profile.id == viewModel.activeProfileID {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14, weight: .semibold))
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                openSettingsWindow()
            } label: {
                Label("Settings…", systemImage: "gear")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Helpers

    private func openSettingsWindow() {
        openWindow(id: "settings")
    }
}
