import 'dart:io';
import 'package:path/path.dart' as p;

class GitChangeItem {
  GitChangeItem({
    required this.path,
    required this.status, // 'M' | 'A' | 'D' | 'U' | '?'
    required this.staged,
  });

  final String path;
  final String status;
  bool staged;

  String get fileName => path.contains('/') ? path.split('/').last : path;
  String get directory => path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
}

class GitStatusResult {
  GitStatusResult({
    required this.branch,
    required this.changes,
    required this.aheadCount,
    required this.behindCount,
  });

  final String branch;
  final List<GitChangeItem> changes;
  final int aheadCount;
  final int behindCount;

  List<GitChangeItem> get stagedChanges => changes.where((c) => c.staged).toList();
  List<GitChangeItem> get unstagedChanges => changes.where((c) => !c.staged).toList();
}

class GitCloneResult {
  GitCloneResult({required this.success, required this.message, this.repoDir});
  final bool success;
  final String message;
  final Directory? repoDir;
}

class GitService {
  GitService();

  /// Formats GitHub URL to include token if provided.
  /// Handles both 'owner/repo' and full 'https://github.com/owner/repo.git' formats.
  String formatRepoUrl(String rawUrl, {String? token}) {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('git@')) {
      url = 'https://github.com/$url';
    }
    if (!url.endsWith('.git')) {
      url = '$url.git';
    }
    if (token != null && token.isNotEmpty && url.startsWith('https://')) {
      final uri = Uri.parse(url);
      url = 'https://$token@${uri.host}${uri.path}';
    }
    return url;
  }

  Future<ProcessResult> _runGit(List<String> args, {Directory? workingDir}) async {
    return Process.run(
      'git',
      args,
      workingDirectory: workingDir?.path,
      runInShell: true,
    );
  }

  Future<bool> isGitInstalled() async {
    try {
      final res = await Process.run('git', ['--version'], runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isGitRepo(Directory dir) async {
    if (!await dir.exists()) return false;
    final gitFolder = Directory(p.join(dir.path, '.git'));
    if (await gitFolder.exists()) return true;

    final res = await _runGit(['rev-parse', '--is-inside-work-tree'], workingDir: dir);
    return res.exitCode == 0 && res.stdout.toString().trim() == 'true';
  }

  Future<void> initRepo(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final res = await _runGit(['init'], workingDir: dir);
    if (res.exitCode != 0) {
      throw Exception('Failed to initialize Git repository: ${res.stderr}');
    }
  }

  Future<GitCloneResult> cloneRepo(
    String repoUrl,
    Directory parentDir, {
    String? token,
    String? branch,
    String? targetFolderName,
  }) async {
    try {
      final formattedUrl = formatRepoUrl(repoUrl, token: token);
      final folderName = targetFolderName ??
          p.basenameWithoutExtension(Uri.parse(formattedUrl).pathSegments.last);

      final targetDir = Directory(p.join(parentDir.path, folderName));
      if (await targetDir.exists() && (await targetDir.list().toList()).isNotEmpty) {
        return GitCloneResult(
          success: false,
          message: 'Target directory "${targetDir.path}" already exists and is not empty.',
        );
      }

      final args = ['clone'];
      if (branch != null && branch.isNotEmpty) {
        args.addAll(['-b', branch]);
      }
      args.addAll([formattedUrl, targetDir.path]);

      final res = await _runGit(args);
      if (res.exitCode == 0) {
        return GitCloneResult(
          success: true,
          message: 'Cloned successfully to ${targetDir.path}',
          repoDir: targetDir,
        );
      } else {
        return GitCloneResult(
          success: false,
          message: 'Clone failed: ${res.stderr.toString().replaceAll(RegExp(r'https://[^@]+@'), 'https://***@')}',
        );
      }
    } catch (e) {
      return GitCloneResult(
        success: false,
        message: 'Clone error: $e',
      );
    }
  }

  Future<GitStatusResult> getStatus(Directory repoDir) async {
    var branch = 'main';
    var ahead = 0;
    var behind = 0;
    final changes = <GitChangeItem>[];

    final branchRes = await _runGit(['rev-parse', '--abbrev-ref', 'HEAD'], workingDir: repoDir);
    if (branchRes.exitCode == 0) {
      branch = branchRes.stdout.toString().trim();
    }

    final statusRes = await _runGit(['status', '--porcelain=v1'], workingDir: repoDir);
    if (statusRes.exitCode == 0) {
      final lines = statusRes.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.length < 3) continue;
        final indexStatus = line[0];
        final workStatus = line[1];
        final filePath = line.substring(3).trim();

        if (indexStatus != ' ' && indexStatus != '?') {
          changes.add(GitChangeItem(
            path: filePath,
            status: _mapStatusChar(indexStatus),
            staged: true,
          ));
        }
        if (workStatus != ' ' || indexStatus == '?') {
          changes.add(GitChangeItem(
            path: filePath,
            status: _mapStatusChar(workStatus == ' ' ? indexStatus : workStatus),
            staged: indexStatus == '?' ? false : false,
          ));
        }
      }
    }

    return GitStatusResult(
      branch: branch,
      changes: changes,
      aheadCount: ahead,
      behindCount: behind,
    );
  }

  String _mapStatusChar(String c) {
    switch (c) {
      case 'M':
        return 'M';
      case 'A':
        return 'A';
      case 'D':
        return 'D';
      case '?':
        return 'U';
      default:
        return 'M';
    }
  }

  Future<void> stageFile(Directory repoDir, String filePath) async {
    final res = await _runGit(['add', filePath], workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Failed to stage $filePath: ${res.stderr}');
    }
  }

  Future<void> stageAll(Directory repoDir) async {
    final res = await _runGit(['add', '.'], workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Failed to stage all files: ${res.stderr}');
    }
  }

  Future<void> unstageFile(Directory repoDir, String filePath) async {
    final res = await _runGit(['restore', '--staged', filePath], workingDir: repoDir);
    if (res.exitCode != 0) {
      // Fallback for older git
      await _runGit(['reset', 'HEAD', filePath], workingDir: repoDir);
    }
  }

  Future<void> unstageAll(Directory repoDir) async {
    final res = await _runGit(['restore', '--staged', '.'], workingDir: repoDir);
    if (res.exitCode != 0) {
      await _runGit(['reset', 'HEAD'], workingDir: repoDir);
    }
  }

  Future<void> commit(
    Directory repoDir,
    String message, {
    String? authorName,
    String? authorEmail,
  }) async {
    if (authorName != null && authorName.isNotEmpty) {
      await _runGit(['config', 'user.name', authorName], workingDir: repoDir);
    }
    if (authorEmail != null && authorEmail.isNotEmpty) {
      await _runGit(['config', 'user.email', authorEmail], workingDir: repoDir);
    }

    final res = await _runGit(['commit', '-m', message], workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Commit failed: ${res.stderr}');
    }
  }

  Future<void> push(
    Directory repoDir, {
    String? token,
    String remote = 'origin',
    String? branch,
  }) async {
    final currentBranch = branch ?? (await getStatus(repoDir)).branch;
    if (token != null && token.isNotEmpty) {
      final urlRes = await _runGit(['remote', 'get-url', remote], workingDir: repoDir);
      if (urlRes.exitCode == 0) {
        final currentUrl = urlRes.stdout.toString().trim();
        final authUrl = formatRepoUrl(currentUrl, token: token);
        await _runGit(['remote', 'set-url', remote, authUrl], workingDir: repoDir);
      }
    }

    final res = await _runGit(['push', remote, currentBranch], workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Push failed: ${res.stderr}');
    }
  }

  Future<void> pull(
    Directory repoDir, {
    String? token,
    String remote = 'origin',
    String? branch,
  }) async {
    final currentBranch = branch ?? (await getStatus(repoDir)).branch;
    if (token != null && token.isNotEmpty) {
      final urlRes = await _runGit(['remote', 'get-url', remote], workingDir: repoDir);
      if (urlRes.exitCode == 0) {
        final currentUrl = urlRes.stdout.toString().trim();
        final authUrl = formatRepoUrl(currentUrl, token: token);
        await _runGit(['remote', 'set-url', remote, authUrl], workingDir: repoDir);
      }
    }

    final res = await _runGit(['pull', remote, currentBranch], workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Pull failed: ${res.stderr}');
    }
  }

  Future<List<String>> getBranches(Directory repoDir) async {
    final res = await _runGit(['branch', '-a'], workingDir: repoDir);
    if (res.exitCode != 0) return ['main'];

    final branches = <String>[];
    for (final line in res.stdout.toString().split('\n')) {
      var trimmed = line.replaceAll('*', '').trim();
      if (trimmed.startsWith('remotes/')) {
        trimmed = trimmed.substring('remotes/'.length);
      }
      if (trimmed.isNotEmpty && !branches.contains(trimmed)) {
        branches.add(trimmed);
      }
    }
    return branches.isEmpty ? ['main'] : branches;
  }

  Future<void> checkoutBranch(Directory repoDir, String branchName, {bool create = false}) async {
    final args = create ? ['checkout', '-b', branchName] : ['checkout', branchName];
    final res = await _runGit(args, workingDir: repoDir);
    if (res.exitCode != 0) {
      throw Exception('Checkout failed: ${res.stderr}');
    }
  }

  Future<String> getDiff(Directory repoDir, {String? filePath}) async {
    final args = ['diff'];
    if (filePath != null) args.add(filePath);
    final res = await _runGit(args, workingDir: repoDir);
    if (res.exitCode == 0) {
      return res.stdout.toString();
    }
    return '';
  }
}
