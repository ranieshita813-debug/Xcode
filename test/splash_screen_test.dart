import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/screens/splash_screen.dart';
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
  testWidgets('SplashScreen renders title and logo', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const SplashScreen()));

    expect(find.text('Lattice'), findsOneWidget);
    expect(find.text('Next-Gen Mobile Code Editor'), findsOneWidget);

    // Fast-forward time for animation & navigation to HomeScreen
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('Lattice Studio'), findsOneWidget);
  });
}
