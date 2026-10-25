import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class ConversationService {
    var conversations: [Conversation] = []
    var isLoading = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(for userId: String) {
        stopListening()

        isLoading = true

        listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.conversations = snapshot?.documents.compactMap { doc in
                    Conversation.from(snapshot: doc)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    @discardableResult
    func createOrGetConversation(
        currentUser: UserProfile,
        otherUser: UserProfile
    ) async throws -> String {
        let currentUid = currentUser.id
        let otherUid = otherUser.id
        guard !currentUid.isEmpty, !otherUid.isEmpty else {
            throw ConversationError.invalidUser
        }

        // Always store participants in sorted order so we can find the conversation easily
        let participants = [currentUid, otherUid].sorted()

        // Try to find an existing conversation with exactly these two participants
        let existing = try await db.collection("conversations")
            .whereField("participants", isEqualTo: participants)
            .limit(to: 1)
            .getDocuments()

        if let existingDoc = existing.documents.first {
            return existingDoc.documentID
        }

        // Create a new conversation
        let conversationRef = db.collection("conversations").document()

        let data: [String: Any] = [
            "participants": participants,
            "participantDetails": [
                currentUid: [
                    "displayName": currentUser.displayName,
                    "photoURL": currentUser.photoURL
                ],
                otherUid: [
                    "displayName": otherUser.displayName,
                    "photoURL": otherUser.photoURL
                ]
            ],
            "updatedAt": FieldValue.serverTimestamp(),
            "unreadCounts": [
                currentUid: 0,
                otherUid: 0
            ]
        ]

        try await conversationRef.setData(data)

        // Optional user-specific index write
        do {
            try await db.collection("userConversations")
                .document(currentUid)
                .collection("conversations")
                .document(conversationRef.documentID)
                .setData([
                    "updatedAt": FieldValue.serverTimestamp(),
                    "otherUserId": otherUid
                ])
        } catch {
            print("userConversations index write skipped: \(error.localizedDescription)")
        }

        return conversationRef.documentID
    }

   

    func searchUsers(query: String, excludingUserId: String) async throws -> [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        // Case-sensitive prefix match (ensure user displayNames are appropriately indexed)
        let snapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: trimmed)
            .whereField("displayName", isLessThanOrEqualTo: trimmed + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard let user = UserProfile.from(snapshot: doc),
                  user.id != excludingUserId && !user.id.isEmpty else { return nil }
            return user
        }
    }

    func fetchAllUsers(excludingUserId: String, limit: Int = 30) async throws -> [UserProfile] {
        let snapshot = try await db.collection("users")
            .order(by: "displayName")
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard let user = UserProfile.from(snapshot: doc),
                  user.id != excludingUserId && !user.id.isEmpty else { return nil }
            return user
        }
    }
}



enum ConversationError: LocalizedError {
    case invalidUser
    case conversationNotFound

    var errorDescription: String? {
        switch self {
        case .invalidUser: return "Invalid user data"
        case .conversationNotFound: return "Conversation not found"
        }
    }
}

