//
//  MerchantMapPin.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct MerchantMapPin: View {
    let name: String

    private let blue = Color(red: 0/255, green: 69/255, blue: 229/255)

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(blue)
                .multilineTextAlignment(.center)
                .shadow(color: Color(red: 208/255, green: 214/255, blue: 226/255).opacity(0.5), radius: 25, y: 6)

            ZStack {
                Circle()
                    .fill(blue)
                    .overlay(
                        Circle()
                            .stroke(blue.opacity(0.3), lineWidth: 3)
                            .padding(-3)
                    )

                Image(systemName: "fork.knife")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(Color(red: 237/255, green: 246/255, blue: 255/255))
            }
            .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    MerchantMapPin(name: "Martabak Bang Jarwo")
        .padding()
}
