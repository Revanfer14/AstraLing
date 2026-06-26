//
//  TransferBerhasilView.swift
//  AstraLing
//
//  Created by Rasya Devan on 25/06/26.
//

import SwiftUI

struct TransferBerhasilView: View {
    @Environment(\.dismiss) private var dismiss

    let amount: Int
    let displayId: String
    let merchantName: String
    let date: Date

    private let blue      = Color.appPrimary
    private let blueBg    = Color.appSurfaceBlue
    private let darkText  = Color.appTextPrimary
    private let greyText  = Color.appTextTertiary
    private let divider   = Color.appDivider

    private var formattedDateTime: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "id_ID")
        fmt.dateFormat = "d MMM yyyy · HH.mm"
        return fmt.string(from: date)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection

                amountCard
                    .padding(.horizontal, 16)
                    .padding(.top, -52)

                detailsCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                selesaiButton
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                footerHint
                    .padding(.top, 14)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }

    private var heroSection: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 88, height: 88)
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.app(.s34))
                        .foregroundStyle(blue)
                }
            }
            .padding(.top , 54)

            Text("Transfer Berhasil")
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.top, 9)

            Text("Saldo sudah masuk ke AstraPay-mu")
                .font(.app(.s14))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.top, 4)
        .padding(.bottom, 82)
        .frame(maxWidth: .infinity)
        .background(
            blue.clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 28,
                    bottomTrailingRadius: 28,
                    topTrailingRadius: 0
                )
            )
        )
    }

    private var amountCard: some View {
        VStack(spacing: 4) {
            Text("Nominal ditransfer")
                .font(.app(.s12))
                .foregroundStyle(greyText)

            Text(amount.rupiah)
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(darkText)
                .padding(.bottom, 7)

            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.app(.s12, weight: .semibold))
                    .foregroundStyle(blue)
                Text("Masuk ke AstraPay pribadi")
                    .font(.app(.s12))
                    .foregroundStyle(blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(blueBg))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 13, x: 0, y: 8)
        )
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "Metode",       value: "Transfer AstraPay",         hasDivider: true)
            detailRow(label: "Tujuan",       value: "\(merchantName) (AstraPay)", hasDivider: true)
            detailRow(label: "Waktu",        value: formattedDateTime,            hasDivider: true)
            detailRow(label: "ID Transaksi", value: displayId,                    hasDivider: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, hasDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.app(.s14))
                    .foregroundStyle(greyText)
                Spacer()
                Text(value)
                    .font(.app(.s14))
                    .foregroundStyle(darkText)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 13)

            if hasDivider {
                Rectangle()
                    .fill(divider)
                    .frame(height: 1)
            }
        }
    }

    private var selesaiButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.app(.s16, weight: .bold))
                Text("Selesai")
                    .font(.app(.s16, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20).fill(blue))
        }
    }

    private var footerHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.app(.s12))
                .foregroundStyle(greyText)
            Text("Saldo bisa langsung dipakai di AstraPay")
                .font(.app(.s12))
                .foregroundStyle(greyText)
        }
    }
}

#Preview {
    TransferBerhasilView(
        amount: 500_000,
        displayId: "#TR260625-0042",
        merchantName: "Bakso Pak Eko",
        date: Date()
    )
}
