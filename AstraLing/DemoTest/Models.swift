import Foundation
import CoreLocation
import FirebaseFirestore
// If you're on an older Firebase SDK and these don't resolve,
// add: import FirebaseFirestoreSwift

struct Merchant: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var latitude: Double
    var longitude: Double
    var isActive: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Ping: Identifiable, Codable {
    @DocumentID var id: String?
    var merchantId: String
    var customerName: String
    var latitude: Double
    var longitude: Double
    var status: String          // "pending", "accepted", etc.
    @ServerTimestamp var createdAt: Timestamp?
}
