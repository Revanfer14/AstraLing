//
//  MerchantPresence.swift
//  AstraLing
//
//  Created by Rasya Devan on 24/06/26.
//

import FirebaseFirestore

struct MerchantPresence: Codable {
    @DocumentID var id: String?
    var merchantUid: String
    var name: String
    var category: String
    var isVisible: Bool
    var bannerUrl: String?
    var location: GeoPoint?
    var geohash: String?
    var locationUpdatedAt: Timestamp?
}
