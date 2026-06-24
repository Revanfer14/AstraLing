//
//  MerchantDetailViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import FirebaseFirestore
import Combine

struct MenuSection: Identifiable {
    let id: String
    let title: String
    let items: [MenuItem]
}

@MainActor
final class MerchantDetailViewModel: ObservableObject {
    @Published var sections: [MenuSection] = []
    @Published var bannerUrl: String?
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func load(merchantUid: String) {
        isLoading = true
        Task {
            async let merchantSnap = db.collection("merchants").document(merchantUid).getDocument()
            async let menuSnap = db.collection("merchants").document(merchantUid)
                .collection("menu").order(by: "order").getDocuments()

            if let data = try? await merchantSnap.data() {
                bannerUrl = data["bannerUrl"] as? String
            }

            if let snapshot = try? await menuSnap {
                let items = snapshot.documents.compactMap { try? $0.data(as: MenuItem.self) }
                sections = grouped(items)
            }

            isLoading = false
        }
    }

    func clear() {
        sections = []
        bannerUrl = nil
    }

    private func grouped(_ items: [MenuItem]) -> [MenuSection] {
        var order: [String] = []
        var buckets: [String: [MenuItem]] = [:]
        for item in items {
            let raw = item.category?.trimmingCharacters(in: .whitespaces) ?? ""
            let key = raw.isEmpty ? "Menu" : raw
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]!.append(item)
        }
        return order.map { key in
            MenuSection(id: key, title: key.uppercased(), items: buckets[key]!)
        }
    }
}
