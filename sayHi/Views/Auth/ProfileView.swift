import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    @Bindable var authService: AuthService
    @Bindable var userService: UserService

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSaveSuccess = false
    @Environment(\.dismiss) private var dismiss

    // live profile fall back to Auth so the name is never blank
    private var displayName: String {
        let fromProfile = userService.currentUserProfile?.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromProfile.isEmpty { return fromProfile }

        let fromAuth = authService.user?.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromAuth.isEmpty { return fromAuth }

        let email = userService.currentUserProfile?.email
            ?? authService.user?.email
            ?? ""
        if let local = email.components(separatedBy: "@").first, !local.isEmpty {
            return local
        }
        return "User"
    }

    private var photoURL: String {
        userService.currentUserProfile?.photoURL
            ?? authService.user?.photoURL?.absoluteString
            ?? ""
    }

    private var email: String {
        userService.currentUserProfile?.email
            ?? authService.user?.email
            ?? ""
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: Spacing.md) {
                        ZStack(alignment: .bottomTrailing) {
                            AvatarView(
                                photoURL: photoURL,
                                name: displayName,
                                size: 108
                            )
                            .overlay {
                                if userService.isUpdating && userService.uploadProgress > 0 {
                                    Circle()
                                        .fill(.black.opacity(0.35))
                                    ProgressView(value: userService.uploadProgress)
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .frame(width: 36, height: 36)
                                }
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 34))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.accentColor)
                            }
                            .disabled(userService.isUpdating)
                        }

                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .listRowBackground(Color.clear)
                }

                Section("Display Name") {
                    if isEditingName {
                        HStack(spacing: Spacing.sm) {
                            TextField("Name", text: $editedName)
                                .textInputAutocapitalization(.words)
                                .textContentType(.name)

                            Button("Save") {
                                Task {
                                    await userService.updateDisplayName(editedName)
                                    if userService.errorMessage == nil {
                                        Haptics.success()
                                        showSaveSuccess = true
                                        isEditingName = false
                                    } else {
                                        Haptics.error()
                                    }
                                }
                            }
                            .fontWeight(.semibold)
                            .disabled(
                                editedName.trimmingCharacters(in: .whitespaces).isEmpty
                                || userService.isUpdating
                            )
                        }
                    } else {
                        HStack {
                            Text(displayName)
                            Spacer()
                            Button("Edit") {
                                editedName = displayName == "User" ? "" : displayName
                                isEditingName = true
                            }
                            .fontWeight(.medium)
                        }
                    }
                }

                Section("Account") {
                    LabeledContent("User ID") {
                        Text(authService.user?.uid ?? "")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Haptics.medium()
                        userService.stopListening()
                        authService.signOut()
                        dismiss()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task { await handlePhoto(newItem) }
            }
            .overlay {
                if userService.isUpdating && userService.uploadProgress == 0 {
                    ProgressView()
                        .scaleEffect(1.15)
                        .padding(Spacing.lg)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
            }
            .alert("Error", isPresented: .constant(userService.errorMessage != nil)) {
                Button("OK") { userService.errorMessage = nil }
            } message: {
                Text(userService.errorMessage ?? "")
            }
            .alert("Saved", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your display name was updated.")
            }
        }
    }

    private func handlePhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        selectedPhoto = nil
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await userService.uploadAvatar(image)
            if userService.errorMessage == nil {
                Haptics.success()
            } else {
                Haptics.error()
            }
        }
    }
}
