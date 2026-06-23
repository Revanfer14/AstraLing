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
    let assetName: String
    var badged: Bool = false
}

struct CustomerMenuGrid: View {
    let items: [MenuTileItem]
    let onAstraLing: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                MenuTile(item: item, onTap: item.title == "AstraLing" ? onAstraLing : {})
            }
        }
        .padding(.vertical, 16)
    }
}

private struct MenuTile: View {
    let item: MenuTileItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    if item.badged {
                        Image(item.assetName)
                            .resizable().scaledToFit()
                            .frame(width: 72, height: 64)
                    } else {
                        Image(item.assetName)
                            .resizable().scaledToFit()
                            .frame(width: 56, height: 56)
                    }
                }
                .frame(height: 64)

                Text(item.title)
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
