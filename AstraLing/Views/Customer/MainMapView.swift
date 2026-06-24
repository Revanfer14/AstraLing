//
//  MainMapView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI
import MapKit

struct MainMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationService()
    @StateObject private var vm = MainMapViewModel()

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.21, longitude: 106.84),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @Namespace private var pickerAnimation
    @State private var selectedTab = 0
    @State private var hideBalance = false
    @State private var hasCenteredOnUser = false
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var sheetDetent: PresentationDetent = .height(360)
    @State private var selectedMerchant: NearbyMerchant?
    @State private var showScanner = false
    @State private var showPingSuccess = false
    @State private var showActivePings = false
    @State private var showCancelPing = false

    private let minSheetHeight: CGFloat = 85

    private var activePingMerchant: NearbyMerchant? {
        guard let selected = selectedMerchant,
              vm.activePing(for: selected.id) != nil else { return nil }
        return selected
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                UserAnnotation()
                merchantAnnotations
                routeOverlays
            }
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.region.center
            }
            .sheet(isPresented: .constant(true)) {
                sheetContent
                    .presentationDetents(
                        {
                            let hasChat = selectedMerchant.map { vm.activePing(for: $0.id) != nil } ?? false
                            if selectedMerchant == nil || hasChat {
                                return [.height(minSheetHeight), .height(360), .large]
                            }
                            return [.height(360), .large]
                        }(),
                        selection: $sheetDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
                    .interactiveDismissDisabled()
                    .presentationCornerRadius(26)
                    .presentationBackground(Color.appSurface)
                    .fullScreenCover(isPresented: $showScanner) {
                        QRScannerView()
                    }
                    .fullScreenCover(isPresented: $showPingSuccess) {
                        PingSuccessDialog(
                            onMonitor: {
                                showPingSuccess = false
                                sheetDetent = .height(minSheetHeight)
                            },
                            onCancel: {
                                vm.cancelPing()
                                showPingSuccess = false
                                selectedMerchant = nil
                            }
                        )
                        .presentationBackground(.clear)
                    }
                    .fullScreenCover(isPresented: $showCancelPing) {
                        CancelPingDialog(
                            onCancelPing: {
                                if let s = selectedMerchant, let a = vm.activePing(for: s.id) {
                                    vm.cancelPing(pingId: a.id)
                                }
                                showCancelPing = false
                                selectedMerchant = nil
                                sheetDetent = .height(minSheetHeight)
                            },
                            onContinue: { showCancelPing = false }
                        )
                        .presentationBackground(.clear)
                    }
                    .sheet(isPresented: $showActivePings) {
                        ActivePingsSheet(pings: vm.activePings) { pingId in
                            vm.cancelPing(pingId: pingId)
                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(26)
                        .presentationBackground(Color.appSurface)
                    }
            }

            topBar
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottomTrailing) {
            if isFarFromUser {
                Button {
                    recenterOnUser()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .frame(width: 46, height: 46)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, minSheetHeight + 16)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 12) {
                if !vm.activePings.isEmpty {
                    Button {
                        showActivePings = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "hand.rays.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.appPrimary)
                                .frame(width: 46, height: 46)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.1), radius: 6, y: 4)

                            Text("\(vm.activePings.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.appPrimary)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                #if DEBUG
                Button {
                    vm.scatterMerchantsAroundMe()
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .frame(width: 46, height: 46)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
                }
                #endif
            }
            .padding(.leading, 24)
            .padding(.bottom, minSheetHeight + 16)
        }
        .animation(.easeInOut(duration: 0.2), value: isFarFromUser)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.activePings.count)
        .onAppear {
            location.requestWhenInUse()
            vm.start()
        }
        .onChange(of: location.current) { _, newLoc in
            vm.setUserLocation(newLoc)
            guard let newLoc, !hasCenteredOnUser else { return }
            hasCenteredOnUser = true
            withAnimation {
                camera = .region(MKCoordinateRegion(
                    center: newLoc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
        .onDisappear { vm.stop() }
    }

    private var isFarFromUser: Bool {
        guard let center = mapCenter, let user = location.current else { return false }
        return CLLocation(latitude: center.latitude, longitude: center.longitude)
            .distance(from: user) > 250
    }

    @MapContentBuilder
    private var merchantAnnotations: some MapContent {
        ForEach(vm.merchants) { merchant in
            Annotation("", coordinate: merchant.coordinate) {
                pinContent(
                    for: merchant,
                    isActivePing: activePingMerchant?.id == merchant.id,
                    isSelected: selectedMerchant?.id == merchant.id
                )
            }
        }
    }

    @MapContentBuilder
    private var routeOverlays: some MapContent {
        ForEach(Array(vm.routes.keys), id: \.self) { uid in
            if let coords = vm.routes[uid], coords.count >= 2 {
                MapPolyline(coordinates: coords)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
    }

    @ViewBuilder
    private func pinContent(for merchant: NearbyMerchant, isActivePing: Bool, isSelected: Bool) -> some View {
        ZStack(alignment: .bottom) {
            if isActivePing {
                MerchantMapBanner(name: merchant.name, bannerUrl: merchant.bannerUrl)
                    .offset(y: -58)
                    .allowsHitTesting(false)
            }
            MerchantMapPin(
                name: merchant.name,
                bannerUrl: merchant.bannerUrl,
                isSelected: isSelected,
                showName: !isActivePing
            )
            .onTapGesture {
                selectedMerchant = merchant
                sheetDetent = .height(360)
                focus(on: merchant)
            }
        }
    }

    private func recenterOnUser() {
        guard let user = location.current else { return }
        withAnimation {
            camera = .region(MKCoordinateRegion(
                center: user.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private func focus(on merchant: NearbyMerchant) {
        let offset = CLLocationCoordinate2D(
            latitude: merchant.coordinate.latitude - 0.004,
            longitude: merchant.coordinate.longitude
        )
        withAnimation {
            camera = .region(MKCoordinateRegion(
                center: offset,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Saldo AstraPay kamu")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextTertiary)
                        Button {
                            hideBalance.toggle()
                        } label: {
                            Image(systemName: hideBalance ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextTertiary)
                        }
                    }
                    Text(hideBalance ? "Rp ••••••" : vm.balance.rupiah)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }

                Spacer()

                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.appTextOnPrimary)
                        .frame(width: 46, height: 46)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding(14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 74)
    }

    @ViewBuilder
    private var sheetContent: some View {
        if let selected = selectedMerchant {
            if let active = vm.activePing(for: selected.id) {
                PingChatSheet(
                    merchant: selected,
                    status: active.status,
                    isFavorite: vm.isFavorite(selected.id),
                    isMinimized: sheetDetent == .height(minSheetHeight),
                    onBack: {
                        selectedMerchant = nil
                        sheetDetent = .height(360)
                    },
                    onToggleFavorite: { vm.toggleFavorite(selected.id) },
                    onRequestCancel: { showCancelPing = true }
                )
            } else {
                MerchantDetailSheet(
                    merchant: selected,
                    isFavorite: vm.isFavorite(selected.id),
                    onBack: {
                        selectedMerchant = nil
                        sheetDetent = .height(360)
                    },
                    onToggleFavorite: {
                        vm.toggleFavorite(selected.id)
                    },
                    onPing: {
                        vm.sendPing(to: selected)
                        showPingSuccess = true
                    }
                )
            }
        } else {
            listContent
        }
    }

    private var listContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Jajanan di sekitarmu")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .padding(.top, 15)

                if !vm.activePings.isEmpty {
                    Text("Kamu punya \(vm.activePings.count) Ping aktif")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextTertiary)
                }
            }

            if sheetDetent != .height(minSheetHeight) {
                let tabs: [String] = vm.activePings.isEmpty
                    ? ["Semua", "Favorit"]
                    : ["Ping Aktif", "Semua", "Favorit"]

                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Text(tabs[index])
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedTab == index ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    if selectedTab == index {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.appPrimary)
                                            .matchedGeometryEffect(id: "activeTab", in: pickerAnimation)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.5)) {
                                    selectedTab = index
                                }
                            }
                    }
                }
                .padding(4)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(20)
                .onChange(of: vm.activePings.count) { _, _ in
                    let newTabs: [String] = vm.activePings.isEmpty
                        ? ["Semua", "Favorit"]
                        : ["Ping Aktif", "Semua", "Favorit"]
                    if selectedTab >= newTabs.count {
                        selectedTab = 0
                    }
                    if !vm.activePings.isEmpty && selectedTab == 0 {
                        selectedTab = 0
                    }
                }

                let activeLabel = tabs[selectedTab]

                if activeLabel == "Ping Aktif" {
                    let pingCards = vm.activePings.compactMap { ping -> (ActivePing, NearbyMerchant)? in
                        guard let merchant = vm.pingedMerchant(for: ping) else { return nil }
                        return (ping, merchant)
                    }
                    if pingCards.isEmpty {
                        Spacer()
                        Text("Belum ada ping aktif")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextTertiary)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(pingCards, id: \.0.id) { ping, merchant in
                                    ActivePingCard(merchant: merchant, status: ping.status)
                                        .onTapGesture {
                                            selectedMerchant = merchant
                                            sheetDetent = .height(360)
                                            focus(on: merchant)
                                        }
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                } else {
                    let displayed = activeLabel == "Favorit"
                        ? vm.merchants.filter(\.isFavorite)
                        : vm.merchants

                    if displayed.isEmpty {
                        Spacer()
                        Text(activeLabel == "Favorit" ? "Belum ada pedagang favorit" : "Belum ada pedagang di sekitarmu")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextTertiary)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(displayed) { merchant in
                                    NearbyMerchantCard(merchant: merchant)
                                        .onTapGesture {
                                            selectedMerchant = merchant
                                            sheetDetent = .height(360)
                                            focus(on: merchant)
                                        }
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    MainMapView()
}
