//
//  NewPingDialog.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 26/06/26.
//

import SwiftUI
import MapKit

struct NewPingDialog: View {
    let customerName: String
    let coordinate: CLLocationCoordinate2D
    let onQueue: () -> Void
    let onReject: () -> Void

    @State private var locationName: String = "Memuat lokasi…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("Ada Ping Baru!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.center)

                    Text(customerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(locationName)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.top, 33)
                .padding(.horizontal, 38)

                Map(
                    position: .constant(
                        MapCameraPosition.region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                            )
                        )
                    )
                ) {
                    Annotation("", coordinate: coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.2))
                                .frame(width: 24, height: 24)
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .disabled(true)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .padding(.horizontal, 19)
                .padding(.top, 16)

                VStack(spacing: 8) {
                    HStack(spacing: 13) {
                        Button(action: onQueue) {
                            Text("Masuk Antrian")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.appPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Button(action: onReject) {
                            Text("Tolak Ping")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.appError)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }

                    Text("Jika kamu tidak merespon dalam 60 detik, ping otomatis masuk antrian sebagai \"menunggu\".")
                        .font(.system(size: 11))
                        .foregroundColor(.appTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 21)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 26)
        }
        .task {
            if let name = await LocationService.reverseGeocode(coordinate) {
                locationName = name
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(60))
            if !Task.isCancelled {
                onQueue()
            }
        }
    }
}
