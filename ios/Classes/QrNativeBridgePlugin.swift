//
//  QrNativeBridgePlugin.swift
//
//  Created by Kalebe Misael on 19/02/26.
//

import Flutter
import UIKit
import AVFoundation
import CoreImage

public class QrNativeBridgePlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "qr_native_bridge",
            binaryMessenger: registrar.messenger()
        )
        let instance = QrNativeBridgePlugin()
        channel.setMethodCallHandler(instance.handle)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "generateQr":
            guard
                let args = call.arguments as? [String: Any],
                let data = args["data"] as? String
            else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing data",
                    details: nil
                ))
                return
            }
            if let pngData = generateQrPng(from: data) {
                result(FlutterStandardTypedData(bytes: pngData))
            } else {
                result(FlutterError(
                    code: "QR_FAILED",
                    message: "Could not generate QR",
                    details: nil
                ))
            }

        case "scanQr":
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if authStatus == .denied || authStatus == .restricted {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Permissão de câmera negada",
                    details: nil
                ))
                return
            }
            if authStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.presentQrScanner(result: result)
                        } else {
                            result(FlutterError(
                                code: "PERMISSION_DENIED",
                                message: "Permissão de câmera negada",
                                details: nil
                            ))
                        }
                    }
                }
            } else {
                presentQrScanner(result: result)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - QR Code Generator

    private func generateQrPng(from string: String) -> Data? {
        guard
            let data = string.data(using: .utf8),
            let filter = CIFilter(name: "CIQRCodeGenerator")
        else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let scaledImage = ciImage.transformed(
            by: CGAffineTransform(scaleX: 10, y: 10)
        )

        let context = CIContext()
        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent
        ) else { return nil }

        return UIImage(cgImage: cgImage).pngData()
    }

    // MARK: - QR Code Scanner

    private func presentQrScanner(result: @escaping FlutterResult) {
        let rootViewController: UIViewController?
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            rootViewController = window.rootViewController
        } else {
            rootViewController = nil
        }

        guard let root = rootViewController else {
            result(FlutterError(
                code: "NO_ROOT_VC",
                message: "Root view controller not found",
                details: nil
            ))
            return
        }

        let scannerVC = QrScannerViewController()
        scannerVC.setResultHandler { qrValue in
            root.dismiss(animated: true) {
                if let qrValue = qrValue {
                    result(qrValue)
                } else {
                    result(FlutterError(
                        code: "USER_CANCELLED",
                        message: "Usuário cancelou o escaneamento",
                        details: nil
                    ))
                }
            }
        }

        let navController = UINavigationController(rootViewController: scannerVC)
        navController.modalPresentationStyle = .fullScreen
        root.present(navController, animated: true)
    }
}
