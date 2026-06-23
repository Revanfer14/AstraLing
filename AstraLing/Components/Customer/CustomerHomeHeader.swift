//
//  CustomerHomeHeader.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerHomeHeader: View {
    let name: String

    private let gradientTop    = Color(red: 0.25, green: 0.47, blue: 0.94)
    private let gradientBottom = Color(red: 0.18, green: 0.35, blue: 0.80)

    private var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? (name.isEmpty ? "there" : name)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 270)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 80)

                HStack {
                    Text("Hi, \(firstName)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.70, green: 0.80, blue: 0.95))
                    Spacer()
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)

                Text("Bayar apa aja,\ndapat cashback\nAstraPoints!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.73, green: 0.80, blue: 0.95))
                    .lineSpacing(5)
                    .padding(.top, 8)
                    .padding(.horizontal, 30)

                HStack(alignment: .center) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Text("Cek promo")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.61, green: 0.72, blue: 0.92))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.61, green: 0.72, blue: 0.92))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
            }
        }
        .frame(height: 270)
    }
}

#Preview {
    CustomerHomeHeader(name: "Revan Ferdinand")
}
