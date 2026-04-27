import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var isPresentingEditor = false
    @State private var editingProfile: GitProfile? = nil

    var body: some View {
        VStack(spacing: 0) {
            errorBanner

            ScrollView {
                VStack(spacing: 20) {
                    header

                    if viewModel.profiles.isEmpty {
                        emptyState
                    } else {
                        profileGrid
                    }

                    addButton
                }
                .padding(24)
            }
        }
        .frame(minWidth: 480, minHeight: 360)
        .sheet(isPresented: $isPresentingEditor) {
            ProfileEditorView(profile: editingProfile)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 4) {
            Text("Git Profiles")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Switch between your Git identities")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var profileGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
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
        .animation(.spring(), value: viewModel.activeProfileID)
        .animation(.spring(), value: viewModel.profiles.count)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text("No profiles yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var addButton: some View {
        Button {
            editingProfile = nil
            isPresentingEditor = true
        } label: {
            Label("Add Profile", systemImage: "plus.circle.fill")
                .font(.system(size: 14, weight: .semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.lastError {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)

                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer()

                Button {
                    viewModel.lastError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.9))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
