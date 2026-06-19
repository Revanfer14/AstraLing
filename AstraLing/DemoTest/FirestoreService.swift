import Foundation
import CoreLocation
import FirebaseFirestore
import Combine
import UIKit
import CoreImage

// MARK: - FirestoreService

final class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()

    @Published var activeMerchants: [Merchant] = []
    @Published var incomingPings: [Ping] = []
    @Published var transactions: [Transaction] = []
    @Published var trackedPing: Ping?

    private var merchantListener: ListenerRegistration?
    private var pingListener: ListenerRegistration?
    private var transactionListener: ListenerRegistration?
    private var trackedPingListener: ListenerRegistration?

    // MARK: Customer side

    func startListeningToMerchants() {
        merchantListener = db.collection("merchants")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.activeMerchants = docs.compactMap { try? $0.data(as: Merchant.self) }
            }
    }

    @discardableResult
    func sendPing(to merchant: Merchant, customerName: String, location: CLLocationCoordinate2D?) throws -> String {
        guard let merchantId = merchant.id else {
            throw NSError(domain: "AstraLing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Merchant ID missing"])
        }
        let ping = Ping(
            merchantId: merchantId,
            customerName: customerName,
            latitude: location?.latitude ?? 0,
            longitude: location?.longitude ?? 0,
            status: "pending",
            message: nil,
            createdAt: nil
        )
        let ref = try db.collection("pings").addDocument(from: ping)
        return ref.documentID
    }

    func startListeningToPing(pingId: String) {
        trackedPingListener?.remove()
        trackedPingListener = db.collection("pings").document(pingId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let snapshot else { return }
                self?.trackedPing = try? snapshot.data(as: Ping.self)
            }
    }

    // MARK: Merchant side

    func setMerchant(_ merchant: Merchant) {
        guard let id = merchant.id else { return }
        do {
            try db.collection("merchants").document(id).setData(from: merchant, merge: true)
        } catch {
            print("setMerchant error: \(error)")
        }
    }

    func startListeningToPings(merchantId: String) {
        pingListener = db.collection("pings")
            .whereField("merchantId", isEqualTo: merchantId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.incomingPings = docs
                    .compactMap { try? $0.data(as: Ping.self) }
                    .sorted {
                        ($0.createdAt?.dateValue() ?? .distantPast) >
                        ($1.createdAt?.dateValue() ?? .distantPast)
                    }
            }
    }

    func updatePingStatus(pingId: String, status: String) {
        db.collection("pings").document(pingId).updateData(["status": status])
    }

    func startListeningToTransactions(merchantId: String) {
        transactionListener = db.collection("transactions")
            .whereField("merchantId", isEqualTo: merchantId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.transactions = docs
                    .compactMap { try? $0.data(as: Transaction.self) }
                    .sorted {
                        ($0.callbackTimestamp?.dateValue() ?? .distantFuture) >
                        ($1.callbackTimestamp?.dateValue() ?? .distantFuture)
                    }
            }
    }

    func stopListening() {
        merchantListener?.remove()
        pingListener?.remove()
        transactionListener?.remove()
        trackedPingListener?.remove()
    }
}

// MARK: - MockPaymentService
//
// Implements PaymentService protocol whose signatures mirror real AstraPay endpoints.
// Swap MockPaymentService → AstraPayService (same protocol), zero caller changes.

@MainActor
final class MockPaymentService: ObservableObject {
    private let db = Firestore.firestore()

    @Published var balance: Int = 150_000    // Rp150.000 hardcoded demo saldo
    @Published var qrImage: UIImage?

    // Mirrors createPayment endpoint: caller gets a Transaction with status PND.
    func createPayment(amount: Int, merchantTransactionId: String, merchantId: String) async throws -> Transaction {
        var transaction = Transaction(
            merchantTransactionId: merchantTransactionId,
            astrapayTransactionId: UUID().uuidString,   // real AstraPay returns this
            merchantId: merchantId,
            amount: amount,
            status: PaymentStatus.PND.rawValue,
            callbackTimestamp: nil
        )
        let ref = try db.collection("transactions").addDocument(from: transaction)
        transaction.id = ref.documentID

        qrImage = makeQR(payload: "\(merchantTransactionId)|\(amount)")

        // Auto-expire PND → TIM after 900s (mirrors AstraPay expiry)
        let docId = ref.documentID
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 900 * 1_000_000_000)
            await self?.expireIfPending(docId: docId)
        }
        return transaction
    }

    // Acts as the AstraPay callback: flips PND → APP and deducts balance.
    func confirmPayment(_ transaction: Transaction) async throws {
        guard let docId = transaction.id else { return }
        try await db.collection("transactions").document(docId).updateData([
            "status": PaymentStatus.APP.rawValue,
            "callbackTimestamp": Timestamp(date: Date())
        ])
        balance -= transaction.amount
        qrImage = nil
    }

    // Mirrors getTransactionStatus endpoint.
    func getTransactionStatus(merchantTransactionId: String) async throws -> PaymentStatus {
        let snapshot = try await db.collection("transactions")
            .whereField("merchantTransactionId", isEqualTo: merchantTransactionId)
            .getDocuments()
        guard let raw = snapshot.documents.first?.data()["status"] as? String else { return .PND }
        return PaymentStatus(rawValue: raw) ?? .PND
    }

    private func expireIfPending(docId: String) async {
        guard let snap = try? await db.collection("transactions").document(docId).getDocument(),
              snap.data()?["status"] as? String == PaymentStatus.PND.rawValue else { return }
        try? await db.collection("transactions").document(docId).updateData([
            "status": PaymentStatus.TIM.rawValue,
            "callbackTimestamp": Timestamp(date: Date())
        ])
    }

    private func makeQR(payload: String) -> UIImage? {
        guard let data = payload.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
