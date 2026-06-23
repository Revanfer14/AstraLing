//
//  CustomerHomeHeader.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerHomeHeader: View {
    private let gradientTop    = Color(red: 0.25, green: 0.47, blue: 0.94)
    private let gradientBottom = Color(red: 0.18, green: 0.35, blue: 0.80)

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 230)

            HStack(spacing: 0) {
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Image("coin-2")
                        .resizable().scaledToFit()
                        .frame(width: 16, height: 19)
                        .padding(.trailing, 127)
                        .padding(.top, 56)

                    Image("coin-3")
                        .resizable().scaledToFit()
                        .frame(width: 15, height: 17)
                        .padding(.trailing, 52)
                        .padding(.top, 4)

                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("APO")
                                .font(.system(size: 30, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.87))
                            Text("AJA")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.90))
                        }
                        .padding(.trailing, 16)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Image("coin-1")
                        .resizable().scaledToFit()
                        .frame(width: 18, height: 21)
                        .padding(.trailing, 28)
                        .padding(.top, 90)
                }
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("badge-untung")
                        .resizable().scaledToFit()
                        .frame(width: 87, height: 24)
                        .padding(.trailing, 48)
                        .padding(.bottom, 58)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 54)

                HStack {
                    Text("Hi, Erin")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.65, green: 0.76, blue: 0.93))
                    Spacer()
                    Image("ic-bell")
                        .resizable().scaledToFit()
                        .frame(width: 18, height: 21)
                }
                .padding(.horizontal, 16)

                Text("Bayar apa aja,\ndapat cashback\nAstraPoints!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.73, green: 0.80, blue: 0.95))
                    .lineSpacing(5)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

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
                .padding(.top, 10)
                .padding(.leading, 16)
            }
        }
        .frame(height: 230)
    }
}
