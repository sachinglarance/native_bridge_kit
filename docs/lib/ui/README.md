# `lib/ui/`

**Purpose:** The single home page and its sections (QR scanner, battery, device info, haptics), built on the Riverpod providers.

> Generated from the code by the `codebase-map` skill (synced at ``). Edit the **Purpose** lines by hand; everything else comes from the source and its `///` comments.

Up: [`lib/`](../README.md)

## Folders

- [`widgets/`](widgets/README.md) — Widgets used by this module's pages; render state passed in or watched from controllers.

## Files

| File | Purpose |
|---|---|
| [`home_page.dart`](#home_pagedart) | Home screen: a scrolling list of demo cards for the native QR scanner, live battery, device info and haptics. |

## `home_page.dart`

**Purpose:** Home screen: a scrolling list of demo cards for the native QR scanner, live battery, device info and haptics.

Source: [`lib/ui/home_page.dart`](../../../lib/ui/home_page.dart)

- **Uses:** `lib/bridge/models.dart`, `lib/state/providers.dart`, `lib/ui/widgets/section_card.dart`
- **Used by:** `lib/main.dart`

### `class HomePage extends ConsumerWidget`

| Member | Kind | What it does |
|---|---|---|
| `const HomePage({super.key})` | constructor | _(auto)_ Creates an instance. |
| `Widget build(BuildContext context, WidgetRef ref)` | method | _(auto)_ Builds this widget's UI. |

### `class _QrSection extends ConsumerWidget`

| Member | Kind | What it does |
|---|---|---|
| `const _QrSection()` | constructor | _(auto)_ Creates an instance. |
| `Future<void> _scan(BuildContext context, WidgetRef ref)` | method | Scan button handler: checks/requests camera permission, shows a SnackBar with a Settings action if access is blocked, otherwise opens the native scanner, plays a success haptic and adds the result to history. Cancel returns silently; `NativeBridgeException`s show as a SnackBar. |
| `Widget build(BuildContext context, WidgetRef ref)` | method | _(auto)_ Builds this widget's UI. |

### `class _BatterySection extends ConsumerWidget`

| Member | Kind | What it does |
|---|---|---|
| `const _BatterySection()` | constructor | _(auto)_ Creates an instance. |
| `Widget build(BuildContext context, WidgetRef ref)` | method | _(auto)_ Builds this widget's UI. |

### `class _DeviceSection extends ConsumerWidget`

| Member | Kind | What it does |
|---|---|---|
| `const _DeviceSection()` | constructor | _(auto)_ Creates an instance. |
| `Widget build(BuildContext context, WidgetRef ref)` | method | _(auto)_ Builds this widget's UI. |

### `class _HapticsSection extends ConsumerWidget`

| Member | Kind | What it does |
|---|---|---|
| `const _HapticsSection()` | constructor | _(auto)_ Creates an instance. |
| `Widget build(BuildContext context, WidgetRef ref)` | method | _(auto)_ Builds this widget's UI. |

