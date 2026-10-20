import SwiftUI

struct LoginView: View {
    @Bindable var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var appeared = false
    @State private var resetSent = false
    @State private var showResetAlert = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandHeaderView()
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.lg)

                VStack(spacing: Spacing.md) {
                    Text("Welcome back")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Spacing.xs)

                    
                    TextField("Email", text: $email)
                        .textFieldStyle(AuthTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        AuthPasswordField(
                            title: "Password",
                            text: $password,
                            textContentType: .password,
                            submitLabel: .go
                        ) {
                            Task { await login() }
                        }

                        Button("Forgot password?") {
                            Task{
                                await sendReset()
                            }
                        }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.sayHiIndigoLight)
                    }

                   
                    if let error = authService.errorMessage {
                        errorBanner(error)
                    }

                    
                    PrimaryButton(
                        title: "Sign In",
                        isLoading: authService.isLoading,
                        isDisabled: email.isEmpty || password.isEmpty
                    ) {
                        Task { await login() }
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
        }.alert(resetSent ? "Please check your email" : "Reset Password", isPresented: $showResetAlert){
            Button("OK", role: .cancel){}
            
        }message:{
            
            if resetSent {
                Text("We sent password reset link to your \(email)")
            }else{
                Text(authService.errorMessage ?? "Something went wrong!")
            }
            
            
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func login() async {
        focusedField = nil
        Haptics.light()
        await authService.signIn(email: email, password: password)
        if authService.errorMessage != nil { Haptics.error() }
        }
    
    
    private func sendReset()async{
       
        focusedField = nil
        
        let ok = await authService.resetPassword(email: email)
        
        resetSent = ok
        
        
        showResetAlert  = true
        
        
        if ok {Haptics.success()} else {Haptics.error()}
        
        
    }
    

}
