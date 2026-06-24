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

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("customers").document(uid).getDocument()
            guard let data = doc.data() else { return }
            name         = data["name"]         as? String ?? ""
            balance      = data["balance"]      as? Int    ?? 0
            astraPoints  = data["astraPoints"]  as? Int    ?? 0
        } catch {}
    }

    func topUp() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let amount = 50_000
        try? await db.collection("customers").document(uid)
            .updateData(["balance": FieldValue.increment(Int64(amount))])
        balance += amount
    }
}
