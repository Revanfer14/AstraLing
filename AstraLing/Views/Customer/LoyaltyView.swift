//
//  LoyaltyView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct LoyaltyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LoyaltyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroCard
                    historySection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .background(Color.Token.blue25.ignoresSafeArea())
        .task { await vm.load() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.appSurface)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            }
            Spacer()
            Text("AstraPoints")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color.Token.blue25.ignoresSafeArea(edges: .top))
    }

    private var heroCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Total poin kamu")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                Text("\(vm.astraPoints)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)
                Text("poin")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            Text("⭐️")
                .font(.system(size: 52))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.Token.gradBlueTop, Color.Token.gradBlueBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.Token.gradBlueBottom.opacity(0.3), radius: 12, y: 6)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riwayat Poin")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appTextPrimary)

            if vm.history.isEmpty {
                Text("Belum ada riwayat transaksi")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(vm.history) { entry in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.appSurfaceBlue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16))
                                    .foregroundColor(.appPrimary)
                            )
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pembayaran QRIS")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            Text(formattedDate(entry.date))
                                .font(.system(size: 12))
                                .foregroundColor(.appTextTertiary)
                        }
                        Spacer()
                        Text("+\(entry.pointsEarned) poin")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(14)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "dd MMM yyyy, HH.mm"
        return f.string(from: date)
    }
}

#Preview {
    LoyaltyView()
}
