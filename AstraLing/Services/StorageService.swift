import FirebaseStorage
import UIKit

// MARK: - How Cloud Storage fits into AstraLing
//
// Firestore stores structured data (text, numbers, geopoints) — never image bytes.
// Cloud Storage is the file bucket for blobs (photos, banners, menu images).
//
// The flow for every image in this app:
//   1.  Pick / capture a UIImage in the UI.
//   2.  Call StorageService.shared.uploadImage(_:to:) with a path from the helpers below.
//   3.  Receive back a download URL string (https://firebasestorage.googleapis.com/…).
//   4.  Write that URL string into the Firestore document field (photoUrl, bannerUrl, etc.).
//   5.  Display with:  AsyncImage(url: URL(string: photoUrl ?? ""))
//
// Deleting an image: call deleteImage(at:) with the same path, then nil out the Firestore field.

final class StorageService {
    static let shared = StorageService()
    private let root = Storage.storage().reference()

    // MARK: Upload

    /// Compresses a UIImage to JPEG and uploads it to `path`, returning the download URL.
    func uploadImage(_ image: UIImage, to path: String, quality: CGFloat = 0.8) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageServiceError.compressionFailed
        }
        return try await upload(data, to: path, contentType: "image/jpeg")
    }

    /// Uploads raw JPEG data to `path`, returning the download URL.
    func uploadImageData(_ data: Data, to path: String) async throws -> String {
        try await upload(data, to: path, contentType: "image/jpeg")
    }

    // MARK: Delete

    func deleteImage(at path: String) async throws {
        try await root.child(path).delete()
    }

    // MARK: Path helpers
    // These mirror the Firestore document hierarchy so paths stay consistent across the app.

    func customerPhotoPath(uid: String) -> String {
        "customers/\(uid)/profile.jpg"
    }

    func merchantBannerPath(uid: String) -> String {
        "merchants/\(uid)/banner.jpg"
    }

    func menuItemPhotoPath(merchantUid: String, itemId: String) -> String {
        "merchants/\(merchantUid)/menu/\(itemId).jpg"
    }

    // MARK: Private

    private func upload(_ data: Data, to path: String, contentType: String) async throws -> String {
        let ref = root.child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}

enum StorageServiceError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        "Failed to compress the image to JPEG data."
    }
}
