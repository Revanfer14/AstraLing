import FirebaseFirestore

enum SenderRole: String, Codable {
    case customer
    case merchant
}

/// `chats/{chatId}/messages/{messageId}` — individual chat message.
///
/// Quick replies ("Sudah sampai", "Sebentar lagi") are UI shortcuts — they produce normal messages.
struct ChatMessage: Codable {
    @DocumentID var id: String?
    var senderUid: String
    var senderRole: SenderRole
    var text: String
    @ServerTimestamp var createdAt: Timestamp?
}
