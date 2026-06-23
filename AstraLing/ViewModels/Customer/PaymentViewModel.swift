//
//  PaymentViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var merchantName = ""
    @Published var bannerUrl: String?
    @Published var balance = 0
    @Published var astraPoints = 0
    @Published var pointsEarned = 0
    @Published var txnDate: Date?
    @Published var isLoaded = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var merchantUid = ""

    func load(merchantUid: String) {
        self.merchantUid = merchantUid
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            async let merchantSnap = db.collection("merchants").document(merchantUid).getDocument()
            async let customerSnap = db.collection("customers").document(uid).getDocument()
            if let mData = try? await merchantSnap.data() {
                merchantName = mData["name"] as? String ?? ""
                bannerUrl = mData["bannerUrl"] as? String
            }
            if let cData = try? await customerSnap.data() {
                balance      = cData["balance"]      as? Int ?? 0
                astraPoints  = cData["astraPoints"]  as? Int ?? 0
            }
            isLoaded = true
        }
    }

    func pay(amount: Int) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let pts = amount / 1000
        let merchantUidCopy = merchantUid
        let db = db

        let dateStr: String = {
            let f = DateFormatter()
            f.dateFormat = "yyMMdd"
            return f.string(from: Date())
        }()
        let displayId = "#QR\(dateStr)-\(String(format: "%04d", Int.random(in: 0...9999)))"

        let customerRef = db.collection("customers").document(uid)
        let merchantRef = db.collection("merchants").document(merchantUidCopy)
        let txnRef     = db.collection("transactions").document()

        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let cSnap: DocumentSnapshot
                let mSnap: DocumentSnapshot
                do {
                    cSnap = try transaction.getDocument(customerRef)
                    mSnap = try transaction.getDocument(merchantRef)
                } catch let e as NSError {
                    errorPointer?.pointee = e
                    return nil
                }

                let curBalance = cSnap.data()?["balance"]     as? Int ?? 0
                let curPoints  = cSnap.data()?["astraPoints"] as? Int ?? 0
                let curName    = cSnap.data()?["name"]        as? String ?? ""
                let mBalance   = mSnap.data()?["balance"]     as? Int ?? 0

                guard curBalance >= amount else {
                    errorPointer?.pointee = NSError(
                        domain: "PaymentError", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Saldo tidak cukup untuk melakukan pembayaran ini."]
                    )
                    return nil
                }

                transaction.updateData(
                    ["balance": curBalance - amount, "astraPoints": curPoints + pts],
                    forDocument: customerRef
                )
                transaction.updateData(["balance": mBalance + amount], forDocument: merchantRef)
                transaction.setData([
                    "type":         "payment",
                    "displayId":    displayId,
                    "customerUid":  uid,
                    "merchantUid":  merchantUidCopy,
                    "customerName": curName,
                    "amount":       amount,
                    "method":       "QRIS AstraPay",
                    "status":       "success",
                    "createdAt":    FieldValue.serverTimestamp()
                ], forDocument: txnRef)
                return nil
            }

            balance     -= amount
            astraPoints += pts
            pointsEarned = pts
            txnDate      = Date()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
