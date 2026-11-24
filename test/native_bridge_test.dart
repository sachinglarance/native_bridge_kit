import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge_kit/bridge/models.dart';
import 'package:native_bridge_kit/bridge/native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(NativeBridge.methodChannelName);
  const battery = EventChannel(NativeBridge.batteryChannelName);
  final bridge = NativeBridge();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getDeviceInfo':
          return {
            'platform': 'android',
            'manufacturer': 'Google',
            'model': 'Pixel 8',
            'osVersion': '15',
            'sdkInt': 35,
            'isPhysicalDevice': false,
          };
        case 'checkCameraPermission':
          return 'permanentlyDenied';
        case 'scanQrCode':
          throw PlatformException(
            code: 'permission_denied',
            message: 'Camera permission is required',
          );
        case 'haptic':
          return null;
      }
      return null; // unknown → MissingPlugin-like handled by Dart side
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(methods, null));

  test('parses device info from the native map', () async {
    final info = await bridge.getDeviceInfo();
    expect(info.model, 'Pixel 8');
    expect(info.sdkInt, 35);
    expect(info.isPhysicalDevice, isFalse);
  });

  test('maps permission strings to the enum', () async {
    expect(await bridge.cameraPermission(), CameraPermission.permanentlyDenied);
  });

  test('wraps PlatformException in a typed NativeBridgeException', () async {
    await expectLater(
      bridge.scanQrCode(),
      throwsA(
        isA<NativeBridgeException>().having(
          (e) => e.code,
          'code',
          'permission_denied',
        ),
      ),
    );
  });

  test('sends the haptic pattern as an argument', () async {
    await bridge.haptic(HapticPattern.success);
    expect(calls.single.arguments, {'pattern': 'success'});
  });

  test('MissingPluginException becomes an "unimplemented" error', () async {
    messenger.setMockMethodCallHandler(methods, null);
    await expectLater(
      bridge.getBatteryLevel(),
      throwsA(
        isA<NativeBridgeException>().having(
          (e) => e.code,
          'code',
          'unimplemented',
        ),
      ),
    );
  });

  test('battery EventChannel events are decoded into BatteryStatus', () async {
    messenger.setMockStreamHandler(
      battery,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          sink.success({'level': 80, 'state': 'charging'});
          sink.success({'level': 81, 'state': 'bogus'});
          sink.endOfStream();
        },
      ),
    );

    final events = await bridge.batteryStream().toList();

    expect(events.map((e) => e.level), [80, 81]);
    expect(events.map((e) => e.state), [
      ChargingState.charging,
      ChargingState.unknown,
    ]);
  });
}
