import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class _Node {
  const _Node(this.name, this.depth,
      {this.folder = false, this.open = false, this.status});
  final String name;
  final int depth;
  final bool folder;
  final bool open;
  final String? status; // 'M' | 'A'
}

const _tree = <_Node>[
  _Node('src', 0, folder: true, open: true),
  _Node('components', 1, folder: true, open: true),
  _Node('editor.tsx', 2, status: 'M'),
  _Node('Tabs.tsx', 2, status: 'A'),
  _Node('fs.ts', 1, status: 'M'),
  _Node('App.tsx', 1),
  _Node('main.dart', 1),
  _Node('app.py', 1),
  _Node('native.cpp', 1),
  _Node('Helper.kt', 1),
  _Node('assets', 0, folder: true),
  _Node('package.json', 0),
  _Node('tsconfig.json', 0),
  _Node('README.md', 0),
];

/// Left side drawer from the "02 Files" frame.
class FilesDrawer extends StatelessWidget {
  const FilesDrawer({
    super.key,
    required this.activeFile,
    required this.changeCount,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.onOpenSourceControl,
  });

  final String activeFile;
  final int changeCount;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSourceControl;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 316,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('lattice-app',
                          style: LatticeText.ui(17,
                              weight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 4),
                      Container(
                        height: 21,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            iconoir.GitBranch(
                                color: c.accent, width: 12, height: 12),
                            const SizedBox(width: 5),
                            Text('main',
                                style: LatticeText.ui(12,
                                    weight: FontWeight.w500, color: c.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  LIconButton(
                      icon: iconoir.PagePlus(
                          color: c.text, width: 18, height: 18),
                      size: 36,
                      onTap: () {}),
                  const SizedBox(width: 10),
                  LIconButton(
                      icon: iconoir.FolderPlus(
                          color: c.text, width: 18, height: 18),
                      size: 36,
                      onTap: () {}),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    iconoir.Search(
                        color: c.textMuted, width: 16, height: 16),
                    const SizedBox(width: 8),
                    Text('Search files',
                        style: LatticeText.ui(14, color: c.textFaint)),
                  ],
                ),
              ),
            ),
            // Tree
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  for (final n in _tree)
                    _Row(
                      node: n,
                      active: n.name == activeFile,
                      onTap: n.folder ? null : () => onOpenFile(n.name),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            // Footer
            SizedBox(
              height: 62,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onOpenSettings,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            iconoir.Settings(
                                color: c.textMuted, width: 18, height: 18),
                            const SizedBox(width: 10),
                            Text('Settings',
                                style: LatticeText.ui(14,
                                    weight: FontWeight.w500, color: c.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onOpenSourceControl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Text('$changeCount changes',
                          style: LatticeText.ui(12, color: c.warning)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.node, required this.active, this.onTap});
  final _Node node;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 38,
            padding: EdgeInsets.only(left: 6 + node.depth * 18.0, right: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: node.folder
                      ? (node.open
                          ? iconoir.NavArrowDown(
                              color: c.textMuted, width: 16, height: 16)
                          : iconoir.NavArrowRight(
                              color: c.textMuted, width: 16, height: 16))
                      : null,
                ),
                const SizedBox(width: 8),
                node.folder
                    ? iconoir.Folder(
                        color: c.accent, width: 18, height: 18)
                    : iconoir.Page(
                        color: c.textMuted, width: 18, height: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    style: LatticeText.ui(
                      14,
                      weight: active ? FontWeight.w500 : FontWeight.w400,
                      color: c.text,
                    ),
                  ),
                ),
                if (node.status != null)
                  Text(
                    node.status!,
                    style: LatticeText.ui(
                      12,
                      weight: FontWeight.w600,
                      color: node.status == 'A' ? c.success : c.warning,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
