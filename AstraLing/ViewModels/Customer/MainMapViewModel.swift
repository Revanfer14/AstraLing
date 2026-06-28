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
import MapKit

struct NearbyMerchant: Identifiable {
    let id: String
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double?
    let isFavorite: Bool
    var distanceLabel: String
    var walkLabel: String
    let bannerUrl: String?
    let isServing: Bool
}

struct ActivePing: Identifiable {
    let id: String
    let merchantName: String
    let merchantUid: String
    let status: PingStatus
    let interestedItems: [String]
    let createdAt: Date?
}

@MainActor
final class MainMapViewModel: ObservableObject {
    @Published var merchants: [NearbyMerchant] = []
    @Published var balance: Int = 0
    @Published var activePings: [ActivePing] = []
    @Published var routes: [String: [CLLocationCoordinate2D]] = [:]
    @Published var showPingRejected = false

    private let db = Firestore.firestore()
    private let radarRadiusMeters: Double = 10000000
    private var listener: ListenerRegistration?
    private var pingsListener: ListenerRegistration?
    private var customerListener: ListenerRegistration?
    private var rawMerchants: [Merchant] = []
    private var rawPings: [Ping] = []
    private var rawPresence: [MerchantPresence] = []
    private var favoriteUids: Set<String> = []
    private var userLocation: CLLocation?
    private var lastWrittenLocation: CLLocation?
    private var customerName: String = ""
    private var lastPingId: String?
    private var lastRoutedUserLocation: CLLocation?
    private var lastRoutedMerchantCoords: [String: CLLocationCoordinate2D] = [:]
    private let routeRefreshThresholdMeters: Double = 30

    func start() {
        loadCustomer()
        attachListener()
        attachPingsListener()
    }

    func setUserLocation(_ loc: CLLocation?) {
        userLocation = loc
        rebuild()
        if let loc { pushLocation(loc) }
    }

    func stop() {
        listener?.remove()
        listener = nil
        pingsListener?.remove()
        pingsListener = nil
        customerListener?.remove()
        customerListener = nil
    }

    func isFavorite(_ uid: String) -> Bool { favoriteUids.contains(uid) }

    func toggleFavorite(_ uid: String) {
        let nowFavorite = !favoriteUids.contains(uid)
        if nowFavorite { favoriteUids.insert(uid) } else { favoriteUids.remove(uid) }
        rebuild()
        Task {
            guard let me = Auth.auth().currentUser?.uid else { return }
            let op: Any = nowFavorite
                ? FieldValue.arrayUnion([uid])
                : FieldValue.arrayRemove([uid])
            try? await db.collection("customers").document(me).updateData(["favorites": op])
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

    func activePing(for merchantUid: String) -> ActivePing? {
        activePings.first { $0.merchantUid == merchantUid }
    }

    func sendPing(to merchant: NearbyMerchant,
                  at coordinate: CLLocationCoordinate2D? = nil,
                  note: String? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let coord = coordinate ?? userLocation?.coordinate else { return }
        let ping = Ping(
            customerUid: uid,
            merchantUid: merchant.id,
            customerName: customerName,
            customerLocation: GeoPoint(latitude: coord.latitude, longitude: coord.longitude),
            note: note,
            status: .active,
            updatedAt: Timestamp(date: Date())
        )
        let optimistic = ActivePing(
            id: UUID().uuidString,
            merchantName: merchant.name,
            merchantUid: merchant.id,
            status: .active,
            interestedItems: [],
            createdAt: Date()
        )
        activePings.insert(optimistic, at: 0)
        Task {
            do {
                let ref = try db.collection("pings").addDocument(from: ping)
                lastPingId = ref.documentID
            } catch {
                print("sendPing: FAILED \(error)")
            }
        }
    }

    func pingedMerchant(for ping: ActivePing) -> NearbyMerchant? {
        merchants.first { $0.id == ping.merchantUid }
    }

    private func recomputeRoutes() {
        guard let userLoc = userLocation else { return }
        let userCoord = userLoc.coordinate
        let onTheWayPings = activePings.filter { $0.status == .onTheWay }
        let activeUids = Set(onTheWayPings.map(\.merchantUid))

        if routes.keys.contains(where: { !activeUids.contains($0) }) {
            routes = routes.filter { activeUids.contains($0.key) }
        }
        lastRoutedMerchantCoords = lastRoutedMerchantCoords.filter { activeUids.contains($0.key) }

        let userMoved = lastRoutedUserLocation.map {
            userLoc.distance(from: $0) > routeRefreshThresholdMeters
        } ?? true

        for ping in onTheWayPings {
            guard let merchant = merchants.first(where: { $0.id == ping.merchantUid }) else { continue }
            let merchantCoord = merchant.coordinate
            let uid = ping.merchantUid
            let merchantMoved: Bool = {
                guard let last = lastRoutedMerchantCoords[uid] else { return true }
                let a = CLLocation(latitude: last.latitude, longitude: last.longitude)
                let b = CLLocation(latitude: merchantCoord.latitude, longitude: merchantCoord.longitude)
                return a.distance(from: b) > routeRefreshThresholdMeters
            }()
            guard routes[uid] == nil || userMoved || merchantMoved else { continue }

            lastRoutedMerchantCoords[uid] = merchantCoord
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: merchantCoord))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
            request.transportType = .walking
            MKDirections(request: request).calculate { [weak self] response, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let polyline = response?.routes.first?.polyline {
                        self.routes[uid] = polyline.coordinates
                    } else {
                        self.routes[uid] = [merchantCoord, userCoord]
                    }
                }
            }
        }
        if userMoved { lastRoutedUserLocation = userLoc }
    }

    func cancelPing(pingId: String? = nil) {
        let id = pingId ?? lastPingId
        guard let id else { return }
        Task {
            do {
                let pingRef = db.collection("pings").document(id)
                let snap = try? await pingRef.getDocument()
                try await pingRef.updateData([
                    "status": PingStatus.cancelled.rawValue,
                    "updatedAt": Timestamp(date: Date())
                ])
                if id == lastPingId { lastPingId = nil }
                if let ping = try? snap?.data(as: Ping.self) {
                    await ChatCleanup.deleteChat(db: db, customerUid: ping.customerUid, merchantUid: ping.merchantUid)
                }
            } catch {
                print("cancelPing: FAILED \(error)")
            }
        }
    }

    private func loadCustomer() {
        guard customerListener == nil,
              let uid = Auth.auth().currentUser?.uid else { return }
        customerListener = db.collection("customers").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let data = snapshot?.data() else { return }
                self.balance = data["balance"] as? Int ?? 0
                self.customerName = data["name"] as? String ?? ""
                let favs = data["favorites"] as? [String] ?? []
                self.favoriteUids = Set(favs)
                self.rebuild()
            }
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

    private func attachPingsListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        pingsListener = db.collection("pings")
            .whereField("customerUid", isEqualTo: uid)
            .whereField("status", in: [PingStatus.active.rawValue, PingStatus.onTheWay.rawValue, PingStatus.rejected.rawValue])
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                for change in snapshot.documentChanges where change.type == .modified {
                    if let ping = try? change.document.data(as: Ping.self), ping.status == .rejected {
                        self.showPingRejected = true
                    }
                }
                self.rawPings = snapshot.documents
                    .compactMap { try? $0.data(as: Ping.self) }
                    .filter { $0.status == .active || $0.status == .onTheWay }
                self.rebuildActivePings()
            }
    }

    private func rebuildActivePings() {
        let merchantMap = Dictionary(uniqueKeysWithValues: rawMerchants.compactMap { m -> (String, String)? in
            guard let uid = m.uid else { return nil }
            return (uid, m.name)
        })
        activePings = rawPings.compactMap { ping in
            guard let id = ping.id else { return nil }
            let merchantName = merchantMap[ping.merchantUid] ?? ping.merchantUid
            return ActivePing(
                id: id,
                merchantName: merchantName,
                merchantUid: ping.merchantUid,
                status: ping.status,
                interestedItems: ping.interestedItems,
                createdAt: ping.createdAt?.dateValue()
            )
        }
        .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        recomputeRoutes()
    }

    private func rebuild() {
        let pingedUids = Set(rawPings.map(\.merchantUid))
            .union(activePings.map(\.merchantUid))
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
                walkLabel: walkLabel,
                bannerUrl: presence.bannerUrl,
                isServing: presence.isServing ?? false
            )
        }
        .filter { merchant in
            if pingedUids.contains(merchant.id) { return true }
            guard let d = merchant.distanceMeters else { return false }
            return d <= radarRadiusMeters
        }
        .sorted {
            switch ($0.distanceMeters, $1.distanceMeters) {
            case let (a?, b?): return a < b
            case (_?, nil): return true
            default: return false
            }
        }
        rebuildActivePings()
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
