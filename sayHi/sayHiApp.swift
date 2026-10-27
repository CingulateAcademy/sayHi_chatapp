import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct sayHiApp: App {
    @State private var authService: AuthService
    
    @State private var minSplashElapsed = false
    @State private var showSplash = true

        init() {
            // Configure Firebase before any services or auth checks run
            FirebaseApp.configure()
            
            // Initialize authService safely after Firebase is ready
            _authService = State(initialValue: AuthService())
        }
    
    
    var body: some Scene {
            WindowGroup {
                
                    ZStack{
                        Group {
                            if authService.user != nil {
                                ConversationListView(authService: authService)
                            } else if authService.isAuthReady{
                                AuthView(authService: authService)
                            }else{
                                Color.sayHiIndigo.ignoresSafeArea()
                            }
                        }
                        .opacity(showSplash ? 0 : 1)
                        
                        if showSplash {
                            SplashView()
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }.animation(.easeOut(duration: 0.35), value: showSplash)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
                            minSplashElapsed = true
                            
                            dismissSplashIfReady()
                            
                        }
                    }.onChange(of: authService.isAuthReady){
                        _,_ in
                        
                        dismissSplashIfReady()
                    }.onChange(of: minSplashElapsed){
                        _, _ in
                        
                        dismissSplashIfReady()
                    }
                
                
                
            }
        }
    
    private func dismissSplashIfReady(){
        guard authService.isAuthReady, minSplashElapsed, showSplash else {return}
        
        withAnimation(.easeInOut(duration: 0.35)){
            showSplash = false
        }
    }
}




