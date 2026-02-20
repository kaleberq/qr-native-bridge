//
//  QrNativeBridgePlugin.swift
//
//
//  Created by Kalebe Misael on 19/02/26.
//

import Flutter
import UIKit

public class QrNativeBridgePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // ==============================
        // QR CODE GENERATOR CHANNEL
        // ==============================
        FlutterMethodChannel(
            name: "br.com.kalebemisael.jogodavelha/qr",
            binaryMessenger: c.binaryMessenger
        ).setMethodCallHandler { [weak self] call, result in

            guard call.method == "generateQr" else {
                result(FlutterMethodNotImplemented)
                return
            }

            guard
                let args = call.arguments as? [String: Any],
                let data = args["data"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing data",
                        details: nil
                    )
                )
                return
            }

            if let pngData = self?.generateQrPng(from: data) {
                result(FlutterStandardTypedData(bytes: pngData))
            } else {
                result(
                    FlutterError(
                        code: "QR_FAILED",
                        message: "Could not generate QR",
                        details: nil
                    )
                )
            }
        }

        // ==============================
        // QR CODE SCANNER CHANNEL
        // ==============================
        FlutterMethodChannel(
            name: "br.com.kalebemisael.jogodavelha/qr_scanner",
            binaryMessenger: c.binaryMessenger
        ).setMethodCallHandler { [weak self] call, result in

            guard call.method == "scanQr" else {
                result(FlutterMethodNotImplemented)
                return
            }

            // Verifica permissão de câmera
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

            if authStatus == .denied || authStatus == .restricted {
                result(
                    FlutterError(
                        code: "PERMISSION_DENIED",
                        message: "Permissão de câmera negada",
                        details: nil
                    )
                )
                return
            }

            if authStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.presentQrScanner(result: result)
                        } else {
                            result(
                                FlutterError(
                                    code: "PERMISSION_DENIED",
                                    message: "Permissão de câmera negada",
                                    details: nil
                                )
                            )
                        }
                    }
                }
            } else {
                self?.presentQrScanner(result: result)
            }
        }

        // ==============================
        // QR CODE GENERATOR
        // ==============================
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
            guard
                let cgImage = context.createCGImage(
                    scaledImage,
                    from: scaledImage.extent
                )
            else { return nil }

            return UIImage(cgImage: cgImage).pngData()
        }

        // ==============================
        // QR CODE SCANNER
        // ==============================
        private func presentQrScanner(result: @escaping FlutterResult) {
            guard let rootViewController = window?.rootViewController else {
                result(
                    FlutterError(
                        code: "NO_ROOT_VC",
                        message: "Root view controller not found",
                        details: nil
                    )
                )
                return
            }

            let scannerVC = QrScannerViewController()
            scannerVC.setResultHandler { qrValue in
                rootViewController.dismiss(animated: true) {
                    if let qrValue = qrValue {
                        result(qrValue)
                    } else {
                        result(
                            FlutterError(
                                code: "USER_CANCELLED",
                                message: "Usuário cancelou o escaneamento",
                                details: nil
                            )
                        )
                    }
                }
            }

            let navController = UINavigationController(
                rootViewController: scannerVC
            )
            navController.modalPresentationStyle = .fullScreen

            rootViewController.present(navController, animated: true)
        }
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
