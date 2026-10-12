/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Desktop integration helpers for registering the app as the default
/// Markdown handler.
///
/// On Linux this is backed by `xdg-mime`. On Windows it registers per-user
/// file associations under `HKCU` using `reg.exe` (no administrator rights
/// needed) and opens the “Default apps” settings page, because Windows 8+
/// keeps the real association in a protected `UserChoice` key that
/// applications cannot write directly.
class DesktopIntegration {
  static const desktopId = 'md-file-viewer.desktop';
  static const mimeTypes = ['text/markdown', 'text/x-markdown'];

  static const _friendlyName = 'MD File Viewer';
  static const _progId = 'MDFileViewer';
  static const _progIdKey = r'Software\Classes\MDFileViewer';
  static const _mdKey = r'Software\Classes\.md';
  static const _openWithProgidsKey = r'Software\Classes\.md\OpenWithProgids';
  static const _capabilitiesKey = r'Software\MD File Viewer\Capabilities';
  static const _registeredAppsKey = r'Software\RegisteredApplications';
  static const _userChoiceKey =
      r'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\UserChoice';

  /// Name of the running executable; Windows keys “Open with” entries by it.
  static String get _exeName =>
      Platform.resolvedExecutable.split(Platform.pathSeparator).last;

  static String get _applicationsKey =>
      'Software\\Classes\\Applications\\$_exeName';

  String get _desktopFile {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.local/share/applications/$desktopId';
  }

  /// Whether the app is registered for the desktop.
  Future<bool> isInstalled() async {
    if (Platform.isWindows) {
      return _regKeyExists(_capabilitiesKey);
    }
    return File(_desktopFile).exists();
  }

  /// Whether this app is currently the default handler for Markdown.
  Future<bool> isDefault() async {
    if (Platform.isWindows) {
      final choice = await _regQuery(_userChoiceKey, 'ProgId');
      if (choice != null && choice.isNotEmpty) {
        final value = choice.toLowerCase();
        return value == _progId.toLowerCase() ||
            value == 'applications\\$_exeName'.toLowerCase();
      }
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
  ///
  /// On Windows, Microsoft reserves the final default-app choice to the
  /// user, so this registers the app and opens Settings → Default apps,
  /// where the user confirms MD File Viewer for `.md` files.
  Future<bool> setAsDefault() async {
    if (Platform.isWindows) {
      final registered = await _registerWindows();
      final opened = await openDefaultAppsSettings();
      return registered && opened;
    }
    var ok = true;
    for (final mime in mimeTypes) {
      final value = await _run(['default', desktopId, mime]);
      if (value == null) ok = false;
    }
    return ok;
  }

  /// Opens Settings → Default apps filtered to this app (Windows only).
  Future<bool> openDefaultAppsSettings() async {
    final uri = Uri.parse(
      'ms-settings:defaultapps'
      '?registeredAppUser=${Uri.encodeComponent(_friendlyName)}',
    );
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
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

    // “Open with” entry, keyed by the executable file name.
    await add(_applicationsKey, 'FriendlyAppName', _friendlyName);
    await add('$_applicationsKey\\DefaultIcon', '', '"$exe",0');
    await add('$_applicationsKey\\shell\\open\\command', '', command);

    // ProgID shown for `.md` files.
    await add(_progIdKey, '', _friendlyName);
    await add('$_progIdKey\\DefaultIcon', '', '"$exe",0');
    await add('$_progIdKey\\shell\\open\\command', '', command);
    await add(_openWithProgidsKey, _progId, '', type: 'REG_NONE');

    // Capabilities so the app appears in Settings → Default apps.
    await add(_capabilitiesKey, 'ApplicationName', _friendlyName);
    await add(_capabilitiesKey, 'ApplicationDescription',
        'View and edit Markdown files.');
    await add('$_capabilitiesKey\\FileAssociations', '.md', _progId);
    await add(_registeredAppsKey, _friendlyName, _capabilitiesKey);

    // Legacy fallback: only effective while Windows has no UserChoice set.
    if (!await _hasUserChoice()) {
      await add(_mdKey, '', _progId);
    }

    return ok;
  }

  Future<bool> _hasUserChoice() async {
    final choice = await _regQuery(_userChoiceKey, 'ProgId');
    return choice != null && choice.isNotEmpty;
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