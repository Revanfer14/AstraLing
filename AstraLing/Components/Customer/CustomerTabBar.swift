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
                CustomerTabBarItem(systemName: "house.fill", label: "Beranda", isActive: true,  action: {})
                CustomerTabBarItem(systemName: "tag",        label: "Promo",   isActive: false, action: {})

                Spacer().frame(width: 64)

                CustomerTabBarItem(systemName: "doc.text",  label: "Riwayat", isActive: false, action: {})
                CustomerTabBarItem(systemName: "person",    label: "Profil",  isActive: false, action: onProfil)
            }
            .padding(.horizontal, 8)
            .frame(height: 56)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
    }
}

private struct CustomerTabBarItem: View {
    let systemName: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    private var tint: Color {
        isActive ? Color(red: 0.44, green: 0.56, blue: 0.84) : Color(UIColor.tertiaryLabel)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemName)
                    .font(.system(size: 20))
                    .foregroundColor(tint)
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .bold : .regular))
                    .foregroundColor(tint)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
