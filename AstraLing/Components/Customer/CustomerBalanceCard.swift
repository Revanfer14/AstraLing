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
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image("logo-astrapay")
                            .resizable().scaledToFit()
                            .frame(width: 20, height: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text("Saldo")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                Image("ic-eye")
                                    .resizable().scaledToFit()
                                    .frame(width: 16, height: 12)
                            }
                            Text(balance.rupiah)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(UIColor.label))
                        }
                    }

                    Spacer()

                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(width: 1, height: 45)

                    BalanceActionButton(imageName: "ic-topup", label: "Top Up")
                    BalanceActionButton(imageName: "ic-transfer", label: "Transfer")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            Divider().padding(.horizontal, 12).padding(.top, 8)

            HStack(spacing: 0) {
                Button(action: onAstraPoints) {
                    BalanceSubCard(
                        iconName: "ic-astrapoints",
                        label: "AstraPoints",
                        value: "\(astraPoints)",
                        badge: "Untung!",
                        badgeColor: Color(red: 0.53, green: 0.18, blue: 1.0)
                    )
                }
                .buttonStyle(.plain)

                Divider().frame(width: 1).padding(.vertical, 8)

                BalanceSubCard(iconName: "ic-voucher", label: "Voucher Saya", value: "0")

                Divider().frame(width: 1).padding(.vertical, 8)

                VStack(spacing: 2) {
                    Image("ic-bank")
                        .resizable().scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("Bank S...")
                        .font(.system(size: 9))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("Aktifkan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.38, green: 0.52, blue: 0.84))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct BalanceActionButton: View {
    let imageName: String
    let label: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

private struct BalanceSubCard: View {
    let iconName: String
    let label: String
    let value: String
    var badge: String? = nil
    var badgeColor: Color = .red

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(iconName)
                    .resizable().scaledToFit()
                    .frame(width: 14, height: 14)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                if let badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .clipShape(Capsule())
                }
            }
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.label))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}
