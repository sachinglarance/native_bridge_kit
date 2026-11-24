# `lib/bridge/`

**Purpose:** Platform-channel layer: the `NativeBridge` client that talks to the Kotlin/Swift code, plus the typed models and error it returns; used by the Riverpod providers in `lib/state/`.

> Generated from the code by the `codebase-map` skill (synced at ``). Edit the **Purpose** lines by hand; everything else comes from the source and its `///` comments.

Up: [`lib/`](../README.md)

## Files

| File | Purpose |
|---|---|
| [`models.dart`](#modelsdart) | Plain data types passed over the platform channels (device info, battery status, camera permission, haptic pattern) and the typed `NativeBridgeException`. |
| [`native_bridge.dart`](#native_bridgedart) | Dart side of the platform channels. |

## `models.dart`

**Purpose:** Plain data types passed over the platform channels (device info, battery status, camera permission, haptic pattern) and the typed `NativeBridgeException`.

Source: [`lib/bridge/models.dart`](../../../lib/bridge/models.dart)

- **Uses:** —
- **Used by:** `lib/bridge/native_bridge.dart`, `lib/state/providers.dart`, `lib/ui/home_page.dart`

### `class DeviceInfo`

> Plain data types passed over the platform channels (device info, battery
> status, camera permission, haptic pattern) and the typed
> `NativeBridgeException`.

| Member | Kind | What it does |
|---|---|---|
| `const DeviceInfo({ required this.platform, required this.manufacturer, required this.model, required this.osVersion, required this.sdkInt, required this.isPhysicalDevice, })` | constructor | _(auto)_ Takes the dependencies / values listed as named parameters. |
| `factory DeviceInfo.fromMap(Map<Object?, Object?> map)` | constructor | _(auto)_ Creates an instance. |
| `final String platform` | field | Platform name sent by native code: `android` or `ios` (`unknown` if the key is missing). |
| `final String manufacturer` | field | Device maker (`Build.MANUFACTURER` on Android, always `Apple` on iOS); empty string if missing. |
| `final String model` | field | Device model name reported by the OS; empty string if missing. Shown in the device info table. |
| `final String osVersion` | field | OS version string (e.g. Android release or iOS version); empty string if missing. |
| `final int? sdkInt` | field | Android API level; `null` on iOS. |
| `final bool isPhysicalDevice` | field | `false` on an emulator/simulator; defaults to `true` when native code doesn't send it. The UI shows "No (emulator)" when false. |

### `enum ChargingState`

| Member | Kind | What it does |
|---|---|---|
| `charging` | value | _(auto)_ Enum value. |
| `discharging` | value | _(auto)_ Enum value. |
| `full` | value | _(auto)_ Enum value. |
| `unknown` | value | _(auto)_ Enum value. |

### `class BatteryStatus`

| Member | Kind | What it does |
|---|---|---|
| `const BatteryStatus({required this.level, required this.state})` | constructor | _(auto)_ Takes the dependencies / values listed as named parameters. |
| `factory BatteryStatus.fromMap(Map<Object?, Object?> map)` | constructor | _(auto)_ Creates an instance. |
| `final int level` | field | 0–100, or -1 when the platform can't report it (e.g. iOS simulator). |
| `final ChargingState state` | field | Charging state parsed by name from the native `state` string; falls back to `unknown` for missing or unrecognised values. |

### `enum CameraPermission`

| Member | Kind | What it does |
|---|---|---|
| `granted` | value | _(auto)_ Enum value. |
| `denied` | value | _(auto)_ Enum value. |
| `permanentlyDenied` | value | _(auto)_ Enum value. |
| `restricted` | value | _(auto)_ Enum value. |
| `notDetermined` | value | _(auto)_ Enum value. |

### `enum HapticPattern`

| Member | Kind | What it does |
|---|---|---|
| `light` | value | _(auto)_ Enum value. |
| `medium` | value | _(auto)_ Enum value. |
| `heavy` | value | _(auto)_ Enum value. |
| `success` | value | _(auto)_ Enum value. |
| `error` | value | _(auto)_ Enum value. |

### `class NativeBridgeException implements Exception`

> Typed error for anything that went wrong on the native side.

| Member | Kind | What it does |
|---|---|---|
| `const NativeBridgeException(this.code, this.message)` | constructor | _(auto)_ Creates an instance. |
| `final String code` | field | Error code from the `PlatformException`, or `unimplemented` when the method has no native handler. |
| `final String? message` | field | Human-readable error text from native code (may be null); the QR section shows it in a SnackBar, falling back to `code`. |
| `String toString()` | method | Returns `NativeBridgeException(<code>): <message>`, which is what the UI shows when a provider errors. |

## `native_bridge.dart`

**Purpose:** Dart side of the platform channels.

Source: [`lib/bridge/native_bridge.dart`](../../../lib/bridge/native_bridge.dart)

- **Uses:** `lib/bridge/models.dart`
- **Used by:** `lib/state/providers.dart`

### `class NativeBridge`

> Dart side of the platform channels. Kotlin: `android/app/src/main/kotlin/...`,
> Swift: `ios/Runner/NativeBridgePlugin.swift`.
>
> Every call goes through [_invoke], so native errors always surface as a
> typed [NativeBridgeException] instead of a raw [PlatformException].

| Member | Kind | What it does |
|---|---|---|
| `NativeBridge({MethodChannel? methods, EventChannel? battery}) : _methods = methods ?? const MethodChannel(methodChannelName), _battery = battery ?? const EventChannel(batteryCha…` | constructor | _(auto)_ Creates an instance. |
| `static const methodChannelName = 'com.sachincharles.native_bridge/methods'` | field | _(auto)_ Constant; the value is in the signature. |
| `static const batteryChannelName = 'com.sachincharles.native_bridge/battery'` | field | _(auto)_ Constant; the value is in the signature. |
| `final MethodChannel _methods` | field | _(auto)_ Injected dependency / private state. |
| `final EventChannel _battery` | field | _(auto)_ Injected dependency / private state. |
| `Future<DeviceInfo> getDeviceInfo()` | method | Calls native `getDeviceInfo` and parses the returned map into a `DeviceInfo`; used by `deviceInfoProvider`. Throws if native returns null. |
| `Future<int> getBatteryLevel()` | method | One-shot read of the battery percentage via native `getBatteryLevel`; returns -1 if native returns null. Used by `batteryProvider` for the first value before the stream fires. |
| `Stream<BatteryStatus> batteryStream()` | method | Live battery updates, pushed by a BroadcastReceiver (Android) or UIDevice notifications (iOS). Native listeners are only registered while this stream has a subscriber. |
| `Future<CameraPermission> cameraPermission({bool request = false})` | method | Checks (`checkCameraPermission`) or, with `request: true`, asks for (`requestCameraPermission`) camera access and maps the native string to `CameraPermission`; unknown values become `denied`. Used by `CameraPermissionController`. |
| `Future<String?> scanQrCode()` | method | Opens the native scanner (CameraX + ML Kit on Android, AVFoundation on iOS). Returns the decoded text, or `null` if the user cancelled. |
| `Future<void> haptic(HapticPattern pattern)` | method | Plays a native haptic by sending the pattern name to `haptic`; called by the haptics buttons and after a successful QR scan. |
| `Future<void> openAppSettings()` | method | Opens this app's page in the system Settings app; used by the SnackBar action when camera access is blocked. |
| `Future<T?> _invoke<T>(String method, [Map<String, Object?>? args])` | method | Single wrapper around `MethodChannel.invokeMethod` used by every method call; rethrows `PlatformException` as `NativeBridgeException` and `MissingPluginException` as code `unimplemented`. |

