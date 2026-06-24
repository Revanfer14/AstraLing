import FirebaseFirestore

enum TransactionType: String, Codable {
    case payment   // QR scan by customer
    case transfer  // merchant moving balance out
}

enum TransactionStatus: String, Codable {
    case success
    case failed
}

/// `transactions/{txnId}` — QR payments and balance transfers.
///
/// Payment must be written atomically with the balance debit/credit via Firestore.runTransaction.
struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var type: TransactionType
    var displayId: String                // human-facing, e.g. "#QR250516-0042"
    var customerUid: String? = nil       // nil for merchant-only transfers
    var merchantUid: String
    var customerName: String? = nil      // denormalised, e.g. "Erin"
    var amount: Int                      // rupiah
    var method: String                   // e.g. "QRIS AstraPay"
    var status: TransactionStatus
    var failureReason: String? = nil     // e.g. "Waktu pembayaran habis"
    var pingId: String? = nil
    @ServerTimestamp var createdAt: Timestamp?
}
