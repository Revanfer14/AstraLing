//
//  ActivePingCardViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 01/07/26.
//

import Combine
import FirebaseFirestore

@MainActor
final class ActivePingCardViewModel: ObservableObject {
    @Published var bannerUrl: String?
    private let db = Firestore.firestore()

    func load(merchantUid: String) {
        Task {
            let snap = try? await db.collection("merchants").document(merchantUid).getDocument()
            if let data = snap?.data() {
                bannerUrl = data["bannerUrl"] as? String
            }
        }
    }
}
