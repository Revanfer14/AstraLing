//
//  RiwayatTransaksiView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

private struct TransaksiItem: Identifiable {
    let id = UUID()
    enum IconKind { case qris, transfer }
    let icon: IconKind
    let name: String
    let time: String
    let method: String
    let amount: String
    let isIncome: Bool
}

private struct TransaksiSection: Identifiable {
    let id = UUID()
    let dayLabel: String
    let total: String
    let items: [TransaksiItem]
}

private let sections: [TransaksiSection] = [
    TransaksiSection(
        dayLabel: "Hari ini · Selasa, 16 Mei",
        total: "+ Rp 1.245.000",
        items: [
            TransaksiItem(icon: .qris, name: "Dari Sela", time: "14.41", method: "QRIS AstraPay", amount: "+Rp 24.000", isIncome: true),
            TransaksiItem(icon: .qris, name: "Dari Rian", time: "14.20", method: "QRIS AstraPay", amount: "+Rp 35.000", isIncome: true),
            TransaksiItem(icon: .qris, name: "Dari Putri", time: "13.58", method: "QRIS Bank lain", amount: "+Rp 18.000", isIncome: true),
            TransaksiItem(icon: .transfer, name: "Transfer ke AstraPay", time: "11.30", method: "Saldo pribadi", amount: "-Rp 500.000", isIncome: false),
        ]
    ),
    TransaksiSection(
        dayLabel: "Kemarin · Senin, 15 Mei",
        total: "+ Rp 980.000",
        items: [
            TransaksiItem(icon: .qris, name: "Dari Andi", time: "19.05", method: "QRIS AstraPay", amount: "+Rp 40.000", isIncome: true),
            TransaksiItem(icon: .qris, name: "Dari Maya", time: "18.40", method: "QRIS AstraPay", amount: "+Rp 22.000", isIncome: true),
        ]
    ),
]

struct RiwayatTransaksiView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                headerSection
                    .padding(.top, 8)

                summaryCard

                ForEach(sections) { section in
                    sectionHeader(section)
                    transactionCard(section.items)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.988, green: 0.988, blue: 0.988).ignoresSafeArea())
        .navigationBarHidden(true)
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
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Riwayat Transaksi")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("Semua pemasukan & penarikan")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            }

            Spacer()

            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                        .font(.system(size: 13))
                    Text("Filter")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                )
            }
        }
        .padding(.bottom, 10)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rp 1.245.000")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("Total masuk hari ini · 42 transaksi")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            }

            Spacer()

            Text("Hari ini ▾")
                .font(.system(size: 11.5))
                .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(red: 0.929, green: 0.965, blue: 1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.08), radius: 13, x: 0, y: 8)
        )
    }

    private func sectionHeader(_ section: TransaksiSection) -> some View {
        HStack {
            Text(section.dayLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            Spacer()
            Text(section.total)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 0.459, green: 0.459, blue: 0.459))
        }
        .padding(.top, 8)
    }

    private func transactionCard(_ items: [TransaksiItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                transactionRow(item, showDivider: index < items.count - 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func transactionRow(_ item: TransaksiItem, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                transactionIcon(item)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                    Text("\(item.time) · \(item.method)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.amount)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            item.isIncome
                                ? Color(red: 0.071, green: 0.478, blue: 0.294)
                                : Color(red: 0.851, green: 0, blue: 0)
                        )
                    Text("Berhasil")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)

            if showDivider {
                Rectangle()
                    .fill(Color(red: 0.941, green: 0.941, blue: 0.941))
                    .frame(height: 1)
                    .padding(.horizontal, 15)
            }
        }
    }

    @ViewBuilder
    private func transactionIcon(_ item: TransaksiItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(
                    item.icon == .qris
                        ? Color(red: 0.906, green: 0.965, blue: 0.937)
                        : Color(red: 0.929, green: 0.965, blue: 1)
                )
                .frame(width: 44, height: 44)

            switch item.icon {
            case .qris:
                Text("QRIS")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.071, green: 0.478, blue: 0.294))
            case .transfer:
                Image(systemName: "arrow.up")
                    .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

#Preview {
    NavigationStack {
        RiwayatTransaksiView()
    }
}
