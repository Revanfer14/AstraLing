//
//  MerchantMapPin.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct MerchantMapPin: View {
    let name: String
    let bannerUrl: String?
    var isSelected: Bool = false
    var showName: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            if showName {
                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .appTextPrimary : .appPrimary)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.Token.shadowBlueGrey.opacity(0.5), radius: 25, y: 6)
            }

            ZStack {
                Circle()
                    .fill(isSelected ? Color.appAccent : Color.appPrimary)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.appAccent.opacity(0.3) : Color.appPrimary.opacity(0.3),
                                lineWidth: 3
                            )
                            .padding(-3)
                    )

                if let urlString = bannerUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            forkKnifeIcon
                        }
                    }
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .clipShape(Circle())
                } else {
                    forkKnifeIcon
                }
            }
            .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private var forkKnifeIcon: some View {
        Image(systemName: "fork.knife")
            .font(.system(size: isSelected ? 12 : 9, weight: .regular))
            .foregroundColor(isSelected ? .appPrimary : .appSurfaceBlue)
    }
}

#Preview {
    HStack(spacing: 24) {
        MerchantMapPin(name: "Martabak Bang Jarwo", bannerUrl: nil, isSelected: false)
        MerchantMapPin(name: "Martabak Bang Jarwo", bannerUrl: nil, isSelected: true)
    }
    .padding()
}
