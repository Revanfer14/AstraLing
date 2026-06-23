//
//  TransferSaldoView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct TransferSaldoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = ""
    @State private var selectedChip: String? = nil
    @FocusState private var amountFocused: Bool

    private let availableBalance = 1_245_000
    private let chips: [(label: String, value: Int)] = [
        ("Rp 100rb", 100_000),
        ("Rp 500rb", 500_000),
        ("Semua",  1_245_000),
    ]

    private var currentAmount: Int {
        Int(amountText.filter { $0.isNumber }) ?? 0
    }

    private var displayAmount: String {
        currentAmount == 0 ? "Rp 0" : formatRupiah(currentAmount)
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
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Transfer Saldo")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Pindahkan saldo usaha ke AstraPay-mu")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
    }

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("Masukan Jumlah")
                .font(.system(size: 12))
                .foregroundStyle(Color.appTextTertiary)

            ZStack {
                Text(displayAmount)
                    .font(.system(size: 36, weight: .bold))
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
                        if amountText != limited {
                            amountText = limited
                        }
                        if let selected = selectedChip, let chip = chips.first(where: { $0.label == selected }) {
                            if limited != String(chip.value) {
                                selectedChip = nil
                            }
                        } else if selectedChip != nil {
                            selectedChip = nil
                        }
                    }
            }
            .onTapGesture { amountFocused = true }

            Text("Saldo usaha tersedia \(formatRupiah(availableBalance))")
                .font(.system(size: 11.5))
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
                        .font(.system(size: 13))
                        .foregroundStyle(
                            Color.appPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(
                                    selectedChip == chip.label
                                    ? Color.appSurfaceBlue
                                        : Color.white
                                )
                                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 7, x: 0, y: 4)
                        )
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
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
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AstraPay Saya")
                    .font(.system(size: 14.5))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Adi Saputra · 0812****34")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
            }
            Spacer()
            Text("Pribadi")
                .font(.system(size: 10))
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.appSurfaceBlue)
                )
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
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.appTextTertiary)
                Spacer()
                Text(displayAmount)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.appTextPrimary)
            }
            HStack {
                Text("Biaya transfer")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.appTextTertiary)
                Spacer()
                Text("Gratis")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.appSuccess)
            }
            .padding(.bottom, 2)
            Rectangle()
                .fill(Color.appDivider)
                .frame(height: 1)
            HStack {
                Text("Masuk ke AstraPay")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text(displayAmount)
                    .font(.system(size: 15))
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
            .font(.system(size: 13))
            .foregroundStyle(Color.appSuccess)
            .lineSpacing(5.5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color.appSuccessBg)
            )
    }

    private var transferButton: some View {
        Button {} label: {
            Text("Transfer ke AstraPay")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appPrimary)
                )
        }
    }
}

#Preview {
    NavigationStack {
        TransferSaldoView()
    }
}
