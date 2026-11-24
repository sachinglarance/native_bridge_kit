import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bridge/models.dart';
import '../bridge/native_bridge.dart';

final nativeBridgeProvider = Provider((ref) => NativeBridge());

final deviceInfoProvider = FutureProvider(
  (ref) => ref.watch(nativeBridgeProvider).getDeviceInfo(),
);

final batteryProvider = StreamProvider<BatteryStatus>((ref) async* {
  final bridge = ref.watch(nativeBridgeProvider);
  // Emit the current level right away; the stream only fires on change.
  yield BatteryStatus(
    level: await bridge.getBatteryLevel(),
    state: ChargingState.unknown,
  );
  yield* bridge.batteryStream();
});

final cameraPermissionProvider =
    AsyncNotifierProvider<CameraPermissionController, CameraPermission>(
      CameraPermissionController.new,
    );

class CameraPermissionController extends AsyncNotifier<CameraPermission> {
  @override
  Future<CameraPermission> build() =>
      ref.read(nativeBridgeProvider).cameraPermission();

  Future<CameraPermission> request() async {
    final result = await ref
        .read(nativeBridgeProvider)
        .cameraPermission(request: true);
    state = AsyncData(result);
    return result;
  }
}

class ScanResult {
  const ScanResult(this.value, this.at);
  final String value;
  final DateTime at;

  bool get isUrl => Uri.tryParse(value)?.hasScheme ?? false;
}

final scanHistoryProvider = NotifierProvider<ScanHistory, List<ScanResult>>(
  ScanHistory.new,
);

class ScanHistory extends Notifier<List<ScanResult>> {
  @override
  List<ScanResult> build() => const [];

  void add(String value) =>
      state = [ScanResult(value, DateTime.now()), ...state].take(20).toList();
}
