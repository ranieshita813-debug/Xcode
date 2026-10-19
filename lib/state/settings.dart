import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  static const List<String> availableFonts = [
    'IBM Plex Mono',
    'JetBrains Mono',
    'Fira Code',
    'Source Code Pro',
    'Inconsolata',
    'Roboto Mono',
    'Space Mono',
  ];

  ThemeMode themeMode = ThemeMode.dark;
  String fontFamily = 'IBM Plex Mono';
  double fontSize = 12;
  bool wordWrap = true;
  bool lineNumbers = true;
  bool autoSave = true;
  bool minimap = false;
  bool formatOnSave = true;

  void update(void Function(AppSettings s) change) {
    change(this);
    notifyListeners();
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
