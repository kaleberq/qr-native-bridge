import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qr_native_bridge_method_channel.dart';

abstract class QrNativeBridgePlatform extends PlatformInterface {
  /// Constructs a QrNativeBridgePlatform.
  QrNativeBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static QrNativeBridgePlatform _instance = MethodChannelQrNativeBridge();

  /// The default instance of [QrNativeBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelQrNativeBridge].
  static QrNativeBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QrNativeBridgePlatform] when
  /// they register themselves.
  static set instance(QrNativeBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
