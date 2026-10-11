import SwiftUI

struct AuthView: View {
    @Bindable var authService: AuthService
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft branded background
                LinearGradient(
                    colors: [
                        Color.sayHiIndigo.opacity(0.08),
                        Color(.systemBackground),
                        Color.sayHiPurple.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if showSignUp {
                        SignUpView(authService: authService)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        LoginView(authService: authService)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSignUp.toggle()
                            authService.errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text(showSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.sayHiIndigoLight)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, Spacing.xl)
                    .padding(.top, Spacing.sm)
                }
            }
            .navigationBarHidden(true)
            .overlay {
                if authService.isLoading {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.25)
                            .tint(Color.sayHiIndigo)
                            .padding(Spacing.lg)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: authService.isLoading)
        }
    }
}
