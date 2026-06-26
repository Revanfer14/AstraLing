//
//  PingCancelledDialog.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 27/06/26.
//

import SwiftUI

struct PingCancelledDialog: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Ping dibatalkan 🙁")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    Image("pingdibatalin")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)

                    Text("Sayang sekali, pelanggan membatalkan pingnya.")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button(action: onDismiss) {
                    Text("Mengerti")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 26)
        }
    }
}
