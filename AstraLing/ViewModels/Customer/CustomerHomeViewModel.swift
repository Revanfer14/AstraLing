//
//  CustomerHomeViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class CustomerHomeViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var balance: Int = 0
    @Published var astraPoints: Int = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func load() {
        guard listener == nil,
              let uid = Auth.auth().currentUser?.uid else { return }
        listener = db.collection("customers").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let data = snapshot?.data() else { return }
                self.name        = data["name"]        as? String ?? ""
                self.balance     = data["balance"]     as? Int    ?? 0
                self.astraPoints = data["astraPoints"] as? Int    ?? 0
            }
    }

    func topUp() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let amount = 50_000
        try? await db.collection("customers").document(uid)
            .updateData(["balance": FieldValue.increment(Int64(amount))])
    }

    deinit {
        listener?.remove()
    }
}
