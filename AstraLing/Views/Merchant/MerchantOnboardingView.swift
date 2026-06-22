//
//  MerchantOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct MerchantOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundStyle(Color.primary)
                }
                Spacer()
                Text("Statistics Dashboard")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding()

            Spacer()
            Text("Merchant statistics will appear here")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

#Preview {
    MerchantOnboardingView()
}
