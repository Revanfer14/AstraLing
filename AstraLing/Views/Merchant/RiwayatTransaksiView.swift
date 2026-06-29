//
//  RiwayatTransaksiView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

private struct Period: Identifiable, Hashable {
    let id: Int
    let label: String
    let days: Int?
}

private let periods: [Period] = [
    Period(id: 0, label: "Hari ini", days: 0),
    Period(id: 1, label: "7 Hari",   days: 7),
    Period(id: 2, label: "30 Hari",  days: 30),
    Period(id: 3, label: "Semua",    days: nil),
]

struct RiwayatTransaksiView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var txnVM: TransactionViewModel

    @State private var selectedPeriod: Period = periods[0]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                headerSection
                    .padding(.top, 8)

                summaryCard

                let groups = txnVM.groupedTransactions(days: selectedPeriod.days)
                if groups.isEmpty {
                    emptyState
                        .padding(.top, 48)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(groups, id: \.label) { group in
                        sectionHeader(label: group.label, total: group.total)
                        transactionCard(group.items)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { txnVM.startListening() }
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
                        .font(.app(.s16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Riwayat Transaksi")
                    .font(.app(.s18))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Semua pemasukan & penarikan")
                    .font(.app(.s12))
                    .foregroundStyle(Color.appTextTertiary)
            }

            Spacer()
        }
        .padding(.bottom, 10)
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(txnVM.summaryTotal(days: selectedPeriod.days).rupiah)
                        .font(.app(.s24, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Total masuk · \(txnVM.summaryCount(days: selectedPeriod.days)) transaksi")
                        .font(.app(.s12))
                        .foregroundStyle(Color.appTextTertiary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(periods) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.label)
                            .font(.app(.s12, weight: selectedPeriod == period ? .semibold : .regular))
                            .foregroundStyle(selectedPeriod == period ? Color.white : Color.appPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPeriod == period ? Color.appPrimary : Color.appSurfaceBlue)
                            )
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appBackground)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.08), radius: 13, x: 0, y: 8)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.app(.s40))
                .foregroundStyle(Color.appTextTertiary)
            Text("Belum ada transaksi")
                .font(.app(.s16, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text("Transaksi dari pelanggan akan muncul di sini")
                .font(.app(.s14))
                .foregroundStyle(Color.appTextTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func sectionHeader(label: String, total: Int) -> some View {
        HStack {
            Text(label)
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)
            Spacer()
            Text("+ \(total.rupiah)")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.top, 8)
    }

    private func transactionCard(_ items: [Transaction]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, txn in
                transactionRow(txn, showDivider: index < items.count - 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appBackground)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func transactionRow(_ txn: Transaction, showDivider: Bool) -> some View {
        let isIncome = txn.type == .payment
        let name = isIncome
            ? "Dari \(txn.customerName ?? "Pelanggan")"
            : "Transfer ke AstraPay"
        let amountStr = isIncome
            ? "+\(txn.amount.rupiah)"
            : "-\(txn.amount.rupiah)"

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                transactionIcon(isIncome: isIncome)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.app(.s14, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("\(TransactionViewModel.timeString(txn.createdAt)) · \(txn.method)")
                        .font(.app(.s12))
                        .foregroundStyle(Color.appTextTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(amountStr)
                        .font(.app(.s16, weight: .bold))
                        .foregroundStyle(
                            isIncome
                                ? Color.appSuccess
                                : Color(red: 0.851, green: 0, blue: 0)
                        )
                    Text(txn.status == .success ? "Berhasil" : "Gagal")
                        .font(.app(.s12))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)

            if showDivider {
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 15)
            }
        }
    }

    @ViewBuilder
    private func transactionIcon(isIncome: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(isIncome ? Color.appSuccessBg : Color.appSurfaceBlue)
                .frame(width: 44, height: 44)

            if isIncome {
                Text("QRIS")
                    .font(.app(.s12))
                    .foregroundStyle(Color.appSuccess)
            } else {
                Image(systemName: "arrow.up")
                    .foregroundStyle(Color.appPrimary)
                    .font(.app(.s16, weight: .semibold))
            }
        }
    }
}

#Preview {
    NavigationStack {
        RiwayatTransaksiView()
            .environmentObject(TransactionViewModel())
    }
}
