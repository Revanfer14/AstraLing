//
//  CustomerMenuGrid.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct MenuTileItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    var badge: String? = nil
    var badgeColor: Color = .red
}

struct CustomerMenuGrid: View {
    let items: [MenuTileItem]
    let onAstraLing: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    MenuTile(item: item, onTap: item.title == "AstraLing" ? onAstraLing : {})
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

private struct MenuTile: View {
    let item: MenuTileItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Image(item.imageName)
                        .resizable().scaledToFit()
                        .frame(width: 44, height: 44)
                    Text(item.title)
                        .font(.system(size: 11))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(item.badgeColor)
                        .clipShape(Capsule())
                        .padding(.trailing, 4)
                        .padding(.top, 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
