/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:convert';
import 'dart:io';

/// Small JSON-backed store for recent files and last folder.
class RecentStore {
  RecentStore._(this._file);

  final File _file;

  static Future<RecentStore> open() async {
    final dir = Directory(_configDirectory());
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return RecentStore._(File('${dir.path}${Platform.pathSeparator}state.json'));
  }

  /// Per-user config directory: `%APPDATA%` on Windows, `~/.config` elsewhere.
  static String _configDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return '$appData\\md_file_viewer';
      }
      return '${Directory.current.path}\\md_file_viewer';
    }
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return '$home/.config/md_file_viewer';
  }

  Future<Map<String, dynamic>> read() async {
    try {
      if (!await _file.exists()) return <String, dynamic>{};
      final data = jsonDecode(await _file.readAsString());
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      await _file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } catch (_) {
      // Ignore persistence failures — the app still works in-memory.
    }
  }
}
