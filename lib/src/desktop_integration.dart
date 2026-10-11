/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

/// Desktop integration helpers backed by `xdg-mime`.
class DesktopIntegration {
  static const desktopId = 'md-file-viewer.desktop';
  static const mimeTypes = ['text/markdown', 'text/x-markdown'];

  String get _desktopFile {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.local/share/applications/$desktopId';
  }

  /// Whether the app's .desktop entry is installed for this user.
  Future<bool> isInstalled() async => File(_desktopFile).exists();

  /// Whether this app is currently the default handler for Markdown.
  Future<bool> isDefault() async {
    for (final mime in mimeTypes) {
      final value = await _run(['query', 'default', mime]);
      if (value != desktopId) return false;
    }
    return true;
  }

  /// Registers this app as the default opener for Markdown files.
  Future<bool> setAsDefault() async {
    var ok = true;
    for (final mime in mimeTypes) {
      final value = await _run(['default', desktopId, mime]);
      if (value == null) ok = false;
    }
    return ok;
  }

  Future<String?> _run(List<String> args) async {
    try {
      final result = await Process.run('xdg-mime', args);
      if (result.exitCode != 0) return null;
      return (result.stdout as String).trim();
    } catch (_) {
      return null;
    }
  }
}
