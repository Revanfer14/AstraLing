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
        if items.isEmpty { return [] }
        var result: [MenuSection] = []
        for cat in MenuCategory.allCases {
            let group = items.filter { $0.category == cat }
            if !group.isEmpty {
                result.append(MenuSection(id: cat.rawValue, title: cat.label.uppercased(), items: group))
            }
        }
        let uncategorized = items.filter { $0.category == nil }
        if !uncategorized.isEmpty {
            result.append(MenuSection(id: "lainnya", title: "LAINNYA", items: uncategorized))
        }
        return result
    }
}
