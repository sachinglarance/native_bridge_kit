import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bridge/models.dart';
import '../state/providers.dart';
import 'widgets/section_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native Bridge Kit')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _QrSection(),
          _BatterySection(),
          _DeviceSection(),
          _HapticsSection(),
        ],
      ),
    );
  }
}

class _QrSection extends ConsumerWidget {
  const _QrSection();

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final bridge = ref.read(nativeBridgeProvider);
    try {
      var permission = await ref.read(cameraPermissionProvider.future);
      if (permission != CameraPermission.granted) {
        permission = await ref
            .read(cameraPermissionProvider.notifier)
            .request();
      }
      if (permission == CameraPermission.permanentlyDenied ||
          permission == CameraPermission.restricted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Camera access is blocked. Enable it in Settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: bridge.openAppSettings,
            ),
          ),
        );
        return;
      }
      if (permission != CameraPermission.granted) return;

      final code = await bridge.scanQrCode();
      if (code == null) return; // user cancelled
      await bridge.haptic(HapticPattern.success);
      ref.read(scanHistoryProvider.notifier).add(code);
    } on NativeBridgeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);
    final permission = ref.watch(cameraPermissionProvider);
    return SectionCard(
      icon: Icons.qr_code_scanner,
      title: 'Native QR scanner',
      trailing: permission.whenOrNull(
        data: (p) =>
            Chip(label: Text(p.name), visualDensity: VisualDensity.compact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Android: CameraX + ML Kit in a Kotlin Activity · iOS: AVFoundation in Swift',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _scan(context, ref),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan QR / barcode'),
          ),
          for (final r in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(r.isUrl ? Icons.link : Icons.text_snippet),
              title: Text(
                r.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(TimeOfDay.fromDateTime(r.at).format(context)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: r.value)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BatterySection extends ConsumerWidget {
  const _BatterySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battery = ref.watch(batteryProvider);
    return SectionCard(
      icon: Icons.battery_charging_full,
      title: 'Battery (EventChannel stream)',
      child: battery.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (b) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.level < 0 ? 'Not available on this device' : '${b.level}%',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (b.level >= 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: b.level / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            const SizedBox(height: 8),
            Text('State: ${b.state.name}'),
          ],
        ),
      ),
    );
  }
}

class _DeviceSection extends ConsumerWidget {
  const _DeviceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(deviceInfoProvider);
    return SectionCard(
      icon: Icons.phone_android,
      title: 'Device info (MethodChannel)',
      child: info.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (d) => Table(
          columnWidths: const {0: IntrinsicColumnWidth()},
          children: [
            for (final (k, v) in [
              ('Platform', d.platform),
              ('Manufacturer', d.manufacturer),
              ('Model', d.model),
              ('OS version', d.osVersion),
              if (d.sdkInt != null) ('API level', '${d.sdkInt}'),
              ('Physical device', d.isPhysicalDevice ? 'Yes' : 'No (emulator)'),
            ])
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 4),
                    child: Text(k),
                  ),
                  Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HapticsSection extends ConsumerWidget {
  const _HapticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    icon: Icons.vibration,
    title: 'Haptics',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in HapticPattern.values)
          OutlinedButton(
            onPressed: () => ref.read(nativeBridgeProvider).haptic(p),
            child: Text(p.name),
          ),
      ],
    ),
  );
}
