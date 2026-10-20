import Foundation
import FirebaseFirestore

struct Message: Identifiable, Hashable {
    var id: String
    var senderId: String
    var text: String
    var type: String          
    var mediaURL: String?
    var createdAt: Date
    var status: [String: String]?

    var isOptimistic: Bool = false
    var localImageData: Data? = nil

    static func from(snapshot: DocumentSnapshot) -> Message? {
        guard snapshot.exists, let data = snapshot.data() else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Message(
            id: snapshot.documentID,
            senderId: data["senderId"] as? String ?? "",
            text: data["text"] as? String ?? "",
            type: data["type"] as? String ?? "text",
            mediaURL: data["mediaURL"] as? String,
            createdAt: createdAt,
            status: data["status"] as? [String: String],
            isOptimistic: false,
            localImageData: nil
        )
    }
}
