//
//  ActivePingCard.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import SwiftUI

struct ActivePingCard: View {
    let merchant: NearbyMerchant
    let status: PingStatus

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                if let urlString = merchant.bannerUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            placeholderBg
                        }
                    }
                } else {
                    placeholderBg
                }
            }
            .frame(width: 180, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                Text(merchant.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)

                statusPill(for: status)

                VStack(alignment: .leading, spacing: 10) {
                    if !merchant.distanceLabel.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.appPrimary)
                            Text(merchant.distanceLabel)
                                .foregroundColor(.appTextPrimary)
                        }
                        .font(.system(size: 14))
                    }

                    if !merchant.walkLabel.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.appPrimary)
                            Text(merchant.walkLabel)
                                .foregroundColor(.appTextPrimary)
                        }
                        .font(.system(size: 14))
                    }
                }
            }

            Spacer()
        }
        .padding(4)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.Token.shadowBlueGrey.opacity(0.5), radius: 25, y: 12)
    }

    private var placeholderBg: some View {
        ZStack {
            Color.appSurfaceMuted
            Image(systemName: "storefront.fill")
                .font(.system(size: 26))
                .foregroundColor(.appPrimary.opacity(0.4))
        }
    }

    @ViewBuilder
    private func statusPill(for status: PingStatus) -> some View {
        switch status {
        case .active:
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 6, height: 6)
                Text("Menunggu pedagang")
                    .font(.system(size: 11))
            }
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appSurfaceBlue)
            .clipShape(Capsule())
        case .onTheWay:
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 6, height: 6)
                Text("Ping Aktif")
                    .font(.system(size: 11))
            }
            .foregroundColor(.appSuccess)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appSuccessBg)
            .clipShape(Capsule())
        default:
            EmptyView()
        }
    }
}
