//
//  EditProfilView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct EditProfilView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var merchantVM: MerchantViewModel

    @State private var merchantName = ""
    @State private var descriptionText = ""
    @State private var selectedBannerImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showSavedToast = false

    private let maxNameLength = 40
    private let dividerColor = Color(red: 0.925, green: 0.933, blue: 0.945)
    private let labelColor   = Color(red: 0.58,  green: 0.627, blue: 0.702)
    private let darkText     = Color.appTextPrimary
    private let primaryBlue  = Color.appPrimary

    private var hasPhoto: Bool {
        selectedBannerImage != nil || merchantVM.merchant?.bannerUrl != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerRow
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        profilePhotoSection
                            .padding(.top, 24)

                        Text("Nama merchant")
                            .font(.system(size: 12.5))
                            .foregroundStyle(labelColor)
                            .padding(.horizontal, 20)
                            .padding(.top, 28)

                        nameField

                        Text("Deskripsi singkat")
                            .font(.system(size: 12.5))
                            .foregroundStyle(labelColor)
                            .padding(.horizontal, 20)
                            .padding(.top, 28)

                        descriptionField

                        HStack {
                            Text("Menu Toko")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(darkText)
                            Spacer()
                            NavigationLink(destination: KelolaMenuView().navigationBarBackButtonHidden(true).environmentObject(merchantVM)) {
                                Label("Ubah Menu & Harga", systemImage: "square.and.pencil")
                                    .font(.system(size: 14))
                                    .foregroundStyle(primaryBlue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 36)

                        ForEach(merchantVM.menuItems) { item in
                            menuRow(item)
                        }

                        Spacer().frame(height: 32)
                    }
                }

                saveButton
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                if let merchant = merchantVM.merchant {
                    merchantName = merchant.name
                    descriptionText = merchant.description ?? ""
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedBannerImage)
            }

            if showSavedToast {
                savedToast
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: showSavedToast)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color(red: 0.965, green: 0.969, blue: 0.976))
                        .frame(width: 42, height: 42)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(darkText)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            Text("Edit Profil")
                .font(.system(size: 18))
                .foregroundStyle(darkText)
        }
    }

    private var profilePhotoSection: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    Button { showImagePicker = true } label: {
                        Group {
                            if let selected = selectedBannerImage {
                                Image(uiImage: selected)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 169, height: 94)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                            } else if let url = merchantVM.merchant?.bannerUrl,
                                      let parsed = URL(string: url) {
                                AsyncImage(url: parsed) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                            .frame(width: 169, height: 94)
                                            .clipShape(RoundedRectangle(cornerRadius: 22))
                                    default:
                                        placeholderBanner
                                    }
                                }
                            } else {
                                placeholderBanner
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(primaryBlue)
                            .frame(width: 32, height: 32)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 3))
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
                }

                if hasPhoto {
                    Button {
                        if selectedBannerImage != nil {
                            selectedBannerImage = nil
                        } else {
                            Task { await merchantVM.deleteBanner() }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.91, green: 0.271, blue: 0.235))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .offset(x: 4, y: -4)
                }
            }

            Text(hasPhoto ? "Ketuk foto untuk ganti · X untuk hapus" : "Ketuk untuk tambah foto toko")
                .font(.system(size: 12.5))
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholderBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.847, green: 0.710, blue: 0.455))
                .frame(width: 169, height: 94)
            Image(systemName: "fork.knife")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var nameField: some View {
        HStack {
            TextField("", text: $merchantName)
                .font(.system(size: 16))
                .foregroundStyle(darkText)
                .onChange(of: merchantName) { _, newValue in
                    if newValue.count > maxNameLength {
                        merchantName = String(newValue.prefix(maxNameLength))
                    }
                }
            Text("\(merchantName.count)/\(maxNameLength)")
                .font(.system(size: 11.5))
                .foregroundStyle(labelColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .overlay(Rectangle().fill(dividerColor).frame(height: 1), alignment: .bottom)
    }

    private var descriptionField: some View {
        TextField("", text: $descriptionText, axis: .vertical)
            .font(.system(size: 15))
            .foregroundStyle(Color(red: 0.278, green: 0.333, blue: 0.412))
            .lineSpacing(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .overlay(Rectangle().fill(dividerColor).frame(height: 1), alignment: .bottom)
    }

    private var menuPhotoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.847, green: 0.710, blue: 0.455))
                .frame(width: 44, height: 44)
            Image(systemName: "fork.knife")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func menuRow(_ item: MenuItem) -> some View {
        HStack(spacing: 13) {
            Group {
                if let urlStr = item.photoUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        default:
                            menuPhotoPlaceholder
                        }
                    }
                } else {
                    menuPhotoPlaceholder
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14.5))
                    .foregroundStyle(darkText)
                Text(item.price.rupiah)
                    .font(.system(size: 13))
                    .foregroundStyle(labelColor)
            }
            Spacer()
            Text(item.status == .tersedia ? "Tersedia" : "Stok habis")
                .font(.system(size: 11))
                .foregroundStyle(
                    item.status == .tersedia
                        ? Color(red: 0.098, green: 0.702, blue: 0.42)
                        : Color(red: 0.91, green: 0.271, blue: 0.235)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var saveButton: some View {
        Button {
            Task {
                await merchantVM.saveProfile(
                    name: merchantName,
                    description: descriptionText,
                    bannerImage: selectedBannerImage
                )
                if merchantVM.errorMessage == nil {
                    withAnimation { showSavedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showSavedToast = false }
                    }
                }
            }
        } label: {
            Group {
                if merchantVM.isSaving {
                    ProgressView().progressViewStyle(.circular).tint(.white)
                } else {
                    Label("Simpan Profil", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 300)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20).fill(primaryBlue))
        }
        .disabled(merchantVM.isSaving)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var savedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
                .font(.system(size: 16))
            Text("Profil berhasil disimpan")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(
            Capsule().fill(Color.appSuccess)
                .shadow(color: Color.appSuccess.opacity(0.35), radius: 12, x: 0, y: 6)
        )
    }
}

#Preview {
    NavigationStack {
        EditProfilView()
            .environmentObject(MerchantViewModel())
    }
}
