//
//  CustomerHistoryView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import SwiftUI

struct CustomerHistoryView: View {
    @StateObject private var vm = CustomerHistoryViewModel()
    @State private var selectedFilter = "AstraPay"

    private let filterOptions = ["AstraPay", "AstraPoints", "Bisnis", "Bank lain"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Riwayat Transaksi")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                Divider()

                filterChipsRow
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if vm.sections.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(vm.sections) { section in
                        sectionBlock(section)
                    }
                }

                Spacer(minLength: 120)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await vm.load() }
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterIconChip
                ForEach(filterOptions, id: \.self) { option in
                    filterTextChip(option)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var filterIconChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
            Text("Filter")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
    }

    private func filterTextChip(_ title: String) -> some View {
        let isSelected = title == selectedFilter
        return Text(title)
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .appPrimary : .appTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appSurfaceBlue : Color.clear)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.appPrimary : Color.appBorder, lineWidth: 1))
            .onTapGesture { selectedFilter = title }
    }

    private func sectionBlock(_ section: HistorySection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.dayLabel)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.offset) { index, txn in
                    transactionRow(txn)
                    if index < section.items.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func transactionRow(_ txn: Transaction) -> some View {
        let title = vm.merchantNames[txn.merchantUid] ?? "Pembayaran QRIS"
        let isCredit = txn.type == .transfer
        let amountString = isCredit ? txn.amount.rupiah : "-\(txn.amount.rupiah)"
        let amountColor: Color = isCredit ? .appSuccess : .appError

        HStack(spacing: 12) {
            transactionIcon(isCredit: isCredit)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("Pembayaran QRIS")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountString)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(amountColor)
                HStack(spacing: 4) {
                    Image("astrapay_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                    Text("AstraPay")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func transactionIcon(isCredit: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurfaceMuted)
                .frame(width: 44, height: 44)
            Image(systemName: isCredit ? "plus.circle" : "qrcode.viewfinder")
                .font(.system(size: 20))
                .foregroundColor(.appTextSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.appTextTertiary)
            Text("Belum ada transaksi")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

#Preview {
    CustomerHistoryView()
}
