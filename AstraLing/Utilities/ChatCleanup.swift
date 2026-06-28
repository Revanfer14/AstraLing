//
//  ChatCleanup.swift
//  AstraLing
//
//  Created by Rasya Deva Pragata on 29/06/26.
//

import FirebaseFirestore

enum ChatCleanup {
    static func deleteChat(db: Firestore, customerUid: String, merchantUid: String) async {
        let chatId = ChatID.make(customerUid: customerUid, merchantUid: merchantUid)
        let chatRef = db.collection("chats").document(chatId)
        if let messages = try? await chatRef.collection("messages").getDocuments() {
            let batch = db.batch()
            messages.documents.forEach { batch.deleteDocument($0.reference) }
            try? await batch.commit()
        }
        try? await chatRef.delete()
    }
}
