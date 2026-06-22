//
//  RoleSelectionView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var selectedRoleRaw: String

    #if DEBUG
    @State private var isSeeding = false
    @State private var seedDone = false
    #endif

    var body: some View {
        VStack(spacing: 24) {
            Text("AstraLing").font(.largeTitle.bold())
            Text("Pilih role").foregroundStyle(.secondary)

            VStack {
                Button {
                    selectedRoleRaw = AppRole.customer.rawValue
                } label: {
                    Text("Customer")
                        .padding()
                        .bold()
                }
                .frame(width: 200, height: 60)
                .background(Color.blue)
                .foregroundStyle(Color.white)
                .cornerRadius(12)

                Button {
                    selectedRoleRaw = AppRole.merchant.rawValue
                } label: {
                    Text("Merchant")
                        .padding()
                        .bold()
                }
                .frame(width: 200, height: 60)
                .background(Color.red)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            }

            #if DEBUG
            seederSection
            #endif
        }
    }

    #if DEBUG
    private var seederSection: some View {
        VStack(spacing: 8) {
            Button {
                guard !isSeeding else { return }
                isSeeding = true
                seedDone = false
                Task {
                    await MockDataSeeder().seedAll()
                    isSeeding = false
                    seedDone = true
                }
            } label: {
                Group {
                    if isSeeding {
                        ProgressView().tint(.white)
                    } else {
                        Text(seedDone ? "Seeded!" : "Seed Mock Data")
                            .bold()
                    }
                }
                .frame(width: 160, height: 36)
            }
            .frame(width: 200, height: 44)
            .background(Color.orange)
            .foregroundStyle(Color.white)
            .cornerRadius(8)
            .disabled(isSeeding)

            if seedDone {
                Text("Check Xcode console for credentials")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
    #endif
}

#Preview {
    RoleSelectionView(selectedRoleRaw: .constant(""))
}
