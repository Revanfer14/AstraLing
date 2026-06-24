import FirebaseFirestore

/// `merchants/{uid}` — static merchant profile. Live data (location, visibility) lives in `presence/live`.
struct Merchant: Codable {
    @DocumentID var uid: String?
    var name: String
    var email: String
    var balance: Int
    var astraPoints: Int
    var category: String
    var description: String? = nil
    var bannerUrl: String? = nil
    var qrPayload: String
    @ServerTimestamp var createdAt: Timestamp?
}
