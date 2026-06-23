//
//  KelilingModeView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI
import MapKit

private struct PinItem: Identifiable {
    let id = UUID()
    let initial: String
    let name: String
    let distanceLabel: String
    let color: Color
    let coordinate: CLLocationCoordinate2D
}

private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

private let expandedDetent = PresentationDetent.height(240)
private let minimizedDetent = PresentationDetent.height(90)

struct KelilingModeView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isVisible = true
    @State private var selectedDetent: PresentationDetent = expandedDetent
    @State private var activePing: PinItem? = nil
    @State private var messageText = ""
    @State private var showDashboard = false
    @State private var hideSheet = false

    private let merchantCenter = CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456)
    
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
    ))

    private let allPings: [PinItem] = [
        PinItem(initial: "E", name: "Erin", distanceLabel: "120 m · 2 menit lalu",
                color: Color(red: 1, green: 0.478, blue: 0.102),
                coordinate: CLLocationCoordinate2D(latitude: -6.2058, longitude: 106.8430)),
        PinItem(initial: "R", name: "Revan", distanceLabel: "240 m · 5 menit lalu",
                color: Color(red: 0.486, green: 0.227, blue: 0.929),
                coordinate: CLLocationCoordinate2D(latitude: -6.2095, longitude: 106.8480)),
        PinItem(initial: "D", name: "Dani", distanceLabel: "320 m · 3 menit lalu",
                color: Color(red: 0.055, green: 0.647, blue: 0.914),
                coordinate: CLLocationCoordinate2D(latitude: -6.2115, longitude: 106.8472)),
        PinItem(initial: "A", name: "Alya", distanceLabel: "380 m · 7 menit lalu",
                color: Color(red: 0.91, green: 0.271, blue: 0.235),
                coordinate: CLLocationCoordinate2D(latitude: -6.2118, longitude: 106.8440)),
        PinItem(initial: "S", name: "Sinta", distanceLabel: "420 m · 4 menit lalu",
                color: Color(red: 0.486, green: 0.227, blue: 0.929),
                coordinate: CLLocationCoordinate2D(latitude: -6.2068, longitude: 106.8428)),
        PinItem(initial: "P", name: "Putri", distanceLabel: "390 m · jalan kaki ± 7 mnt",
                color: Color(red: 1, green: 0.478, blue: 0.102),
                coordinate: CLLocationCoordinate2D(latitude: -6.2060, longitude: 106.8462)),
    ]

    private var isMinimized: Bool { selectedDetent == minimizedDetent }

    var body: some View {
        ZStack {
            mapLayer

            if !isVisible && activePing == nil {
                dimOverlay
            }

            topGradient

            if isVisible && activePing == nil {
                mapControls
            }

            if let pin = activePing {
                topBar(for: pin)
            } else {
                floatingHeader
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: Binding(get: { isVisible && !hideSheet }, set: { _ in })) {
            if let pin = activePing {
                chatSheetContent(for: pin)
                    .presentationDetents([minimizedDetent, .medium, .large], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(true)
                    .presentationCornerRadius(34)
            } else {
                sheetContent
                    .presentationDetents([minimizedDetent, expandedDetent, .large], selection: $selectedDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(true)
                    .presentationCornerRadius(34)
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue { selectedDetent = expandedDetent }
        }
        .onChange(of: showDashboard) { _, isShowing in
            if !isShowing { hideSheet = false }
        }
        .fullScreenCover(isPresented: $showDashboard) {
            MerchantDashboardView()
        }
    }
    
    private func setActivePing(_ pin: PinItem?) {
        withAnimation {
            activePing = pin
            if let pin = pin {
                selectedDetent = minimizedDetent
                let lats = [merchantCenter.latitude, pin.coordinate.latitude]
                let lons = [merchantCenter.longitude, pin.coordinate.longitude]
                let centerLat = (lats.min()! + lats.max()!) / 2
                let centerLon = (lons.min()! + lons.max()!) / 2
                let spanLat = max((lats.max()! - lats.min()!) * 3.5, 0.006)
                let spanLon = max((lons.max()! - lons.min()!) * 3.5, 0.006)
                mapPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
                ))
            } else {
                selectedDetent = expandedDetent
                mapPosition = .region(MKCoordinateRegion(
                    center: merchantCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
                ))
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $mapPosition) {
            if let pin = activePing {
                MapPolyline(coordinates: [merchantCenter, pin.coordinate])
                    .stroke(
                        Color(red: 0, green: 0.271, blue: 0.898),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round, dash: [0, 13])
                    )

                Annotation("", coordinate: merchantCenter) {
                    merchantPin
                }

                Annotation("", coordinate: pin.coordinate) {
                    customerPin(pin)
                }
            } else {
                if isVisible {
                    MapCircle(center: merchantCenter, radius: 500)
                        .foregroundStyle(Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.04))
                        .stroke(Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.4), lineWidth: 2)

                    MapCircle(center: merchantCenter, radius: 900)
                        .foregroundStyle(.clear)
                        .stroke(Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.24), lineWidth: 2)

                    MapCircle(center: merchantCenter, radius: 1300)
                        .foregroundStyle(.clear)
                        .stroke(Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.12), lineWidth: 2)

                    ForEach(allPings) { pin in
                        Annotation("", coordinate: pin.coordinate) {
                            customerPin(pin)
                                .onTapGesture { setActivePing(pin) }
                        }
                    }
                }

                Annotation("", coordinate: merchantCenter) {
                    merchantPin
                        .opacity(isVisible ? 1 : 0.5)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var merchantPin: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0, green: 0.271, blue: 0.898))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 4)
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .medium))
            }
            .padding(.bottom, -2)

            DownTriangle()
                .fill(Color.white)
                .frame(width: 14, height: 9)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 3)
        }
    }

    private func customerPin(_ pin: PinItem) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8.5)
                    .fill(pin.color)
                    .frame(width: 34, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.5)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 4)
                Text(pin.initial)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, -2)

            DownTriangle()
                .fill(Color.white)
                .frame(width: 14, height: 9)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 3)
        }
    }

    private var dimOverlay: some View {
        Color(red: 0.957, green: 0.965, blue: 0.984)
            .opacity(0.78)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var topGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.059, green: 0.118, blue: 0.275).opacity(0.34),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 230)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
    
    private func topBar(for pin: PinItem) -> some View {
        HStack(spacing: 8) {
            Button { setActivePing(nil) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 6, x: 0, y: 2)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(red: 0.906, green: 0.965, blue: 0.937))
                        .frame(width: 34, height: 34)
                    Image(systemName: "figure.walk")
                        .foregroundStyle(Color(red: 0.071, green: 0.478, blue: 0.294))
                        .font(.system(size: 15, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Kamu sedang OTW ke \(pin.name)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                        .lineLimit(1)
                    Text("\(pin.name) sudah diberi tahu · 120 m lagi")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Text("± 2 mnt")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.839, green: 0.914, blue: 1))
                    )
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.16), radius: 10, x: 0, y: 6)
            )
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 61)
    }

    private var floatingHeader: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color(red: 0, green: 0.271, blue: 0.898))
                        .frame(width: 42, height: 42)
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Martabak Bang Jarwo")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                        .lineLimit(1)
                    Text("AstraMerchant · ID 0812****34")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                }

                Spacer()

                Button {
                    var transaction = SwiftUI.Transaction()
                    transaction.disablesAnimations = true
                    
                    withTransaction(transaction) {
                        hideSheet = true
                    }
                    
                    DispatchQueue.main.async {
                        showDashboard = true
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.929, green: 0.965, blue: 1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color(red: 0, green: 0.271, blue: 0.898))
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }

            HStack(spacing: 10) {
                Circle()
                    .fill(isVisible
                          ? Color(red: 0.071, green: 0.478, blue: 0.294)
                          : Color(red: 0.557, green: 0.557, blue: 0.576))
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle()
                            .stroke(isVisible
                                    ? Color(red: 0.098, green: 0.702, blue: 0.42).opacity(0.18)
                                    : .clear, lineWidth: 4)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(isVisible ? "Sedang berjualan" : "Sedang tidak berjualan")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isVisible
                                         ? Color(red: 0.071, green: 0.478, blue: 0.294)
                                         : Color(red: 0.557, green: 0.557, blue: 0.576))

                    Text(isVisible
                         ? "Tokomu aktif & bisa ditemukan customer"
                         : "Tokomu tidak terlihat oleh customer")
                        .font(.system(size: 11))
                        .foregroundStyle(isVisible
                                         ? Color(red: 0.071, green: 0.478, blue: 0.294)
                                         : Color(red: 0.557, green: 0.557, blue: 0.576))
                }

                Spacer()

                Toggle("", isOn: $isVisible)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.071, green: 0.478, blue: 0.294)))
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(height: 55)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isVisible
                          ? Color(red: 0.906, green: 0.965, blue: 0.937)
                          : Color(red: 0.941, green: 0.941, blue: 0.941))
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
        )
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 58)
    }

    private var mapControls: some View {
        VStack(spacing: 10) {
            mapControlButton("plus")
            mapControlButton("minus")
            mapControlButton("location")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 19)
        .padding(.top, 204)
    }

    private func mapControlButton(_ icon: String) -> some View {
        Button {} label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(width: 46, height: 46)
                    .shadow(
                        color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06),
                        radius: 6, x: 0, y: 2
                    )
                Image(systemName: icon)
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .font(.system(size: 18, weight: .medium))
            }
        }
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ping dari pelanggan")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                .padding(.horizontal, 16)
                .padding(.top, 28)

            HStack(spacing: 8) {
                Text("\(allPings.count) customer")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("dalam radius 500 m · update barusan")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(allPings.enumerated()), id: \.element.id) { index, pin in
                        pingRow(pin, showDivider: index < allPings.count - 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func pingRow(_ pin: PinItem, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(red: 0.941, green: 0.941, blue: 0.941))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pin.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))

                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(red: 0.098, green: 0.702, blue: 0.42))
                        Text(pin.distanceLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.098, green: 0.702, blue: 0.42))
                    }
                }

                Spacer()

                Button { setActivePing(pin) } label: {
                    Text("Terima Ping")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 97, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0, green: 0.271, blue: 0.898))
                        )
                }
            }
            .padding(.vertical, 11)

            if showDivider {
                Rectangle()
                    .fill(Color(red: 0.933, green: 0.945, blue: 0.965))
                    .frame(height: 1)
            }
        }
    }
    
    private func chatSheetContent(for pin: PinItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0, green: 0.271, blue: 0.898))
                        .frame(width: 48, height: 48)
                    Text(pin.initial)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pin.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                    Text("Menunggu kamu · 120 m")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.071, green: 0.478, blue: 0.294))
                }

                Spacer()
            }
            .padding(12)
            .padding(.top, 24)

            if selectedDetent != minimizedDetent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Spacer()
                            Text("Hari ini · 14.42")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                            Spacer()
                        }
                        .padding(.top, 14)

                        receivedBubble("Pak, posisi di mana? mau beli cimol 2 bungkus ya", time: "14.41")
                        sentBubble("Saya OTW ya bu, 2 menit lagi sampai 🙏", time: "14.42")
                        receivedBubble("Oke pak ditunggu, depan pagar hijau ya", time: "14.42")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
                .background(Color(red: 0.929, green: 0.965, blue: 1))

                VStack(spacing: 11) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickReplyChip("Sudah sampai")
                            quickReplyChip("Sebentar lagi")
                            quickReplyChip("Pesanan siap")
                        }
                        .padding(.horizontal, 18)
                    }

                    HStack(spacing: 9) {
                        TextField("Tulis pesan ke \(pin.name)…", text: $messageText)
                            .font(.system(size: 13.5))
                            .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))

                        Button {} label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.106, green: 0.31, blue: 0.878))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(red: 0.965, green: 0.984, blue: 1))
                    )
                    .padding(.horizontal, 18)
                }
                .padding(.top, 13)
                .padding(.bottom, 24)
                .background(
                    Color.white
                        .overlay(
                            Rectangle()
                                .fill(Color(red: 0.933, green: 0.945, blue: 0.965))
                                .frame(height: 1),
                            alignment: .top
                        )
                )
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func receivedBubble(_ text: String, time: String) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3.6) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.055, green: 0.09, blue: 0.149))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Text(time)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color(red: 0.055, green: 0.09, blue: 0.149).opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 15, bottomLeadingRadius: 5,
                    bottomTrailingRadius: 15, topTrailingRadius: 15
                )
                .fill(Color.white)
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15, bottomLeadingRadius: 5,
                        bottomTrailingRadius: 15, topTrailingRadius: 15
                    )
                    .stroke(Color(red: 0.933, green: 0.945, blue: 0.965), lineWidth: 1)
                )
            )
            .frame(maxWidth: 280, alignment: .leading)

            Spacer(minLength: 56)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func sentBubble(_ text: String, time: String) -> some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: 56)

            VStack(alignment: .leading, spacing: 3.6) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Text(time)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 15, bottomLeadingRadius: 15,
                    bottomTrailingRadius: 5, topTrailingRadius: 15
                )
                .fill(Color(red: 0.024, green: 0.369, blue: 1))
            )
            .frame(maxWidth: 280, alignment: .leading)
        }
        .padding(.top, 10)
    }

    private func quickReplyChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 13))
            .foregroundStyle(Color(red: 0.106, green: 0.31, blue: 0.878))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.933, green: 0.953, blue: 1))
            )
    }
}

#Preview {
    KelilingModeView()
        .environmentObject(AuthViewModel())
}
