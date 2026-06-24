//
//  CustomerHistoryViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import FirebaseAuth
import FirebaseFirestore
import Combine

struct HistorySection: Identifiable {
    let id: Date
    let dayLabel: String
    let items: [Transaction]
}

@MainActor
final class CustomerHistoryViewModel: ObservableObject {
    @Published var sections: [HistorySection] = []
    @Published var merchantNames: [String: String] = [:]
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await db.collection("transactions")
                .whereField("customerUid", isEqualTo: uid)
                .getDocuments()

            let txns: [Transaction] = snapshot.documents.compactMap { doc in
                try? doc.data(as: Transaction.self)
            }.sorted {
                ($0.createdAt?.dateValue() ?? .distantPast) > ($1.createdAt?.dateValue() ?? .distantPast)
            }

            let uids = Array(Set(txns.map { $0.merchantUid }))
            var names: [String: String] = [:]
            for muid in uids {
                if let doc = try? await db.collection("merchants").document(muid).getDocument(),
                   let name = doc.data()?["name"] as? String {
                    names[muid] = name
                }
            }
            merchantNames = names

            let calendar = Calendar.current
            var grouped: [Date: [Transaction]] = [:]
            for txn in txns {
                let day = calendar.startOfDay(for: txn.createdAt?.dateValue() ?? Date())
                grouped[day, default: []].append(txn)
            }

            sections = grouped.keys.sorted(by: >).map { day in
                HistorySection(id: day, dayLabel: day.dayLabelID, items: grouped[day]!)
            }
        } catch {}
    }
}
