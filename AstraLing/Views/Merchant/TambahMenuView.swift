//
//  TambahMenuView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI
import PhotosUI

struct TambahMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var merchantVM: MerchantViewModel

    @State private var name: String = ""
    @State private var priceText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhoto: UIImage? = nil
    @FocusState private var priceFocused: Bool

    private let labelColor = Color.appTextSecondary
    private let fieldBg    = Color.appBackground
    private let greyText   = Color.appTextTertiary
    private let darkText   = Color.appTextPrimary
    private let primaryBlue = Color.appPrimary

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                photoSection

                fieldBlock(label: "Nama menu") {
                    TextField("Contoh: Martabak Susu", text: $name)
                        .font(.app(.s16))
                        .foregroundStyle(darkText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(fieldBg)
                                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                }

                fieldBlock(label: "Harga") {
                    HStack(spacing: 4) {
                        Text("Rp")
                            .font(.app(.s16))
                            .foregroundStyle(greyText)
                        TextField("0", text: $priceText)
                            .focused($priceFocused)
                            .font(.app(.s16))
                            .foregroundStyle(darkText)
                            .keyboardType(.numberPad)
                            .onChange(of: priceText) { _, newValue in
                                priceText = String(newValue.filter { $0.isNumber }.prefix(10))
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(fieldBg)
                            .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
                    )
                    .onTapGesture { priceFocused = true }
                }

                Button {
                    let price = Int(priceText) ?? 0
                    guard !name.isEmpty, price > 0 else { return }
                    Task {
                        await merchantVM.addMenuItem(name: name, price: price, image: selectedPhoto)
                        if merchantVM.errorMessage == nil {
                            Haptics.success()
                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if merchantVM.isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Label("Simpan Menu", systemImage: "square.and.arrow.down")
                                .font(.app(.s16, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(name.isEmpty || priceText.isEmpty ? Color.appPrimaryPressed.opacity(0.5) : Color.appPrimaryPressed)
                    )
                }
                .disabled(name.isEmpty || priceText.isEmpty || merchantVM.isSaving)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .background(fieldBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onTapGesture { priceFocused = false }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedPhoto = image
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(fieldBg)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(darkText)
                        .font(.app(.s16, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Tambah Menu Baru")
                    .font(.app(.s18))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Lengkapi detail menu")
                    .font(.app(.s12))
                    .foregroundStyle(greyText)
            }
        }
    }

    private var photoSection: some View {
        VStack(spacing: 5) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let photo = selectedPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.Token.blue100)
                                    .frame(width: 96, height: 96)
                                Image(systemName: "photo")
                                    .font(.app(.s28))
                                    .foregroundStyle(primaryBlue.opacity(0.4))
                            }
                        }
                    }
                    ZStack {
                        Circle()
                            .fill(primaryBlue)
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        Image(systemName: "plus")
                            .font(.app(.s14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }

            Text("Tambahkan foto menu")
                .font(.app(.s12))
                .foregroundStyle(greyText)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.app(.s12))
                .foregroundStyle(labelColor)
            content()
        }
        .padding(.top, 20)
    }
}

#Preview {
    NavigationStack {
        TambahMenuView()
            .environmentObject(MerchantViewModel())
    }
}
