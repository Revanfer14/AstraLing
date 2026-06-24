//
//  PingChatSheet.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import SwiftUI

struct PingChatSheet: View {
    let merchant: NearbyMerchant
    let status: PingStatus
    let isFavorite: Bool
    var isMinimized: Bool = false
    let onBack: () -> Void
    let onToggleFavorite: () -> Void
    let onRequestCancel: () -> Void

    @StateObject private var vm = PingChatViewModel()
    @State private var draft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            if !isMinimized {
                statusSection
                if status == .onTheWay {
                    chatArea
                    inputArea
                } else {
                    waitingPlaceholder
                }
            }
        }
        .onAppear {
            if status == .onTheWay {
                vm.start(merchantUid: merchant.id, merchantName: merchant.name)
            }
        }
        .onChange(of: merchant.id) { _, newId in
            if status == .onTheWay {
                vm.start(merchantUid: newId, merchantName: merchant.name)
            } else {
                vm.stop()
            }
        }
        .onChange(of: status) { _, newStatus in
            if newStatus == .onTheWay {
                vm.start(merchantUid: merchant.id, merchantName: merchant.name)
            } else {
                vm.stop()
            }
        }
        .onDisappear { vm.stop() }
    }

    private var waitingPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "hourglass")
                .font(.system(size: 36))
                .foregroundColor(.appPrimary.opacity(0.4))
            Text("Chat akan terbuka setelah pedagang mengonfirmasi pingmu")
                .font(.system(size: 14))
                .foregroundColor(.appTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurfaceBlue)
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Spacer()

                Menu {
                    Button {
                        onToggleFavorite()
                    } label: {
                        Label(
                            isFavorite ? "Hapus dari favorit" : "Tambah ke favorit",
                            systemImage: isFavorite ? "heart.fill" : "heart"
                        )
                    }
                    Button(role: .destructive) {
                        onRequestCancel()
                    } label: {
                        Label("Batalkan Ping", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .frame(width: 46, height: 46)
                        .background(Color.appSurfaceBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var statusSection: some View {
        VStack(spacing: 10) {
            statusPill

            if !merchant.distanceLabel.isEmpty || !merchant.walkLabel.isEmpty {
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
            }

            Text(subtitleText)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusPill: some View {
        switch status {
        case .active:
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.appTextTertiary)
                    .frame(width: 10, height: 10)
                Text("Menunggu konfirmasi")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSurfaceMuted)
            .clipShape(Capsule())
        case .onTheWay:
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 10, height: 10)
                Text("Ping Aktif")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appSuccess)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSuccessBg)
            .clipShape(Capsule())
        default:
            EmptyView()
        }
    }

    private var subtitleText: String {
        switch status {
        case .active:
            return "Menunggu pedagang mengonfirmasi pingmu…"
        case .onTheWay:
            return "Pedagang sudah menerima sinyal dan akan bergerak menuju tempatmu. Temui langsung untuk bertransaksi."
        default:
            return ""
        }
    }

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 18) {
                    if !vm.messages.isEmpty {
                        HStack {
                            Spacer()
                            Text("Hari ini")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "94A0B3"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            Spacer()
                        }
                    }

                    ForEach(vm.messages) { item in
                        messageBubble(item)
                            .id(item.id)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .background(Color.appSurfaceBlue)
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func messageBubble(_ item: ChatMessageItem) -> some View {
        if item.isMine {
            HStack {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.text)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    if let time = item.time {
                        Text(time.timeLabelID)
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appPrimaryPressed)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 15,
                        bottomTrailingRadius: 5,
                        topTrailingRadius: 15
                    )
                )
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.text)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0E1726"))
                        .multilineTextAlignment(.leading)
                    if let time = item.time {
                        Text(time.timeLabelID)
                            .font(.system(size: 9.5))
                            .foregroundColor(Color(hex: "0E1726").opacity(0.6))
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .background(Color.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 5,
                        bottomTrailingRadius: 15,
                        topTrailingRadius: 15
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 5,
                        bottomTrailingRadius: 15,
                        topTrailingRadius: 15
                    )
                    .stroke(Color(hex: "EEF1F6"), lineWidth: 1)
                )
                Spacer(minLength: 60)
            }
        }
    }

    private var inputArea: some View {
        VStack(spacing: 11) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Sudah sampai", "Sebentar lagi", "Pesanan siap"], id: \.self) { chip in
                        Button {
                            vm.send(chip)
                        } label: {
                            Text(chip)
                                .font(.system(size: 13))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.appSurfaceBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal, 18)
            }

            HStack(spacing: 9) {
                TextField("Tulis pesan ke \(merchant.name)…", text: $draft)
                    .font(.system(size: 13.5))
                    .foregroundColor(.appTextPrimary)

                Button {
                    vm.send(draft)
                    draft = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.leading, 15)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(Color(hex: "F6FBFF"))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal, 18)
        }
        .padding(.top, 13)
        .padding(.bottom, 24)
        .background(Color.appSurface)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
