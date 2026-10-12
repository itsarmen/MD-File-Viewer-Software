/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

/// Desktop integration helpers for registering the app as the default
/// Markdown handler.
///
/// On Linux this is backed by `xdg-mime`. On Windows it registers per-user
/// file associations under `HKCU\Software\Classes` using `reg.exe`, so no
/// administrator rights are required.
class DesktopIntegration {
  static const desktopId = 'md-file-viewer.desktop';
  static const mimeTypes = ['text/markdown', 'text/x-markdown'];

  static const _progId = 'MDFileViewer';
  static const _friendlyName = 'MD File Viewer';
  static const _appKey = r'Software\Classes\Applications\md-file-viewer.exe';
  static const _progIdKey = r'Software\Classes\MDFileViewer';
  static const _mdKey = r'Software\Classes\.md';
  static const _openWithKey = r'Software\Classes\.md\OpenWithProgids';

  String get _desktopFile {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.local/share/applications/$desktopId';
  }

  /// Whether the app is registered for the desktop.
  Future<bool> isInstalled() async {
    if (Platform.isWindows) {
      return _regKeyExists(_appKey);
    }
    return File(_desktopFile).exists();
  }

  /// Whether this app is currently the default handler for Markdown.
  Future<bool> isDefault() async {
    if (Platform.isWindows) {
      final value = await _regQuery(_mdKey, '');
      return value?.toLowerCase() == _progId.toLowerCase();
    }
    for (final mime in mimeTypes) {
      final value = await _run(['query', 'default', mime]);
      if (value != desktopId) return false;
    }
    return true;
  }

  /// Registers this app as the default opener for Markdown files.
  Future<bool> setAsDefault() async {
    if (Platform.isWindows) return _registerWindows();
    var ok = true;
    for (final mime in mimeTypes) {
      final value = await _run(['default', desktopId, mime]);
      if (value == null) ok = false;
    }
    return ok;
  }

  Future<bool> _registerWindows() async {
    final exe = Platform.resolvedExecutable;
    final command = '"$exe" "%1"';
    var ok = true;

    Future<void> add(
      String key,
      String name,
      String value, {
      String type = 'REG_SZ',
    }) async {
      if (!await _regAdd(key, name, value, type: type)) ok = false;
    }

    // Register the executable so it shows up under "Open with".
    await add(_appKey, 'FriendlyAppName', _friendlyName);
    await add('$_appKey\\DefaultIcon', '', '"$exe",0');
    await add('$_appKey\\shell\\open\\command', '', command);

    // Register a ProgID and advertise it for .md files.
    await add(_progIdKey, '', _friendlyName);
    await add('$_progIdKey\\DefaultIcon', '', '"$exe",0');
    await add('$_progIdKey\\shell\\open\\command', '', command);
    await add(_openWithKey, _progId, '', type: 'REG_NONE');

    // Best effort: become the default when Windows has no user choice set.
    await add(_mdKey, '', _progId);
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

  Future<bool> _regAdd(
    String key,
    String name,
    String value, {
    String type = 'REG_SZ',
  }) async {
    try {
      final args = <String>['add', 'HKCU\\$key'];
      if (name.isEmpty) {
        args.add('/ve');
      } else {
        args.addAll(['/v', name]);
      }
      args.addAll(['/t', type]);
      if (type != 'REG_NONE') {
        args.addAll(['/d', value]);
      }
      args.add('/f');
      final result = await Process.run('reg', args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _regKeyExists(String key) async {
    try {
      final result = await Process.run('reg', ['query', 'HKCU\\$key']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _regQuery(String key, String name) async {
    try {
      final args = <String>['query', 'HKCU\\$key'];
      if (name.isEmpty) {
        args.add('/ve');
      } else {
        args.addAll(['/v', name]);
      }
      final result = await Process.run('reg', args);
      if (result.exitCode != 0) return null;
      final output = result.stdout as String;
      for (final line in output.split('\n')) {
        final match = RegExp(r'REG_\w+\s+(.*)$').firstMatch(line.trim());
        if (match != null) return match.group(1)?.trim() ?? '';
      }
      return '';
    } catch (_) {
      return null;
    }
  }
}
