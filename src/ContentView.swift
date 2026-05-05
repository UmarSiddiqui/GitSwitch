import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresentingEditor = false
    @State private var isPresentingScanner = false
    @State private var editingProfile: GitProfile? = nil
    @State private var scanResults: [ScannedProfile] = []

    var body: some View {
        VStack(spacing: 0) {
            errorBanner

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    settingsHeader

                    if !viewModel.profiles.isEmpty {
                        GitSwitchTheme.sectionCaption("Profiles")
                            .padding(.top, 20)
                            .padding(.bottom, 10)

                        profileGrid
                    } else {
                        emptyState
                            .padding(.top, 28)
                    }

                    actionButtons
                        .padding(.top, viewModel.profiles.isEmpty ? 20 : 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .padding(.top, 8)
            }
        }
        .settingsWindowTitle()
        .frame(minWidth: 520, minHeight: 400)
        .tint(GitSwitchTheme.brandIndigo)
        .background(settingsBackground)
        .sheet(isPresented: $isPresentingEditor) {
            ProfileEditorView(profile: editingProfile)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $isPresentingScanner) {
            ScanResultsView(results: scanResults) { selected in
                viewModel.importScannedProfiles(selected)
            }
        }
    }

    // MARK: - Chrome

    private var settingsBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [
                    GitSwitchTheme.brandIndigo.opacity(colorScheme == .dark ? 0.12 : 0.06),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    private var settingsHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            GitSwitchBrandTile(size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("GitSwitch · profiles on this Mac")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Profiles

    private var profileGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 14) {
            ForEach(viewModel.profiles) { profile in
                ProfileCardView(profile: profile)
                    .environmentObject(viewModel)
                    .contextMenu {
                        Button {
                            viewModel.activateProfile(profile)
                        } label: {
                            Label("Set as Active", systemImage: "checkmark.circle")
                        }

                        Button {
                            editingProfile = profile
                            isPresentingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.deleteProfile(id: profile.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.activeProfileID)
        .animation(.easeOut(duration: 0.2), value: viewModel.profiles.count)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                GitSwitchTheme.brandIndigo.opacity(0.35),
                                GitSwitchTheme.brandIndigo.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "person.2.crop.square.stack")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(GitSwitchTheme.brandIndigo)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("No profiles yet")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Scan this Mac for GitHub CLI logins, SSH keys, and Git config—or add a profile by hand.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                runScan()
            } label: {
                Label("Scan for accounts", systemImage: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                runScan()
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.isScanning)

            Button {
                editingProfile = nil
                isPresentingEditor = true
            } label: {
                Label("Add profile", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.lastError {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.2)))

                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    viewModel.lastError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.92), Color.red.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func runScan() {
        Task { @MainActor in
            scanResults = await viewModel.scanForProfiles()
            isPresentingScanner = true
        }
    }
}
