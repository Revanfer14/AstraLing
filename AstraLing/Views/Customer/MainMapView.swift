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
    @State private var selectedTab = 0
    @State private var hideBalance = false
    @State private var hasCenteredOnUser = false
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var sheetDetent: PresentationDetent = .height(360)

    private let blue = Color(red: 0/255, green: 69/255, blue: 229/255)
    private let minSheetHeight: CGFloat = 96

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                UserAnnotation()
                ForEach(vm.merchants) { merchant in
                    Annotation(merchant.name, coordinate: merchant.coordinate) {
                        MerchantMapPin(name: merchant.name)
                    }
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.region.center
            }
            .sheet(isPresented: .constant(true)) {
                sheetContent
                    .presentationDetents([.height(minSheetHeight), .height(360), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
                    .interactiveDismissDisabled()
                    .presentationCornerRadius(26)
                    .presentationBackground(.white)
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
                        .foregroundColor(blue)
                        .frame(width: 46, height: 46)
                        .background(Color.white)
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
                    .foregroundColor(blue)
                    .frame(width: 46, height: 46)
                    .background(Color.white)
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

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(blue)
                    .frame(width: 46, height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Saldo AstraPay kamu")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.systemGray))
                        Button {
                            hideBalance.toggle()
                        } label: {
                            Image(systemName: hideBalance ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.systemGray))
                        }
                    }
                    Text(hideBalance ? "Rp ••••••" : vm.balance.rupiah)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 74)
    }

    private var sheetContent: some View {
        VStack(spacing: 16) {
            Text("Jajanan di sekitarmu")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 10)

            if sheetDetent != .height(minSheetHeight) {
                Picker("", selection: $selectedTab) {
                    Text("Semua").tag(0)
                    Text("Favorit").tag(1)
                }
                .pickerStyle(.segmented)
                .tint(blue)

                let displayed = selectedTab == 0 ? vm.merchants : vm.merchants.filter(\.isFavorite)

                if displayed.isEmpty {
                    Spacer()
                    Text(selectedTab == 1 ? "Belum ada pedagang favorit" : "Belum ada pedagang di sekitarmu")
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.systemGray))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(displayed) { merchant in
                                NearbyMerchantCard(merchant: merchant)
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
