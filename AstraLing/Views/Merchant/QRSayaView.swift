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
    @EnvironmentObject var merchantVM: MerchantViewModel

    @State private var showShareSheet = false
    @State private var savedToPhotos = false

    private var qrPayload: String {
        merchantVM.merchant?.qrPayload ?? "ASTRAPAY-MERCHANT-PLACEHOLDER"
    }

    private var qrImage: UIImage { generateQRCode(qrPayload) }

    private var brandedQRImage: UIImage {
        let qr = qrImage
        let name = merchantName
        let nmidText = "NMID : \(nmid)"
        let padding: CGFloat = 40
        let nameFont = UIFont.boldSystemFont(ofSize: 28)
        let nmidFont = UIFont.systemFont(ofSize: 14)
        let nameAttr: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: UIColor.black]
        let nmidAttr: [NSAttributedString.Key: Any] = [.font: nmidFont, .foregroundColor: UIColor.gray]
        let nameSize = (name as NSString).size(withAttributes: nameAttr)
        let nmidSize = (nmidText as NSString).size(withAttributes: nmidAttr)
        let qrSide = qr.size.width
        let totalWidth = qrSide + padding * 2
        let totalHeight = padding + nameSize.height + 8 + nmidSize.height + 24 + qrSide + padding
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: CGSize(width: totalWidth, height: totalHeight)))
            var y = padding
            (name as NSString).draw(
                in: CGRect(x: (totalWidth - nameSize.width) / 2, y: y, width: nameSize.width, height: nameSize.height),
                withAttributes: nameAttr)
            y += nameSize.height + 8
            (nmidText as NSString).draw(
                in: CGRect(x: (totalWidth - nmidSize.width) / 2, y: y, width: nmidSize.width, height: nmidSize.height),
                withAttributes: nmidAttr)
            y += nmidSize.height + 24
            qr.draw(in: CGRect(x: padding, y: y, width: qrSide, height: qrSide))
        }
    }

    private var merchantName: String {
        merchantVM.merchant?.name ?? "Merchant"
    }

    private var nmid: String {
        "ID\(String((merchantVM.uid ?? "").prefix(13)).uppercased())"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
                .padding(.top, 8)

            qrCard

            actionRow
                .padding(.top, 4)

            if savedToPhotos {
                Text("QR berhasil disimpan ke Foto")
                    .font(.app(.s14))
                    .foregroundStyle(Color.appSuccess)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            QRShareSheet(image: brandedQRImage)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 0.063, green: 0.133, blue: 0.314).opacity(0.1), radius: 9, x: 0, y: 6)
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appTextPrimary)
                        .font(.app(.s16, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("QR Saya")
                    .font(.app(.s18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Tunjukkan ke customer untuk membayar")
                    .font(.app(.s12))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
    }

    private var qrCard: some View {
        VStack(spacing: 3) {
            Text(merchantName)
                .font(.app(.s24, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("NMID : \(nmid)")
                .font(.app(.s12))
                .foregroundStyle(Color.appTextTertiary)
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
                        .stroke(Color.appDivider, lineWidth: 1)
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
            Button {
                UIImageWriteToSavedPhotosAlbum(brandedQRImage, nil, nil, nil)
                withAnimation { savedToPhotos = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { savedToPhotos = false }
                }
            } label: {
                Label("Simpan", systemImage: "square.and.arrow.down")
                    .font(.app(.s16, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.Token.blue100)
                    )
            }

            Button { showShareSheet = true } label: {
                Label("Bagikan", systemImage: "square.and.arrow.up")
                    .font(.app(.s16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.appPrimary)
                    )
            }
        }
    }
}

private struct QRShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        QRSayaView()
            .environmentObject(MerchantViewModel())
    }
}
