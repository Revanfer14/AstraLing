//
//  MerchantMapBanner.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import SwiftUI

struct MerchantMapBanner: View {
    let name: String
    let bannerUrl: String?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let urlString = bannerUrl, let url = URL(string: urlString) {
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
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .clipped()

            HStack(spacing: 5) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appPrimary)
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Color.appSurface)
        }
        .frame(width: 150)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }

    private var placeholderBg: some View {
        ZStack {
            Color.appSurfaceMuted
            Image(systemName: "storefront.fill")
                .font(.system(size: 26))
                .foregroundColor(.appPrimary.opacity(0.4))
        }
    }
}
