//
//  MerchantDashboardView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct MerchantDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var merchantVM: MerchantViewModel
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @StateObject private var txnVM = TransactionViewModel()
    @State private var selectedPeriod = "7 hari terakhir"
    private let periods = ["7 hari terakhir", "30 hari terakhir"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 16)

                balanceCard
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                Text("Ringkasan Usaha Hari Ini")
                    .font(.app(.s18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                summaryGrid
                    .padding(.top, 12)
                    .padding(.horizontal, 16)

                HStack {
                    Text("Rekap Usaha")
                        .font(.app(.s18, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    Menu {
                        ForEach(periods, id: \.self) { period in
                            Button(period) { selectedPeriod = period }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedPeriod)
                                .font(.app(.s12))
                                .foregroundStyle(Color.appPrimary)
                            Image(systemName: "chevron.down")
                                .font(.app(.s12, weight: .semibold))
                                .foregroundStyle(Color.appPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appSurfaceBlue)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                rekapCard
                    .padding(.top, 12)
                    .padding(.horizontal, 16)

                Button {
                    Haptics.warning()
                    Task {
                        await merchantVM.setVisible(false)
                        authViewModel.logout()
                        selectedRoleRaw = ""
                    }
                } label: {
                    Text("Keluar Akun")
                        .font(.app(.s16, weight: .bold))
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { txnVM.startListening() }
        .onDisappear { txnVM.stopListening() }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appTextPrimary)
                        .font(.app(.s16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Dashboard Usaha")
                    .font(.app(.s18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(merchantVM.merchant?.name ?? "Memuat...")
                    .font(.app(.s12))
                    .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
            }
        }
        .padding(.horizontal, 16)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Total Saldo")
                .font(.app(.s12))
                .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))

            Text((merchantVM.merchant?.balance ?? 0).rupiah)
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.top, 2)

            Text("▲ Hari ini · \(txnVM.todayCount) transaksi")
                .font(.app(.s12))
                .foregroundStyle(Color.appSuccess)
                .padding(.bottom, 12)

            NavigationLink(destination: RiwayatTransaksiView().navigationBarBackButtonHidden(true).environmentObject(txnVM)) {
                HStack(spacing: 11) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appPrimary)
                            .frame(width: 34, height: 34)
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.white)
                            .font(.app(.s14))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Lihat Riwayat Transaksi")
                            .font(.app(.s14, weight: .bold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Semua pemasukan & penarikan")
                            .font(.app(.s12))
                            .foregroundStyle(Color.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
                        .font(.app(.s14))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appSurfaceBlue)
                )
            }

            HStack(spacing: 10) {
                NavigationLink(destination: TransferSaldoView().navigationBarBackButtonHidden(true).environmentObject(merchantVM)) {
                    quickActionItem(icon: "arrow.up", label: "Transfer Saldo")
                }
                NavigationLink(destination: QRSayaView().navigationBarBackButtonHidden(true).environmentObject(merchantVM)) {
                    quickActionItem(icon: "qrcode", label: "QR Saya")
                }
            }
            .padding(.top, 11)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.08), radius: 13, x: 0, y: 8)
        )
    }

    private func quickActionItem(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSurfaceBlue)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(Color.appPrimary)
                    .font(.app(.s16))
            }
            Text(label)
                .font(.app(.s12))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            statCard(
                icon: "banknote.fill",
                value: "\(txnVM.todayCount)",
                label: "Transaksi",
                change: "Hari ini",
                changeColor: Color(red: 0.098, green: 0.702, blue: 0.42)
            )
            statCard(
                icon: "chart.line.uptrend.xyaxis",
                value: txnVM.todayTotal.rupiah,
                label: "Omzet",
                change: "Hari ini",
                changeColor: Color(red: 0.098, green: 0.702, blue: 0.42)
            )
            statCard(
                icon: "person.2.fill",
                value: "\(txnVM.uniqueCustomersTodayCount)",
                label: "Pelanggan",
                change: "Hari ini",
                changeColor: Color(red: 0.098, green: 0.702, blue: 0.42)
            )
            statCard(
                icon: "chart.bar.xaxis.ascending",
                value: txnVM.avgTransactionToday.rupiah,
                label: "Rata-rata /transaksi",
                change: "Hari ini",
                changeColor: Color(red: 0.098, green: 0.702, blue: 0.42)
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, change: String, changeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.appSurfaceBlue)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundStyle(Color.appPrimary)
                    .font(.app(.s16))
            }

            Text(value)
                .font(.app(.s18, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.top, 10)

            Text(label)
                .font(.app(.s12))
                .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))

            Text(change)
                .font(.app(.s12))
                .foregroundStyle(changeColor)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var rekapCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Jam Tersibuk")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)

            Text("Pukul 16.00 – 19.00")
                .font(.app(.s18, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.bottom, 11)

            divider

            Text("Area Terbanyak Transaksi")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)
                .padding(.top, 11)

            areaBar(
                name: "Perumahan Griya",
                fraction: 0.65,
                percent: "65%",
                nameColor: Color.appTextPrimary,
                barColor: Color.appPrimary,
                percentColor: Color.appPrimary
            )
            .padding(.top, 8)

            areaBar(
                name: "Jl. Melati Raya",
                fraction: 0.20,
                percent: "20%",
                nameColor: Color.appTextTertiary,
                barColor: Color.Token.blue300,
                percentColor: Color.appTextTertiary
            )
            .padding(.top, 8)

            areaBar(
                name: "Cluster Bougenville",
                fraction: 0.15,
                percent: "15%",
                nameColor: Color.appTextTertiary,
                barColor: Color.Token.blue300,
                percentColor: Color.appTextTertiary
            )
            .padding(.top, 8)
            .padding(.bottom, 12)

            (
                Text("Selasa, jam 4 sore")
                    .foregroundStyle(Color.appPrimary)
                + Text(" area Perumahan Griya selalu ramai, coba pertimbangkan lewat sana.")
                    .foregroundStyle(Color.appTextSecondary)
            )
            .font(.app(.s14))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appSurfaceBlue)
            )

            divider.padding(.top, 16)

            Text("Pelanggan bulan ini")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)
                .padding(.top, 16)

            HStack(spacing: 12) {
                customerBox(
                    number: "47",
                    label: "Pelanggan Baru",
                    bgColor: Color.appSurfaceBlue,
                    numberColor: Color.appPrimary
                )
                customerBox(
                    number: "83",
                    label: "Pelanggan Setia",
                    bgColor: Color.appSuccessBg,
                    numberColor: Color.appSuccess
                )
            }
            .padding(.top, 8)
        }
        .padding(17)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appBackground)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.08), radius: 26, x: 0, y: 8)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: 1)
    }

    private func areaBar(name: String, fraction: CGFloat, percent: String, nameColor: Color, barColor: Color, percentColor: Color) -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.app(.s14))
                .foregroundStyle(nameColor)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.appDivider)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(barColor)
                        .frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)

            Text(percent)
                .font(.app(.s14))
                .foregroundStyle(percentColor)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func customerBox(number: String, label: String, bgColor: Color, numberColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(number)
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(numberColor)
            Text(label)
                .font(.app(.s12))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(bgColor)
        )
    }
}

#Preview {
    MerchantDashboardView()
}
