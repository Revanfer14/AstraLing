import Foundation
import CoreLocation
import FirebaseFirestore
import Combine

final class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()

    @Published var activeMerchants: [Merchant] = []
    @Published var incomingPings: [Ping] = []

    private var merchantListener: ListenerRegistration?
    private var pingListener: ListenerRegistration?

    // MARK: - Customer side

    /// Live-updates the list of merchants currently in "Keliling Mode".
    func startListeningToMerchants() {
        merchantListener = db.collection("merchants")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self?.activeMerchants = docs.compactMap { try? $0.data(as: Merchant.self) }
            }
    }

    /// Sends a ping to a merchant.
    func sendPing(to merchant: Merchant, customerName: String, location: CLLocationCoordinate2D?) {
        guard let merchantId = merchant.id else { return }
        let ping = Ping(
            merchantId: merchantId,
            customerName: customerName,
            latitude: location?.latitude ?? 0,
            longitude: location?.longitude ?? 0,
            status: "pending",
            createdAt: nil   // filled in by @ServerTimestamp on the server
        )
        do {
            try db.collection("pings").addDocument(from: ping)
        } catch {
            print("Failed to send ping: \(error)")
        }
    }

    // MARK: - Merchant side

    /// Toggles this merchant on/off the map and updates its location.
    func setMerchant(_ merchant: Merchant) {
        guard let id = merchant.id else { return }
        do {
            try db.collection("merchants").document(id).setData(from: merchant, merge: true)
        } catch {
            print("Failed to update merchant: \(error)")
        }
    }

    /// Live-updates the inbox of pings addressed to this merchant.
    /// Sorted client-side so you don't need a Firestore composite index.
    func startListeningToPings(merchantId: String) {
        pingListener = db.collection("pings")
            .whereField("merchantId", isEqualTo: merchantId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self?.incomingPings = docs
                    .compactMap { try? $0.data(as: Ping.self) }
                    .sorted {
                        ($0.createdAt?.dateValue() ?? .distantPast) >
                        ($1.createdAt?.dateValue() ?? .distantPast)
                    }
            }
    }

    func stopListening() {
        merchantListener?.remove()
        pingListener?.remove()
    }
}
