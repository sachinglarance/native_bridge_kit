# `lib/`

**Purpose:** Flutter app source for Native Bridge Kit: the entry point, the platform-channel bridge, Riverpod state and the UI.

> Generated from the code by the `codebase-map` skill (synced at ``). Edit the **Purpose** lines by hand; everything else comes from the source and its `///` comments.

## Folders

- [`bridge/`](bridge/README.md) — Platform-channel layer: the `NativeBridge` client that talks to the Kotlin/Swift code, plus the typed models and error it returns; used by the Riverpod providers in `lib/state/`.
- [`state/`](state/README.md) — Riverpod providers and notifiers that wrap `NativeBridge` (device info, battery, camera permission, scan history); watched by the UI in `lib/ui/`.
- [`ui/`](ui/README.md) — The single home page and its sections (QR scanner, battery, device info, haptics), built on the Riverpod providers.

## Files

| File | Purpose |
|---|---|
| [`main.dart`](#maindart) | App entry point: wraps the app in a Riverpod `ProviderScope` and sets up the Material 3 light/dark theme with `HomePage` as home. |

## `main.dart`

**Purpose:** App entry point: wraps the app in a Riverpod `ProviderScope` and sets up the Material 3 light/dark theme with `HomePage` as home.

Source: [`lib/main.dart`](../../lib/main.dart)

- **Uses:** `lib/ui/home_page.dart`
- **Used by:** — (entry point, generated-code target, or unused)

### function `void main()`

### `class NativeBridgeApp extends StatelessWidget`

| Member | Kind | What it does |
|---|---|---|
| `const NativeBridgeApp({super.key})` | constructor | _(auto)_ Creates an instance. |
| `Widget build(BuildContext context)` | method | _(auto)_ Builds this widget's UI. |

