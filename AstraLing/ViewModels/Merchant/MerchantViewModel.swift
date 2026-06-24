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
    @Published var menuItems: [MenuItem] = []
    @Published var activePings: [Ping] = []
    @Published var isSaving = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private var menuListener: ListenerRegistration?
    private var pingsListener: ListenerRegistration?

    var uid: String? { Auth.auth().currentUser?.uid }

    func startListening() {
        guard let uid else { return }

        profileListener = db.collection("merchants").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription; return }
                self.merchant = try? snapshot?.data(as: Merchant.self)
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
    }

    func stopListening() {
        profileListener?.remove()
        menuListener?.remove()
        pingsListener?.remove()
        profileListener = nil
        menuListener = nil
        pingsListener = nil
    }

    func setVisible(_ isVisible: Bool) async {
        guard let uid else { return }
        try? await db.collection("merchants").document(uid).updateData(["isVisible": isVisible])
    }

    func updateLocation(_ coordinate: CLLocationCoordinate2D) async {
        guard let uid else { return }
        let geopoint = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geohash = Geohash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude)
        try? await db.collection("merchants").document(uid).updateData([
            "location": geopoint,
            "geohash": geohash,
            "locationUpdatedAt": FieldValue.serverTimestamp()
        ])
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
}
