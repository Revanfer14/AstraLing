//
//  KelolaMenuView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct KelolaMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var merchantVM: MerchantViewModel

    @State private var editedNames: [String: String] = [:]
    @State private var editedPrices: [String: String] = [:]
    @State private var photoPickingId: String? = nil
    @State private var pendingUploadId: String? = nil
    @State private var pickedImage: UIImage? = nil
    @State private var debounceWork: [String: DispatchWorkItem] = [:]

    private let labelColor  = Color(red: 0.58,  green: 0.627, blue: 0.702)
    private let darkText    = Color.appTextPrimary
    private let fieldBorder = Color(red: 0.906, green: 0.918, blue: 0.937)
    private let greenColor  = Color(red: 0.098, green: 0.702, blue: 0.42)
    private let greenBg     = Color.appSuccessBg
    private let greyBg      = Color(red: 0.957, green: 0.965, blue: 0.973)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    headerRow
                        .padding(.top, 2)
                        .padding(.bottom, 4)

                    if !merchantVM.menuItems.isEmpty {
                        Text("MAKANAN")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextTertiary)
                            .tracking(0.3)
                    }

                    ForEach(merchantVM.menuItems) { item in
                        menuCard(item: item)
                    }

                    Spacer().frame(height: 16)
                }
                .padding(.horizontal, 16)
            }

            addMenuButton
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { initLocalState() }
        .onChange(of: merchantVM.menuItems) { _, items in
            for item in items {
                guard let id = item.id else { continue }
                if editedNames[id] == nil { editedNames[id] = item.name }
                if editedPrices[id] == nil { editedPrices[id] = "\(item.price)" }
            }
        }
        .sheet(isPresented: Binding(
            get: { photoPickingId != nil },
            set: { if !$0 { photoPickingId = nil } }
        )) {
            ImagePickerView(image: $pickedImage)
        }
        .onChange(of: pickedImage) { _, image in
            guard let image, let id = pendingUploadId else { return }
            pendingUploadId = nil
            pickedImage = nil
            Task { await merchantVM.uploadMenuItemPhoto(id: id, image: image) }
        }
    }

    private func initLocalState() {
        for item in merchantVM.menuItems {
            guard let id = item.id else { continue }
            editedNames[id] = item.name
            editedPrices[id] = "\(item.price)"
        }
    }

    private func scheduleAutoSave(id: String) {
        debounceWork[id]?.cancel()
        let work = DispatchWorkItem {
            Task { @MainActor in
                let name = self.editedNames[id] ?? ""
                let price = Int(self.editedPrices[id] ?? "") ?? 0
                guard !name.isEmpty else { return }
                await self.merchantVM.updateMenuItem(id: id, name: name, price: price)
            }
        }
        debounceWork[id] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(darkText)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Kelola Menu & Harga")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Atur menu, harga, dan ketersediaan")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
    }

    @ViewBuilder
    private func menuCard(item: MenuItem) -> some View {
        let id = item.id ?? ""
        let nameBinding = Binding(
            get: { editedNames[id] ?? item.name },
            set: { editedNames[id] = $0; scheduleAutoSave(id: id) }
        )
        let priceBinding = Binding(
            get: { editedPrices[id] ?? "\(item.price)" },
            set: {
                editedPrices[id] = String($0.filter { $0.isNumber }.prefix(10))
                scheduleAutoSave(id: id)
            }
        )

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 13) {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        Button {
                            pendingUploadId = id
                            photoPickingId = id
                        } label: {
                            Group {
                                if let urlStr = item.photoUrl, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                        default:
                                            photoPlaceholder
                                        }
                                    }
                                } else {
                                    photoPlaceholder
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appPrimary)
                                .frame(width: 20, height: 20)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
                            Image(systemName: "camera.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 3, y: 3)
                    }

                    if item.photoUrl != nil {
                        Button {
                            Task { await merchantVM.deleteMenuItemPhoto(id: id) }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.91, green: 0.271, blue: 0.235))
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                Image(systemName: "xmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .offset(x: 3, y: -3)
                    }
                }

                VStack(alignment: .leading, spacing: 11) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NAMA MENU")
                            .font(.system(size: 10.5))
                            .foregroundStyle(labelColor)
                            .tracking(0.3)

                        HStack {
                            TextField("", text: nameBinding)
                                .font(.system(size: 15))
                                .foregroundStyle(darkText)
                                .onSubmit { scheduleAutoSave(id: id) }
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(labelColor)
                        }
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(fieldBorder, lineWidth: 1))
                        )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("HARGA")
                            .font(.system(size: 10.5))
                            .foregroundStyle(labelColor)
                            .tracking(0.3)

                        HStack(spacing: 2) {
                            Text("Rp")
                                .font(.system(size: 15))
                                .foregroundStyle(labelColor)
                            TextField("", text: priceBinding)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 0.106, green: 0.310, blue: 0.878))
                                .keyboardType(.numberPad)
                                .onSubmit { scheduleAutoSave(id: id) }
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(labelColor)
                        }
                        .frame(height: 38)
                        .padding(.horizontal, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(fieldBorder, lineWidth: 1))
                        )
                    }
                }
            }

            Text("STATUS KETERSEDIAAN")
                .font(.system(size: 10.5))
                .foregroundStyle(labelColor)
                .tracking(0.3)
                .padding(.top, 7)

            HStack(spacing: 8) {
                availabilityOption(label: "Tersedia", isSelected: item.status == .tersedia) {
                    Task { await merchantVM.setMenuItemStatus(id: id, status: .tersedia) }
                }
                availabilityOption(label: "Stok habis", isSelected: item.status == .habis, isDestructive: true) {
                    Task { await merchantVM.setMenuItemStatus(id: id, status: .habis) }
                }
                Button {
                    Task { await merchantVM.deleteMenuItem(id: id) }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(red: 0.91, green: 0.271, blue: 0.235))
                        .padding(10)
                        .frame(width: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.992, green: 0.925, blue: 0.922)))
                }
                .frame(width: 48)
            }
            .padding(.bottom, 7)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var photoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.847, green: 0.710, blue: 0.455))
                .frame(width: 60, height: 60)
            Image(systemName: "fork.knife")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private func availabilityOption(label: String, isSelected: Bool, isDestructive: Bool = false, onTap: @escaping () -> Void) -> some View {
        let activeColor = isDestructive ? Color(red: 0.91, green: 0.271, blue: 0.235) : greenColor
        let activeBg = isDestructive ? Color(red: 0.992, green: 0.925, blue: 0.922) : greenBg

        Button(action: onTap) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(activeColor)
                }
                Text(label)
                    .font(.system(size: 12.5))
                    .foregroundStyle(isSelected ? activeColor : labelColor)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 11).fill(isSelected ? activeBg : greyBg))
        }
    }

    private var addMenuButton: some View {
        NavigationLink(destination: TambahMenuView().navigationBarBackButtonHidden(true).environmentObject(merchantVM)) {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                Text("Tambah Menu Baru").font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 50).fill(Color.appPrimaryPressed))
        }
    }
}

#Preview {
    NavigationStack {
        KelolaMenuView()
            .environmentObject(MerchantViewModel())
    }
}
