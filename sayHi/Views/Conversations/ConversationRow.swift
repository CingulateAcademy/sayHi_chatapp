import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String

    private var other: ParticipantInfo? {
        conversation.otherParticipant(currentUserId: currentUserId)
    }

    private var unread: Int {
        conversation.unreadCount(for: currentUserId)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(
                photoURL: other?.photoURL ?? "",
                name: other?.displayName ?? "?",
                size: 54
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(other?.displayName ?? "Unknown")
                        .font(.body.weight(unread > 0 ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: Spacing.xs)

                    if let last = conversation.lastMessage {
                        Text(relativeTime(last.timestamp))
                            .font(.caption)
                            .foregroundStyle(unread > 0 ? Color.accentColor : .secondary)
                    }
                }

                HStack(alignment: .center, spacing: Spacing.xs) {
                    Text(lastMessagePreview)
                        .font(.subheadline)
                        .foregroundStyle(unread > 0 ? .primary : .secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if unread > 0 {
                        Text(unread > 99 ? "99+" : "\(unread)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var lastMessagePreview: String {
        guard let last = conversation.lastMessage else {
            return "No messages yet"
        }
        let prefix = last.senderId == currentUserId ? "You: " : ""
        if last.type == "image" {
            if last.text.isEmpty { return prefix + "📷 Photo" }
            return prefix + "📷 " + last.text
        }
        return prefix + last.text
    }

    private func relativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f.string(from: date)
    }
}
