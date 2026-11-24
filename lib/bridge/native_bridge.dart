import 'package:flutter/services.dart';

import 'models.dart';

/// Dart side of the platform channels. Kotlin: `android/app/src/main/kotlin/...`,
/// Swift: `ios/Runner/NativeBridgePlugin.swift`.
///
/// Every call goes through [_invoke], so native errors always surface as a
/// typed [NativeBridgeException] instead of a raw [PlatformException].
class NativeBridge {
  NativeBridge({MethodChannel? methods, EventChannel? battery})
    : _methods = methods ?? const MethodChannel(methodChannelName),
      _battery = battery ?? const EventChannel(batteryChannelName);

  static const methodChannelName = 'com.sachincharles.native_bridge/methods';
  static const batteryChannelName = 'com.sachincharles.native_bridge/battery';

  final MethodChannel _methods;
  final EventChannel _battery;

  Future<DeviceInfo> getDeviceInfo() async => DeviceInfo.fromMap(
    (await _invoke<Map<Object?, Object?>>('getDeviceInfo'))!,
  );

  Future<int> getBatteryLevel() async =>
      (await _invoke<int>('getBatteryLevel')) ?? -1;

  /// Live battery updates, pushed by a BroadcastReceiver (Android) or
  /// UIDevice notifications (iOS). Native listeners are only registered while
  /// this stream has a subscriber.
  Stream<BatteryStatus> batteryStream() => _battery
      .receiveBroadcastStream()
      .map((e) => BatteryStatus.fromMap(e as Map<Object?, Object?>));

  Future<CameraPermission> cameraPermission({bool request = false}) async {
    final raw = await _invoke<String>(
      request ? 'requestCameraPermission' : 'checkCameraPermission',
    );
    return CameraPermission.values.asNameMap()[raw] ?? CameraPermission.denied;
  }

  /// Opens the native scanner (CameraX + ML Kit on Android, AVFoundation on
  /// iOS). Returns the decoded text, or `null` if the user cancelled.
  Future<String?> scanQrCode() => _invoke<String>('scanQrCode');

  Future<void> haptic(HapticPattern pattern) =>
      _invoke<void>('haptic', {'pattern': pattern.name});

  Future<void> openAppSettings() => _invoke<void>('openAppSettings');

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _methods.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw NativeBridgeException(e.code, e.message);
    } on MissingPluginException {
      throw NativeBridgeException(
        'unimplemented',
        '$method is not implemented on this platform',
      );
    }
  }
}
