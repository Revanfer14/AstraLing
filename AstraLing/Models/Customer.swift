import FirebaseFirestore

/// `customers/{uid}` — customer profile, balance, and live location.
struct Customer: Codable {
    @DocumentID var uid: String?
    var name: String
    var email: String
    var balance: Int                     // rupiah, integer
    var astraPoints: Int
    var photoUrl: String? = nil          // Cloud Storage download URL
    var location: GeoPoint
    var geohash: String                  // for radius queries — see Geohash.swift
    var locationUpdatedAt: Timestamp
    var favorites: [String] = []        // array of merchantUids
    @ServerTimestamp var createdAt: Timestamp?
}
