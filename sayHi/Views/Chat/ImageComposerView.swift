import SwiftUI

struct PendingChatImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

//preview sheet
struct ImageComposerView: View {
    let image: UIImage
    var isSending: Bool
    var onCancel: () -> Void
    var onSend: (String) -> Void

    @State private var caption = ""
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image preview will always fill available space
                ZStack {
                    Color.black

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(Spacing.md)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

                // Caption + send bar
                HStack(alignment: .bottom, spacing: Spacing.xs) {
                    TextField("Add a caption…", text: $caption, axis: .vertical)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .lineLimit(1...4)
                        .focused($captionFocused)
                        .disabled(isSending)

                    Button {
                        Haptics.light()
                        onSend(caption.trimmingCharacters(in: .whitespacesAndNewlines))
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(isSending)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Send Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSending)
                }
            }
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay {
                if isSending {
                    ZStack {
                        Color.black.opacity(0.45).ignoresSafeArea()
                        VStack(spacing: Spacing.sm) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                            Text("Sending…")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(Spacing.lg)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                }
            }
        }
        // Prevent interactive swipe-dismiss while uploading
        .interactiveDismissDisabled(isSending)
    }
}
