import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/screens/home_screen.dart';
import 'package:lattice/state/settings.dart';
import 'package:lattice/theme/app_theme.dart';
import 'package:lattice/theme/tokens.dart';

Widget buildTestableWidget(Widget child) {
  final settings = AppSettings();
  return SettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: buildTheme(LatticeColors.light, Brightness.light),
      darkTheme: buildTheme(LatticeColors.dark, Brightness.dark),
      home: child,
    ),
  );
}

void main() {
  testWidgets('HomeScreen renders Projects and Settings tabs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const HomeScreen()));

    expect(find.text('Lattice Studio'), findsOneWidget);
    expect(find.text('Launch Editor Workspace'), findsOneWidget);
    expect(find.text('RECENT FILES & PROJECTS'), findsOneWidget);

    // Tap on second tab item in NavigationBar
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);
  });
}
