import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: Identifiable, Hashable {
    var id: String
    var displayName: String
    var email: String
    var photoURL: String
    var bio: String
    var createdAt: Date?
    var lastSeen: Date?
    var fcmTokens: [String]?

    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    static func from(snapshot: DocumentSnapshot) -> UserProfile? {
        guard snapshot.exists else { return nil }
        let data = snapshot.data() ?? [:]

        let name = (data["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = data["email"] as? String ?? ""
        let photo = data["photoURL"] as? String ?? ""
        let bio = data["bio"] as? String ?? ""
        let tokens = data["fcmTokens"] as? [String]

        var createdAt: Date?
        var lastSeen: Date?
        if let ts = data["createdAt"] as? Timestamp { createdAt = ts.dateValue() }
        if let ts = data["lastSeen"] as? Timestamp { lastSeen = ts.dateValue() }

        let resolvedName: String = {
            if !name.isEmpty { return name }
            if let authName = Auth.auth().currentUser?.displayName,
               !authName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return authName
            }
            if !email.isEmpty {
                return email.components(separatedBy: "@").first ?? "User"
            }
            return "User"
        }()

        return UserProfile(
            id: snapshot.documentID,
            displayName: resolvedName,
            email: email,
            photoURL: photo,
            bio: bio,
            createdAt: createdAt,
            lastSeen: lastSeen,
            fcmTokens: tokens
        )
    }
}
