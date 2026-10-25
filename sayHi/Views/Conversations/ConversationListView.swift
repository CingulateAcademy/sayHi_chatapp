import SwiftUI
import FirebaseAuth


struct ConversationListView: View{
    @Bindable var authService: AuthService
    @State private var conversationService = ConversationService()
    @State private var userService = UserService()
    
    @State private var showNewChat = false
    @State private var showProfile = false
    
    
    private var currentUserId: String{
        authService.user?.uid ?? ""
    }
    
    
    private var resolvedDisplayName: String {
           let fromProfile = userService.currentUserProfile?.displayName
               .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
           if !fromProfile.isEmpty { return fromProfile }
           let fromAuth = authService.user?.displayName?
               .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
           if !fromAuth.isEmpty { return fromAuth }
           return authService.user?.email?.components(separatedBy: "@").first ?? "U"
       }

       private var resolvedPhotoURL: String {
           userService.currentUserProfile?.photoURL
               ?? authService.user?.photoURL?.absoluteString
               ?? ""
       }
    
    
    
    
    var body: some View {
        NavigationStack{
            Group{
                if conversationService.isLoading && conversationService.conversations.isEmpty{
                    List{
                        ForEach(0..<6, id: \.self){
                            _ in ConversationSkeletonRow()
                        }
                    }.listStyle(.plain)
                        .disabled(true)
                } else if conversationService.conversations.isEmpty{
                    ContentUnavailableView{
                        Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
                    } description: {
                        Text("Start a conversation and it will show up here.")
                    }actions: {
                        Button{
                            showNewChat = true
                        }label:{
                            Label("New Chat", systemImage: "square.and.pencil")
                        }.buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                }else{
                    
                    List(conversationService.conversations){
                        conversation in
                        let id = conversation.id
                        
                        NavigationLink(value: id){
                            ConversationRow(conversation: conversation, currentUserId: currentUserId)
                        }.disabled(id.isEmpty)
                    }.listStyle(.plain)
                    
                }
            }
            .navigationTitle("SayHi")
            .navigationDestination(for: String.self){
                conversationId in
                
                if let conversation = conversationService.conversations.first(where: {$0.id == conversationId}){
                    ChatView(
                        conversation: conversation,
                        currentUserId: currentUserId
                    )
                }else{
                    ProgressView("Opening chat")
                }
            }.toolbar{
                ToolbarItem(placement: .primaryAction){
                    Button{
                        Haptics.light()
                        showNewChat = true
                    }label:{
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading){
                    Button{
                        showProfile = true
                    }label:{
                        AvatarView(
                            photoURL: resolvedPhotoURL,
                            name: resolvedDisplayName,
                            size: 32
                        )
                    }
                }
                
            }
            .sheet(isPresented: $showNewChat){
                NewChatView(
                   conversationService: conversationService,
                   userService: userService,
                   currentUserId: currentUserId
                )
            }.sheet(isPresented: $showProfile){
                ProfileView(authService: authService, userService: userService)
            }.task(id: currentUserId){
                guard !currentUserId.isEmpty else {return}
                conversationService.startListening(for: currentUserId)
                userService.startListening(for: currentUserId)
            }
        }
    }
}
