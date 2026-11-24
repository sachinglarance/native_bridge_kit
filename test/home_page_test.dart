import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge_kit/bridge/models.dart';
import 'package:native_bridge_kit/bridge/native_bridge.dart';
import 'package:native_bridge_kit/state/providers.dart';
import 'package:native_bridge_kit/ui/home_page.dart';

class FakeBridge extends NativeBridge {
  CameraPermission permission = CameraPermission.notDetermined;
  final haptics = <HapticPattern>[];

  @override
  Future<DeviceInfo> getDeviceInfo() async => const DeviceInfo(
    platform: 'ios',
    manufacturer: 'Apple',
    model: 'iPhone16,1',
    osVersion: 'iOS 26',
    sdkInt: null,
    isPhysicalDevice: true,
  );
  @override
  Future<int> getBatteryLevel() async => 64;
  @override
  Stream<BatteryStatus> batteryStream() => const Stream.empty();
  @override
  Future<CameraPermission> cameraPermission({bool request = false}) async {
    if (request) permission = CameraPermission.granted;
    return permission;
  }

  @override
  Future<String?> scanQrCode() async => 'https://flutter.dev';
  @override
  Future<void> haptic(HapticPattern pattern) async => haptics.add(pattern);
}

void main() {
  testWidgets(
    'requests permission, scans, plays success haptic and lists the result',
    (tester) async {
      final bridge = FakeBridge();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nativeBridgeProvider.overrideWithValue(bridge)],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('64%'), findsOneWidget);
      expect(find.text('iPhone16,1'), findsOneWidget);

      await tester.tap(find.text('Scan QR / barcode'));
      await tester.pumpAndSettle();

      expect(find.text('https://flutter.dev'), findsOneWidget);
      expect(bridge.permission, CameraPermission.granted);
      expect(bridge.haptics, [HapticPattern.success]);
    },
  );
}
