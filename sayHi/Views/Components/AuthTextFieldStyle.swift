import SwiftUI

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 15)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(Color.sayHiSeparator, lineWidth: 1)
            )
    }
}

// Password field with show / hide toggle.
struct AuthPasswordField: View {
    let title: String
    @Binding var text: String
    var textContentType: UITextContentType = .password
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @State private var isVisible = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Group {
                if isVisible {
                    TextField(title, text: $text)
                        .textContentType(textContentType)
                } else {
                    SecureField(title, text: $text)
                        .textContentType(textContentType)
                }
            }
            .font(.body)
            .focused($focused)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }

            Button {
                isVisible.toggle()
                Haptics.light()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 15)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(
                    focused ? Color.sayHiIndigoLight.opacity(0.6) : Color.sayHiSeparator,
                    lineWidth: focused ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
    }
}
