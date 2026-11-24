# Native Bridge Kit: Flutter Platform Channels with Kotlin and Swift

A Flutter app that calls **native Android (Kotlin) and iOS (Swift) code that I wrote by hand
through Platform Channels**. It uses no plugins for these features. The main feature is a
**native QR and barcode scanner**: CameraX with ML Kit on Android, and AVFoundation on iOS.

| Feature | Channel | Android (Kotlin) | iOS (Swift) |
|---|---|---|---|
| QR / barcode scanner | `MethodChannel` | `QrScannerActivity`: CameraX preview + ML Kit `BarcodeScanning`, result returned with the Activity Result API | `QRScannerViewController`: `AVCaptureSession` + `AVCaptureMetadataOutput` |
| Camera permission | `MethodChannel` | `ActivityResultContracts.RequestPermission`, with detection of "permanently denied" | `AVCaptureDevice.requestAccess` |
| Live battery level and state | `EventChannel` | Sticky `ACTION_BATTERY_CHANGED` `BroadcastReceiver` | `UIDevice` battery notifications |
| Device info | `MethodChannel` | `Build.*` and emulator detection | `utsname` model id and simulator detection |
| Haptics | `MethodChannel` | `VibrationEffect` waveforms through `VibratorManager` | `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` |
| Open app settings | `MethodChannel` | `ACTION_APPLICATION_DETAILS_SETTINGS` | `openSettingsURLString` |

## Engineering details

- **One typed Dart API** (`lib/bridge/native_bridge.dart`). Every call is wrapped, so
  `PlatformException` and `MissingPluginException` become a typed `NativeBridgeException`,
  and the UI never sees raw channel errors.
- **Channel lifecycle**: the battery `BroadcastReceiver` and the iOS observers are registered
  only while Dart listens (`onListen` and `onCancel`), so no work runs in the background.
- **Single in-flight guard** on both platforms. If a second scan or permission request arrives
  while one is open, it gets a `busy` error instead of leaking a `Result`.
- The scanner **completes the result exactly once**, using `AtomicBoolean` on Android and a
  `finished` flag on iOS, even if several frames decode at the same time.
- `STRATEGY_KEEP_ONLY_LATEST` back-pressure keeps camera latency low.
- **Android permanent-denial detection**: Android has no API for this. The app combines an
  "asked before" flag with `shouldShowRequestPermissionRationale`.
- **Modern embedding on both platforms**: `FlutterFragmentActivity` with the Activity Result
  API on Android, and the iOS implicit-engine and UIScene `AppDelegate`, where channels are
  registered as an in-app `FlutterPlugin`.
- Riverpod `StreamProvider` and `AsyncNotifier` sit on top. Tests replace the whole bridge
  with one provider override.

## Project layout

```
lib/
├── bridge/        # NativeBridge (channels) + typed models
├── state/         # Riverpod providers
└── ui/            # HomePage with scanner, battery, device and haptics sections
android/app/src/main/kotlin/com/sachincharles/native_bridge_kit/
├── MainActivity.kt          # channel registration, permissions, scan launcher
├── QrScannerActivity.kt     # CameraX + ML Kit
├── BatteryStreamHandler.kt  # EventChannel
└── DeviceFeatures.kt        # device info, battery, haptics
ios/Runner/
├── NativeBridgePlugin.swift      # MethodChannel + EventChannel handlers
└── QRScannerViewController.swift # AVFoundation scanner
```

## Tests

```bash
flutter test
```

- **Channel contract tests** use mocked `MethodChannel` and `EventChannel` handlers. They cover argument encoding, map decoding, mapping of `PlatformException` and `MissingPluginException`, and stream event parsing.
- A **widget test** runs the full scan flow with a fake bridge: request permission, scan, play the success haptic, and show the result in the history list.
- **CI** compiles the Kotlin code (`flutter build apk`) on Ubuntu and the Swift code (`flutter build ios --simulator`) on macOS.

## Run

```bash
flutter run   # use a real device to try the scanner (simulators have no camera)
```

**Tech:** Flutter · Dart · Kotlin · Swift · Platform Channels (Method + Event) · CameraX · ML Kit · AVFoundation · Riverpod
