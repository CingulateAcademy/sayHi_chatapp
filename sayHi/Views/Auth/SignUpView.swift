import SwiftUI

struct SignUpView: View {
    @Bindable var authService: AuthService
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var appeared = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password, confirm }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.isEmpty
            && password.count >= 6
            && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandHeaderView()
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.lg)
                    

                // Card
                VStack(spacing: Spacing.md) {
                    Text("Create account")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Join sayHi and start chatting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Spacing.xs)

                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(AuthTextFieldStyle())
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }

                    TextField("Email", text: $email)
                        .textFieldStyle(AuthTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    AuthPasswordField(
                        title: "Password",
                        text: $password,
                        textContentType: .newPassword,
                        submitLabel: .next
                    ) {
                        focusedField = .confirm
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        AuthPasswordField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            textContentType: .newPassword,
                            submitLabel: .go
                        ) {
                            Task { await signUp() }
                        }

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.leading, 4)
                                .transition(.opacity)
                        }

                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.leading, 4)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: passwordsMatch)

                    if let error = authService.errorMessage {
                        errorBanner(error)
                    }

                    PrimaryButton(
                        title: "Create Account",
                        isLoading: authService.isLoading,
                        isDisabled: !canSubmit
                    ) {
                        Task { await signUp() }
                    }

                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
                )
                .padding(.horizontal, Spacing.lg)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .padding(.bottom, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }


    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }

    private func signUp() async {
        focusedField = nil
        guard canSubmit else {
            if !passwordsMatch {
                authService.errorMessage = "Passwords don't match."
            }
            Haptics.error()
            return
        }
        Haptics.light()
        await authService.signUp(email: email, password: password, displayName: displayName)
        if authService.errorMessage != nil { Haptics.error() }
        else { Haptics.success() }
    }
}
