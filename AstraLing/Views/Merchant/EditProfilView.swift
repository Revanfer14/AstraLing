//
//  EditProfilView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

private struct MenuItemData: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let available: Bool
    let photoColor: Color
}

struct EditProfilView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var merchantName = "Martabak Bang Jarwo"
    @State private var descriptionText = "Bakso urat & telur homemade, kuah kaldu sapi asli.\nMangkal tiap sore di Perumahan Griya."

    private let maxNameLength = 40

    private let menuItems: [MenuItemData] = [
        MenuItemData(name: "Martabak Keju",       price: "Rp 18.000", available: true,  photoColor: Color(red: 0.847, green: 0.710, blue: 0.455)),
        MenuItemData(name: "Martabak Kacang Keju", price: "Rp 20.000", available: true,  photoColor: Color(red: 0.459, green: 0.302, blue: 0.149)),
        MenuItemData(name: "Martabak Greentea",    price: "Rp 10.000", available: false, photoColor: Color(red: 0.396, green: 0.624, blue: 0.388)),
    ]

    private let dividerColor = Color(red: 0.925, green: 0.933, blue: 0.945)
    private let labelColor   = Color(red: 0.58,  green: 0.627, blue: 0.702)
    private let darkText     = Color(red: 0.055, green: 0.09,  blue: 0.149)
    private let primaryBlue  = Color(red: 0,     green: 0.271, blue: 0.898)

    var body: some View {
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
                        Button {} label: {
                            Label("Ubah Menu & Harga", systemImage: "square.and.pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(primaryBlue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 36)

                    ForEach(menuItems) { item in
                        menuRow(item)
                    }

                    Spacer().frame(height: 32)
                }
            }

            saveButton
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
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
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 47)
                        .fill(Color(red: 0.847, green: 0.710, blue: 0.455))
                        .frame(width: 93, height: 94)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.8))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(primaryBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 3)
                        )
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                .offset(x: 4, y: 4)
            }

            Text("Ketuk untuk ganti foto toko")
                .font(.system(size: 12.5))
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity)
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
        .overlay(
            Rectangle().fill(dividerColor).frame(height: 1),
            alignment: .bottom
        )
    }

    private var descriptionField: some View {
        TextField("", text: $descriptionText, axis: .vertical)
            .font(.system(size: 15))
            .foregroundStyle(Color(red: 0.278, green: 0.333, blue: 0.412))
            .lineSpacing(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .overlay(
                Rectangle().fill(dividerColor).frame(height: 1),
                alignment: .bottom
            )
    }

    private func menuRow(_ item: MenuItemData) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.photoColor)
                    .frame(width: 44, height: 44)
                Image(systemName: "fork.knife")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14.5))
                    .foregroundStyle(darkText)
                Text(item.price)
                    .font(.system(size: 13))
                    .foregroundStyle(labelColor)
            }
            Spacer()
            Text(item.available ? "Tersedia" : "Stok habis")
                .font(.system(size: 11))
                .foregroundStyle(
                    item.available
                        ? Color(red: 0.098, green: 0.702, blue: 0.42)
                        : Color(red: 0.91, green: 0.271, blue: 0.235)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var saveButton: some View {
        Button {} label: {
            Label("Simpan Profil", systemImage: "square.and.arrow.down")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 300)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(primaryBlue)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

#Preview {
    NavigationStack {
        EditProfilView()
    }
}
