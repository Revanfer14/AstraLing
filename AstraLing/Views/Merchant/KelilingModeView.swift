//
//  KelilingModeView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI
import MapKit
import UIKit
import FirebaseFirestore

private struct PinItem: Identifiable {
    let id: String
    let customerUid: String
    let initial: String
    let name: String
    let distanceLabel: String
    let walkMinutes: Int
    let color: Color
    let coordinate: CLLocationCoordinate2D
    let status: PingStatus
    let acceptedAt: Date
    let note: String?
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

private struct SlideToCompleteButton: View {
    let onComplete: () -> Void
    @State private var dragOffset: CGFloat = 0
    private let knobSize: CGFloat = 44
    private let trackHeight: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let maxDrag = trackWidth - knobSize - 8
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSuccessBg)
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSuccess.opacity(0.18))
                    .frame(width: knobSize + 8 + dragOffset, height: trackHeight)

                Text("Geser untuk Selesaikan Ping")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.appSuccess)
                    .frame(maxWidth: .infinity)
                    .opacity(dragOffset < maxDrag * 0.5 ? 1 : 1 - (dragOffset - maxDrag * 0.5) / (maxDrag * 0.5))

                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.appSuccess)
                        .shadow(color: Color.appSuccess.opacity(0.4), radius: 6, x: 0, y: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: knobSize, height: knobSize)
                .offset(x: 4 + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = min(max(0, value.translation.width), maxDrag)
                        }
                        .onEnded { _ in
                            if dragOffset >= maxDrag * 0.7 {
                                onComplete()
                            }
                            withAnimation(.spring()) { dragOffset = 0 }
                        }
                )
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
    }
}

private let expandedDetent = PresentationDetent.height(240)
private let minimizedDetent = PresentationDetent.height(90)

private enum FullScreenDestination: Identifiable {
    case dashboard
    case editProfile
    case transactionSuccess(Transaction)
    
    var id: String {
        switch self {
        case .dashboard: return "dashboard"
        case .editProfile: return "editProfile"
        case .transactionSuccess(let t): return "txn_\(t.id ?? UUID().uuidString)"
        }
    }
}

struct KelilingModeView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var merchantVM = MerchantViewModel()
    @StateObject private var chatVM = MerchantChatViewModel()
    
    @State private var isVisible = false
    @State private var isVisibleSynced = false
    @State private var selectedDetent: PresentationDetent = expandedDetent
    @State private var activePing: PinItem? = nil
    @State private var messageText = ""
    @State private var fullScreen: FullScreenDestination? = nil
    
    @StateObject private var location = LocationService()
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
    )
    @State private var pendingRecenter = false
    @State private var highlightedPingId: String? = nil
    @State private var previewRoute: [CLLocationCoordinate2D] = []
    @State private var locationNames: [String: String] = [:]
#if DEBUG
    @State private var debugOffsetEnabled = false
#endif
    
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
    ))
    
    private var merchantCoordinate: CLLocationCoordinate2D {
        guard let loc = merchantVM.presence?.location else {
            return CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456)
        }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }
    
    private func resolvedCoordinate(_ coord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
#if DEBUG
        guard debugOffsetEnabled else { return coord }
        return CLLocationCoordinate2D(latitude: coord.latitude + 0.004, longitude: coord.longitude)
#else
        return coord
#endif
    }
    
    private let radarRadii: [Double] = [200, 400, 600]
    
    private let pinPalette: [Color] = [
        Color(red: 1, green: 0.478, blue: 0.102),
        Color(red: 0.486, green: 0.227, blue: 0.929),
        Color(red: 0.055, green: 0.647, blue: 0.914),
        Color(red: 0.91, green: 0.271, blue: 0.235),
    ]
    
    private var livePings: [PinItem] {
        let origin = CLLocation(latitude: merchantCoordinate.latitude, longitude: merchantCoordinate.longitude)
        return merchantVM.activePings.map { ping in
            let dest = CLLocation(latitude: ping.customerLocation.latitude, longitude: ping.customerLocation.longitude)
            let meters = origin.distance(from: dest)
            let label = meters < 1000
                ? "\(Int(meters)) m"
                : String(format: "%.1f km", meters / 1000)
            let walk = max(1, Int((meters / 80).rounded()))
            let colorIndex = abs(ping.customerUid.hashValue) % pinPalette.count
            return PinItem(
                id: ping.id ?? ping.customerUid,
                customerUid: ping.customerUid,
                initial: String(ping.customerName.prefix(1)).uppercased(),
                name: ping.customerName,
                distanceLabel: label,
                walkMinutes: walk,
                color: pinPalette[colorIndex],
                coordinate: CLLocationCoordinate2D(
                    latitude: ping.customerLocation.latitude,
                    longitude: ping.customerLocation.longitude
                ),
                status: ping.status,
                acceptedAt: ping.updatedAt.dateValue(),
                note: ping.note
            )
        }
    }
    
    private var isMinimized: Bool { selectedDetent == minimizedDetent }

    private var orderedPings: [PinItem] {
        let accepted = livePings.filter { $0.status == .onTheWay }
            .sorted { $0.acceptedAt < $1.acceptedAt }
        var pending = livePings.filter { $0.status == .active }
        if let hId = highlightedPingId,
           let idx = pending.firstIndex(where: { $0.id == hId }) {
            pending.insert(pending.remove(at: idx), at: 0)
        }
        return accepted + pending
    }

    private var servingPings: [PinItem] {
        livePings.filter { $0.status == .onTheWay }
            .sorted { $0.acceptedAt < $1.acceptedAt }
    }

    private var incomingPings: [PinItem] {
        var pending = livePings.filter { $0.status == .active }
        if let hId = highlightedPingId,
           let idx = pending.firstIndex(where: { $0.id == hId }) {
            pending.insert(pending.remove(at: idx), at: 0)
        }
        return pending
    }
    
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
        .onAppear {
            merchantVM.startListening()
            location.requestAuthorization()
            location.startUpdating()
        }
        .onDisappear {
            merchantVM.stopListening()
            location.stopUpdating()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            if isVisible { merchantVM.goOfflineBestEffort() }
        }
        .onChange(of: merchantVM.presence?.merchantUid) { _, uid in
            guard uid != nil, !isVisibleSynced, let presence = merchantVM.presence else { return }
            isVisibleSynced = true
            isVisible = presence.isVisible
            guard let loc = presence.location else { return }
            let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            let region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
            )
            mapPosition = .region(region)
            currentRegion = region
        }
        .onChange(of: location.current) { _, newLocation in
            guard let newLocation else { return }
            if pendingRecenter {
                pendingRecenter = false
                let newRegion = MKCoordinateRegion(center: newLocation.coordinate, span: currentRegion.span)
                withAnimation { mapPosition = .region(newRegion) }
                currentRegion = newRegion
            }
            if isVisible {
                Task { await merchantVM.updateLocation(resolvedCoordinate(newLocation.coordinate)) }
            }
            if let pin = activePing {
                merchantVM.updateRoute(merchantCoord: merchantCoordinate, customerCoord: pin.coordinate)
            }
        }
        .sheet(isPresented: $isVisible) {
            Group {
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
            .fullScreenCover(item: Binding(
                get: { isVisible ? fullScreen : nil },
                set: { fullScreen = $0 }
            )) { fullScreenContent($0) }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue { selectedDetent = expandedDetent }
        }
        .fullScreenCover(item: Binding(
            get: { isVisible ? nil : fullScreen },
            set: { fullScreen = $0 }
        )) { fullScreenContent($0) }
        .onReceive(NotificationCenter.default.publisher(for: .transactionNotificationTapped)) { notification in
            guard let txnId = notification.object as? String,
                  let txn = merchantVM.transaction(for: txnId) else { return }
            fullScreen = .transactionSuccess(txn)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pingNotificationTapped)) { notification in
            guard let pingId = notification.object as? String else { return }
            setActivePing(nil)
            highlightedPingId = pingId
            selectedDetent = expandedDetent
            if let pin = orderedPings.first(where: { $0.id == pingId }) {
                computePreviewRoute(to: pin)
            }
        }
    }
    
    @ViewBuilder
    private func fullScreenContent(_ dest: FullScreenDestination) -> some View {
        switch dest {
        case .dashboard:
            MerchantDashboardView()
                .environmentObject(merchantVM)
        case .editProfile:
            NavigationStack {
                EditProfilView()
                    .environmentObject(merchantVM)
            }
        case .transactionSuccess(let txn):
            TransaksiBerhasilView(transaction: txn)
        }
    }
    
    private func setActivePing(_ pin: PinItem?) {
        highlightedPingId = nil
        previewRoute = []
        merchantVM.clearRoute()
        if let pin = pin {
            chatVM.start(customerUid: pin.customerUid)
            merchantVM.updateRoute(merchantCoord: merchantCoordinate, customerCoord: pin.coordinate)
        } else {
            chatVM.stop()
        }
        withAnimation {
            activePing = pin
            if let pin = pin {
                selectedDetent = minimizedDetent
                let lats = [merchantCoordinate.latitude, pin.coordinate.latitude]
                let lons = [merchantCoordinate.longitude, pin.coordinate.longitude]
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
                    center: merchantCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
                ))
            }
        }
    }
    
    private func computePreviewRoute(to pin: PinItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: merchantCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate))
        request.transportType = .walking
        Task { @MainActor in
            if let response = try? await MKDirections(request: request).calculate(),
               let polyline = response.routes.first?.polyline {
                previewRoute = polyline.coordinates
            } else {
                previewRoute = [merchantCoordinate, pin.coordinate]
            }
        }
    }

    private func resolveLocationName(for pin: PinItem) {
        guard locationNames[pin.id] == nil else { return }
        Task {
            if let name = await LocationService.reverseGeocode(pin.coordinate) {
                locationNames[pin.id] = name
            }
        }
    }

    private var mapLayer: some View {
        let routeCoords: [CLLocationCoordinate2D] = {
            guard let pin = activePing else { return [] }
            return merchantVM.activeRoute.count >= 2 ? merchantVM.activeRoute : [merchantCoordinate, pin.coordinate]
        }()
        let previewCoords: [CLLocationCoordinate2D] = activePing == nil ? previewRoute : []
        return Map(position: $mapPosition) {
            UserAnnotation()
            if let pin = activePing {
                MapPolyline(coordinates: routeCoords.count >= 2 ? routeCoords : [merchantCoordinate, pin.coordinate])
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))


                Annotation("", coordinate: merchantCoordinate) {
                    merchantPin
                }
                
                Annotation("", coordinate: pin.coordinate) {
                    customerPin(pin)
                }
            } else {
                if previewCoords.count >= 2 {
                    MapPolyline(coordinates: previewCoords)
                        .stroke(Color.appPrimary.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 5]))
                }
                if isVisible {
                    ForEach(Array(radarRadii.enumerated()), id: \.offset) { index, radius in
                        MapCircle(center: merchantCoordinate, radius: radius)
                            .foregroundStyle(index == 0
                                             ? Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.04)
                                             : Color.clear)
                            .stroke(
                                Color(red: 0.106, green: 0.31, blue: 0.878)
                                    .opacity(index == 0 ? 0.4 : index == 1 ? 0.24 : 0.12),
                                lineWidth: 2
                            )
                    }
                    
                    ForEach(radarRadii, id: \.self) { radius in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: merchantCoordinate.latitude + radius / 111_320,
                            longitude: merchantCoordinate.longitude
                        )) {
                            radarLabel(radius)
                        }
                    }
                    
                    ForEach(livePings) { pin in
                        Annotation("", coordinate: pin.coordinate) {
                            customerPin(pin)
                                .onTapGesture {
                                    highlightedPingId = pin.id
                                    selectedDetent = expandedDetent
                                    computePreviewRoute(to: pin)
                                }
                        }
                    }
                }
                
                Annotation("", coordinate: merchantCoordinate) {
                    merchantPin
                        .opacity(isVisible ? 1 : 0.5)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {}
        .onMapCameraChange(frequency: .continuous) { context in
            currentRegion = context.region
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var merchantPin: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appPrimary)
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
    
    private func radarLabel(_ meters: Double) -> some View {
        Text("\(Int(meters)) m")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Color(red: 0.106, green: 0.31, blue: 0.878).opacity(0.65))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(.white.opacity(0.88)))
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
                        .foregroundStyle(Color.appTextPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.appSuccessBg)
                        .frame(width: 34, height: 34)
                    Image(systemName: "figure.walk")
                        .foregroundStyle(Color.appSuccess)
                        .font(.system(size: 15, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kamu sedang OTW ke \(pin.name)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    Text("\(pin.name) sudah diberi tahu · 120 m lagi")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.appTextTertiary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                Text("± 2 mnt")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Token.blue100)
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
    
    private var bannerPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.appPrimary)
                .frame(width: 42, height: 42)
            Image(systemName: "fork.knife")
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    private var floatingHeader: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                Button {
                    fullScreen = .editProfile
                } label: {
                    HStack(spacing: 11) {
                        Group {
                            if let urlStr = merchantVM.merchant?.bannerUrl,
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                            .frame(width: 42, height: 42)
                                            .clipShape(RoundedRectangle(cornerRadius: 13))
                                    default:
                                        bannerPlaceholder
                                    }
                                }
                            } else {
                                bannerPlaceholder
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(merchantVM.merchant?.name ?? "Memuat...")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.appTextPrimary)
                                .lineLimit(1)
                            Text("AstraMerchant · #\(String((merchantVM.uid ?? "").prefix(8)).uppercased())")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    fullScreen = .dashboard
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appSurfaceBlue)
                            .frame(width: 40, height: 40)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color.appPrimary)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            
            HStack(spacing: 10) {
                Circle()
                    .fill(isVisible
                          ? Color.appSuccess
                          : Color.appTextTertiary)
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
                                         ? Color.appSuccess
                                         : Color.appTextTertiary)
                    
                    Text(isVisible
                         ? "Tokomu aktif & bisa ditemukan customer"
                         : "Tokomu tidak terlihat oleh customer")
                    .font(.system(size: 11))
                    .foregroundStyle(isVisible
                                     ? Color.appSuccess
                                     : Color.appTextTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isVisible },
                    set: { newValue in
                        isVisible = newValue
                        Task {
                            await merchantVM.setVisible(newValue)
                            if newValue, let current = location.current {
                                await merchantVM.updateLocation(resolvedCoordinate(current.coordinate))
                            }
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color.appSuccess))
                .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(height: 55)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isVisible
                          ? Color.appSuccessBg
                          : Color.appDivider)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
            //                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 8)
        )
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 58)
    }
    
    private var mapControls: some View {
        VStack {
            
            Button(action: recenterOnUser) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 46, height: 46)
                        .shadow(
                            color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06),
                            radius: 6, x: 0, y: 2
                        )
                    Image(systemName: "scope")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 20, weight: .medium))
                }
            }
#if DEBUG
            Button {
                debugOffsetEnabled.toggle()
                if isVisible, let current = location.current {
                    Task { await merchantVM.updateLocation(resolvedCoordinate(current.coordinate)) }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(debugOffsetEnabled ? Color.appPrimary : Color.white)
                        .frame(width: 46, height: 46)
                        .shadow(
                            color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06),
                            radius: 6, x: 0, y: 2
                        )
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(debugOffsetEnabled ? Color.white : Color.appTextPrimary)
                        .font(.system(size: 18, weight: .medium))
                }
            }
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 19)
        .padding(.top, 204)
        
    }
    
    private func recenterOnUser() {
        location.requestAuthorization()
        if let current = location.current {
            let newRegion = MKCoordinateRegion(center: current.coordinate, span: currentRegion.span)
            withAnimation { mapPosition = .region(newRegion) }
            currentRegion = newRegion
        } else {
            pendingRecenter = true
        }
    }
    
    private var sheetContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !servingPings.isEmpty {
                    Text("Ping Berlangsung")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 28)

                    Text("\(servingPings.count) customer")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 10)

                    VStack(spacing: 0) {
                        ForEach(Array(servingPings.enumerated()), id: \.element.id) { index, pin in
                            pingRow(pin, showDivider: index < servingPings.count - 1)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Text("Ping Masuk")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, servingPings.isEmpty ? 28 : 24)

                Text("\(incomingPings.count) customer")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 10)

                if incomingPings.isEmpty {
                    Text("Belum ada ping masuk")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(incomingPings.enumerated()), id: \.element.id) { index, pin in
                            pingRow(pin, showDivider: index < incomingPings.count - 1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func pingRow(_ pin: PinItem, showDivider: Bool) -> some View {
        let isServing = pin.status == .onTheWay
        let isHighlighted = pin.id == highlightedPingId

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.appSurfaceMuted)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.appTextTertiary)
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        (
                            Text(pin.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.appTextPrimary)
                            + Text(" · ")
                                .font(.system(size: 14.5))
                                .foregroundStyle(Color.appTextPrimary)
                            + Text(pin.distanceLabel)
                                .font(.system(size: 14.5))
                                .foregroundStyle(Color.appSuccess)
                        )
                        .lineLimit(1)

                        Text("\(locationNames[pin.id] ?? "Memuat lokasi…") · ± \(pin.walkMinutes) mnt")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextTertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isServing {
                        highlightedPingId = pin.id
                        selectedDetent = expandedDetent
                        computePreviewRoute(to: pin)
                    }
                }

                if isServing {
                    Button {
                        setActivePing(pin)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.Token.blue600)
                                .frame(width: 34, height: 34)
                            Image(systemName: "message.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                } else {
                    HStack(spacing: 3) {
                        Button {
                            if let ping = merchantVM.activePings.first(where: { ($0.id ?? $0.customerUid) == pin.id }) {
                                Task { await merchantVM.accept(ping) }
                            }
                            setActivePing(pin)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appSuccess)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }

                        Button {
                            if let ping = merchantVM.activePings.first(where: { ($0.id ?? $0.customerUid) == pin.id }) {
                                Task { await merchantVM.reject(ping) }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appError)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "xmark")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, isHighlighted ? 8 : 0)
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurfaceBlue)
                }
            }
            .padding(.vertical, isHighlighted ? 4 : 0)
            .task(id: pin.id) { resolveLocationName(for: pin) }

            if showDivider && !isHighlighted {
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: 1)
            }
        }
    }
    
    private func chatSheetContent(for pin: PinItem) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 11) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13.7)
                            .fill(Color(red: 0.918, green: 0.929, blue: 0.953))
                            .frame(width: 47, height: 47)
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.appTextTertiary)
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(pin.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text(locationNames[pin.id] ?? "Memuat lokasi…")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appSuccess)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 50)
                .padding(.bottom, 12)
                .task(id: pin.id) { resolveLocationName(for: pin) }

                Rectangle()
                    .fill(Color(red: 0.933, green: 0.945, blue: 0.965))
                    .frame(height: 1)
            }


            if selectedDetent != minimizedDetent {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if !chatVM.messages.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Hari ini")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                                    Spacer()
                                }
                                .padding(.top, 14)
                            }
                            ForEach(chatVM.messages) { item in
                                Group {
                                    if item.isMine {
                                        sentBubble(item.text, time: item.time?.timeLabelID ?? "")
                                    } else {
                                        receivedBubble(item.text, time: item.time?.timeLabelID ?? "")
                                    }
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)
                    }
                    .background(Color(red: 0.965, green: 0.969, blue: 0.976))
                    .onChange(of: chatVM.messages.count) { _, _ in
                        if let last = chatVM.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(red: 0.933, green: 0.945, blue: 0.965))
                        .frame(height: 1)

                    VStack(spacing: 10) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button { chatVM.send("Sudah sampai") } label: { quickReplyChip("Sudah sampai") }
                                Button { chatVM.send("Sebentar lagi") } label: { quickReplyChip("Sebentar lagi") }
                                Button { chatVM.send("Pesanan siap") } label: { quickReplyChip("Pesanan siap") }
                            }
                            .padding(.horizontal, 18)
                        }

                        HStack(spacing: 9) {
                            TextField("Tulis pesan ke \(pin.name)…", text: $messageText)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Color.appTextTertiary)
                            Button {
                                chatVM.send(messageText)
                                messageText = ""
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.appPrimary)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "paperplane.fill")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 13))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color(red: 0.949, green: 0.957, blue: 0.969))
                        )
                        .padding(.horizontal, 18)

                        SlideToCompleteButton {
                            Task { await merchantVM.completePing(pingId: pin.id) }
                            setActivePing(nil)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 28)
                    }
                    .padding(.top, 12)
                    .background(Color.white)
                }
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
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Text(time)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.appTextPrimary.opacity(0.6))
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
                .fill(Color.appPrimaryPressed)
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
