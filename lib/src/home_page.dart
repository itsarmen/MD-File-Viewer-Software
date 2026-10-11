/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

import 'github_markdown.dart';
import 'recent_store.dart';
import 'settings_dialog.dart';
import 'toast.dart';

enum ViewMode { preview, split, edit }

const _markdownExtensions = ['md', 'markdown', 'mdx', 'mdown', 'mkd', 'txt'];

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _editor = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final ScrollController _previewScroll = ScrollController();

  RecentStore? _store;
  String? _path;
  String _savedContent = '';
  String? _folder;
  List<String> _folderFiles = const [];
  List<String> _recent = const [];
  ViewMode _mode = ViewMode.preview;
  bool _sidebar = true;
  bool _dirty = false;

  String get _content => _editor.text;

  String? get _baseDirectory => _path == null ? null : File(_path!).parent.path;

  List<String> get _visibleFiles {
    final query = _search.text.trim().toLowerCase();
    final source = _folderFiles.isEmpty ? _recent : _folderFiles;
    if (query.isEmpty) return source;
    return source
        .where((p) => p.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _editor.addListener(_onEditorChanged);
    _restore();
  }

  @override
  void dispose() {
    _editor
      ..removeListener(_onEditorChanged)
      ..dispose();
    _search.dispose();
    _previewScroll.dispose();
    super.dispose();
  }

  void _onEditorChanged() {
    final dirty = _content != _savedContent;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  Future<void> _restore() async {
    final store = await RecentStore.open();
    final data = await store.read();
    if (!mounted) return;
    setState(() {
      _store = store;
      _recent = (data['recent'] as List?)?.cast<String>() ?? const [];
      _folder = data['folder'] as String?;
    });
    final folder = _folder;
    if (folder != null) {
      final files = await _scanFolder(folder);
      if (!mounted) return;
      setState(() => _folderFiles = files);
    }
    final last = widget.initialPath ?? data['last'] as String?;
    if (last != null && File(last).existsSync()) {
      await _loadPath(last);
    }
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.write({'recent': _recent, 'folder': _folder, 'last': _path});
  }

  Future<List<String>> _scanFolder(String dir) async {
    try {
      final directory = Directory(dir);
      if (!await directory.exists()) return const [];
      final entries = await directory.list(followLinks: false).toList();
      final files =
          entries
              .whereType<File>()
              .where((f) => _isMarkdown(f.path))
              .map((f) => f.path)
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return files;
    } catch (_) {
      return const [];
    }
  }

  bool _isMarkdown(String path) {
    final lower = path.toLowerCase();
    return _markdownExtensions.any((e) => lower.endsWith('.$e'));
  }

  Future<void> _loadPath(String path) async {
    try {
      final content = await File(path).readAsString();
      if (!mounted) return;
      setState(() {
        _path = path;
        _savedContent = content;
        _editor.text = content;
        _dirty = false;
        _recent = [path, ..._recent.where((p) => p != path)].take(12).toList();
      });
      await _persist();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not open file: $error');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFile(
      dialogTitle: 'Open Markdown file',
      type: FileType.custom,
      allowedExtensions: _markdownExtensions,
    );
    final path = result?.path;
    if (path != null) await _loadPath(path);
  }

  Future<void> _pickFolder() async {
    final dir = await FilePicker.getDirectoryPath(dialogTitle: 'Open folder');
    if (dir == null) return;
    final files = await _scanFolder(dir);
    if (!mounted) return;
    setState(() {
      _folder = dir;
      _folderFiles = files;
    });
    await _persist();
    if (files.isNotEmpty) await _loadPath(files.first);
  }

  Future<void> _save() async {
    final path = _path;
    if (path == null) return _saveAs();
    try {
      await File(path).writeAsString(_editor.text);
      if (!mounted) return;
      setState(() {
        _savedContent = _editor.text;
        _dirty = false;
      });
      _showMessage('Saved');
    } catch (error) {
      _showMessage('Could not save: $error');
    }
  }

  Future<void> _saveAs() async {
    final name = _path == null
        ? 'untitled.md'
        : File(_path!).uri.pathSegments.last;
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Markdown file',
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode(_editor.text)),
      mimeType: 'text/markdown',
    );
    if (uri == null) return;
    final path = uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
    try {
      if (uri.scheme != 'file') {
        await File(path).writeAsString(_editor.text);
      } else {
        await _loadPath(path);
      }
    } catch (error) {
      _showMessage('Could not save: $error');
    }
  }

  void _openLink(String text, String? href) {
    if (href == null || href.isEmpty || href.startsWith('#')) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (uri.hasScheme &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https' ||
            uri.scheme == 'mailto')) {
      _openInBrowser(href);
      return;
    }
    final base = _baseDirectory;
    if (base != null) {
      final resolved = File('$base/${uri.path}').absolute.path;
      if (File(resolved).existsSync() && _isMarkdown(resolved)) {
        _loadPath(resolved);
        return;
      }
      _launchExternal('file://${Uri.encodeFull(resolved)}');
      return;
    }
    _launchExternal(href);
  }

  /// Opens a URL in the default browser.
  ///
  /// `url_launcher`'s Linux backend launches through
  /// `gtk_show_uri_on_window`, which blocks the GTK main loop and makes the
  /// window report "is not responding" while the browser/portal starts. So we
  /// use `url_launcher` to check a handler exists, then spawn a detached
  /// handler process that never blocks the UI.
  Future<void> _openInBrowser(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    try {
      final can = await canLaunchUrl(uri);
      if (!can) {
        _showMessage('No application found to open this link.');
        return;
      }
    } catch (_) {
      // Proceed anyway; the detached handler is the source of truth.
    }
    await _launchExternal(href);
  }

  /// Opens a URL with the desktop's handler without blocking the UI thread.
  Future<void> _launchExternal(String url) async {
    for (final command in <List<String>>[
      <String>['xdg-open', url],
      <String>['gio', 'open', url],
    ]) {
      try {
        await Process.start(
          command.first,
          command.sublist(1),
          mode: ProcessStartMode.detached,
        );
        return;
      } catch (_) {
        // Try the next handler.
      }
    }
    _showMessage('Could not open link');
  }

  bool _isExternalLink(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) return false;
    return uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'mailto';
  }

  Future<void> _showLinkMenu(
    String text,
    String? href,
    Offset globalPosition,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );
    final external = href != null && _isExternalLink(href);
    final value = await showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        if (external)
          const PopupMenuItem<String>(
            value: 'open',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.open_in_new, size: 18),
              title: Text('Open link in browser'),
            ),
          ),
        if (href != null && href.isNotEmpty)
          const PopupMenuItem<String>(
            value: 'copyLink',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link, size: 18),
              title: Text('Copy link address'),
            ),
          ),
        if (text.isNotEmpty)
          const PopupMenuItem<String>(
            value: 'copyText',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.copy_rounded, size: 18),
              title: Text('Copy link text'),
            ),
          ),
      ],
    );
    if (!mounted || value == null) return;
    switch (value) {
      case 'open':
        _openLink(text, href);
      case 'copyLink':
        await Clipboard.setData(ClipboardData(text: href ?? ''));
        _showMessage('Link copied to clipboard');
      case 'copyText':
        await Clipboard.setData(ClipboardData(text: text));
        _showMessage('Copied to clipboard');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showToast(context, message);
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (_) => const QuickSettingsDialog(),
    );
  }

  KeyEventResult _handleScrollKeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_mode == ViewMode.edit) return KeyEventResult.ignored;
    final controller = _previewScroll;
    if (!controller.hasClients) return KeyEventResult.ignored;
    final position = controller.position;
    final page = position.viewportDimension * 0.9;
    final double? target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => position.pixels + 48,
      LogicalKeyboardKey.arrowUp => position.pixels - 48,
      LogicalKeyboardKey.pageDown => position.pixels + page,
      LogicalKeyboardKey.pageUp => position.pixels - page,
      LogicalKeyboardKey.home => 0.0,
      LogicalKeyboardKey.end => position.maxScrollExtent,
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    controller.jumpTo(target.clamp(0.0, position.maxScrollExtent).toDouble());
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _pickFile,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): _saveAs,
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleScrollKeys,
        child: SelectionArea(
          contextMenuBuilder: (context, state) =>
              AdaptiveTextSelectionToolbar.selectableRegion(
                selectableRegionState: state,
              ),
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 4,
              leading: YaruIconButton(
                icon: Icon(_sidebar ? Icons.menu_open : Icons.menu),
                tooltip: 'Toggle sidebar',
                onPressed: () => setState(() => _sidebar = !_sidebar),
              ),
              title: _buildTitle(theme),
              actions: [
                YaruIconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'Open file (Ctrl+O)',
                  onPressed: _pickFile,
                ),
                YaruIconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: 'Open folder',
                  onPressed: _pickFolder,
                ),
                YaruIconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Save (Ctrl+S)',
                  onPressed: _dirty || _path == null ? _save : null,
                ),
                const SizedBox(width: 8),
                SegmentedButton<ViewMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ViewMode.preview,
                      icon: Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'Preview',
                    ),
                    ButtonSegment(
                      value: ViewMode.split,
                      icon: Icon(Icons.vertical_split_outlined, size: 18),
                      tooltip: 'Split',
                    ),
                    ButtonSegment(
                      value: ViewMode.edit,
                      icon: Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
                const SizedBox(width: 8),
                YaruIconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Quick settings',
                  onPressed: _openSettings,
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (_sidebar) _buildSidebar(theme),
                      if (_sidebar) const VerticalDivider(width: 1),
                      Expanded(child: _buildContent(theme)),
                    ],
                  ),
                ),
                _buildStatusBar(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final name = _path == null
        ? 'MD File Viewer'
        : File(_path!).uri.pathSegments.last;
    return Row(
      children: [
        const Icon(Icons.article_outlined, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (_dirty)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '•',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final files = _visibleFiles;
    final recentMode = _folderFiles.isEmpty;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: YaruSearchField(
              controller: _search,
              hintText: 'Filter files',
              autofocus: false,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              recentMode
                  ? 'RECENT'
                  : (_folder == null
                        ? 'FILES'
                        : File(_folder!).uri.pathSegments
                              .where((s) => s.isNotEmpty)
                              .last
                              .toUpperCase()),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? _buildEmptySidebar(theme)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final path = files[index];
                      final selected = path == _path;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        leading: const Icon(
                          Icons.description_outlined,
                          size: 18,
                        ),
                        title: Tooltip(
                          message: path,
                          child: Text(
                            File(path).uri.pathSegments.last,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () => _loadPath(path),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySidebar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No files yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFolder,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Open folder'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_path == null) return _buildWelcome(theme);
    switch (_mode) {
      case ViewMode.preview:
        return _buildPreview();
      case ViewMode.edit:
        return _buildEditor();
      case ViewMode.split:
        return Row(
          children: [
            Expanded(child: _buildEditor()),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPreview()),
          ],
        );
    }
  }

  Widget _buildWelcome(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text('MD File Viewer', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Open a Markdown file or a folder to preview it with '
              'GitHub-styled formatting.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Open file'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickFolder,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Open folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Scrollbar(
      controller: _previewScroll,
      child: SingleChildScrollView(
        controller: _previewScroll,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: GitHubMarkdown(
              data: _content,
              imageDirectory: _baseDirectory,
              onTapLink: _openLink,
              onLinkContextMenu: _showLinkMenu,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TextField(
        controller: _editor,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.55,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
          hintText: 'Write Markdown here…',
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    final words = _content.trim().isEmpty
        ? 0
        : _content.trim().split(RegExp(r'\s+')).length;
    final lines = _content.isEmpty ? 0 : _content.split('\n').length;
    final path = _path ?? 'No file open';
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              path,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            '$words words · $lines lines · ${_mode.name}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
