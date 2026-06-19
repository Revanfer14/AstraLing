import SwiftUI
import MapKit

// MARK: - CustomerMapView

struct CustomerMapView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var firestore = FirestoreService()
    @StateObject private var payment = MockPaymentService()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedMerchant: Merchant?
    @State private var payingMerchant: Merchant?
    @State private var showPayment = false

    private let customerName = "Customer"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(firestore.activeMerchants) { merchant in
                    Annotation(merchant.name, coordinate: merchant.coordinate) {
                        Button { selectedMerchant = merchant } label: {
                            VStack(spacing: 2) {
                                Image(systemName: categoryIcon(merchant.category))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(.blue, in: Circle())
                                    .shadow(radius: 3)
                                Text(merchant.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(.white.opacity(0.85), in: Capsule())
                            }
                        }
                    }
                }
            }
            .mapControls { MapUserLocationButton() }

            // Balance pill overlay
            HStack(spacing: 6) {
                Image(systemName: "wallet.pass.fill")
                Text("Rp\(payment.balance.formattedIDR)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 2)
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            location.request()
            firestore.startListeningToMerchants()
        }
        .sheet(item: $selectedMerchant) { merchant in
            VendorDetailSheet(
                merchant: merchant,
                firestore: firestore,
                customerName: customerName,
                customerLocation: location.location
            ) {
                selectedMerchant = nil
                payingMerchant = merchant
                showPayment = true
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPayment) {
            if let merchant = payingMerchant {
                PaymentView(merchant: merchant, payment: payment)
            }
        }
    }

    private func categoryIcon(_ category: String) -> String {
        let lower = category.lowercased()
        if lower.contains("food") || lower.contains("makan") || lower.contains("jajanan") { return "fork.knife" }
        if lower.contains("minum") || lower.contains("drink") || lower.contains("kopi") { return "cup.and.saucer.fill" }
        return "cart.fill"
    }
}

// MARK: - VendorDetailSheet

struct VendorDetailSheet: View {
    let merchant: Merchant
    @ObservedObject var firestore: FirestoreService
    let customerName: String
    let customerLocation: CLLocationCoordinate2D?
    let onPay: () -> Void

    @State private var pinged = false

    private var pingStatus: String? {
        guard pinged else { return nil }
        return firestore.trackedPing?.status
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(merchant.name)
                            .font(.title2.bold())
                        Label(merchant.category, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }

                if let desc = merchant.vendorDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Menu list
                if let menu = merchant.menuItems, !menu.isEmpty {
                    Text("Menu")
                        .font(.headline)
                    ForEach(menu) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.priceRange)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        Divider()
                    }
                }

                // Ping status banner
                if pinged, let status = pingStatus {
                    pingBanner(status)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        guard !pinged else { return }
                        if let pingId = try? firestore.sendPing(
                            to: merchant,
                            customerName: customerName,
                            location: customerLocation
                        ) {
                            firestore.startListeningToPing(pingId: pingId)
                            pinged = true
                        }
                    } label: {
                        Label(
                            pingButtonLabel,
                            systemImage: pingButtonIcon
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(pinged)
                    .tint(pingButtonTint)

                    Button(action: onPay) {
                        Label("Bayar", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func pingBanner(_ status: String) -> some View {
        let isAccepted = status == "accepted"
        let isRejected = status == "rejected"
        let color: Color = isAccepted ? .green : isRejected ? .red : .orange
        let icon = isAccepted ? "checkmark.circle.fill" : isRejected ? "xmark.circle.fill" : "clock.fill"
        let text = isAccepted
            ? "PKL sudah menerima ping-mu!"
            : isRejected
            ? "PKL tidak bisa melayani sekarang"
            : "Menunggu respons PKL..."

        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(color)
    }

    private var pingButtonLabel: String {
        switch pingStatus {
        case "accepted": return "Diterima!"
        case "rejected": return "Ditolak"
        case .some: return "Menunggu..."
        case .none: return "Ping"
        }
    }

    private var pingButtonIcon: String {
        switch pingStatus {
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case .some: return "clock.fill"
        case .none: return "hand.wave.fill"
        }
    }

    private var pingButtonTint: Color {
        switch pingStatus {
        case "accepted": return .green
        case "rejected": return .red
        case .some: return .orange
        case .none: return .blue
        }
    }
}

// MARK: - PaymentView

struct PaymentView: View {
    let merchant: Merchant
    @ObservedObject var payment: MockPaymentService
    @Environment(\.dismiss) private var dismiss

    private let demoAmount = 20_000     // Rp20.000 fixed demo amount

    @State private var merchantTransactionId = UUID().uuidString
    @State private var transaction: Transaction?
    @State private var isLoading = false
    @State private var isConfirming = false
    @State private var isSuccess = false
    @State private var secondsRemaining = 900

    var body: some View {
        NavigationStack {
            Group {
                if isSuccess {
                    successView
                } else if let tx = transaction {
                    qrView(tx)
                } else if isLoading {
                    ProgressView("Membuat transaksi...")
                        .frame(maxHeight: .infinity)
                } else {
                    prePayView
                }
            }
            .padding(24)
            .navigationTitle("Pembayaran QRIS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }

    // MARK: Pre-pay screen
    private var prePayView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.blue.opacity(0.8))

            VStack(spacing: 6) {
                Text(merchant.name).font(.headline)
                Text("Total Pembayaran")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Rp\(demoAmount.formattedIDR)")
                    .font(.largeTitle.bold())
            }

            Text("Saldo AstraPay: Rp\(payment.balance.formattedIDR)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    Task { await initiate() }
                } label: {
                    Label("Bayar Sekarang", systemImage: "qrcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(payment.balance < demoAmount)

                if payment.balance < demoAmount {
                    Text("Saldo tidak mencukupi")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: QR screen
    @ViewBuilder
    private func qrView(_ tx: Transaction) -> some View {
        VStack(spacing: 20) {
            Text("Scan QRIS untuk membayar")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let img = payment.qrImage {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            }

            VStack(spacing: 4) {
                Text(tx.formattedAmount).font(.title2.bold())
                Text("ID: \(String(tx.merchantTransactionId.prefix(12)))...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Kedaluwarsa dalam \(secondsRemaining)s")
                    .font(.caption)
                    .foregroundStyle(secondsRemaining < 60 ? .red : .secondary)
            }

            Spacer()

            Button {
                Task { await confirm(tx) }
            } label: {
                Group {
                    if isConfirming {
                        ProgressView()
                    } else {
                        Label("Sudah Bayar", systemImage: "checkmark.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isConfirming)
        }
        .task {
            // Countdown timer — auto-dismissed when time runs out
            while secondsRemaining > 0 && !isSuccess {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                secondsRemaining -= 1
            }
            if !isSuccess { dismiss() }
        }
    }

    // MARK: Success screen
    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Pembayaran Berhasil!")
                .font(.title.bold())
            Text("Saldo tersisa: Rp\(payment.balance.formattedIDR)")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Selesai") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Actions
    private func initiate() async {
        guard let merchantId = merchant.id else { return }
        isLoading = true
        do {
            transaction = try await payment.createPayment(
                amount: demoAmount,
                merchantTransactionId: merchantTransactionId,
                merchantId: merchantId
            )
        } catch {
            print("createPayment error: \(error)")
        }
        isLoading = false
    }

    private func confirm(_ tx: Transaction) async {
        isConfirming = true
        do {
            try await payment.confirmPayment(tx)
            isSuccess = true
        } catch {
            print("confirmPayment error: \(error)")
        }
        isConfirming = false
    }
}
