//
//  CustomerPromoBanner.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerPromoBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Akses Fitur Masih Terbatas?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.Token.promoTitle)
                Text("Upgrade yuk, biar bisa transfer & tarik tunai!")
                    .font(.system(size: 12))
                    .foregroundColor(Color.Token.promoSubtitle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Upgrade")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.Token.promoButtonText)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.Token.promoButtonText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.Token.promoButtonBg)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.Token.promoButtonBorder, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.Token.promoGradStart, Color.Token.promoGradEnd],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
