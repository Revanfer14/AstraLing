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

    private let balance: Int = 0
    private let astraPoints: Int = 0

    private let menuItems: [MenuTileItem] = [
        MenuTileItem(title: "AstraLing",          imageName: "menu-astraling"),
        MenuTileItem(title: "Pulsa & Paket Data",  imageName: "menu-pulsa",           badge: "Promo"),
        MenuTileItem(title: "PLN",                 imageName: "menu-pln",             badge: "Promo"),
        MenuTileItem(title: "Uang Elektronik",     imageName: "menu-uang-elektronik"),
        MenuTileItem(title: "Travel & Hiburan",    imageName: "menu-travel"),
        MenuTileItem(title: "Gift Voucher",        imageName: "menu-gift-voucher",    badge: "Baru", badgeColor: Color(red: 0.53, green: 0.18, blue: 1.0)),
        MenuTileItem(title: "FIFGROUP",            imageName: "menu-fifgroup",        badge: "Murah"),
        MenuTileItem(title: "Lihat Semua",         imageName: "menu-lihat-semua"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CustomerHomeHeader()

                    VStack(spacing: 12) {
                        CustomerBalanceCard(
                            balance: balance,
                            astraPoints: astraPoints,
                            onAstraPoints: openAstraPoints
                        )
                        .padding(.top, -36)

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
                    .padding(.bottom, 70)
            }

            CustomerTabBar(onProfil: {
                authViewModel.logout()
                selectedRoleRaw = ""
            })
        }
        .ignoresSafeArea(edges: .top)
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
