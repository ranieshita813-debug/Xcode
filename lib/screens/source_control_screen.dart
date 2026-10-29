import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../services/git_service.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/clone_dialog.dart';
import '../widgets/common.dart';

class SourceControlScreen extends StatefulWidget {
  const SourceControlScreen({super.key, this.repoDir});

  final Directory? repoDir;

  @override
  State<SourceControlScreen> createState() => _SourceControlScreenState();
}

class _SourceControlScreenState extends State<SourceControlScreen> {
  final _gitService = GitService();
  final _message = TextEditingController(text: 'Fix: wait for save before clearing dirty flag');
  final _tokenController = TextEditingController();

  Directory? _activeRepoDir;
  bool _loading = false;
  String _currentBranch = 'main';
  List<GitChangeItem> _changes = [];
  bool _isRealGit = false;

  int get _stagedCount => _changes.where((c) => c.staged).length;

  @override
  void initState() {
    super.initState();
    _activeRepoDir = widget.repoDir;
    _refreshGitStatus();
  }

  @override
  void dispose() {
    _message.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _refreshGitStatus() async {
    final dir = _activeRepoDir;
    if (dir != null && await _gitService.isGitRepo(dir)) {
      setState(() => _loading = true);
      try {
        final status = await _gitService.getStatus(dir);
        if (!mounted) return;
        setState(() {
          _isRealGit = true;
          _currentBranch = status.branch;
          _changes = status.changes;
          _loading = false;
        });
        return;
      } catch (_) {}
    }

    // Fallback demo data
    setState(() {
      _isRealGit = false;
      _loading = false;
      _currentBranch = 'main';
      _changes = [
        GitChangeItem(path: 'src/components/editor.tsx', status: 'M', staged: true),
        GitChangeItem(path: 'src/fs.ts', status: 'M', staged: true),
        GitChangeItem(path: 'src/components/Tabs.tsx', status: 'A', staged: false),
      ];
    });
  }

  Future<void> _toggleStage(GitChangeItem item) async {
    final dir = _activeRepoDir;
    if (_isRealGit && dir != null) {
      try {
        if (item.staged) {
          await _gitService.unstageFile(dir, item.path);
        } else {
          await _gitService.stageFile(dir, item.path);
        }
        await _refreshGitStatus();
        return;
      } catch (e) {
        _toast('Error: $e');
      }
    }
    setState(() => item.staged = !item.staged);
  }

  Future<void> _stageAll() async {
    final dir = _activeRepoDir;
    if (_isRealGit && dir != null) {
      try {
        await _gitService.stageAll(dir);
        await _refreshGitStatus();
        return;
      } catch (e) {
        _toast('Error: $e');
      }
    }
    setState(() {
      for (final ch in _changes) {
        ch.staged = true;
      }
    });
  }

  Future<void> _commit() async {
    if (_stagedCount == 0) return;
    final msg = _message.text.trim();
    if (msg.isEmpty) {
      _toast('Please enter a commit message');
      return;
    }

    final dir = _activeRepoDir;
    if (_isRealGit && dir != null) {
      try {
        await _gitService.commit(dir, msg);
        _toast('Committed successfully');
        _message.clear();
        await _refreshGitStatus();
        return;
      } catch (e) {
        _toast('Commit error: $e');
        return;
      }
    }

    final n = _stagedCount;
    setState(() => _changes.removeWhere((c) => c.staged));
    _toast('Committed $n file${n == 1 ? '' : 's'}');
  }

  Future<void> _push() async {
    final dir = _activeRepoDir;
    if (_isRealGit && dir != null) {
      setState(() => _loading = true);
      try {
        await _gitService.push(dir, token: _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim());
        _toast('Pushed changes successfully to remote');
      } catch (e) {
        _toast('Push error: $e');
      } finally {
        setState(() => _loading = false);
        await _refreshGitStatus();
      }
    } else {
      _toast('Pushed 1 commit to origin/$_currentBranch (demo)');
    }
  }

  Future<void> _pull() async {
    final dir = _activeRepoDir;
    if (_isRealGit && dir != null) {
      setState(() => _loading = true);
      try {
        await _gitService.pull(dir, token: _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim());
        _toast('Pulled latest changes from remote');
      } catch (e) {
        _toast('Pull error: $e');
      } finally {
        setState(() => _loading = false);
        await _refreshGitStatus();
      }
    } else {
      _toast('Already up to date with origin/$_currentBranch (demo)');
    }
  }

  Future<void> _openCloneDialog() async {
    final newDir = await CloneDialog.show(context);
    if (newDir != null) {
      setState(() => _activeRepoDir = newDir);
      await _refreshGitStatus();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Row(
                  children: [
                    LIconButton(
                      icon: iconoir.Menu(color: c.text, width: 22, height: 22),
                      iconSize: 22,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Source Control',
                          style: LatticeText.ui(17, weight: FontWeight.w600, color: c.text)),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          iconoir.GitBranch(color: c.accent, width: 14, height: 14),
                          const SizedBox(width: 6),
                          Text(_currentBranch,
                              style: LatticeText.ui(13, weight: FontWeight.w500, color: c.text)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Clone Repository',
                      child: LIconButton(
                        icon: iconoir.GitBranch(color: c.accent, width: 18, height: 18),
                        onTap: _openCloneDialog,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Pull',
                      child: LIconButton(
                        icon: iconoir.Download(color: c.text, width: 18, height: 18),
                        onTap: _pull,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Push',
                      child: LIconButton(
                        icon: iconoir.Upload(color: c.text, width: 18, height: 18),
                        onTap: _push,
                      ),
                    ),
                    const SizedBox(width: 4),
                    LIconButton(
                      icon: iconoir.Refresh(color: c.text, width: 18, height: 18),
                      onTap: _refreshGitStatus,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Commit message input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      height: 84,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        controller: _message,
                        maxLines: null,
                        expands: true,
                        cursorColor: c.accent,
                        style: LatticeText.ui(14, color: c.text, height: 1.4),
                        decoration: InputDecoration(
                          hintText: 'Message (Ctrl+Enter to commit)',
                          hintStyle: LatticeText.ui(14, color: c.textFaint),
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  // CHANGES header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text('CHANGES',
                            style: LatticeText.ui(11,
                                weight: FontWeight.w600,
                                color: c.textMuted,
                                letterSpacing: 0.9)),
                        const SizedBox(width: 8),
                        CountBadge(_changes.length),
                        const Spacer(),
                        GestureDetector(
                          onTap: _stageAll,
                          child: Text('Stage all',
                              style: LatticeText.ui(13,
                                  weight: FontWeight.w500, color: c.accent)),
                        ),
                      ],
                    ),
                  ),
                  if (_changes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('No changes detected', style: LatticeText.ui(14, color: c.textMuted)),
                      ),
                    ),
                  for (final ch in _changes)
                    _ChangeRow(change: ch, onToggle: () => _toggleStage(ch)),
                  // Diff header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Text(_changes.isNotEmpty ? _changes.first.fileName : 'editor.tsx',
                            style: LatticeText.mono(12,
                                weight: FontWeight.w500, color: c.text)),
                        const Spacer(),
                        Text('+4', style: LatticeText.mono(12, color: c.success)),
                        const SizedBox(width: 8),
                        Text('−1', style: LatticeText.mono(12, color: c.error)),
                      ],
                    ),
                  ),
                  const _Diff(),
                ],
              ),
            ),
            // Commit button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
              child: Material(
                color: _stagedCount == 0 ? c.key : c.accent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _commit,
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconoir.Check(
                            color: _stagedCount == 0 ? c.textMuted : c.onAccent,
                            width: 18,
                            height: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Commit $_stagedCount staged file${_stagedCount == 1 ? '' : 's'}',
                          style: LatticeText.ui(15,
                              weight: FontWeight.w600,
                              color: _stagedCount == 0 ? c.textMuted : c.onAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change, required this.onToggle});
  final GitChangeItem change;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = change.status == 'A' ? c.success : (change.status == 'D' ? c.error : c.warning);
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(change.status,
                  style: LatticeText.ui(12, weight: FontWeight.w600, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(change.fileName,
                      style: LatticeText.ui(14, weight: FontWeight.w500, color: c.text)),
                  if (change.directory.isNotEmpty)
                    Text(change.directory, style: LatticeText.ui(12, color: c.textMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: change.staged ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: change.staged ? c.accent : c.border, width: 1.5),
                ),
                child: change.staged
                    ? Center(
                        child: iconoir.Check(color: c.onAccent, width: 14, height: 14),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Diff extends StatelessWidget {
  const _Diff();

  static const _lines = <(String, String)>[
    ('hunk', '@@ -8,6 +8,9 @@'),
    (' ', '  async function onSave(text: string) {'),
    ('-', '-   saveFile(path, text);'),
    ('+', '+   await saveFile(path, text);'),
    ('+', '+   setDirty(false);'),
    ('+', "+   track('save');"),
    (' ', '  }'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.surface,
      child: Column(
        children: [
          for (final (kind, text) in _lines)
            Container(
              height: 24,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: kind == '+'
                  ? c.success.withValues(alpha: 0.10)
                  : kind == '-'
                      ? c.error.withValues(alpha: 0.10)
                      : Colors.transparent,
              child: Text(
                text,
                style: LatticeText.mono(
                  12,
                  color: kind == '+'
                      ? c.success
                      : kind == '-'
                          ? c.error
                          : kind == 'hunk'
                              ? c.accent
                              : c.synPlain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
