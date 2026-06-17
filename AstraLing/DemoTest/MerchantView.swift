import SwiftUI
import CoreLocation

struct MerchantView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var firestore = FirestoreService()
    @State private var isLive = false

    // For the demo, this device represents one fixed merchant.
    // In a real build you'd load the logged-in merchant's profile.
    private let merchantId = "merchant-001"
    private let merchantName = "Jajanan Pasar Bu Siti"
    private let merchantCategory = "Street food"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle("Keliling Mode", isOn: $isLive)
                    .font(.headline)
                    .padding()
                    .background(.gray.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: isLive) { _, newValue in
                        updateLiveStatus(active: newValue)
                    }

                Text(isLive ? "You're visible on the map" : "You're offline")
                    .font(.subheadline)
                    .foregroundStyle(isLive ? .green : .secondary)

                List(firestore.incomingPings) { ping in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ping.customerName).font(.headline)
                        Text("wants to buy from you")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .overlay {
                    if firestore.incomingPings.isEmpty {
                        ContentUnavailableView("No pings yet",
                                               systemImage: "tray",
                                               description: Text("Turn on Keliling Mode and wait for a customer."))
                    }
                }
            }
            .padding()
            .navigationTitle("Ping Inbox")
            .onAppear {
                location.request()
                firestore.startListeningToPings(merchantId: merchantId)
            }
        }
    }

    private func updateLiveStatus(active: Bool) {
        // Fall back to a Jakarta coordinate if location isn't ready yet.
        let coord = location.location
            ?? CLLocationCoordinate2D(latitude: -6.200, longitude: 106.816)

        let merchant = Merchant(
            id: merchantId,
            name: merchantName,
            category: merchantCategory,
            latitude: coord.latitude,
            longitude: coord.longitude,
            isActive: active
        )
        firestore.setMerchant(merchant)
    }
}
