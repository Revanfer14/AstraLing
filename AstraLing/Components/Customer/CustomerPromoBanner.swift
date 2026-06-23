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
                    .foregroundColor(Color(red: 0.97, green: 0.75, blue: 0.60))
                Text("Upgrade yuk, biar bisa transfer & tarik tunai!")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.96, green: 0.67, blue: 0.48))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Upgrade")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.94, green: 0.67, blue: 0.48))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(red: 0.94, green: 0.67, blue: 0.48))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(red: 0.99, green: 0.95, blue: 0.92))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(red: 0.98, green: 0.87, blue: 0.76), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.55, blue: 0.25), Color(red: 0.97, green: 0.45, blue: 0.15)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
