//
//  AstraPayHomeView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct AstraPayHomeView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @AppStorage("hasSeenAstraLingOnboarding") private var hasSeenAstraLingOnboarding = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var homeVM = CustomerHomeViewModel()
    @State private var showAstraLing = false
    @State private var showMainMap = false
    @State private var showAstraPoints = false
    @State private var openMapAfterOnboarding = false
    @State private var selectedTab: CustomerTab = .beranda

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
            Color.appBackground.ignoresSafeArea()

            if selectedTab == .riwayat {
                CustomerHistoryView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        CustomerHomeHeader(name: homeVM.name)

                        VStack(spacing: 12) {
                            CustomerBalanceCard(
                                balance: homeVM.balance,
                                astraPoints: homeVM.astraPoints,
                                onAstraPoints: openAstraPoints,
                                onTopUp: { Task { await homeVM.topUp(); Haptics.success() } }
                            )
                            .padding(.top, -20)

                            CustomerPromoBanner()

                            CustomerMenuGrid(items: menuItems, onAstraLing: openAstraLing)
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 120)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }

            VStack(spacing: 0) {
                Spacer()
                CustomerQRISButton()
                    .padding(.bottom, 44)
            }

            CustomerTabBar(selection: $selectedTab, onProfil: {
                Haptics.warning()
                authViewModel.logout()
                selectedRoleRaw = ""
            })
        }
        .onAppear { homeVM.load() }
        .fullScreenCover(isPresented: $showAstraLing, onDismiss: {
            if openMapAfterOnboarding {
                openMapAfterOnboarding = false
                showMainMap = true
            }
        }) {
            CustomerOnboardingView(onStart: {
                openMapAfterOnboarding = true
                showAstraLing = false
            })
        }
        .fullScreenCover(isPresented: $showMainMap) { MainMapView() }
        .fullScreenCover(isPresented: $showAstraPoints) { AstraPointsView() }
    }

    private func openAstraLing() {
        if hasSeenAstraLingOnboarding {
            showMainMap = true
        } else {
            showAstraLing = true
        }
    }

    private func openAstraPoints() {
        showAstraPoints = true
    }
}

#Preview {
    AstraPayHomeView()
        .environmentObject(AuthViewModel())
}
