//
//  TransaksiBerhasilView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI
import FirebaseFirestore

struct TransaksiBerhasilView: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction

    private let greenDark    = Color.appSuccess
    private let greenLight   = Color.appSuccessBg
    private let darkText     = Color.appTextPrimary
    private let greyText     = Color.appTextTertiary
    private let dividerColor = Color.appDivider

    private var customerName: String {
        transaction.customerName ?? "Customer"
    }

    private var formattedDateTime: String {
        guard let ts = transaction.createdAt else { return "--" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "id_ID")
        fmt.dateFormat = "d MMM yyyy · HH.mm"
        return fmt.string(from: ts.dateValue())
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

                selesaikanButton
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
        .onAppear { Haptics.success() }
    }

    private var heroSection: some View {
        VStack(spacing: 7) {
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark")
                        .font(.app(.s26, weight: .bold))
                        .foregroundStyle(greenDark)
                }
            }
            .padding(.top , 54)

            Text("Pembayaran Berhasil")
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.top, 9)

            Text("Dana sudah masuk ke saldo usahamu")
                .font(.app(.s14))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.top, 4)
        .padding(.bottom, 82)
        .frame(maxWidth: .infinity)
        .background(
            greenDark
                .clipShape(
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
            Text("Nominal diterima")
                .font(.app(.s12))
                .foregroundStyle(greyText)

            Text(transaction.amount.rupiah)
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(darkText)
                .padding(.bottom, 7)

            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.app(.s12, weight: .semibold))
                    .foregroundStyle(greenDark)
                Text("Masuk ke saldo usaha")
                    .font(.app(.s12))
                    .foregroundStyle(greenDark)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(greenLight))
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
            detailRow(label: "Metode",       value: transaction.method,    hasDivider: true)
            detailRow(label: "Dari",         value: customerName,          hasDivider: true)
            detailRow(label: "Waktu",        value: formattedDateTime,     hasDivider: true)
            detailRow(label: "ID Transaksi", value: transaction.displayId, hasDivider: false)
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
            }
            .padding(.vertical, 13)

            if hasDivider {
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)
            }
        }
    }

    private var selesaikanButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Kembali")
                .font(.app(.s16, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(greenDark)
                )
        }
    }

    private var footerHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.app(.s12))
                .foregroundStyle(greyText)
            Text("Pembayaran dari \(customerName) telah diterima")
                .font(.app(.s12))
                .foregroundStyle(greyText)
        }
    }
}
