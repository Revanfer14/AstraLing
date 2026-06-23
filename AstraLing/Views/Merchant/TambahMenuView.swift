//
//  TambahMenuView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

struct TambahMenuView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var priceText: String = ""
    @State private var selectedCategory: String = ""
    @FocusState private var priceFocused: Bool

    private let categories = ["Makanan", "Minuman", "Camilan", "Dessert"]

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
                        .font(.system(size: 15))
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
                            .font(.system(size: 15))
                            .foregroundStyle(greyText)
                        TextField("0", text: $priceText)
                            .focused($priceFocused)
                            .font(.system(size: 15))
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

                fieldBlock(label: "Kategori") {
                    Menu {
                        ForEach(categories, id: \.self) { cat in
                            Button(cat) { selectedCategory = cat }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory.isEmpty ? "Pilih kategori" : selectedCategory)
                                .font(.system(size: 15))
                                .foregroundStyle(selectedCategory.isEmpty ? greyText : darkText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundStyle(greyText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(fieldBg)
                                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                    }
                }

                Button {} label: {
                    Label("Simpan Menu", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.appPrimaryPressed)
                        )
                }
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .background(fieldBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onTapGesture { priceFocused = false }
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
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Tambah Menu Baru")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Lengkapi detail menu")
                    .font(.system(size: 12))
                    .foregroundStyle(greyText)
            }
        }
    }

    private var photoSection: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.Token.blue100)
                        .frame(width: 96, height: 96)
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(primaryBlue.opacity(0.4))
                }
                ZStack {
                    Circle()
                        .fill(primaryBlue)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 4, y: 4)
            }

            Text("Tambahkan foto menu")
                .font(.system(size: 12))
                .foregroundStyle(greyText)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(labelColor)
            content()
        }
        .padding(.top, 20)
    }
}

#Preview {
    NavigationStack {
        TambahMenuView()
    }
}
