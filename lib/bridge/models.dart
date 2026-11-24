/// Plain data types passed over the platform channels (device info, battery
/// status, camera permission, haptic pattern) and the typed
/// `NativeBridgeException`.
class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.manufacturer,
    required this.model,
    required this.osVersion,
    required this.sdkInt,
    required this.isPhysicalDevice,
  });

  factory DeviceInfo.fromMap(Map<Object?, Object?> map) => DeviceInfo(
    platform: map['platform'] as String? ?? 'unknown',
    manufacturer: map['manufacturer'] as String? ?? '',
    model: map['model'] as String? ?? '',
    osVersion: map['osVersion'] as String? ?? '',
    sdkInt: map['sdkInt'] as int?,
    isPhysicalDevice: map['isPhysicalDevice'] as bool? ?? true,
  );

  final String platform;
  final String manufacturer;
  final String model;
  final String osVersion;

  /// Android API level; `null` on iOS.
  final int? sdkInt;
  final bool isPhysicalDevice;
}

enum ChargingState { charging, discharging, full, unknown }

class BatteryStatus {
  const BatteryStatus({required this.level, required this.state});

  factory BatteryStatus.fromMap(Map<Object?, Object?> map) => BatteryStatus(
    level: map['level'] as int? ?? -1,
    state:
        ChargingState.values.asNameMap()[map['state']] ?? ChargingState.unknown,
  );

  /// 0–100, or -1 when the platform can't report it (e.g. iOS simulator).
  final int level;
  final ChargingState state;
}

enum CameraPermission {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notDetermined,
}

enum HapticPattern { light, medium, heavy, success, error }

/// Typed error for anything that went wrong on the native side.
class NativeBridgeException implements Exception {
  const NativeBridgeException(this.code, this.message);
  final String code;
  final String? message;

  @override
  String toString() => 'NativeBridgeException($code): $message';
}
