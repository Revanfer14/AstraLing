import FirebaseFirestore

enum MenuItemStatus: String, Codable {
    case tersedia
    case habis
}

struct MenuItem: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var price: Int
    var status: MenuItemStatus = .tersedia
    var photoUrl: String? = nil
    var category: String? = nil
    var order: Int
}
