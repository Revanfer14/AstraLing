//
//  CancelPingDialog.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import SwiftUI

struct CancelPingDialog: View {
    let onCancelPing: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image("batalkanping")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)

                    VStack(spacing: 10) {
                        Text("Yakin ingin membatalkan Ping? 🙁")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.appError)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Pedagang sudah menerima Ping kamu. Jika berubah pikiran, kamu tetap bisa membatalkannya sekarang.")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 16) {
                    Button(action: onCancelPing) {
                        Text("Batalkan Ping")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.appError)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    Button(action: onContinue) {
                        Text("Lanjutkan Ping")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.appSurfaceBlue)
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
