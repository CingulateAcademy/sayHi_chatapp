import Foundation
import FirebaseAuth
import FirebaseFirestore


@Observable
final class AuthService {
    var user: User? = nil
    var isLoading = false
    var errorMessage: String?
    
    var isAuthReady = false
   

    private var db: Firestore {
        Firestore.firestore()
    }
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        
        if let existing = Auth.auth().currentUser{
            self.user = existing
            self.isAuthReady = true
            
            Task{
                await self.validateAndSetUser(existing)
            }
        }
        
        
        
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                
                guard let self else{return }
                
                Task{
                    @MainActor in
                    
                    if let user {
                        self.user = user
                        self.isAuthReady = true
                        Task{
                            await self.validateAndSetUser(user)
                        }
                    }else{
                        self.user = nil
                        self.isAuthReady = true
                    }
                }

                }
                    
        Task{
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run{
                if !self.isAuthReady{
                    self.user = Auth.auth().currentUser
                    self.isAuthReady = true
                }
            }
        }
        
        
        
        }

    
    deinit {
            // Clean up the listener if the service ever deallocates
            if let handle = authStateHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    
    private func validateAndSetUser(_ user : User)async{
        
        do{
            try await user.reload()
            
            await MainActor.run {self.user = Auth.auth().currentUser}
            try await ensureUserDocumentExists(for: Auth.auth().currentUser ?? user)
            
            
        }catch{
            
            let nsError = error as NSError
            
            let codeThatrequireSignout: Set<Int> = [17011,17005,17021,17014]
            if nsError.domain == AuthErrorDomain && codeThatrequireSignout.contains(nsError.code)
            {
                print("Auth user invalid \(nsError.code) signing out locally")
                
                await MainActor.run{
                    try? Auth.auth().signOut()
                    self.user = nil
                }
            }else{
                await MainActor.run {self.user = user}
                try? await ensureUserDocumentExists(for: user)
            }
            
        }
        
        
    }
    

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            try await createUserDocument(user: result.user, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await ensureUserDocumentExists(for: result.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async -> Bool{
        
        
        let trim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trim.isEmpty else {
            errorMessage = "You have to enter an email"
            return false
        }
        
        isLoading = true
        
        errorMessage = nil
        
        defer {isLoading = false}
        
        do{
            try await Auth.auth().sendPasswordReset(withEmail: trim)
            return true
            
        }catch{
            errorMessage = error.localizedDescription
            return false
            
        }
        
        
    }

    private func ensureUserDocumentExists(for user: User, fallbackDisplayName: String? = nil) async throws {
        let userRef = db.collection("users").document(user.uid)
        let snapshot = try await userRef.getDocument()

        guard snapshot.exists else{
            throw NSError(
                domain: "AuthService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile no longer exists"]
            )
        }
        
        try await userRef.updateData([
            "lastSeen": FieldValue.serverTimestamp()
        ])
    }

  
    
    private func createUserDocument(user: User, displayName: String) async throws {
        let data: [String: Any] = [
            "displayName": displayName,
            "email": user.email ?? "",
            "photoURL": user.photoURL?.absoluteString ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "lastSeen": FieldValue.serverTimestamp(),
            "fcmTokens": [],
            "bio": ""
        ]

        try await db.collection("users").document(user.uid).setData(data)
    }


}

