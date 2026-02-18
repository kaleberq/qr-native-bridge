
import 'qr_native_bridge_platform_interface.dart';

class QrNativeBridge {
  Future<String?> getPlatformVersion() {
    return QrNativeBridgePlatform.instance.getPlatformVersion();
  }
}
