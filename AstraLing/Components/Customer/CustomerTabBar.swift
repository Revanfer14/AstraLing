//
//  CustomerTabBar.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerTabBar: View {
    let onProfil: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                CustomerTabBarItem(imageName: "tab-beranda", label: "Beranda", isActive: true,  action: {})
                CustomerTabBarItem(imageName: "tab-promo",   label: "Promo",   isActive: false, action: {})

                Spacer().frame(width: 64)

                CustomerTabBarItem(imageName: "tab-riwayat", label: "Riwayat", isActive: false, action: {})
                CustomerTabBarItem(imageName: "tab-profil",  label: "Profil",  isActive: false, action: onProfil)
            }
            .padding(.horizontal, 8)
            .frame(height: 56)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
    }
}

private struct CustomerTabBarItem: View {
    let imageName: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    private var tint: Color {
        isActive ? Color(red: 0.44, green: 0.56, blue: 0.84) : Color(UIColor.tertiaryLabel)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(imageName)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .colorMultiply(tint)
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .bold : .regular))
                    .foregroundColor(tint)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
