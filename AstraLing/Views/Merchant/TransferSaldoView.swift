//
//  TransferSaldoView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct TransferSaldoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChip: String? = "Rp 500rb"

    private let chips = ["Rp 100rb", "Rp 500rb", "Semua"]

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
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color(red: 0.055, green: 0.09, blue: 0.149))
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Transfer Saldo")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("Pindahkan saldo usaha ke AstraPay-mu")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            }
        }
    }

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("Masukan Jumlah")
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))

            Text("Rp 500.000")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color(red: 0.055, green: 0.09, blue: 0.149))

            Text("Saldo usaha tersedia Rp 1.245.000")
                .font(.system(size: 11.5))
                .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
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
            ForEach(chips, id: \.self) { chip in
                Button { selectedChip = chip } label: {
                    Text(chip)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color.white)
                                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 7, x: 0, y: 4)
                        )
                }
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            .kerning(0.3)
            .padding(.top, 10)
    }

    private var destinationCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(red: 0, green: 0.271, blue: 0.898))
                    .frame(width: 46, height: 46)
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AstraPay Saya")
                    .font(.system(size: 14.5))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("Adi Saputra · 0812****34")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            }

            Spacer()

            Text("Pribadi")
                .font(.system(size: 10))
                .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(red: 0.929, green: 0.965, blue: 1))
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
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                Spacer()
                Text("Rp 500.000")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
            }

            HStack {
                Text("Biaya transfer")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                Spacer()
                Text("Gratis")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color(red: 0.071, green: 0.478, blue: 0.294))
            }
            .padding(.bottom, 2)

            Rectangle()
                .fill(Color(red: 0.941, green: 0.941, blue: 0.941))
                .frame(height: 1)

            HStack {
                Text("Masuk ke AstraPay")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Spacer()
                Text("Rp 500.000")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var infoBox: some View {
        Text("Saldo langsung masuk ke AstraPay pribadimu, bisa dipakai bayar atau tarik tunai kapan saja.")
            .font(.system(size: 13))
            .foregroundStyle(Color(red: 0.071, green: 0.478, blue: 0.294))
            .lineSpacing(5.5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(red: 0.906, green: 0.965, blue: 0.937))
            )
    }

    private var transferButton: some View {
        Button {} label: {
            Text("Transfer ke AstraPay")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 0.988, green: 0.988, blue: 0.988))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0, green: 0.271, blue: 0.898))
                )
        }
    }
}

#Preview {
    TransferSaldoView()
}
