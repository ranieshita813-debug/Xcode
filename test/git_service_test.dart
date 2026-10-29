import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/services/git_service.dart';

void main() {
  final gitService = GitService();

  test('formatRepoUrl formats short and full GitHub URLs', () {
    expect(gitService.formatRepoUrl('flutter/flutter'), equals('https://github.com/flutter/flutter.git'));
    expect(gitService.formatRepoUrl('https://github.com/owner/repo'), equals('https://github.com/owner/repo.git'));
    expect(
      gitService.formatRepoUrl('owner/repo', token: 'ghp_secret'),
      equals('https://ghp_secret@github.com/owner/repo.git'),
    );
  });

  test('isGitInstalled returns a boolean', () async {
    final installed = await gitService.isGitInstalled();
    expect(installed, isA<bool>());
  });

  test('isGitRepo returns false for non-git temp directory', () async {
    final tempDir = await Directory.systemTemp.createTemp('non_git_test');
    try {
      final isRepo = await gitService.isGitRepo(tempDir);
      expect(isRepo, isFalse);
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
