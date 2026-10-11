import Foundation
import FirebaseAuth
import FirebaseFirestore


@Observable
final class AuthService {
    var user: User? = nil
    var isLoading = false
    var errorMessage: String?

    private var db: Firestore {
        Firestore.firestore()
    }
    private var currentNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                self?.user = user
                if let user {
                    Task {
                        do {
                            try await self?.ensureUserDocumentExists(for: user)
                        } catch {
                            self?.errorMessage = error.localizedDescription
                        }
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

    private func ensureUserDocumentExists(for user: User, fallbackDisplayName: String? = nil) async throws {
        let userRef = db.collection("users").document(user.uid)
        let snapshot = try await userRef.getDocument()

        if snapshot.exists {
            // Optional: update lastSeen
            try await userRef.updateData([
                "lastSeen": FieldValue.serverTimestamp()
            ])
        } else {
            try await createUserDocument(
                user: user,
                displayName: fallbackDisplayName ?? user.displayName ?? "User"
            )
        }
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

