# `lib/state/`

**Purpose:** Riverpod providers and notifiers that wrap `NativeBridge` (device info, battery, camera permission, scan history); watched by the UI in `lib/ui/`.

> Generated from the code by the `codebase-map` skill (synced at ``). Edit the **Purpose** lines by hand; everything else comes from the source and its `///` comments.

Up: [`lib/`](../README.md)

## Files

| File | Purpose |
|---|---|
| [`providers.dart`](#providersdart) | All Riverpod providers: the shared `NativeBridge`, device info, live battery, camera permission controller and the in-memory QR scan history. |

## `providers.dart`

**Purpose:** All Riverpod providers: the shared `NativeBridge`, device info, live battery, camera permission controller and the in-memory QR scan history.

Source: [`lib/state/providers.dart`](../../../lib/state/providers.dart)

- **Uses:** `lib/bridge/models.dart`, `lib/bridge/native_bridge.dart`
- **Used by:** `lib/ui/home_page.dart`

### variable `final nativeBridgeProvider = Provider((ref) => NativeBridge())`

### variable `final deviceInfoProvider = …`

### variable `final batteryProvider = …`

### variable `final cameraPermissionProvider = AsyncNotifierProvider<CameraPermissionController, CameraPermission>(CameraPermissionController.new)`

### `class CameraPermissionController extends AsyncNotifier<CameraPermission>`

| Member | Kind | What it does |
|---|---|---|
| `Future<CameraPermission> build()` | method | Loads the initial state by checking (not requesting) the current camera permission through `NativeBridge.cameraPermission()`. |
| `Future<CameraPermission> request()` | method | Asks the OS for camera permission, stores the result as the new state and returns it; called by the QR section before scanning when permission isn't granted. |

### `class ScanResult`

| Member | Kind | What it does |
|---|---|---|
| `const ScanResult(this.value, this.at)` | constructor | _(auto)_ Creates an instance. |
| `final String value` | field | Decoded text of the scanned QR/barcode; shown in the history list and copied by the copy button. |
| `final DateTime at` | field | When the scan was added (`DateTime.now()` in `ScanHistory.add`); shown as a time of day. |
| `bool get isUrl` | getter | True when `value` parses as a URI with a scheme (e.g. `https:`); the UI uses it to pick a link vs text icon. |

### variable `final scanHistoryProvider = …`

### `class ScanHistory extends Notifier<List<ScanResult>>`

| Member | Kind | What it does |
|---|---|---|
| `List<ScanResult> build()` | method | Starts the history as an empty list; it is in memory only and resets on app restart. |
| `void add(String value)` | method | Prepends a new `ScanResult` stamped with the current time and keeps only the 20 most recent; called after a successful scan. |

