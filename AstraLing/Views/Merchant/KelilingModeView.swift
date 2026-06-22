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
private let minimizedDetent = PresentationDetent.height(100)

struct KelilingModeView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isVisible = true
    @State private var selectedDetent: PresentationDetent = expandedDetent

    private let merchantCenter = CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456)

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

            if !isVisible {
                dimOverlay
            }

            topGradient

            if isVisible {
                mapControls
            }

            floatingHeader
        }
        .ignoresSafeArea()
        .sheet(isPresented: Binding(get: { isVisible }, set: { _ in })) {
            sheetContent
                .presentationDetents([minimizedDetent, expandedDetent, .large], selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(true)
                .presentationCornerRadius(34)
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue { selectedDetent = expandedDetent }
        }
    }

    private var mapLayer: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: merchantCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        ))) {
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
                        }
                    
                }
            }

            Annotation("", coordinate: merchantCenter) {
                merchantPin
                    .opacity(isVisible ? 1 : 0.5)
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

                Button {} label: {
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
                .padding(.top, 12)

            HStack(spacing: 8) {
                Text("\(allPings.count) customer")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("dalam radius 500 m · update barusan")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color(red: 0.58, green: 0.627, blue: 0.702))
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
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

                Button {} label: {
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
}

#Preview {
    KelilingModeView()
        .environmentObject(AuthViewModel())
}
