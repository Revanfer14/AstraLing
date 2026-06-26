import FirebaseFirestore

enum PingStatus: String, Codable {
    case active
    case onTheWay = "on_the_way"
    case completed
    case cancelled
}

/// `pings/{pingId}` — a customer signalling "I'm coming" to a merchant.
///
/// Status lifecycle: active → on_the_way → completed | cancelled
struct Ping: Identifiable, Codable {
    @DocumentID var id: String?
    var customerUid: String
    var merchantUid: String
    var customerName: String             // denormalised so merchant list renders without extra reads
    var customerLocation: GeoPoint
    var interestedItems: [String] = []  // e.g. ["Manis Coklat", "Telur Kornet"]
    var note: String? = nil
    var status: PingStatus
    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp
}
