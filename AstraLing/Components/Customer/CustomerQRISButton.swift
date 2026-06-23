//
//  CustomerQRISButton.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerQRISButton: View {
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.Token.gradBlueTop, Color.Token.gradBlueBottom],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: 64)
                    VStack(spacing: 2) {
                        Text("QRIS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                Text("Bayar")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
