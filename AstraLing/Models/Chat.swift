import FirebaseFirestore

/// `chats/{customerUid}_{merchantUid}` — one conversation per customer↔merchant pair.
///
/// The deterministic ID means "open chat with X" is a single direct lookup — no query needed.
struct Chat: Codable {
    @DocumentID var id: String?
    var customerUid: String
    var merchantUid: String
    var participantUids: [String]        // [customerUid, merchantUid] — for security rules
    var customerName: String             // denormalised for list rendering
    var merchantName: String
    var lastMessage: String
    var lastMessageAt: Timestamp
    var pingId: String? = nil            // optional link to the ping that started the chat
}
