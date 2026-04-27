import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            activeProfileBanner

            if !viewModel.profiles.isEmpty {
                profileList
                    .padding(.vertical, 4)
            }

            Divider()
                .padding(.horizontal, 12)

            footer
        }
        .frame(minWidth: 280)
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

    private var activeProfileBanner: some View {
        Group {
            if let activeID = viewModel.activeProfileID,
               let profile = viewModel.profiles.first(where: { $0.id == activeID }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Profile")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(profile.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)

                        if let date = viewModel.lastSwitchedDate {
                            Text("Switched \(timeAgo(date))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
        }
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

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hrs = Int(interval / 3600)
            return "\(hrs)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
