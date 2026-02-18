import 'package:flutter_test/flutter_test.dart';
import 'package:qr_native_bridge/qr_native_bridge.dart';
import 'package:qr_native_bridge/qr_native_bridge_platform_interface.dart';
import 'package:qr_native_bridge/qr_native_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQrNativeBridgePlatform
    with MockPlatformInterfaceMixin
    implements QrNativeBridgePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QrNativeBridgePlatform initialPlatform = QrNativeBridgePlatform.instance;

  test('$MethodChannelQrNativeBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQrNativeBridge>());
  });

  test('getPlatformVersion', () async {
    QrNativeBridge qrNativeBridgePlugin = QrNativeBridge();
    MockQrNativeBridgePlatform fakePlatform = MockQrNativeBridgePlatform();
    QrNativeBridgePlatform.instance = fakePlatform;

    expect(await qrNativeBridgePlugin.getPlatformVersion(), '42');
  });
}
