//
//  LoyaltyView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

private enum AstraPointsTab { case beli, saya }

private struct Voucher: Identifiable {
    let id = UUID()
    let brand: String
    let symbol: String
    let color: Color
    let title: String
    let cost: Int
    let originalCost: Int
}

private let mockVouchers: [Voucher] = [
    Voucher(brand: "AstraPay", symbol: "creditcard.fill", color: Color(hex: "#1A3FCB"),
            title: "Cashback 10% Transaksi AstraPay", cost: 1, originalCost: 5000),
    Voucher(brand: "FIFGROUP", symbol: "car.fill", color: Color(hex: "#E63946"),
            title: "Cicilan 0% Motor FIFGROUP", cost: 2, originalCost: 8000),
    Voucher(brand: "Kuliner PKL", symbol: "fork.knife", color: Color(hex: "#F4A261"),
            title: "Diskon 15% Kuliner Pedagang Keliling", cost: 1, originalCost: 5000),
    Voucher(brand: "Pulsa", symbol: "antenna.radiowaves.left.and.right", color: Color(hex: "#2A9D8F"),
            title: "Bonus Pulsa 5.000 Semua Operator", cost: 1, originalCost: 3000),
    Voucher(brand: "Kopi Nusantara", symbol: "cup.and.saucer.fill", color: Color(hex: "#6B4226"),
            title: "Gratis 1 Kopi Susu Kopi Nusantara", cost: 3, originalCost: 10000),
    Voucher(brand: "Belanja", symbol: "bag.fill", color: Color(hex: "#7B2D8B"),
            title: "Voucher Belanja Rp 20.000 di Mitra AstraPay", cost: 2, originalCost: 6000),
]

struct AstraPointsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AstraPointsViewModel()
    @State private var tab: AstraPointsTab = .beli

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroCard
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    tabControl
                    filterChips
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if tab == .beli {
                        voucherList
                    } else {
                        emptyVoucherSaya
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await vm.load() }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 44, height: 44)
            }
            Text("AstraPoints")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 56)
        .background(Color.appBackground)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image("astrapoints_logo")
                        .resizable().scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("AstraPoints")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .clipShape(Capsule())

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Cara Pakai Poin")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
            }

            Spacer().frame(height: 16)

            Text("\(vm.astraPoints) Poin")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("0 poin kedaluwarsa di 01 Jul 2026")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 4)

            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack {
                Text("Riwayat Poin")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.Token.gradBlueTop, Color.Token.gradBlueBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.Token.gradBlueBottom.opacity(0.35), radius: 14, y: 6)
    }

    private var tabControl: some View {
        HStack(spacing: 0) {
            tabButton("Beli Voucher", tab: .beli)
            tabButton("Voucher Saya", tab: .saya)
        }
        .background(Color.appBackground)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func tabButton(_ label: String, tab: AstraPointsTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { self.tab = tab }
        } label: {
            VStack(spacing: 0) {
                Text(label)
                    .font(.system(size: 14, weight: self.tab == tab ? .semibold : .regular))
                    .foregroundColor(self.tab == tab ? .appPrimary : .appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                Rectangle()
                    .fill(self.tab == tab ? Color.appPrimary : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Filter", systemName: "slider.horizontal.3", active: false)
                filterChip(label: "Semua", active: true)
                filterChip(label: "Voucher Bisa Dibeli", active: false)
                filterChip(label: "Promo", active: false)
                filterChip(label: "Terbaru", active: false)
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(label: String, systemName: String? = nil, active: Bool) -> some View {
        HStack(spacing: 4) {
            if let sys = systemName {
                Image(systemName: sys)
                    .font(.system(size: 11))
            }
            Text(label)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
        }
        .foregroundColor(active ? .appPrimary : .appTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(active ? Color.appSurfaceBlue : Color.appSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(active ? Color.appPrimary.opacity(0.4) : Color.appDivider, lineWidth: 1)
        )
    }

    private var voucherList: some View {
        LazyVStack(spacing: 12) {
            ForEach(mockVouchers) { v in
                VoucherCard(voucher: v)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var emptyVoucherSaya: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 40))
                .foregroundColor(.appTextTertiary)
            Text("Kamu belum punya voucher")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Text("Tukar poin kamu dengan voucher menarik\ndi tab Beli Voucher.")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct VoucherCard: View {
    let voucher: Voucher

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(voucher.color)
                    .frame(width: 64, height: 64)
                VStack(spacing: 4) {
                    Image(systemName: voucher.symbol)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                    Text(voucher.brand)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 52)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(voucher.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Image("astrapoints_logo")
                        .resizable().scaledToFit()
                        .frame(width: 13, height: 13)
                    Text("\(voucher.cost) Poin")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }

                Text("\(voucher.originalCost.formattedPoints) Poin")
                    .font(.system(size: 11))
                    .foregroundColor(.appTextTertiary)
                    .strikethrough(true, color: .appTextTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

private extension Int {
    var formattedPoints: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview {
    AstraPointsView()
}
