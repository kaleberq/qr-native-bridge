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
}
