//
//  MainMapViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

struct NearbyMerchant: Identifiable {
    let id: String
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double?
    let isFavorite: Bool
    var distanceLabel: String
    var walkLabel: String
}

@MainActor
final class MainMapViewModel: ObservableObject {
    @Published var merchants: [NearbyMerchant] = []
    @Published var balance: Int = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var rawPresence: [MerchantPresence] = []
    private var favoriteUids: Set<String> = []
    private var userLocation: CLLocation?
    private var lastWrittenLocation: CLLocation?

    func start() {
        Task {
            await loadCustomer()
            attachListener()
        }
    }

    func setUserLocation(_ loc: CLLocation?) {
        userLocation = loc
        rebuild()
        if let loc { pushLocation(loc) }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func scatterMerchantsAroundMe() {
        guard let center = userLocation else { return }
        let lat = center.coordinate.latitude
        let lng = center.coordinate.longitude
        let latRad = lat * .pi / 180
        for presence in rawPresence {
            let uid = presence.merchantUid
            let distance = Double.random(in: 300...600)
            let bearing = Double.random(in: 0 ..< (2 * .pi))
            let newLat = lat + (distance * cos(bearing)) / 111_320
            let newLng = lng + (distance * sin(bearing)) / (111_320 * cos(latRad))
            Task {
                try? await db.collection("merchants").document(uid)
                    .collection("presence").document("live")
                    .setData([
                        "location": GeoPoint(latitude: newLat, longitude: newLng),
                        "geohash": Geohash.encode(latitude: newLat, longitude: newLng),
                        "locationUpdatedAt": Timestamp(date: Date())
                    ], merge: true)
            }
        }
    }

    private func pushLocation(_ loc: CLLocation) {
        if let last = lastWrittenLocation, loc.distance(from: last) < 25 { return }
        lastWrittenLocation = loc
        guard let uid = Auth.auth().currentUser?.uid else {
            print("pushLocation: no auth uid")
            return
        }
        let coord = loc.coordinate
        print("pushLocation: writing \(coord.latitude), \(coord.longitude) for \(uid)")
        Task {
            do {
                try await db.collection("customers").document(uid).updateData([
                    "location": GeoPoint(latitude: coord.latitude, longitude: coord.longitude),
                    "geohash": Geohash.encode(latitude: coord.latitude, longitude: coord.longitude),
                    "locationUpdatedAt": Timestamp(date: Date())
                ])
                print("pushLocation: success")
            } catch {
                print("pushLocation: FAILED \(error)")
            }
        }
    }

    private func loadCustomer() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("customers").document(uid).getDocument()
            guard let data = doc.data() else { return }
            balance = data["balance"] as? Int ?? 0
            let favs = data["favorites"] as? [String] ?? []
            favoriteUids = Set(favs)
        } catch {}
    }

    private func attachListener() {
        listener = db.collectionGroup("presence")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.rawPresence = docs.compactMap { try? $0.data(as: MerchantPresence.self) }
                    .filter { $0.isVisible }
                self.rebuild()
            }
    }

    private func rebuild() {
        merchants = rawPresence.compactMap { presence in
            guard let loc = presence.location else { return nil }
            let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            let merchantLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distMeters: Double? = userLocation.map { $0.distance(from: merchantLoc) }
            let distLabel = distLabel(for: distMeters)
            let walkLabel = walkLabel(for: distMeters)
            return NearbyMerchant(
                id: presence.merchantUid,
                name: presence.name,
                category: presence.category,
                coordinate: coord,
                distanceMeters: distMeters,
                isFavorite: favoriteUids.contains(presence.merchantUid),
                distanceLabel: distLabel,
                walkLabel: walkLabel
            )
        }
        .sorted {
            switch ($0.distanceMeters, $1.distanceMeters) {
            case let (a?, b?): return a < b
            case (_?, nil): return true
            default: return false
            }
        }
    }

    private func distLabel(for meters: Double?) -> String {
        guard let m = meters else { return "" }
        if m < 1000 { return "\(Int(m.rounded())) m" }
        let km = m / 1000
        return String(format: "%.1f km", km).replacingOccurrences(of: ".", with: ",")
    }

    private func walkLabel(for meters: Double?) -> String {
        guard let m = meters else { return "" }
        let minutes = max(1, Int((m / 80).rounded()))
        return "\(minutes) menit"
    }
}
