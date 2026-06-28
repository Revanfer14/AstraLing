//
//  PaymentView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

private enum PaymentPhase: Equatable {
    case input, processing, success
}

private struct SuccessBurst: View {
    private let dotCount = 12
    private let radius: CGFloat = 52

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { i in
                let angle = Double(i) / Double(dotCount) * 2 * .pi
                Circle()
                    .fill(Color.appPrimary.opacity(i % 2 == 0 ? 1 : 0.45))
                    .frame(width: i % 3 == 0 ? 8 : 5, height: i % 3 == 0 ? 8 : 5)
                    .offset(x: CGFloat(cos(angle)) * radius,
                            y: CGFloat(sin(angle)) * radius)
            }
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 80, height: 80)
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 120, height: 120)
    }
}

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PaymentViewModel()

    let merchantUid: String
    let rawPayload: String
    let onFinish: () -> Void

    @State private var phase: PaymentPhase = .input
    @State private var amountDigits = ""
    @State private var paidAmount = 0
    @State private var spinAngle: Double = 0
    @State private var dotCount = 1
    @State private var showLoyalty = false
    @State private var showError = false

    private var amount: Int { Int(amountDigits) ?? 0 }

    var body: some View {
        ZStack {
            switch phase {
            case .input:      inputView
            case .processing: processingView
            case .success:    successView
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .onAppear { vm.load(merchantUid: merchantUid) }
        .fullScreenCover(isPresented: $showLoyalty) { AstraPointsView() }
        .alert("Pembayaran Gagal", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage ?? "Terjadi kesalahan. Silakan coba lagi.")
        }
    }

    private var inputView: some View {
        VStack(spacing: 0) {
            inputHeader

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    merchantCard
                    amountCard

                    VStack(spacing: 14) {
                        keypadRow(["1", "2", "3"])
                        keypadRow(["4", "5", "6"])
                        keypadRow(["7", "8", "9"])
                        HStack {
                            Spacer()
                            numKey("0")
                            Spacer().frame(width: 45)
                            deleteKey
                        }
                    }
                    .frame(maxWidth: 300)
                    .frame(maxWidth: .infinity)

                    bayarButton
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.Token.blue25.ignoresSafeArea())
    }

    private var inputHeader: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            }
            Text("Transfer QRIS")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color.Token.blue25.ignoresSafeArea(edges: .top))
    }

    private var merchantCard: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: vm.bannerUrl ?? "")) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .frame(width: 80, height: 80).clipShape(Circle())
                default:
                    Circle().fill(Color.appSurfaceBlue).frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 24))
                                .foregroundColor(.appPrimary)
                        )
                }
            }
            Text(vm.isLoaded ? vm.merchantName : " ")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("Masukan Jumlah")
                .font(.system(size: 12))
                .foregroundColor(.appTextTertiary)

            HStack(spacing: 2) {
                Text(amount == 0 ? "Rp 0" : "Rp \(amount.formattedIDR)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: "0E1726"))
                Rectangle()
                    .fill(Color.appPrimary)
                    .frame(width: 2, height: 38)
            }

            Text("Saldo Anda tersedia \(vm.balance.rupiah)")
                .font(.system(size: 11.5))
                .foregroundColor(.appPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 34)
        .padding(.bottom, 22)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private func keypadRow(_ digits: [String]) -> some View {
        HStack {
            numKey(digits[0]); Spacer(); numKey(digits[1]); Spacer(); numKey(digits[2])
        }
    }

    private func numKey(_ digit: String) -> some View {
        Button {
            guard amountDigits.count < 9 else { return }
            if amountDigits.isEmpty && digit == "0" { return }
            amountDigits.append(digit)
        } label: {
            Text(digit)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .frame(width: 70, height: 70)
                .contentShape(Rectangle())
        }
    }

    private var deleteKey: some View {
        Button {
            if !amountDigits.isEmpty { amountDigits.removeLast() }
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .frame(width: 70, height: 70)
                .contentShape(Rectangle())
        }
    }

    private var bayarButton: some View {
        let enabled = amount > 0 && amount <= vm.balance
        return Button {
            Haptics.impact(.medium)
            paidAmount = amount
            phase = .processing
            Task {
                let start = Date()
                let success = await vm.pay(amount: paidAmount)
                let elapsed = Date().timeIntervalSince(start)
                let remaining = 1.5 - elapsed
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                if success {
                    Haptics.success()
                    phase = .success
                } else {
                    Haptics.error()
                    phase = .input
                    showError = true
                }
            }
        } label: {
            Text("Bayar")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appTextOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()

            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    AngularGradient(
                        colors: [Color.Token.blue300.opacity(0.15), Color.Token.blue300, Color.Token.blue700],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(spinAngle - 90))

            HStack(spacing: 2) {
                Text("Memproses pembayaran")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(String(repeating: ".", count: dotCount))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 24, alignment: .leading)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            spinAngle = 0
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
            Task {
                while phase == .processing {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    dotCount = dotCount % 3 + 1
                }
            }
        }
    }

    private var successView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    SuccessBurst()
                    Text("Pembayaran Berhasil!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text("Pembayaran telah diterima oleh pedagang.")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                receiptCard

                VStack(spacing: 12) {
                    Button { showLoyalty = true } label: {
                        Text("Lihat AstraPoints")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    Button { onFinish() } label: {
                        Text("Selesai")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.Token.blue100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.Token.blue25.ignoresSafeArea())
    }

    private var receiptCard: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                AsyncImage(url: URL(string: vm.bannerUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 40, height: 40).clipShape(Circle())
                    default:
                        Circle().fill(Color.appSurfaceBlue).frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appPrimary)
                            )
                    }
                }
                Text(vm.merchantName)
                    .font(.system(size: 16))
                    .foregroundColor(.appTextPrimary)
                Text("Rp \(paidAmount.formattedIDR)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: "0E1726"))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("⭐️ AstraPoints")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("+ \(vm.pointsEarned) poin")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("Berhasil ditambahkan ke akun Anda.")
                    .font(.system(size: 16))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.appAccent.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 12) {
                receiptRow("Tanggal", value: formattedDate)
                receiptRow("Waktu", value: formattedTime)
                receiptRow("Metode", value: "AstraPay • QRIS")
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private func receiptRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.appTextPrimary)
        }
    }

    private var formattedDate: String {
        guard let date = vm.txnDate else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "dd MMMM yyyy"
        return f.string(from: date)
    }

    private var formattedTime: String {
        guard let date = vm.txnDate else { return "" }
        let f = DateFormatter()
        f.dateFormat = "HH.mm"
        return f.string(from: date) + " WIB"
    }
}

#Preview {
    PaymentView(merchantUid: "abc123", rawPayload: "astraling://pay/abc123", onFinish: {})
}
