//
//  TransactionViewModel.swift
//  AstraLing
//
//  Created by Rasya Devan on 24/06/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener = db.collection("transactions")
            .whereField("merchantUid", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                self.transactions = snapshot?.documents.compactMap {
                    try? $0.data(as: Transaction.self)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    private var todayPayments: [Transaction] {
        let cal = Calendar.current
        return transactions.filter { txn in
            txn.type == .payment &&
            txn.status == .success &&
            (txn.createdAt.map { cal.isDateInToday($0.dateValue()) } ?? false)
        }
    }

    var todayTotal: Int { todayPayments.reduce(0) { $0 + $1.amount } }
    var todayCount: Int { todayPayments.count }

    var uniqueCustomersTodayCount: Int {
        Set(todayPayments.compactMap(\.customerUid)).count
    }

    var avgTransactionToday: Int {
        todayCount == 0 ? 0 : todayTotal / todayCount
    }

    var groupedByDay: [(label: String, total: Int, items: [Transaction])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "id_ID")
        fmt.dateFormat = "EEEE, d MMM"

        let grouped = Dictionary(grouping: transactions) { txn -> Date in
            cal.startOfDay(for: txn.createdAt?.dateValue() ?? Date())
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { date, items in
                let label: String
                if cal.isDateInToday(date) {
                    label = "Hari ini · \(fmt.string(from: date).capitalized)"
                } else if cal.isDateInYesterday(date) {
                    label = "Kemarin · \(fmt.string(from: date).capitalized)"
                } else {
                    label = fmt.string(from: date).capitalized
                }
                let dayTotal = items
                    .filter { $0.type == .payment && $0.status == .success }
                    .reduce(0) { $0 + $1.amount }
                return (label: label, total: dayTotal, items: items)
            }
    }

    static func timeString(_ ts: Timestamp?) -> String {
        guard let ts else { return "--" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH.mm"
        return fmt.string(from: ts.dateValue())
    }
}
