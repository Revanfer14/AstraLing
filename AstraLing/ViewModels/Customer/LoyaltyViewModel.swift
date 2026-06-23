//
//  LoyaltyViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import FirebaseAuth
import FirebaseFirestore
import Combine

struct PointEntry: Identifiable {
    let id: String
    let date: Date
    let amount: Int
    var pointsEarned: Int { amount / 1000 }
}

@MainActor
final class LoyaltyViewModel: ObservableObject {
    @Published var astraPoints = 0
    @Published var history: [PointEntry] = []

    private let db = Firestore.firestore()

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("customers").document(uid).getDocument()
            astraPoints = doc.data()?["astraPoints"] as? Int ?? 0

            let snapshot = try await db.collection("transactions")
                .whereField("customerUid", isEqualTo: uid)
                .getDocuments()

            history = Array(
                snapshot.documents.compactMap { doc -> PointEntry? in
                    guard let amount = doc.data()["amount"] as? Int,
                          let ts = doc.data()["createdAt"] as? Timestamp else { return nil }
                    return PointEntry(id: doc.documentID, date: ts.dateValue(), amount: amount)
                }
                .sorted { $0.date > $1.date }
                .prefix(15)
            )
        } catch {}
    }
}
