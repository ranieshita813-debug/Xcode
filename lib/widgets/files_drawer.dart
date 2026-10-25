import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class TreeNode {
  const TreeNode(this.name, this.depth,
      {this.folder = false, this.open = false, this.status, this.fullPath = ''});
  final String name;
  final int depth;
  final bool folder;
  final bool open;
  final String? status;
  final String fullPath;
}

/// Dynamic Left side drawer displaying storage file tree.
class FilesDrawer extends StatefulWidget {
  const FilesDrawer({
    super.key,
    required this.activeFile,
    required this.changeCount,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.onOpenSourceControl,
    this.onCreateFile,
    this.onCreateFolder,
    this.customNodes,
  });

  final String activeFile;
  final int changeCount;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSourceControl;
  final VoidCallback? onCreateFile;
  final VoidCallback? onCreateFolder;
  final List<TreeNode>? customNodes;

  @override
  State<FilesDrawer> createState() => _FilesDrawerState();
}

class _FilesDrawerState extends State<FilesDrawer> {
  static const _defaultTree = <TreeNode>[
    TreeNode('src', 0, folder: true, open: true),
    TreeNode('components', 1, folder: true, open: true),
    TreeNode('editor.tsx', 2, status: 'M'),
    TreeNode('Tabs.tsx', 2, status: 'A'),
    TreeNode('fs.ts', 1, status: 'M'),
    TreeNode('App.tsx', 1),
    TreeNode('main.dart', 1),
    TreeNode('app.py', 1),
    TreeNode('native.cpp', 1),
    TreeNode('Helper.kt', 1),
    TreeNode('assets', 0, folder: true),
    TreeNode('package.json', 0),
    TreeNode('tsconfig.json', 0),
    TreeNode('README.md', 0),
  ];

  late Set<String> _openFolders;

  @override
  void initState() {
    super.initState();
    _openFolders = {'src', 'components', 'assets'};
  }

  void _toggleFolder(String name) {
    setState(() {
      if (_openFolders.contains(name)) {
        _openFolders.remove(name);
      } else {
        _openFolders.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nodes = widget.customNodes ?? _defaultTree;

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
                      onTap: widget.onCreateFile ?? () {}),
                  const SizedBox(width: 10),
                  LIconButton(
                      icon: iconoir.FolderPlus(
                          color: c.text, width: 18, height: 18),
                      size: 36,
                      onTap: widget.onCreateFolder ?? () {}),
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
                  for (final n in nodes)
                    _Row(
                      node: TreeNode(
                        n.name,
                        n.depth,
                        folder: n.folder,
                        open: _openFolders.contains(n.name),
                        status: n.status,
                        fullPath: n.fullPath,
                      ),
                      active: n.name == widget.activeFile,
                      onTap: n.folder
                          ? () => _toggleFolder(n.name)
                          : () => widget.onOpenFile(n.name),
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
                      onTap: widget.onOpenSettings,
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
                    onTap: widget.onOpenSourceControl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Text('${widget.changeCount} changes',
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
  final TreeNode node;
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
