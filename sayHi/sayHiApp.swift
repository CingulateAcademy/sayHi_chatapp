import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct sayHiApp: App {
    @State private var authService: AuthService

        init() {
            // Configure Firebase before any services or auth checks run
            FirebaseApp.configure()
            
            // Initialize authService safely after Firebase is ready
            _authService = State(initialValue: AuthService())
        }
    
    
    var body: some Scene {
            WindowGroup {
                Group {
                    if authService.user != nil {
                        MainPlaceholderView(authService: authService)
                    } else {
                        AuthView(authService: authService)
                    }
                }
                .animation(.easeInOut, value: authService.user != nil)
            }
        }
}


struct MainPlaceholderView: View {
    @Bindable var authService: AuthService

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("You're signed in!")
                    .font(.title.bold())
                
                Text(authService.user?.email ?? "")
                    .foregroundStyle(.secondary)

                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("sayHi")
        }
    }
}

