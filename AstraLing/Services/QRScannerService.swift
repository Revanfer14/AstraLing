//
//  QRScannerService.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

@preconcurrency import AVFoundation
import Combine

@MainActor
final class QRScannerService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus
    @Published var scannedPayload: String?
    @Published var isTorchOn = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "qr.session.queue", qos: .userInitiated)
    private var isSessionConfigured = false

    override init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        super.init()
    }

    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
            }
        }
    }

    func configureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true
        let captureSession = session
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else { return }
            captureSession.beginConfiguration()
            captureSession.addInput(input)
            let output = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
            }
            captureSession.commitConfiguration()
        }
    }

    func start() {
        let captureSession = session
        sessionQueue.async {
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    func stop() {
        let captureSession = session
        sessionQueue.async {
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        isTorchOn.toggle()
        device.torchMode = isTorchOn ? .on : .off
        device.unlockForConfiguration()
    }
}

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let string = obj.stringValue else { return }
        Task { @MainActor in
            self.scannedPayload = string
            self.stop()
        }
    }
}
