/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import 'desktop_integration.dart';

class QuickSettingsDialog extends StatefulWidget {
  const QuickSettingsDialog({super.key});

  @override
  State<QuickSettingsDialog> createState() => _QuickSettingsDialogState();
}

class _QuickSettingsDialogState extends State<QuickSettingsDialog> {
  final _integration = DesktopIntegration();

  bool _loading = true;
  bool _installed = false;
  bool _isDefault = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final installed = await _integration.isInstalled();
    final isDefault = installed && await _integration.isDefault();
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _isDefault = isDefault;
      _loading = false;
    });
  }

  Future<void> _setDefault() async {
    setState(() => _busy = true);
    final ok = await _integration.setAsDefault();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    _message(
      ok
          ? 'MD File Viewer is now the default for .md files'
          : 'Could not set the default app',
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Quick Settings')),
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _loading || _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DESKTOP INTEGRATION',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: YaruCircularProgressIndicator()),
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _isDefault
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _isDefault
                      ? Colors.green
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: const Text('Default MD viewer/editor'),
                subtitle: Text(_subtitle()),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: (_busy || _isDefault || !_installed)
                      ? null
                      : _setDefault,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Set as default'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _loading || _busy ? null : _refresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh status'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _subtitle() {
    if (!_installed) {
      return Platform.isWindows
          ? 'Not registered for the desktop yet. Use “Set as default”.'
          : 'Not installed for the desktop yet. Run scripts/install.sh first.';
    }
    if (_isDefault) {
      return 'Enabled — double-clicking a .md file opens this app.';
    }
    return Platform.isWindows
        ? 'Registered, but another app opens .md files. Use “Set as default”.'
        : 'Disabled — .md files currently open in another app.';
  }
}
