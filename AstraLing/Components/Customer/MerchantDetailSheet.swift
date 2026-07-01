//
//  MerchantDetailSheet.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct MerchantDetailSheet: View {
    let merchant: NearbyMerchant
    let isFavorite: Bool
    let onBack: () -> Void
    let onToggleFavorite: () -> Void
    let onPing: () -> Void

    @StateObject private var vm = MerchantDetailViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                if merchant.isServing {
                    servingStatusPill
                }
                distanceRow
                photoStrip
                menuContent
                pingButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .onAppear { vm.load(merchantUid: merchant.id) }
        .onChange(of: merchant.id) { _, newId in vm.load(merchantUid: newId) }
    }

    private var headerRow: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.appSurfaceBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Spacer()

            Text(merchant.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.appSurfaceBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.top, 20)
    }

    private var servingStatusPill: some View {
        Text("Sedang melayani pelanggan lain")
            .font(.system(size: 14))
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSurfaceBlue)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var distanceRow: some View {
        HStack(spacing: 16) {
            if !merchant.distanceLabel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.appPrimary)
                    Text(merchant.distanceLabel)
                        .foregroundColor(.appTextPrimary)
                }
            }
            if !merchant.walkLabel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.appPrimary)
                    Text(merchant.walkLabel)
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .font(.system(size: 14))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var stripImageUrls: [String] {
        var urls: [String] = []
        if let banner = vm.bannerUrl, !banner.isEmpty { urls.append(banner) }
        let menuPhotos = vm.sections.flatMap { $0.items }
            .compactMap { $0.photoUrl }
            .filter { !$0.isEmpty }
        for p in menuPhotos where !urls.contains(p) && urls.count < 3 {
            urls.append(p)
        }
        return Array(urls.prefix(3))
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(stripImageUrls, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                photoPlaceholderContent
                            }
                        }
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                ForEach(0 ..< max(0, 3 - stripImageUrls.count), id: \.self) { _ in
                    photoPlaceholderTile
                }
            }
        }
    }

    private var photoPlaceholderTile: some View {
        photoPlaceholderContent
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var photoPlaceholderContent: some View {
        ZStack {
            Color.appSurfaceBlue
            Image(systemName: "fork.knife")
                .font(.system(size: 32))
                .foregroundColor(Color.appPrimary.opacity(0.5))
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        if vm.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        } else {
            ForEach(vm.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextTertiary)
                        .tracking(0.3)
                        .padding(.top, 8)

                    ForEach(section.items) { item in
                        menuItemRow(item)
                    }
                }
            }
        }
    }

    private func menuItemRow(_ item: MenuItem) -> some View {
        HStack(spacing: 13) {
            Group {
                if let urlString = item.photoUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            menuPlaceholderContent
                        }
                    }
                } else {
                    menuPlaceholderContent
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text(item.price.rupiah)
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)

                statusPill(for: item.status)
            }

            Spacer()
        }
        .padding(13)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 4, y: 4)
    }

    private var menuPlaceholderContent: some View {
        ZStack {
            Color.appSurfaceBlue
            Image(systemName: "fork.knife")
                .font(.system(size: 16))
                .foregroundColor(Color.appPrimary.opacity(0.5))
        }
    }

    @ViewBuilder
    private func statusPill(for status: MenuItemStatus) -> some View {
        if status == .tersedia {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                Text("Tersedia")
                    .font(.system(size: 11))
            }
            .foregroundColor(Color(hex: "127A4B"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "E7F6EF"))
            .clipShape(Capsule())
        } else {
            HStack(spacing: 5) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                Text("Stok habis")
                    .font(.system(size: 11))
            }
            .foregroundColor(Color(hex: "E8453C"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "FDECEB"))
            .clipShape(Capsule())
        }
    }

    private var pingButton: some View {
        HStack {
            Spacer()
            Button(action: onPing) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.rays")
                        .font(.system(size: 14, weight: .bold))
                    Text("Ping pedagang")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.appSurface)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
            }
        }
        .padding(.top, 8)
    }
}
