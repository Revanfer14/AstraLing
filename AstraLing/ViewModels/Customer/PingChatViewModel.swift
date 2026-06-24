//
//  PingChatViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

struct ChatMessageItem: Identifiable {
    let id: String
    let text: String
    let isMine: Bool
    let time: Date?
}

@MainActor
final class PingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessageItem] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var currentChatId: String?
    private var currentUid: String?
    private var currentMerchantName: String?

    func start(merchantUid: String, merchantName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        currentUid = uid
        currentMerchantName = merchantName
        let chatId = ChatID.make(customerUid: uid, merchantUid: merchantUid)
        currentChatId = chatId

        listener?.remove()
        listener = db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.messages = docs.compactMap { doc in
                    guard let msg = try? doc.data(as: ChatMessage.self) else { return nil }
                    return ChatMessageItem(
                        id: doc.documentID,
                        text: msg.text,
                        isMine: msg.senderRole == .customer,
                        time: msg.createdAt?.dateValue()
                    )
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let uid = currentUid,
              let chatId = currentChatId else { return }
        let msg = ChatMessage(senderUid: uid, senderRole: .customer, text: trimmed)
        Task {
            do {
                try db.collection("chats").document(chatId)
                    .collection("messages").addDocument(from: msg)
                try await db.collection("chats").document(chatId).updateData([
                    "lastMessage": trimmed,
                    "lastMessageAt": Timestamp(date: Date())
                ])
            } catch { print("send: FAILED \(error)") }
        }
    }
}
