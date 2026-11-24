# `lib/ui/widgets/`

**Purpose:** Widgets used by this module's pages; render state passed in or watched from controllers.

> Generated from the code by the `codebase-map` skill (synced at ``). Edit the **Purpose** lines by hand; everything else comes from the source and its `///` comments.

Up: [`lib/ui/`](../README.md)

## Files

| File | Purpose |
|---|---|
| [`section_card.dart`](#section_carddart) | `SectionCard`, the shared card layout (icon, title, optional trailing widget, body) used by every home page section. |

## `section_card.dart`

**Purpose:** `SectionCard`, the shared card layout (icon, title, optional trailing widget, body) used by every home page section.

Source: [`lib/ui/widgets/section_card.dart`](../../../../lib/ui/widgets/section_card.dart)

- **Uses:** —
- **Used by:** `lib/ui/home_page.dart`

### `class SectionCard extends StatelessWidget`

| Member | Kind | What it does |
|---|---|---|
| `const SectionCard({ super.key, required this.icon, required this.title, required this.child, this.trailing, })` | constructor | _(auto)_ Takes the dependencies / values listed as named parameters. |
| `final IconData icon` | field | _(auto)_ Value passed in by the parent widget. |
| `final String title` | field | _(auto)_ Value passed in by the parent widget. |
| `final Widget child` | field | _(auto)_ Value passed in by the parent widget. |
| `final Widget? trailing` | field | _(auto)_ Value passed in by the parent widget. |
| `Widget build(BuildContext context)` | method | _(auto)_ Builds this widget's UI. |

