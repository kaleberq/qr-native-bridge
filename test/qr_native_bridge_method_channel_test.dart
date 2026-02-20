import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_native_bridge/qr_native_bridge_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelQrNativeBridge platform = MethodChannelQrNativeBridge();
  const MethodChannel channel = MethodChannel('qr_native_bridge');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'scanQr':
            return 'scanned-qr-value';
          case 'generateQr':
            return Uint8List.fromList([1, 2, 3]);
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('scanQr', () async {
    expect(await platform.scanQr(), 'scanned-qr-value');
  });

  test('generateQr', () async {
    final bytes = await platform.generateQr('data');
    expect(bytes, [1, 2, 3]);
  });
}
