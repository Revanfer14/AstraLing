//
//  KelolaMenuView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI

private struct EditableMenuItem: Identifiable {
    let id = UUID()
    var name: String
    var price: String
    var available: Bool
    let photoColor: Color
}

struct KelolaMenuView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var items: [EditableMenuItem] = [
        EditableMenuItem(name: "Martabak Keju",        price: "18.000", available: true,  photoColor: Color(red: 0.847, green: 0.710, blue: 0.455)),
        EditableMenuItem(name: "Martabak Kacang Keju", price: "20.000", available: true,  photoColor: Color(red: 0.459, green: 0.302, blue: 0.149)),
        EditableMenuItem(name: "Martabak Greentea",    price: "20.000", available: false, photoColor: Color(red: 0.396, green: 0.624, blue: 0.388)),
    ]

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

                    Text("MAKANAN")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextTertiary)
                        .tracking(0.3)

                    ForEach($items) { $item in
                        menuCard(item: $item)
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
    private func menuCard(item: Binding<EditableMenuItem>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 13) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(item.wrappedValue.photoColor)
                            .frame(width: 60, height: 60)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appPrimary)
                            .frame(width: 20, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 3, y: 3)
                }

                VStack(alignment: .leading, spacing: 11) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("NAMA MENU")
                            .font(.system(size: 10.5))
                            .foregroundStyle(labelColor)
                            .tracking(0.3)

                        HStack {
                            TextField("", text: item.name)
                                .font(.system(size: 15))
                                .foregroundStyle(darkText)
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(labelColor)
                        }
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(fieldBorder, lineWidth: 1)
                                )
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
                            TextField("", text: item.price)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 0.106, green: 0.310, blue: 0.878))
                                .keyboardType(.numberPad)
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(labelColor)
                        }
                        .frame(height: 38)
                        .padding(.horizontal, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .stroke(fieldBorder, lineWidth: 1)
                                )
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
                availabilityOption(label: "Tersedia", isSelected: item.wrappedValue.available) {
                    item.available.wrappedValue = true
                }
                availabilityOption(label: "Stok habis", isSelected: !item.wrappedValue.available, isDestructive: true) {
                    item.available.wrappedValue = false
                }
                Button {} label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(red: 0.91, green: 0.271, blue: 0.235))
                        .padding(10)
                        .frame(width: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.992, green: 0.925, blue: 0.922))
                        )
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
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(isSelected ? activeBg : greyBg)            )
        }
    }

    private var addMenuButton: some View {
        NavigationLink(destination: TambahMenuView().navigationBarBackButtonHidden(true)) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Tambah Menu Baru")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.appPrimaryPressed)
            )
        }
    }
}

#Preview {
    NavigationStack {
        KelolaMenuView()
    }
}
