import Foundation
import CoreLocation
import FirebaseFirestore

// MARK: - Menu

struct MenuItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var priceMin: Int
    var priceMax: Int

    var priceRange: String {
        priceMin == priceMax
            ? "Rp\(priceMin.formattedIDR)"
            : "Rp\(priceMin.formattedIDR) – Rp\(priceMax.formattedIDR)"
    }
}

// MARK: - Merchant / Vendor

struct Merchant: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var latitude: Double
    var longitude: Double
    var isActive: Bool
    var vendorDescription: String?
    var menuItems: [MenuItem]?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Ping

struct Ping: Identifiable, Codable {
    @DocumentID var id: String?
    var merchantId: String
    var customerName: String
    var latitude: Double
    var longitude: Double
    var status: String          // "pending", "accepted", "rejected"
    var message: String?
    @ServerTimestamp var createdAt: Timestamp?
}

// MARK: - Payment

enum PaymentStatus: String, Codable, CaseIterable {
    case PND, APP, REJ, TIM

    var label: String {
        switch self {
        case .PND: return "Menunggu"
        case .APP: return "Berhasil"
        case .REJ: return "Ditolak"
        case .TIM: return "Kedaluwarsa"
        }
    }
}

// Transaction mirrors the AstraPay callback payload shape exactly.
// MockPaymentService writes this doc; AstraPayService would receive it via webhook.
struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var merchantTransactionId: String
    var astrapayTransactionId: String   // UUID mock; real AstraPay returns this
    var merchantId: String
    var amount: Int                      // IDR
    var status: String                   // PaymentStatus.rawValue
    // Set when status changes to APP/REJ/TIM (mirrors callback timestamp)
    var callbackTimestamp: Timestamp?

    var paymentStatus: PaymentStatus {
        PaymentStatus(rawValue: status) ?? .PND
    }

    var formattedAmount: String { "Rp\(amount.formattedIDR)" }
}

// MARK: - Helpers

extension Int {
    var formattedIDR: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
