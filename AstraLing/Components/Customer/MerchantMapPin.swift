//
//  MerchantMapPin.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct MerchantMapPin: View {
    let name: String

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)
                .shadow(color: Color.Token.shadowBlueGrey.opacity(0.5), radius: 25, y: 6)

            ZStack {
                Circle()
                    .fill(Color.appPrimary)
                    .overlay(
                        Circle()
                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 3)
                            .padding(-3)
                    )

                Image(systemName: "fork.knife")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.appSurfaceBlue)
            }
            .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    MerchantMapPin(name: "Martabak Bang Jarwo")
        .padding()
}
