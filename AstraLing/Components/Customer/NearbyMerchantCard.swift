//
//  NearbyMerchantCard.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct NearbyMerchantCard: View {
    let merchant: NearbyMerchant

    private let blue = Color(red: 0/255, green: 69/255, blue: 229/255)

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 237/255, green: 246/255, blue: 255/255))
                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundColor(blue.opacity(0.5))
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text(merchant.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    if !merchant.distanceLabel.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(blue)
                            Text(merchant.distanceLabel)
                                .foregroundColor(.black)
                        }
                        .font(.system(size: 14))
                    }

                    if !merchant.walkLabel.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(blue)
                            Text(merchant.walkLabel)
                                .foregroundColor(.black)
                        }
                        .font(.system(size: 14))
                    }
                }
            }

            Spacer()
        }
        .padding(4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(red: 208/255, green: 214/255, blue: 226/255).opacity(0.5), radius: 25, y: 6)
    }
}
