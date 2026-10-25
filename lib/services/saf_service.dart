import 'package:flutter/services.dart';

/// Storage Access Framework (SAF) integration for Android 11+ SAF document browsing.
class SafService {
  static const MethodChannel _channel = MethodChannel('com.example.lattice/saf');

  Future<String?> openDocumentTree() async {
    try {
      final uri = await _channel.invokeMethod<String>('openDocumentTree');
      return uri;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> listFiles(String treeUri) async {
    try {
      final list = await _channel.invokeListMethod<String>('listFiles', {'uri': treeUri});
      return list ?? [];
    } on MissingPluginException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> readFile(String documentUri) async {
    try {
      return await _channel.invokeMethod<String>('readFile', {'uri': documentUri});
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeFile(String documentUri, String content) async {
    try {
      final result = await _channel.invokeMethod<bool>('writeFile', {
        'uri': documentUri,
        'content': content,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
