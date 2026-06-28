//
//  TransferSaldoView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct TransferSaldoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var merchantVM: MerchantViewModel

    @State private var amountText: String = ""
    @State private var selectedChip: String? = nil
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var successResult: (displayId: String, date: Date)? = nil
    @FocusState private var amountFocused: Bool

    private var availableBalance: Int { merchantVM.merchant?.balance ?? 0 }

    private var chips: [(label: String, value: Int)] {
        [
            ("Rp 100rb",  100_000),
            ("Rp 500rb",  500_000),
            ("Semua",     availableBalance),
        ]
    }

    private var currentAmount: Int {
        Int(amountText.filter { $0.isNumber }) ?? 0
    }

    private var displayAmount: String {
        currentAmount == 0 ? "Rp 0" : formatRupiah(currentAmount)
    }

    private var canTransfer: Bool {
        currentAmount > 0 && currentAmount <= availableBalance && !isSending
    }

    private func formatRupiah(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return "Rp \(formatter.string(from: NSNumber(value: value)) ?? "\(value)")"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                headerSection
                    .padding(.top, 8)

                amountCard

                quickAmountRow

                sectionLabel("TUJUAN")

                destinationCard

                sectionLabel("RINCIAN")

                summaryCard

                infoBox

                transferButton
                    .padding(.top, 4)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onTapGesture { amountFocused = false }
        .fullScreenCover(isPresented: $showSuccess) {
            if let result = successResult {
                TransferBerhasilView(
                    amount: currentAmount,
                    displayId: result.displayId,
                    merchantName: merchantVM.merchant?.name ?? "Merchant",
                    date: result.date
                )
            }
        }
        .alert("Transfer Gagal", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(merchantVM.errorMessage ?? "Terjadi kesalahan. Silakan coba lagi.")
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appTextPrimary)
                        .font(.app(.s16, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Transfer Saldo")
                    .font(.app(.s18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Pindahkan saldo usaha ke AstraPay-mu")
                    .font(.app(.s12))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
    }

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("Masukan Jumlah")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)

            ZStack {
                Text(displayAmount)
                    .font(.app(.s36, weight: .bold))
                    .foregroundStyle(
                        currentAmount > 0
                            ? Color.appTextPrimary
                            : Color(red: 0.753, green: 0.788, blue: 0.839)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .allowsHitTesting(false)

                TextField("", text: $amountText)
                    .focused($amountFocused)
                    .keyboardType(.numberPad)
                    .foregroundColor(.clear)
                    .accentColor(.clear)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .onChange(of: amountText) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        let limited = String(digits.prefix(10))
                        if amountText != limited { amountText = limited }
                        if let sel = selectedChip,
                           let chip = chips.first(where: { $0.label == sel }),
                           limited != String(chip.value) {
                            selectedChip = nil
                        }
                    }
            }
            .onTapGesture { amountFocused = true }

            Text("Saldo usaha tersedia \(formatRupiah(availableBalance))")
                .font(.app(.s12))
                .foregroundStyle(Color.appPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 34)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var quickAmountRow: some View {
        HStack(spacing: 9) {
            ForEach(chips, id: \.label) { chip in
                Button {
                    selectedChip = chip.label
                    amountText = String(chip.value)
                    amountFocused = false
                } label: {
                    Text(chip.label)
                        .font(.app(.s14))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(selectedChip == chip.label ? Color.appSurfaceBlue : Color.white)
                                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 7, x: 0, y: 4)
                        )
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.app(.s12))
            .foregroundStyle(Color.appTextTertiary)
            .kerning(0.3)
            .padding(.top, 10)
    }

    private var destinationCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color.appPrimary)
                    .frame(width: 46, height: 46)
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .font(.app(.s18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AstraPay Saya")
                    .font(.app(.s14))
                    .foregroundStyle(Color.appTextPrimary)
                Text(merchantVM.merchant?.name ?? "Merchant")
                    .font(.app(.s12))
                    .foregroundStyle(Color.appTextTertiary)
            }
            Spacer()
            Text("Pribadi")
                .font(.app(.s12))
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.appSurfaceBlue))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Nominal")
                    .font(.app(.s14))
                    .foregroundStyle(Color.appTextTertiary)
                Spacer()
                Text(displayAmount)
                    .font(.app(.s14))
                    .foregroundStyle(Color.appTextPrimary)
            }
            HStack {
                Text("Biaya transfer")
                    .font(.app(.s14))
                    .foregroundStyle(Color.appTextTertiary)
                Spacer()
                Text("Gratis")
                    .font(.app(.s14))
                    .foregroundStyle(Color.appSuccess)
            }
            .padding(.bottom, 2)
            Rectangle().fill(Color.appDivider).frame(height: 1)
            HStack {
                Text("Masuk ke AstraPay")
                    .font(.app(.s16))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text(displayAmount)
                    .font(.app(.s16))
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appBackground)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var infoBox: some View {
        Text("Saldo langsung masuk ke AstraPay pribadimu, bisa dipakai bayar atau tarik tunai kapan saja.")
            .font(.app(.s14))
            .foregroundStyle(Color.appSuccess)
            .lineSpacing(5.5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.appSuccessBg))
    }

    private var transferButton: some View {
        Button {
            amountFocused = false
            isSending = true
            Task {
                let result = await merchantVM.transferBalance(amount: currentAmount)
                isSending = false
                if let result {
                    successResult = result
                    showSuccess = true
                } else {
                    Haptics.error()
                    showError = true
                }
            }
        } label: {
            Group {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Transfer ke AstraPay")
                        .font(.app(.s16, weight: .bold))
                        .foregroundStyle(Color.appBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(canTransfer ? Color.appPrimary : Color.appPrimary.opacity(0.4))
            )
        }
        .disabled(!canTransfer)
    }
}

#Preview {
    NavigationStack {
        TransferSaldoView()
            .environmentObject(MerchantViewModel())
    }
}
