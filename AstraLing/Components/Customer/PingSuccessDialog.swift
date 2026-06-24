//
//  PingSuccessDialog.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct PingSuccessDialog: View {
    let onMonitor: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image("paper_airplane")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)

                    VStack(spacing: 10) {
                        Text("Ping terkirim! 👋🏻")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Pedagang sudah menerima sinyal bahwa kamu akan mampir. Temui langsung untuk bertransaksi.")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 16) {
                    Button(action: onMonitor) {
                        Text("Pantau di peta")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    Button(action: onCancel) {
                        Text("Batalkan Ping")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appError)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.appErrorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
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
