//
//  NearbyMerchantCard.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct NearbyMerchantCard: View {
    let merchant: NearbyMerchant

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appSurfaceBlue)
                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundColor(Color.appPrimary.opacity(0.5))
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text(merchant.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
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
        .shadow(color: Color.Token.shadowBlueGrey.opacity(0.5), radius: 25, y: 6)
    }
}
