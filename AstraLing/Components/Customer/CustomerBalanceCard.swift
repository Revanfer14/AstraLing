//
//  CustomerBalanceCard.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerBalanceCard: View {
    let balance: Int
    let astraPoints: Int
    let onAstraPoints: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Image("astrapay_logo")
                    .resizable().scaledToFit()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Saldo")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextSecondary)
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    Text(balance.rupiah)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                }

                Spacer()

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: 1, height: 44)

                BalanceActionButton(systemName: "plus", label: "Top Up", tint: .Token.gradBlueTop)
                BalanceActionButton(systemName: "arrow.up.right", label: "Transfer", tint: .Token.gradBlueTop)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 12)

            HStack(spacing: 10) {
                Button(action: onAstraPoints) {
                    PointsBox(
                        iconName: "astrapoints_logo",
                        label: "AstraPoints",
                        value: "\(astraPoints)",
                        badge: "Untung!",
                        badgeColor: Color.Token.pointsBadge
                    )
                }
                .buttonStyle(.plain)

                PointsBox(
                    iconName: "voucher_logo",
                    label: "Voucher Saya",
                    value: "0"
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct BalanceActionButton: View {
    let systemName: String
    let label: String
    let tint: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint)
                        .frame(width: 30, height: 30)
                    Image(systemName: systemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

private struct PointsBox: View {
    let iconName: String
    let label: String
    let value: String
    var badge: String? = nil
    var badgeColor: Color = .red

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(iconName)
                    .resizable().scaledToFit()
                    .frame(width: 14, height: 14)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Color.appTextSecondary)
                if let badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color.appTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }
}
