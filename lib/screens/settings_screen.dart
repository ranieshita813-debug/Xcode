import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Row(
                  children: [
                    LIconButton(
                      icon: iconoir.NavArrowLeft(
                          color: c.text, width: 24, height: 24),
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('Settings',
                        style: LatticeText.ui(17,
                            weight: FontWeight.w600, color: c.text)),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: SettingsScreenContent(),
            ),
          ],
        ),
      ),
    );
  }
}
