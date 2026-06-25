//
//  MerchantViewModel.swift
//  AstraLing
//
//  Created by Rasya Devan on 24/06/26.
//

import SwiftUI
import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MerchantViewModel: ObservableObject {
    @Published var merchant: Merchant? = nil
    @Published var presence: MerchantPresence? = nil
    @Published var menuItems: [MenuItem] = []
    @Published var activePings: [Ping] = []
    @Published var isSaving = false
    @Published var errorMessage: String? = nil
    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private var presenceListener: ListenerRegistration?
    private var menuListener: ListenerRegistration?
    private var pingsListener: ListenerRegistration?
    private var transactionListener: ListenerRegistration?
    private var knownTransactionIds: Set<String> = []
    private var isFirstTransactionLoad = true
    private var receivedTransactions: [String: Transaction] = [:]

    var uid: String? { Auth.auth().currentUser?.uid }

    func startListening() {
        guard let uid else { return }

        profileListener = db.collection("merchants").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.merchant = try? snapshot?.data(as: Merchant.self)
            }

        presenceListener = db.collection("merchants").document(uid)
            .collection("presence").document("live")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.presence = try? snapshot?.data(as: MerchantPresence.self)
            }

        menuListener = db.collection("merchants").document(uid)
            .collection("menu")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.menuItems = snapshot?.documents.compactMap {
                    try? $0.data(as: MenuItem.self)
                } ?? []
            }

        pingsListener = db.collection("pings")
            .whereField("merchantUid", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.activePings = (snapshot?.documents.compactMap {
                    try? $0.data(as: Ping.self)
                } ?? []).filter { $0.status == .active || $0.status == .onTheWay }
            }

        isFirstTransactionLoad = true
        transactionListener = db.collection("transactions")
            .whereField("merchantUid", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                if self.isFirstTransactionLoad {
                    self.isFirstTransactionLoad = false
                    self.knownTransactionIds = Set(snapshot.documents.map { $0.documentID })
                    return
                }
                for change in snapshot.documentChanges where change.type == .added {
                    let docId = change.document.documentID
                    guard !self.knownTransactionIds.contains(docId) else { continue }
                    self.knownTransactionIds.insert(docId)
                    if let txn = try? change.document.data(as: Transaction.self), txn.status == .success, txn.type == .payment {
                        self.receivedTransactions[docId] = txn
                        NotificationService.shared.postTransactionArrived(
                            amount: txn.amount.rupiah,
                            customerName: txn.customerName ?? "Pelanggan",
                            txnId: docId
                        )
                    }
                }
            }
    }

    func stopListening() {
        profileListener?.remove()
        presenceListener?.remove()
        menuListener?.remove()
        pingsListener?.remove()
        transactionListener?.remove()
        profileListener = nil
        presenceListener = nil
        menuListener = nil
        pingsListener = nil
        transactionListener = nil
    }

    func transaction(for id: String) -> Transaction? { receivedTransactions[id] }

    func completePing(pingId: String) async {
        try? await db.collection("pings").document(pingId).updateData([
            "status": PingStatus.completed.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func goOfflineBestEffort() {
        presenceRef?.setData([
            "isVisible": false,
            "locationUpdatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    private var presenceRef: DocumentReference? {
        guard let uid else { return nil }
        return db.collection("merchants").document(uid).collection("presence").document("live")
    }

    func setVisible(_ isVisible: Bool) async {
        guard let uid else { return }
        var data: [String: Any] = [
            "merchantUid": uid,
            "isVisible": isVisible,
            "locationUpdatedAt": FieldValue.serverTimestamp()
        ]
        if let merchant {
            data["name"] = merchant.name
            data["category"] = merchant.category
            if let bannerUrl = merchant.bannerUrl {
                data["bannerUrl"] = bannerUrl
            }
        }
        try? await presenceRef?.setData(data, merge: true)
    }

    func updateLocation(_ coordinate: CLLocationCoordinate2D) async {
        let geopoint = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geohash = Geohash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude)
        try? await presenceRef?.setData([
            "location": geopoint,
            "geohash": geohash,
            "locationUpdatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func saveProfile(name: String, description: String, bannerImage: UIImage?) async {
        guard let uid else { return }
        isSaving = true
        defer { isSaving = false }

        var updates: [String: Any] = ["name": name, "description": description]

        if let image = bannerImage {
            do {
                let url = try await StorageService.shared.uploadImage(
                    image, to: StorageService.shared.merchantBannerPath(uid: uid))
                print("✅ Banner uploaded:", url)
                updates["bannerUrl"] = url
            } catch {
                print("❌ Banner upload failed:", error)
                errorMessage = error.localizedDescription
                return
            }
        }

        do {
            try await db.collection("merchants").document(uid).updateData(updates)
            var presenceMirror: [String: Any] = ["name": name]
            if let bannerUrl = updates["bannerUrl"] as? String {
                presenceMirror["bannerUrl"] = bannerUrl
            }
            try? await presenceRef?.setData(presenceMirror, merge: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addMenuItem(name: String, price: Int, image: UIImage?) async {
        guard let uid else { return }
        isSaving = true
        defer { isSaving = false }

        let nextOrder = (menuItems.map(\.order).max() ?? -1) + 1
        let ref = db.collection("merchants").document(uid).collection("menu").document()

        var data: [String: Any] = [
            "name": name,
            "price": price,
            "status": MenuItemStatus.tersedia.rawValue,
            "order": nextOrder
        ]

        if let image {
            do {
                let path = StorageService.shared.menuItemPhotoPath(merchantUid: uid, itemId: ref.documentID)
                let url = try await StorageService.shared.uploadImage(image, to: path)
                data["photoUrl"] = url
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        do {
            try await ref.setData(data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func transferBalance(amount: Int) async -> (displayId: String, date: Date)? {
        guard let uid else { return nil }
        let dateStr: String = {
            let f = DateFormatter()
            f.dateFormat = "yyMMdd"
            return f.string(from: Date())
        }()
        let displayId = "#TR\(dateStr)-\(String(format: "%04d", Int.random(in: 0...9999)))"
        let now = Date()
        let merchantRef = db.collection("merchants").document(uid)
        let txnRef = db.collection("transactions").document()
        do {
            _ = try await db.runTransaction { txn, errorPointer in
                let snap: DocumentSnapshot
                do { snap = try txn.getDocument(merchantRef) }
                catch let e as NSError { errorPointer?.pointee = e; return nil }
                let cur = snap.data()?["balance"] as? Int ?? 0
                guard cur >= amount else {
                    errorPointer?.pointee = NSError(
                        domain: "TransferError", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Saldo tidak cukup untuk transfer ini."]
                    )
                    return nil
                }
                txn.updateData(["balance": cur - amount], forDocument: merchantRef)
                txn.setData([
                    "type":        "transfer",
                    "displayId":   displayId,
                    "merchantUid": uid,
                    "amount":      amount,
                    "method":      "Transfer AstraPay",
                    "status":      "success",
                    "createdAt":   FieldValue.serverTimestamp()
                ], forDocument: txnRef)
                return nil
            }
            return (displayId: displayId, date: now)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteBanner() async {
        guard let uid else { return }
        try? await StorageService.shared.deleteImage(at: StorageService.shared.merchantBannerPath(uid: uid))
        try? await db.collection("merchants").document(uid).updateData(["bannerUrl": NSNull()])
    }

    func uploadMenuItemPhoto(id: String, image: UIImage) async {
        guard let uid else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let path = StorageService.shared.menuItemPhotoPath(merchantUid: uid, itemId: id)
            let url = try await StorageService.shared.uploadImage(image, to: path)
            try await db.collection("merchants").document(uid)
                .collection("menu").document(id)
                .updateData(["photoUrl": url])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMenuItemPhoto(id: String) async {
        guard let uid else { return }
        let path = StorageService.shared.menuItemPhotoPath(merchantUid: uid, itemId: id)
        try? await StorageService.shared.deleteImage(at: path)
        try? await db.collection("merchants").document(uid)
            .collection("menu").document(id)
            .updateData(["photoUrl": NSNull()])
    }

    func updateMenuItem(id: String, name: String, price: Int) async {
        guard let uid else { return }
        try? await db.collection("merchants").document(uid)
            .collection("menu").document(id)
            .updateData(["name": name, "price": price])
    }

    func setMenuItemStatus(id: String, status: MenuItemStatus) async {
        guard let uid else { return }
        try? await db.collection("merchants").document(uid)
            .collection("menu").document(id)
            .updateData(["status": status.rawValue])
    }

    func deleteMenuItem(id: String) async {
        guard let uid else { return }
        try? await db.collection("merchants").document(uid)
            .collection("menu").document(id)
            .delete()
    }

    func accept(_ ping: Ping) async {
        guard let pingId = ping.id else { return }
        let merchantName = merchant?.name ?? presence?.name ?? "Pedagang"
        let chatId = ChatID.make(customerUid: ping.customerUid, merchantUid: ping.merchantUid)
        let opening = "Halo kak, tunggu sebentar ya. Saya otw 🙏"
        let chatRef = db.collection("chats").document(chatId)
        let chatSnap = try? await chatRef.getDocument()
        if chatSnap?.exists != true {
            let chat = Chat(
                customerUid: ping.customerUid,
                merchantUid: ping.merchantUid,
                participantUids: [ping.customerUid, ping.merchantUid],
                customerName: ping.customerName,
                merchantName: merchantName,
                lastMessage: opening,
                lastMessageAt: Timestamp(date: Date()),
                pingId: pingId
            )
            try? chatRef.setData(from: chat, merge: false)
            let msg = ChatMessage(senderUid: ping.merchantUid, senderRole: .merchant, text: opening)
            try? chatRef.collection("messages").addDocument(from: msg)
        }
        try? await db.collection("pings").document(pingId).updateData([
            "status": PingStatus.onTheWay.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }
}
