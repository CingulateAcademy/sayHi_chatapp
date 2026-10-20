import Foundation
import FirebaseFirestore

struct ParticipantInfo: Codable, Hashable {
    var displayName: String
    var photoURL: String
}

struct LastMessage: Hashable {
    var text: String
    var senderId: String
    var timestamp: Date
    var type: String
}

struct Conversation: Identifiable, Hashable {
    var id: String
    var participants: [String]
    var participantDetails: [String: ParticipantInfo]
    var lastMessage: LastMessage?
    var updatedAt: Date
    var unreadCounts: [String: Int]

    func otherParticipant(currentUserId: String) -> ParticipantInfo? {
        guard let otherId = participants.first(where: { $0 != currentUserId }) else { return nil }
        return participantDetails[otherId]
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participants.first(where: { $0 != currentUserId })
    }

    func unreadCount(for userId: String) -> Int {
        unreadCounts[userId] ?? 0
    }

    static func from(snapshot: DocumentSnapshot) -> Conversation? {
        guard snapshot.exists, let data = snapshot.data() else { return nil }

        let participants = data["participants"] as? [String] ?? []

        var details: [String: ParticipantInfo] = [:]
        if let raw = data["participantDetails"] as? [String: [String: Any]] {
            for (uid, info) in raw {
                details[uid] = ParticipantInfo(
                    displayName: info["displayName"] as? String ?? "",
                    photoURL: info["photoURL"] as? String ?? ""
                )
            }
        }

        var lastMessage: LastMessage? = nil
        if let lm = data["lastMessage"] as? [String: Any] {
            let ts = (lm["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            lastMessage = LastMessage(
                text: lm["text"] as? String ?? "",
                senderId: lm["senderId"] as? String ?? "",
                timestamp: ts,
                type: lm["type"] as? String ?? "text"
            )
        }

        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let unread = data["unreadCounts"] as? [String: Int] ?? [:]

        return Conversation(
            id: snapshot.documentID,
            participants: participants,
            participantDetails: details,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            unreadCounts: unread
        )
    }
}
