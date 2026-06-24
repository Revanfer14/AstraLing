import FirebaseFirestore

enum MenuItemStatus: String, Codable {
    case tersedia
    case habis
}

/// `merchants/{uid}/menu/{itemId}` — a single item on the merchant's menu.
struct MenuItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var price: Int
    var status: MenuItemStatus = .tersedia
    var photoUrl: String? = nil
    var category: String? = nil
    var order: Int
}
