# Lattice – Mobile Code Editor (Flutter)

Flutter conversion of the Figma file **Mobile Code Editor** (`enlkOXYPkCWxE6iXZXhOmn`, page "Lattice screens").

## Screens
| Figma frame | Flutter |
|---|---|
| 01 Editor | `lib/screens/editor_screen.dart` + `widgets/code_view.dart`, `widgets/keyboard.dart` |
| 02 Files | `widgets/files_drawer.dart` (tap the menu icon) |
| 03 Command palette | `widgets/command_palette.dart` (tap the file title in the app bar) |
| 04 Terminal | `widgets/terminal_panel.dart` (tap Run) |
| 05 Source control | `screens/source_control_screen.dart` (drawer → "3 changes") |
| 06 Settings | `screens/settings_screen.dart` (drawer → Settings) |

Design tokens (colors, type) live in `lib/theme/`. Fonts: IBM Plex Sans + JetBrains Mono via `google_fonts`.

## Run
```bash
flutter create . --platforms=android,ios   # generates the platform folders
flutter pub get
flutter run
flutter test
```
Requires Flutter 3.27+.

## Notes / known gaps
- The in-app keyboard is custom (as in the design) and drives the editor and the palette.
- Icons use Material Icons instead of the exported Figma SVGs.
- Light theme values are derived; the Figma file only draws the dark theme. The error color (`#F7768E`) is also inferred.
- Word wrap, minimap and format-on-save are stored settings but not yet applied to the editor; "Format" just trims trailing whitespace.
- Git and file tree data are static demo data.
