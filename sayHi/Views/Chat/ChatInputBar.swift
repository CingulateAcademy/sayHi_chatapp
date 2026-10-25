import SwiftUI
import PhotosUI

struct ChatInputBar: View {
    @Binding var text: String
    var isSending: Bool
    var onSendText: () -> Void

    var onImagePicked: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .disabled(isSending)
            .onChange(of: selectedItem) { _, newItem in
                Task { await handleSelectedPhoto(newItem) }
            }

            TextField("Message", text: $text, axis: .vertical)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.sayHiSurface)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .lineLimit(1...6)
                .focused($isFocused)

            Button {
                Haptics.light()
                onSendText()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canSend ? Color.accentColor : Color.gray.opacity(0.35))
            }
            .disabled(!canSend || isSending)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        selectedItem = nil
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            Haptics.light()
            onImagePicked(image)
        }
    }
}
