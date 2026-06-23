//
//  QRSayaView.swift
//  AstraLing
//
//  Created by Rasya Devan on 23/06/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

private func generateQRCode(_ string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "H"
    if let output = filter.outputImage {
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cgImage)
        }
    }
    return UIImage()
}

struct QRSayaView: View {
    @Environment(\.dismiss) private var dismiss

    private let qrImage = generateQRCode("ASTRAPAY-MERCHANT-ID1024896745213-A01")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
                .padding(.top, 8)

            qrCard

            actionRow
                .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.988, green: 0.988, blue: 0.988))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color(red: 0.055, green: 0.09, blue: 0.149))
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("QR Saya")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                Text("Tunjukkan ke customer untuk membayar")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
            }
        }
    }

    private var qrCard: some View {
        VStack(spacing: 3) {
            Text("Martabak Bang Jarwo")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("NMID : ID1024896745213 · A01")
                .font(.system(size: 11.5))
                .foregroundStyle(Color(red: 0.557, green: 0.557, blue: 0.576))
                .frame(maxWidth: .infinity, alignment: .center)

            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 19)
                .padding(.top, 32)
                .padding(.bottom, 19)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.941, green: 0.941, blue: 0.941), lineWidth: 1)
                )

            Color.clear.frame(height: 24)
                .padding(.top, 12)
        }
        .padding(.horizontal, 22)
        .padding(.top, 32)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 15, x: 0, y: 10)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 16) {
            Button {} label: {
                Label("Simpan", systemImage: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.839, green: 0.914, blue: 1))
                    )
            }

            Button {} label: {
                Label("Bagikan", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0, green: 0.271, blue: 0.898))
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        QRSayaView()
    }
}
