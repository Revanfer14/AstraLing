import FirebaseFirestore

/// Lightweight role-lookup document at `users/{uid}`.
/// Written immediately after Auth account creation so login knows which profile to load.
struct AppUser: Codable {
    @DocumentID var uid: String?
    var role: AppRole
    @ServerTimestamp var createdAt: Timestamp?
}
