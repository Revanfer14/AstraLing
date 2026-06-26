//
//  PingLocationSheet.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct PingLocationSheet: View {
    let initialCoordinate: CLLocationCoordinate2D?
    let onSend: (CLLocationCoordinate2D, String?) -> Void
    let onCancel: () -> Void

    private static let fallback = CLLocationCoordinate2D(latitude: -6.21, longitude: 106.84)

    @State private var address: String = ""
    @State private var detail: String = ""
    @State private var centerCoordinate: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition
    @State private var addressPrefilled = false

    init(initialCoordinate: CLLocationCoordinate2D?,
         onSend: @escaping (CLLocationCoordinate2D, String?) -> Void,
         onCancel: @escaping () -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onSend = onSend
        self.onCancel = onCancel
        let coord = initialCoordinate ?? PingLocationSheet.fallback
        _centerCoordinate = State(initialValue: coord)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                headerRow
                formContent
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .task {
            guard !addressPrefilled else { return }
            addressPrefilled = true
            let coord = initialCoordinate ?? PingLocationSheet.fallback
            if let resolved = await LocationService.reverseGeocode(coord) {
                address = resolved
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.appSurfaceBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            Spacer()
            Text("Konfirmasi Lokasimu")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
            Spacer()
            Color.clear
                .frame(width: 46, height: 46)
        }
        .padding(.top, 8)
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Pastikan titik lokasi sudah benar agar pedagang dapat menemukan Anda dengan lebih mudah.")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appTextPrimary)

            locationField
            mapPicker
            detailField
        }
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Lokasimu")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextPrimary)
            TextField("", text: $address)
                .font(.system(size: 16))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appTextSecondary, lineWidth: 1)
                )
        }
    }

    private var mapPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Geser pin di peta")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextPrimary)
            ZStack {
                Map(position: $cameraPosition)
                    .frame(height: 174)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onMapCameraChange(frequency: .continuous) { context in
                        centerCoordinate = context.region.center
                    }

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Color(red: 0, green: 0.478, blue: 1))
                        .frame(width: 12, height: 12)
                }

                VStack {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0, green: 0.478, blue: 1))
                            Text("Precise: On")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 0, green: 0.478, blue: 1))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                    Spacer()
                }
            }
            .frame(height: 174)
        }
    }

    private var detailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Detail lokasi (opsional)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextPrimary)
            TextField("nomor, nama gedung, dsb.", text: $detail)
                .font(.system(size: 16))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appTextSecondary, lineWidth: 1)
                )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: sendPing) {
                Text("Kirim Ping")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            Button(action: onCancel) {
                Text("Batalkan Ping")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appError)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.appErrorBg)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private func sendPing() {
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespaces)
        let parts = [trimmedAddress, trimmedDetail].filter { !$0.isEmpty }
        let note: String? = parts.isEmpty ? nil : parts.joined(separator: " — ")
        onSend(centerCoordinate, note)
    }
}
