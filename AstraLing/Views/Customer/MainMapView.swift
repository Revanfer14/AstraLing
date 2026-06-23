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

    private let minSheetHeight: CGFloat = 85

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                UserAnnotation()
                ForEach(vm.merchants) { merchant in
                    Annotation(merchant.name, coordinate: merchant.coordinate) {
                        MerchantMapPin(name: merchant.name, isSelected: selectedMerchant?.id == merchant.id)
                            .onTapGesture {
                                selectedMerchant = merchant
                                sheetDetent = .height(360)
                                focus(on: merchant)
                            }
                    }
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.region.center
            }
            .sheet(isPresented: .constant(true)) {
                sheetContent
                    .presentationDetents(
                        selectedMerchant != nil
                            ? [.height(360), .large]
                            : [.height(minSheetHeight), .height(360), .large],
                        selection: $sheetDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
                    .interactiveDismissDisabled()
                    .presentationCornerRadius(26)
                    .presentationBackground(Color.appSurface)
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
        .animation(.easeInOut(duration: 0.2), value: isFarFromUser)
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
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
            .padding(.leading, 24)
            .padding(.bottom, minSheetHeight + 16)
        }
        #endif
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

                Button {} label: {
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
            MerchantDetailSheet(
                merchant: selected,
                isFavorite: vm.isFavorite(selected.id),
                onBack: {
                    selectedMerchant = nil
                    sheetDetent = .height(360)
                },
                onToggleFavorite: {
                    vm.toggleFavorite(selected.id)
                }
            )
        } else {
            listContent
        }
    }

    private var listContent: some View {
        VStack(spacing: 16) {
            Text("Jajanan di sekitarmu")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .padding(.top, 15)

            if sheetDetent != .height(minSheetHeight) {
                HStack(spacing: 0) {
                    let tabs = ["Semua", "Favorit"]
                    ForEach(0..<2, id: \.self) { index in
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

                let displayed = selectedTab == 0 ? vm.merchants : vm.merchants.filter(\.isFavorite)

                if displayed.isEmpty {
                    Spacer()
                    Text(selectedTab == 1 ? "Belum ada pedagang favorit" : "Belum ada pedagang di sekitarmu")
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
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    MainMapView()
}
