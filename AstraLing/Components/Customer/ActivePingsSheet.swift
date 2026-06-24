//
//  ActivePingsSheet.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct ActivePingsSheet: View {
    let pings: [ActivePing]
    let onCancel: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Ping Aktif")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text("\(pings.count) ping sedang berjalan")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if pings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "hand.rays")
                        .font(.system(size: 40))
                        .foregroundColor(.appPrimary.opacity(0.4))
                    Text("Belum ada ping aktif")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextTertiary)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(pings) { ping in
                            pingRow(ping)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func pingRow(_ ping: ActivePing) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Color.appSurfaceBlue
                Image(systemName: "storefront.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(ping.merchantName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                statusPill(for: ping.status)

                if !ping.interestedItems.isEmpty {
                    Text(ping.interestedItems.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundColor(.appTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                onCancel(ping.id)
            } label: {
                Text("Batal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appError)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.appErrorBg)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 4, y: 4)
    }

    @ViewBuilder
    private func statusPill(for status: PingStatus) -> some View {
        switch status {
        case .active:
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 6, height: 6)
                Text("Menunggu pedagang")
                    .font(.system(size: 11))
            }
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appSurfaceBlue)
            .clipShape(Capsule())
        case .onTheWay:
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 6, height: 6)
                Text("Pedagang menuju ke sini")
                    .font(.system(size: 11))
            }
            .foregroundColor(.appSuccess)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appSuccessBg)
            .clipShape(Capsule())
        default:
            EmptyView()
        }
    }
}
