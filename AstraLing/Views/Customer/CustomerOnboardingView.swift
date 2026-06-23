//
//  CustomerOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct CustomerOnboardingView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var homeVM = CustomerHomeViewModel()

    private let menuItems: [MenuTileItem] = [
        MenuTileItem(title: "AstraLing",          assetName: "astraling_logo"),
        MenuTileItem(title: "Pulsa & Paket Data",  assetName: "pulsapaketdata",  badged: true),
        MenuTileItem(title: "PLN",                 assetName: "pln",             badged: true),
        MenuTileItem(title: "Uang Elektronik",     assetName: "uangelektronik"),
        MenuTileItem(title: "Travel & Hiburan",    assetName: "travelhiburan"),
        MenuTileItem(title: "Gift Voucher",        assetName: "giftvoucher",     badged: true),
        MenuTileItem(title: "FIFGROUP",            assetName: "fifgroup",        badged: true),
        MenuTileItem(title: "Lihat Semua",         assetName: "lihatsemua"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CustomerHomeHeader(name: homeVM.name)

                    VStack(spacing: 12) {
                        CustomerBalanceCard(
                            balance: homeVM.balance,
                            astraPoints: homeVM.astraPoints,
                            onAstraPoints: openAstraPoints
                        )
                        .padding(.top, -20)

                        CustomerPromoBanner()

                        CustomerMenuGrid(items: menuItems, onAstraLing: openAstraLing)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 120)
                }
            }

            VStack(spacing: 0) {
                Spacer()
                CustomerQRISButton()
                    .padding(.bottom, 44)
            }

            CustomerTabBar(onProfil: {
                authViewModel.logout()
                selectedRoleRaw = ""
            })
        }
        .ignoresSafeArea(edges: .top)
        .task { await homeVM.load() }
    }

    private func openAstraLing() {
    }

    private func openAstraPoints() {
    }
}

#Preview {
    CustomerOnboardingView()
        .environmentObject(AuthViewModel())
}
