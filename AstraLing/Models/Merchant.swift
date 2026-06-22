import FirebaseFirestore

/// `merchants/{uid}` — merchant profile, balance, location, and visibility flag.
struct Merchant: Codable {
    @DocumentID var uid: String?
    var name: String
    var email: String
    var balance: Int                     // rupiah, integer
    var astraPoints: Int
    var category: String                 // e.g. "bakso", "martabak" — used for map filter
    var description: String? = nil
    var bannerUrl: String? = nil         // Cloud Storage download URL
    var qrPayload: String                // static string encoded in the merchant's QR code
    var location: GeoPoint
    var geohash: String
    var locationUpdatedAt: Timestamp
    var isVisible: Bool                  // customers only see merchants where isVisible == true
    @ServerTimestamp var createdAt: Timestamp?
}
