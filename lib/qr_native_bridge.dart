import 'dart:typed_data';

import 'qr_native_bridge_platform_interface.dart';

/// Plugin para leitura e geração de QR code nativo (iOS/Android).
class QrNativeBridge {
  /// Versão da plataforma (ex: "iOS 17.0").
  Future<String?> getPlatformVersion() {
    return QrNativeBridgePlatform.instance.getPlatformVersion();
  }

  /// Abre o scanner nativo de QR code.
  /// Retorna o valor escaneado ou `null` se o usuário cancelar.
  Future<String?> scanQr() {
    return QrNativeBridgePlatform.instance.scanQr();
  }

  /// Gera um QR code em PNG a partir do texto [data].
  /// Retorna os bytes da imagem PNG.
  Future<Uint8List> generateQr(String data) {
    return QrNativeBridgePlatform.instance.generateQr(data);
  }
}
