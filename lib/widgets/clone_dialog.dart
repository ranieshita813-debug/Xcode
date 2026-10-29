import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import 'package:path_provider/path_provider.dart';
import '../services/git_service.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class CloneDialog extends StatefulWidget {
  const CloneDialog({super.key, this.onSuccess});

  final ValueChanged<Directory>? onSuccess;

  static Future<Directory?> show(BuildContext context) {
    return showDialog<Directory>(
      context: context,
      builder: (ctx) => const CloneDialog(),
    );
  }

  @override
  State<CloneDialog> createState() => _CloneDialogState();
}

class _CloneDialogState extends State<CloneDialog> {
  final _gitService = GitService();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');

  bool _loading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _clone() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Please enter a GitHub repository URL or owner/repo.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = 'Cloning repository...';
      _isError = false;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final reposDir = Directory('${appDir.path}/repos');
      if (!await reposDir.exists()) {
        await reposDir.create(recursive: true);
      }

      final res = await _gitService.cloneRepo(
        url,
        reposDir,
        token: _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim(),
        branch: _branchController.text.trim().isEmpty ? null : _branchController.text.trim(),
      );

      if (!mounted) return;

      if (res.success && res.repoDir != null) {
        setState(() {
          _loading = false;
          _statusMessage = 'Cloned successfully!';
        });
        widget.onSuccess?.call(res.repoDir!);
        Navigator.of(context).pop(res.repoDir);
      } else {
        setState(() {
          _loading = false;
          _isError = true;
          _statusMessage = res.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isError = true;
        _statusMessage = 'Clone error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AlertDialog(
      backgroundColor: c.surface,
      title: Row(
        children: [
          iconoir.GitBranch(color: c.accent, width: 22, height: 22),
          const SizedBox(width: 8),
          Text('Clone GitHub Repository', style: LatticeText.ui(16, weight: FontWeight.w600, color: c.text)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repository URL or owner/repo', style: LatticeText.ui(12, color: c.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _urlController,
              autofocus: true,
              style: LatticeText.ui(14, color: c.text),
              cursorColor: c.accent,
              decoration: InputDecoration(
                hintText: 'e.g. flutter/flutter or https://github.com/user/repo.git',
                hintStyle: LatticeText.ui(12, color: c.textFaint),
                isDense: true,
                filled: true,
                fillColor: c.raised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Personal Access Token (optional for private repos)', style: LatticeText.ui(12, color: c.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _tokenController,
              obscureText: true,
              style: LatticeText.ui(14, color: c.text),
              cursorColor: c.accent,
              decoration: InputDecoration(
                hintText: 'ghp_xxxxxxxxxxxx (for push/private repos)',
                hintStyle: LatticeText.ui(12, color: c.textFaint),
                isDense: true,
                filled: true,
                fillColor: c.raised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Branch (optional)', style: LatticeText.ui(12, color: c.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: _branchController,
              style: LatticeText.ui(14, color: c.text),
              cursorColor: c.accent,
              decoration: InputDecoration(
                hintText: 'main',
                hintStyle: LatticeText.ui(12, color: c.textFaint),
                isDense: true,
                filled: true,
                fillColor: c.raised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  if (_loading) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: LatticeText.ui(12, color: _isError ? c.error : c.text),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: LatticeText.ui(14, color: c.textMuted)),
        ),
        FilledButton(
          onPressed: _loading ? null : _clone,
          style: FilledButton.styleFrom(backgroundColor: c.accent),
          child: Text('Clone', style: LatticeText.ui(14, weight: FontWeight.w600, color: c.onAccent)),
        ),
      ],
    );
  }
}
