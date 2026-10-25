import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


@Observable
@MainActor
final class UserService{
    
    var currentUserProfile: UserProfile?
    var isUpdating = false
    var uploadProgress: Double = 0
    var errorMessage: String?
    
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    
    enum ConversationError: LocalizedError{
        case invalidUser
    }
    
    
    func startListening(for userId: String){
        
        stopListening()
        
        listener = db.collection("users").document(userId)
            .addSnapshotListener{[weak self] snapshot, error in
                guard let self else {return}
                
                if let error {
                    print("Userservice listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot else {return}
                
                if snapshot.exists{
                    let profile = UserProfile.from(snapshot: snapshot)
                    print("Userservice profile loaded: \(profile?.displayName ?? "nil")")
                    
                    self.currentUserProfile = profile
                    
                }else{
                    self.currentUserProfile = self.profileFromAuth(uid: userId)
                }
                
            }
    }
    
    
    func stopListening(){
        listener?.remove()
        listener = nil
        currentUserProfile = nil
    }
    
    
//    helpers
    
    
    func fetchUser(uid: String) async throws -> UserProfile{
        let snapshot = try await db.collection("users").document(uid).getDocument()
        
        if let profile = UserProfile.from(snapshot: snapshot){
            return profile
        }
        
        throw ConversationError.invalidUser
    }
    
    func updateDisplayName(_ name: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {return}
        
        isUpdating = true
        errorMessage = nil
        
        defer {isUpdating = false}
        
        do{
            try await db.collection("users").document(uid).setData([
                "displayName": trimmed
            ], merge: true)
            
            
            if currentUserProfile != nil{
                
                currentUserProfile?.displayName = trimmed
                
            }else{
                currentUserProfile = profileFromAuth(uid: uid)
                currentUserProfile?.displayName = trimmed
            }
            
            do{
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = trimmed
                
                try await changeRequest?.commitChanges()
                
                
                
            }catch{
                print("Auth displayName update failed: \(error.localizedDescription)")
            }
            
            
            do{
                try await updateParticipantDetailsInConversations(
                    uid:uid,
                    displayName: trimmed,
                    photoURL: nil
                )
                
                
            }catch{
                print("ParticipantDetails sync failed: \(error.localizedDescription)")
            }
            
        }catch{
            errorMessage = error.localizedDescription
        }
        
        
        
        
        
    }
    
    
    func uploadAvatar(_ image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isUpdating = true
        uploadProgress = 0
        errorMessage = nil
        defer {
            isUpdating = false
            uploadProgress = 0
        }

        guard let imageData = compressImage(image, maxDimension: 800, quality: 0.75) else {
            errorMessage = "Could not process image"
            return
        }

        let storagePath = "avatars/\(uid)/avatar.jpg"
        let storageRef = storage.reference().child(storagePath)

        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

//            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
//                let task = storageRef.putData(imageData, metadata: metadata)
//
//                task.observe(.progress) { [weak self] snapshot in
//                    guard let progress = snapshot.progress else { return }
//                    let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
//                    Task { @MainActor in
//                        self?.uploadProgress = percent
//                    }
//                }
//
//                task.observe(.success) { snapshot in
//                    continuation.resume(returning: snapshot.metadata ?? StorageMetadata())
//                }
//
//                task.observe(.failure) { snapshot in
//                    continuation.resume(throwing: snapshot.error ?? NSError(domain: "Storage", code: -1))
//                }
//            }
            
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata){
                [weak self] progress in
                
                guard let progress else {return}
                
                
                let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                
                Task{
                    @MainActor in
                    
                    self?.uploadProgress = percent
                }
                
            }
            

            let downloadURL = try await storageRef.downloadURL()
            let urlString = downloadURL.absoluteString

            try await db.collection("users").document(uid).setData([
                "photoURL": urlString
            ], merge: true)

            currentUserProfile?.photoURL = urlString

            do {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.photoURL = downloadURL
                try await changeRequest?.commitChanges()
            } catch {
                print("Auth photoURL update failed (non-fatal): \(error.localizedDescription)")
            }

            do {
                try await updateParticipantDetailsInConversations(
                    uid: uid,
                    displayName: nil,
                    photoURL: urlString
                )
            } catch {
                print("participantDetails photo sync failed (non-fatal): \(error.localizedDescription)")
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func profileFromAuth(uid: String) -> UserProfile {
        let authUser = Auth.auth().currentUser
        let name = authUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = authUser?.email ?? ""
        let resolved = (name?.isEmpty == false ? name! : nil)
            ?? email.components(separatedBy: "@").first
            ?? "User"

        return UserProfile(
            id: uid,
            displayName: resolved,
            email: email,
            photoURL: authUser?.photoURL?.absoluteString ?? "",
            bio: "",
            createdAt: nil,
            lastSeen: nil,
            fcmTokens: nil
        )
    }

    private func updateParticipantDetailsInConversations(
        uid: String,
        displayName: String?,
        photoURL: String?
    ) async throws {
        let snapshot = try await db.collection("conversations")
            .whereField("participants", arrayContains: uid)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        // Update one-by-one so a single rule failure doesn't kill the whole batch
        for doc in snapshot.documents {
            var updates: [String: Any] = [:]
            if let displayName {
                updates["participantDetails.\(uid).displayName"] = displayName
            }
            if let photoURL {
                updates["participantDetails.\(uid).photoURL"] = photoURL
            }
            guard !updates.isEmpty else { continue }

            do {
                try await doc.reference.updateData(updates)
            } catch {
                print("Failed to update conversation \(doc.documentID): \(error.localizedDescription)")
            }
        }
    }

    private func compressImage(_ image: UIImage, maxDimension: CGFloat, quality: CGFloat) -> Data? {
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
