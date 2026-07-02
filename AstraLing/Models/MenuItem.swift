import FirebaseFirestore

enum MenuItemStatus: String, Codable {
    case tersedia
    case habis
}

enum MenuCategory: String, Codable, CaseIterable {
    case makanan, minuman, camilan, paket

    var label: String {
        switch self {
        case .makanan: "Makanan"
        case .minuman: "Minuman"
        case .camilan: "Camilan"
        case .paket:   "Paket"
        }
    }
}

/// `merchants/{uid}/menu/{itemId}` — a single item on the merchant's menu.
struct MenuItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var price: Int
    var status: MenuItemStatus = .tersedia
    var photoUrl: String? = nil
    var order: Int
    var category: MenuCategory? = nil
}
