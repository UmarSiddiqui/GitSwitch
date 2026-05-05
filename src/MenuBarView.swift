import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandRow
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            activeProfileCard
                .padding(.horizontal, 10)

            if !viewModel.profiles.isEmpty {
                sectionLabel("Identities")
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                profileList
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
            }

            Divider()
                .opacity(colorScheme == .dark ? 0.35 : 0.55)
                .padding(.horizontal, 10)

            footer
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
        .frame(minWidth: GitSwitchTheme.minMenuWidth)
        .background {
            RoundedRectangle(cornerRadius: GitSwitchTheme.cornerPanel, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.12), radius: 18, y: 8)
        }
        .padding(8)
    }

    // MARK: - Brand

    private var brandRow: some View {
        HStack(spacing: 8) {
            GitSwitchBrandTile()

            VStack(alignment: .leading, spacing: 1) {
                Text("GitSwitch")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Git & GitHub identity")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Active profile

    @ViewBuilder
    private var activeProfileCard: some View {
        if let activeID = viewModel.activeProfileID,
           let profile = viewModel.profiles.first(where: { $0.id == activeID }) {
            HStack(alignment: .center, spacing: 12) {
                activeAvatar(for: profile)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Active")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(GitSwitchTheme.brandIndigo)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(profile.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    if !profile.username.isEmpty {
                        Text("@\(profile.username)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    statusLine
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: GitSwitchTheme.cornerCard, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : GitSwitchTheme.brandIndigo.opacity(0.06))
                RoundedRectangle(cornerRadius: GitSwitchTheme.cornerCard, style: .continuous)
                    .strokeBorder(GitSwitchTheme.brandIndigo.opacity(colorScheme == .dark ? 0.35 : 0.22), lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [GitSwitchTheme.brandIndigo, GitSwitchTheme.brandIndigo.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, 10)
                    .padding(.leading, 4)
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if viewModel.isSwitching {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.75)
                Text("Applying…")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        } else if let date = viewModel.lastSwitchedDate {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("Updated \(timeAgo(date))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green.opacity(0.85))
                Text("Matches this Mac")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func activeAvatar(for profile: GitProfile) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [GitSwitchTheme.brandIndigo.opacity(0.9), GitSwitchTheme.brandIndigo.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 46, height: 46)
            avatarCore(for: profile, size: 40)
        }
    }

    // MARK: - Section

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    // MARK: - Profile list

    private var profileList: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.profiles) { profile in
                profileRow(profile)
            }
        }
    }

    private func profileRow(_ profile: GitProfile) -> some View {
        let isActive = profile.id == viewModel.activeProfileID
        let busy = viewModel.isSwitching && isActive

        return Button {
            viewModel.activateProfile(profile)
        } label: {
            HStack(spacing: 10) {
                avatarCore(for: profile, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if !profile.username.isEmpty {
                            Text("@\(profile.username)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text(profile.gitName)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                rowTrailing(for: profile, busy: busy, isActive: isActive)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: GitSwitchTheme.cornerRow, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: GitSwitchTheme.cornerRow, style: .continuous)
                    .fill(GitSwitchTheme.brandIndigo.opacity(colorScheme == .dark ? 0.22 : 0.12))
            }
        }
        .animation(.easeOut(duration: 0.18), value: viewModel.activeProfileID)
        .accessibilityLabel("Switch to profile \(profile.name)")
    }

    @ViewBuilder
    private func rowTrailing(for profile: GitProfile, busy: Bool, isActive: Bool) -> some View {
        if busy {
            ProgressView()
                .controlSize(.small)
        } else if isActive {
            Image(systemName: "largecircle.fill.circle")
                .symbolRenderingMode(.palette)
                .foregroundStyle(GitSwitchTheme.brandIndigo, Color.primary.opacity(0.35))
                .font(.system(size: 18, weight: .medium))
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
    }

    private func avatarCore(for profile: GitProfile, size: CGFloat) -> some View {
        Group {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholderAvatar(size: size)
                    }
                }
            } else {
                placeholderAvatar(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func placeholderAvatar(size: CGFloat) -> some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.38, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.8))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06))
            )
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            footerButton(title: "Settings…", systemImage: "gearshape.fill", iconTint: GitSwitchTheme.brandIndigo.opacity(0.9)) {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)
            footerButton(title: "Quit GitSwitch", systemImage: "power", iconTint: .secondary) {
                NSApplication.shared.terminate(nil)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func footerButton(title: String, systemImage: String, iconTint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(iconTint)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func openSettingsWindow() {
        openWindow(id: "settings")
        SettingsWindowSupport.activateAndFocusSettingsWindow()
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
