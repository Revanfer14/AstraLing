import SwiftUI
import CoreLocation
import FirebaseCore

// MARK: - MerchantView

struct MerchantView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var firestore = FirestoreService()
    @State private var isLive = false

    private let merchantId = "merchant-001"
    private let merchantName = "Jajanan Pasar Bu Siti"
    private let merchantCategory = "Street food"

    var pendingPingCount: Int {
        firestore.incomingPings.filter { $0.status == "pending" }.count
    }

    var body: some View {
        TabView {
            kelilingTab
                .tabItem { Label("Keliling", systemImage: "mappin.and.ellipse") }

            pingInboxTab
                .tabItem { Label("Ping", systemImage: "bell.fill") }
                .badge(pendingPingCount)

            transactionTab
                .tabItem { Label("Transaksi", systemImage: "creditcard.fill") }
        }
        .onAppear {
            location.request()
            firestore.startListeningToPings(merchantId: merchantId)
            firestore.startListeningToTransactions(merchantId: merchantId)
        }
        // Publish updated location whenever device moves (distanceFilter: 10m)
        .onReceive(location.$location) { newLoc in
            guard isLive, let newLoc else { return }
            publish(coord: newLoc, active: true)
        }
    }

    // MARK: Keliling Tab
    private var kelilingTab: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Toggle("Mulai Jualan", isOn: $isLive)
                    .font(.headline)
                    .padding()
                    .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: isLive) { _, newValue in
                        if newValue {
                            // Publish immediately if GPS already resolved;
                            // otherwise onReceive fires when the first fix arrives.
                            if let coord = location.location {
                                publish(coord: coord, active: true)
                            }
                        } else {
                            // Mark offline — use last known coord (location doesn't matter when inactive)
                            let coord = location.location
                                ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                            publish(coord: coord, active: false)
                        }
                    }

                VStack(spacing: 8) {
                    Image(systemName: isLive
                          ? "antenna.radiowaves.left.and.right"
                          : "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(isLive ? .green : .secondary)

                    if isLive && location.location == nil {
                        Label("Menunggu GPS...", systemImage: "location.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text(isLive ? "Kamu terlihat di peta customer" : "Kamu offline")
                            .font(.subheadline)
                            .foregroundStyle(isLive ? .green : .secondary)
                    }
                }
                .padding(.vertical, 8)

                HStack(spacing: 16) {
                    StatBubble(label: "Ping masuk", value: "\(firestore.incomingPings.count)")
                    StatBubble(label: "Transaksi", value: "\(firestore.transactions.count)")
                }

                Spacer()
            }
            .padding()
            .navigationTitle(merchantName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Ping Inbox Tab
    private var pingInboxTab: some View {
        NavigationStack {
            Group {
                if firestore.incomingPings.isEmpty {
                    ContentUnavailableView(
                        "Belum ada ping",
                        systemImage: "bell.slash",
                        description: Text("Aktifkan Keliling Mode dan tunggu customer.")
                    )
                } else {
                    List(firestore.incomingPings) { ping in
                        PingRow(ping: ping) { newStatus in
                            guard let id = ping.id else { return }
                            firestore.updatePingStatus(pingId: id, status: newStatus)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Ping Masuk")
        }
    }

    // MARK: Transaksi Tab
    private var transactionTab: some View {
        NavigationStack {
            Group {
                if firestore.transactions.isEmpty {
                    ContentUnavailableView(
                        "Belum ada transaksi",
                        systemImage: "creditcard",
                        description: Text("Transaksi dari customer akan muncul di sini secara real-time.")
                    )
                } else {
                    List(firestore.transactions) { tx in
                        TransactionRow(transaction: tx)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transaksi")
        }
    }

    // MARK: Helpers
    private func publish(coord: CLLocationCoordinate2D, active: Bool) {
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

// MARK: - PingRow

struct PingRow: View {
    let ping: Ping
    let onRespond: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.blue)
                Text(ping.customerName)
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if let msg = ping.message, !msg.isEmpty {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let ts = ping.createdAt?.dateValue() {
                Text(ts.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if ping.status == "pending" {
                HStack(spacing: 12) {
                    Button { onRespond("accepted") } label: {
                        Label("Terima", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button { onRespond("rejected") } label: {
                        Label("Tolak", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let (label, color): (String, Color) = {
            switch ping.status {
            case "accepted": return ("Diterima", .green)
            case "rejected": return ("Ditolak", .red)
            default:         return ("Menunggu", .orange)
            }
        }()
        return Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - TransactionRow

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(.headline)
                Text("ID: \(String(transaction.merchantTransactionId.prefix(12)))...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.paymentStatus.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12), in: Capsule())

                if let ts = transaction.callbackTimestamp?.dateValue() {
                    Text(ts.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch transaction.paymentStatus {
        case .APP: return .green
        case .PND: return .orange
        case .REJ: return .red
        case .TIM: return .gray
        }
    }
}

// MARK: - StatBubble

struct StatBubble: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
