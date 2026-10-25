import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    var showTimestamp: Bool = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isFromCurrentUser { Spacer(minLength: 64) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                if message.type == "image" {
                    VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                        imageContent
                        if !message.text.isEmpty {
                            Text(message.text)
                                .font(.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    isFromCurrentUser
                                        ? Color.sayHiBubbleSent
                                        : Color.sayHiBubbleReceived
                                )
                                .foregroundStyle(isFromCurrentUser ? .white : .primary)
                                .clipShape(BubbleShape(isFromCurrentUser: isFromCurrentUser))
                        }
                    }
                } else {
                    textContent
                }

                if showTimestamp {
                    HStack(spacing: 3) {
                        Text(message.createdAt, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        if isFromCurrentUser && message.isOptimistic {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            if !isFromCurrentUser { Spacer(minLength: 64) }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 2)
        .opacity(message.isOptimistic ? 0.7 : 1.0)
        .animation(.easeOut(duration: 0.2), value: message.isOptimistic)
    }

    private var textContent: some View {
        Text(message.text)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isFromCurrentUser
                    ? Color.sayHiBubbleSent
                    : Color.sayHiBubbleReceived
            )
            .foregroundStyle(isFromCurrentUser ? .white : .primary)
            .clipShape(BubbleShape(isFromCurrentUser: isFromCurrentUser))
    }

    @ViewBuilder
    private var imageContent: some View {
        Group {
            if let data = message.localImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = message.mediaURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        imagePlaceholder.overlay { ProgressView() }
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: 220, maxHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay {
            if message.isOptimistic {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(.black.opacity(0.28))
                ProgressView().tint(.white)
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .fill(Color.sayHiSurface)
            .frame(width: 180, height: 180)
            .overlay {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundStyle(.tertiary)
            }
    }
}

// chat bubble

struct BubbleShape: Shape {
    let isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        var path = Path()

        if isFromCurrentUser {
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: r, bottomLeading: r,
                    bottomTrailing: 4, topTrailing: r
                )
            )
        } else {
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: r, bottomLeading: 4,
                    bottomTrailing: r, topTrailing: r
                )
            )
        }
        return path
    }
}

// day separator

struct DaySeparator: View {
    let date: Date

    var body: some View {
        HStack {
            line
            Text(formatted)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)
            line
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.sayHiSeparator)
            .frame(height: 0.5)
    }

    private var formatted: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
