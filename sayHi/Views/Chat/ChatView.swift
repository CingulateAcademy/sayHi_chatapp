import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    let currentUserId: String

    @State private var chatService = ChatService()
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var pendingImage: PendingChatImage?

    private var otherName: String {
        conversation.otherParticipant(currentUserId: currentUserId)?.displayName ?? "Chat"
    }

    private var groupedMessages: [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: chatService.messages) { msg in
            calendar.startOfDay(for: msg.createdAt)
        }
        return grouped
            .map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if chatService.isLoading && chatService.messages.isEmpty {
                            ProgressView()
                                .padding(.top, Spacing.xxl)
                        }

                        ForEach(groupedMessages, id: \.date) { group in
                            DaySeparator(date: group.date)

                            ForEach(group.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == currentUserId,
                                    showTimestamp: shouldShowTimestamp(for: message, in: group.messages)
                                )
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(animated: false)
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    scrollToBottom(animated: true)
                }
            }

            if chatService.isSending && chatService.uploadProgress > 0 {
                ProgressView(value: chatService.uploadProgress)
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)
                    .padding(.horizontal)
                    .transition(.opacity)
            }

            Divider().opacity(0.5)

            ChatInputBar(
                text: $messageText,
                isSending: chatService.isSending,
                onSendText: sendTextMessage,
                onImagePicked: { image in
                    // sheet(item:) presents only when this is non-nil – always has the image
                    pendingImage = PendingChatImage(image: image)
                }
            )
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        // we use item-based sheet so content is never empty/white
        .sheet(item: $pendingImage) { pending in
            ImageComposerView(
                image: pending.image,
                isSending: chatService.isSending,
                onCancel: {
                    pendingImage = nil
                },
                onSend: { caption in
                    Task {
                        await chatService.sendImage(
                            pending.image,
                            caption: caption,
                            conversation: conversation
                        )
                        // Dismiss only after send finishes (or fails)
                        await MainActor.run {
                            pendingImage = nil
                        }
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            chatService.startListening(
                conversationId: conversation.id,
                currentUserId: currentUserId
            )
            Task { await chatService.markAsRead(conversation: conversation) }
        }
        .onDisappear {
            chatService.stopListening()
        }
        .alert("Error", isPresented: .constant(chatService.errorMessage != nil)) {
            Button("OK") { chatService.errorMessage = nil }
        } message: {
            Text(chatService.errorMessage ?? "")
        }
    }

    private func shouldShowTimestamp(for message: Message, in messages: [Message]) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        let next = messages.index(after: idx)
        if next < messages.count {
            let nextMsg = messages[next]
            let sameSender = nextMsg.senderId == message.senderId
            let withinMinute = abs(nextMsg.createdAt.timeIntervalSince(message.createdAt)) < 60
            if sameSender && withinMinute { return false }
        }
        return true
    }

    private func sendTextMessage() {
        let text = messageText
        messageText = ""
        Task { await chatService.sendText(text, conversation: conversation) }
    }

    private func scrollToBottom(animated: Bool) {
        guard let lastId = chatService.messages.last?.id else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                scrollProxy?.scrollTo(lastId, anchor: .bottom)
            }
        } else {
            scrollProxy?.scrollTo(lastId, anchor: .bottom)
        }
    }
}
