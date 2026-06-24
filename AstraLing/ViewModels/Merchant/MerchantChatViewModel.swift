//
//  MerchantChatViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

struct MerchantChatMessageItem: Identifiable {
    let id: String
    let text: String
    let isMine: Bool
    let time: Date?
}

@MainActor
final class MerchantChatViewModel: ObservableObject {
    @Published var messages: [MerchantChatMessageItem] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var currentChatId: String?
    private var currentUid: String?

    func start(customerUid: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        currentUid = uid
        let chatId = ChatID.make(customerUid: customerUid, merchantUid: uid)
        currentChatId = chatId

        listener?.remove()
        listener = db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.messages = docs.compactMap { doc in
                    guard let msg = try? doc.data(as: ChatMessage.self) else { return nil }
                    return MerchantChatMessageItem(
                        id: doc.documentID,
                        text: msg.text,
                        isMine: msg.senderRole == .merchant,
                        time: msg.createdAt?.dateValue()
                    )
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        messages = []
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let uid = currentUid,
              let chatId = currentChatId else { return }
        let msg = ChatMessage(senderUid: uid, senderRole: .merchant, text: trimmed)
        Task {
            do {
                try db.collection("chats").document(chatId)
                    .collection("messages").addDocument(from: msg)
                try await db.collection("chats").document(chatId).updateData([
                    "lastMessage": trimmed,
                    "lastMessageAt": Timestamp(date: Date())
                ])
            } catch { print("MerchantChatVM send: FAILED \(error)") }
        }
    }
}
