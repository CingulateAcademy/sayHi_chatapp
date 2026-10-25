import SwiftUI
import FirebaseAuth

struct NewChatView: View {
    @Bindable var conversationService: ConversationService
    @Bindable var userService: UserService
    let currentUserId: String

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var users: [UserProfile] = []
    @State private var isLoading = false
    @State private var hasLoadedOnce = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && !hasLoadedOnce {
                    ProgressView("Loading people…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if users.isEmpty && hasLoadedOnce && !isLoading {
                    ContentUnavailableView(
                        searchText.trimmingCharacters(in: .whitespaces).count >= 2
                            ? "No users found"
                            : "No other users yet",
                        systemImage: "person.slash",
                        description: Text(
                            searchText.trimmingCharacters(in: .whitespaces).count >= 2
                                ? "Try a different name"
                                : "When others sign up, they’ll show up here"
                        )
                    )
                } else {
                    List(users) { user in
                        Button {
                            Task { await startChat(with: user) }
                        } label: {
                            HStack(spacing: 14) {
                                AvatarView(
                                    photoURL: user.photoURL,
                                    name: user.displayName,
                                    size: 44
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .disabled(isCreating)
                    }
                    .listStyle(.plain)
                    .overlay(alignment: .bottom) {
                        if isLoading && hasLoadedOnce {
                            ProgressView()
                                .padding(10)
                                .background(.regularMaterial)
                                .clipShape(Capsule())
                                .padding(.bottom, 8)
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await performSearch(query: newValue)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isCreating {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView("Starting chat…")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadInitialUsers()
            }
        }
    }

    private func loadInitialUsers() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoadedOnce = true
        }
        do {
            users = try await conversationService.fetchAllUsers(excludingUserId: currentUserId)
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 {
            await loadInitialUsers()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await conversationService.searchUsers(
                query: trimmed,
                excludingUserId: currentUserId
            )
            guard !Task.isCancelled else { return }
            users = result
            hasLoadedOnce = true
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startChat(with otherUser: UserProfile) async {
        let currentProfile: UserProfile
        if let profile = userService.currentUserProfile {
            currentProfile = profile
        } else if let uid = Auth.auth().currentUser?.uid {
            let authUser = Auth.auth().currentUser
            currentProfile = UserProfile(
                id: uid,
                displayName: authUser?.displayName
                    ?? authUser?.email?.components(separatedBy: "@").first
                    ?? "User",
                email: authUser?.email ?? "",
                photoURL: authUser?.photoURL?.absoluteString ?? "",
                bio: "",
                createdAt: nil,
                lastSeen: nil,
                fcmTokens: nil
            )
        } else {
            errorMessage = "Could not load your profile. Try signing out and back in."
            return
        }

        guard !currentProfile.id.isEmpty, !otherUser.id.isEmpty else {
            errorMessage = "Invalid user data"
            return
        }

        isCreating = true
        defer { isCreating = false }

        do {
            _ = try await conversationService.createOrGetConversation(
                currentUser: currentProfile,
                otherUser: otherUser
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
