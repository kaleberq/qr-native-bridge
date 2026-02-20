import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qr_native_bridge_platform_interface.dart';

/// An implementation of [QrNativeBridgePlatform] that uses method channels.
class MethodChannelQrNativeBridge extends QrNativeBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qr_native_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> scanQr() async {
    try {
      final result = await methodChannel.invokeMethod<String>('scanQr');
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> generateQr(String data) async {
    final bytes = await methodChannel.invokeMethod<Uint8List>('generateQr', {
      'data': data,
    });
    if (bytes == null) {
      throw PlatformException(
        code: 'QR_FAILED',
        message: 'QR generation failed',
      );
    }
    return bytes;
  }
}
