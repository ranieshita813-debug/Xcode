import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String fontFamily = 'JetBrains Mono';
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
