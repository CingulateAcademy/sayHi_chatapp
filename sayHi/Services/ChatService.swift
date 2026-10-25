import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@Observable
@MainActor
final class ChatService {
    var messages: [Message] = []
    var isLoading = false
    var isSending = false
    var uploadProgress: Double = 0
    var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    private var conversationId: String = ""
    private var currentUserId: String = ""

    func startListening(conversationId: String, currentUserId: String) {
        stopListening()

        guard !conversationId.isEmpty, !currentUserId.isEmpty else {
            errorMessage = "Invalid conversation"
            isLoading = false
            return
        }

        self.conversationId = conversationId
        self.currentUserId = currentUserId
        isLoading = true

        listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                let serverMessages: [Message] = snapshot?.documents.compactMap { doc in
                    Message.from(snapshot: doc)
                } ?? []

                // deduplicate reliably using unique message IDS
               
                let serverMessageIds = Set(serverMessages.map { $0.id })
                let stillPending = self.messages.filter { $0.isOptimistic && !serverMessageIds.contains($0.id) }

                self.messages = serverMessages + stillPending
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        messages = []
    }

//   send optimistic text

    func sendText(_ text: String, conversation: Conversation) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !currentUserId.isEmpty,
              !conversationId.isEmpty else { return }

        isSending = true
        defer { isSending = false }
        // Persistent UUID so firestore doc ID matches optimistic ID
        
        let messageId = UUID().uuidString
        let optimisticMessage = Message(
            id: messageId,
            senderId: currentUserId,
            text: trimmed,
            type: "text",
            mediaURL: nil,
            createdAt: Date(),
            status: [currentUserId: "sent"],
            isOptimistic: true
        )

        messages.append(optimisticMessage)

        let messageRef = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)

        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "text": trimmed,
            "type": "text",
            "createdAt": FieldValue.serverTimestamp(),
            "status": [currentUserId: "sent"]
        ]

        do {
            try await messageRef.setData(messageData)
            try await updateConversationAfterSend(
                conversation: conversation,
                previewText: trimmed,
                type: "text"
            )
        } catch {
            messages.removeAll { $0.id == messageId }
            errorMessage = error.localizedDescription
        }
    }

//   sending optimistic image

    func sendImage(_ image: UIImage, caption: String = "", conversation: Conversation) async {
        guard !currentUserId.isEmpty, !conversationId.isEmpty else { return }

        isSending = true
        uploadProgress = 0
        defer {
            isSending = false
            uploadProgress = 0
        }

        guard let imageData = compressImage(image) else {
            errorMessage = "Could not process image"
            return
        }

        let captionText = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageId = UUID().uuidString

        let optimisticMessage = Message(
            id: messageId,
            senderId: currentUserId,
            text: captionText,
            type: "image",
            mediaURL: nil,
            createdAt: Date(),
            status: [currentUserId: "sent"],
            isOptimistic: true,
            localImageData: imageData
        )
        messages.append(optimisticMessage)

        let storagePath = "conversations/\(conversationId)/\(messageId).jpg"
        let storageRef = storage.reference().child(storagePath)

        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            // Using native Firebase Storage async/await API
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata) { [weak self] progress in
                guard let progress else { return }
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                Task { @MainActor in
                    self?.uploadProgress = percent
                }
            }

            let downloadURL = try await storageRef.downloadURL()

            let messageRef = db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(messageId)

            let messageData: [String: Any] = [
                "senderId": currentUserId,
                "text": captionText,
                "type": "image",
                "mediaURL": downloadURL.absoluteString,
                "createdAt": FieldValue.serverTimestamp(),
                "status": [currentUserId: "sent"]
            ]

            try await messageRef.setData(messageData)

            let preview = captionText.isEmpty ? "Photo" : captionText
            try await updateConversationAfterSend(
                conversation: conversation,
                previewText: preview,
                type: "image"
            )

        } catch {
            messages.removeAll { $0.id == messageId }
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(conversation: Conversation) async {
        guard !currentUserId.isEmpty, !conversationId.isEmpty else { return }

        do {
            try await db.collection("conversations")
                .document(conversationId)
                .updateData([
                    "unreadCounts.\(currentUserId)": 0
                ])
        } catch {
            print("Failed to reset unread count: \(error)")
        }
    }

    

    private func updateConversationAfterSend(
        conversation: Conversation,
        previewText: String,
        type: String
    ) async throws {
        let conversationRef = db.collection("conversations").document(conversationId)
        let otherUserId = conversation.otherParticipantId(currentUserId: currentUserId)

        var updates: [String: Any] = [
            "lastMessage": [
                "text": previewText,
                "senderId": currentUserId,
                "timestamp": FieldValue.serverTimestamp(),
                "type": type
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let otherUserId {
            updates["unreadCounts.\(otherUserId)"] = FieldValue.increment(Int64(1))
        }

        try await conversationRef.updateData(updates)
    }

   
    private func compressImage(_ image: UIImage, maxDimension: CGFloat = 1200, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)

        let scale = longest > maxDimension ? maxDimension / longest : 1.0
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: quality)
    }
}

