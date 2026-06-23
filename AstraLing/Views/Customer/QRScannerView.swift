//
//  QRScannerView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import AVFoundation
import SwiftUI

private struct ScannedPayload: Identifiable {
    let id = UUID()
    let merchantUid: String
    let rawPayload: String
}

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = QRScannerService()
    @State private var animateLine = false
    @State private var scannedItem: ScannedPayload?

    private let scanWindowSize: CGFloat = 280

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if scanner.authorizationStatus == .authorized {
                CameraPreviewView(session: scanner.session)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                scanWindow
                Spacer()
                footer
            }

            VStack {
                HStack {
                    Spacer()
                    actionButtons
                        .padding(.top, 8)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            .padding(.top, 56 + 16)
        }
        .onAppear {
            scanner.requestAccess()
            scanner.configureSession()
            scanner.start()
            animateLine = true
        }
        .onDisappear {
            scanner.stop()
        }
        .onChange(of: scanner.scannedPayload) { _, payload in
            guard let payload else { return }
            let prefix = "astraling://pay/"
            let uid = payload.hasPrefix(prefix)
                ? String(payload.dropFirst(prefix.count))
                : payload
            scannedItem = ScannedPayload(merchantUid: uid, rawPayload: payload)
        }
        .fullScreenCover(item: $scannedItem, onDismiss: {
            scanner.scannedPayload = nil
            scanner.start()
        }) { item in
            PaymentView(
                merchantUid: item.merchantUid,
                rawPayload: item.rawPayload,
                onFinish: { dismiss() }
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Scan")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    private var scanWindow: some View {
        ZStack(alignment: .top) {
            Canvas { context, size in
                let bracketLen: CGFloat = 30
                let stroke = CGFloat(3.5)
                let color = Color.white

                var tl = Path()
                tl.move(to: CGPoint(x: 0, y: bracketLen))
                tl.addLine(to: CGPoint(x: 0, y: 0))
                tl.addLine(to: CGPoint(x: bracketLen, y: 0))
                context.stroke(tl, with: .color(color),
                               style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))

                var tr = Path()
                tr.move(to: CGPoint(x: size.width - bracketLen, y: 0))
                tr.addLine(to: CGPoint(x: size.width, y: 0))
                tr.addLine(to: CGPoint(x: size.width, y: bracketLen))
                context.stroke(tr, with: .color(color),
                               style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))

                var bl = Path()
                bl.move(to: CGPoint(x: 0, y: size.height - bracketLen))
                bl.addLine(to: CGPoint(x: 0, y: size.height))
                bl.addLine(to: CGPoint(x: bracketLen, y: size.height))
                context.stroke(bl, with: .color(color),
                               style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))

                var br = Path()
                br.move(to: CGPoint(x: size.width - bracketLen, y: size.height))
                br.addLine(to: CGPoint(x: size.width, y: size.height))
                br.addLine(to: CGPoint(x: size.width, y: size.height - bracketLen))
                context.stroke(br, with: .color(color),
                               style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round))
            }
            .frame(width: scanWindowSize, height: scanWindowSize)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.1), Color.cyan, Color.cyan.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: scanWindowSize, height: 2.5)
                .shadow(color: Color.cyan.opacity(0.9), radius: 6, y: 0)
                .offset(y: animateLine ? scanWindowSize - 2.5 : 0)
                .animation(.linear(duration: 1.8).repeatForever(autoreverses: true), value: animateLine)
        }
        .frame(width: scanWindowSize, height: scanWindowSize)
        .clipped()
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                scanner.toggleTorch()
            } label: {
                Image(systemName: scanner.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Button {} label: {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("Astrapay mendukung")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Image("qris")
                .resizable()
                .scaledToFit()
                .frame(height: 26)
        }
        .padding(.bottom, 48)
    }
}

#Preview {
    QRScannerView()
}
