/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'toast.dart';

/// Palette modelled on GitHub's Primer design tokens.
class GitHubPalette {
  const GitHubPalette({
    required this.canvas,
    required this.canvasSubtle,
    required this.fgDefault,
    required this.fgMuted,
    required this.border,
    required this.accent,
    required this.neutralMuted,
    required this.isDark,
  });

  final Color canvas;
  final Color canvasSubtle;
  final Color fgDefault;
  final Color fgMuted;
  final Color border;
  final Color accent;
  final Color neutralMuted;
  final bool isDark;

  static const light = GitHubPalette(
    canvas: Color(0xFFFFFFFF),
    canvasSubtle: Color(0xFFF6F8FA),
    fgDefault: Color(0xFF1F2328),
    fgMuted: Color(0xFF59636E),
    border: Color(0xFFD0D7DE),
    accent: Color(0xFF0969DA),
    neutralMuted: Color(0xFF818B98),
    isDark: false,
  );

  static const dark = GitHubPalette(
    canvas: Color(0xFF0D1117),
    canvasSubtle: Color(0xFF161B22),
    fgDefault: Color(0xFFE6EDF3),
    fgMuted: Color(0xFF8B949E),
    border: Color(0xFF30363D),
    accent: Color(0xFF4493F8),
    neutralMuted: Color(0xFF6E7681),
    isDark: true,
  );

  static GitHubPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

MarkdownStyleSheet gitHubMarkdownStyleSheet(GitHubPalette p) {
  const mono = 'monospace';
  final body = TextStyle(color: p.fgDefault, fontSize: 16, height: 1.6);
  final heading = TextStyle(
    color: p.fgDefault,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  return MarkdownStyleSheet(
    a: TextStyle(
      color: p.accent,
      decoration: TextDecoration.underline,
      decorationColor: p.accent.withValues(alpha: 0.4),
    ),
    p: body,
    pPadding: const EdgeInsets.only(bottom: 16),
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.w600),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    h1: heading.copyWith(fontSize: 32),
    h1Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h2: heading.copyWith(fontSize: 24),
    h2Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h3: heading.copyWith(fontSize: 20),
    h3Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h4: heading.copyWith(fontSize: 16),
    h4Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h5: heading.copyWith(fontSize: 14),
    h5Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h6: heading.copyWith(fontSize: 13.6, color: p.fgMuted),
    h6Padding: const EdgeInsets.only(top: 24, bottom: 16),
    code: TextStyle(
      fontFamily: mono,
      fontSize: 13.6,
      color: p.fgDefault,
      backgroundColor: p.isDark
          ? const Color(0x3D6E7681)
          : const Color(0x1F818B98),
    ),
    codeblockPadding: const EdgeInsets.all(16),
    codeblockDecoration: BoxDecoration(
      color: p.canvasSubtle,
      border: Border.all(color: p.border),
      borderRadius: BorderRadius.circular(6),
    ),
    blockquote: TextStyle(color: p.fgMuted, fontSize: 16, height: 1.6),
    blockquotePadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: p.border, width: 4)),
    ),
    listBullet: body,
    listIndent: 28,
    listBulletPadding: const EdgeInsets.only(right: 8),
    blockSpacing: 16,
    checkbox: body,
    tableHead: TextStyle(
      color: p.fgDefault,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    tableBody: TextStyle(color: p.fgDefault, fontSize: 14, height: 1.5),
    tableBorder: TableBorder.all(color: p.border, width: 1),
    tableColumnWidth: const IntrinsicColumnWidth(),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    tableVerticalAlignment: TableCellVerticalAlignment.middle,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: p.border, width: 2)),
    ),
  );
}

/// Renders Markdown the way GitHub does (GFM), with syntax-highlighted code.
class GitHubMarkdown extends StatefulWidget {
  const GitHubMarkdown({
    super.key,
    required this.data,
    this.imageDirectory,
    this.onTapLink,
    this.onLinkContextMenu,
  });

  final String data;
  final String? imageDirectory;
  final void Function(String text, String? href)? onTapLink;

  /// Invoked on a secondary (right) click over a link, with the global
  /// position of the click so a context menu can be shown there.
  final void Function(String text, String? href, Offset globalPosition)?
  onLinkContextMenu;

  @override
  State<GitHubMarkdown> createState() => _GitHubMarkdownState();
}

class _GitHubMarkdownState extends State<GitHubMarkdown> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final palette = GitHubPalette.of(context);
    final sheet = gitHubMarkdownStyleSheet(palette);
    return MarkdownBody(
      data: _expandHtmlImages(widget.data),
      selectable: false,
      extensionSet: md.ExtensionSet.gitHubWeb,
      styleSheet: sheet,
      sizedImageBuilder: (config) =>
          _buildImage(config, palette, widget.imageDirectory),
      builders: {
        'pre': _CodeBlockBuilder(palette: palette),
        'a': _LinkBuilder(
          style: sheet.a ?? TextStyle(color: palette.accent),
          register: _recognizers.add,
          onTap: (text, href) => widget.onTapLink?.call(text, href),
          onSecondaryTap: widget.onLinkContextMenu,
        ),
      },
      onTapLink: (text, href, title) => widget.onTapLink?.call(text, href),
    );
  }
}

class _LinkBuilder extends MarkdownElementBuilder {
  _LinkBuilder({
    required this.style,
    required this.register,
    required this.onTap,
    this.onSecondaryTap,
  });

  final TextStyle style;
  final void Function(TapGestureRecognizer recognizer) register;
  final void Function(String text, String? href) onTap;
  final void Function(String text, String? href, Offset globalPosition)?
  onSecondaryTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final href = element.attributes['href'];
    final text = element.textContent;
    Offset lastSecondaryTap = Offset.zero;
    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () => onTap(text, href);
    recognizer.onSecondaryTapDown = (details) {
      lastSecondaryTap = details.globalPosition;
    };
    recognizer.onSecondaryTap = () {
      final handler = onSecondaryTap;
      if (handler != null) {
        handler(text, href, lastSecondaryTap);
      } else {
        onTap(text, href);
      }
    };
    register(recognizer);
    return Text.rich(
      TextSpan(
        text: text.isEmpty ? (href ?? '') : text,
        style: preferredStyle?.merge(style) ?? style,
        recognizer: recognizer,
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.palette});

  final GitHubPalette palette;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    String? language;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final cls = child.attributes['class'];
        if (cls != null && cls.startsWith('language-')) {
          language = cls.substring('language-'.length);
        }
        break;
      }
    }
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    return _CodeBlock(code: code, language: language, palette: palette);
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.language,
    required this.palette,
  });

  final String code;
  final String? language;
  final GitHubPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.canvasSubtle,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (language ?? 'text').toLowerCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.fgMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                _CopyButton(code: code, palette: palette),
              ],
            ),
          ),
          HighlightView(
            code,
            language: language ?? 'plaintext',
            theme: palette.isDark ? atomOneDarkTheme : githubTheme,
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13.6,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.code, required this.palette});

  final String code;
  final GitHubPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (context.mounted) {
          showToast(
            context,
            'Copied to clipboard',
            duration: const Duration(seconds: 1),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.copy_rounded, size: 16, color: palette.fgMuted),
      ),
    );
  }
}

/// Rewrites raw HTML `<img>` tags into Markdown image syntax so the native
/// renderer can display them (GitHub allows HTML inside Markdown).
///
/// Fenced code blocks and inline code spans are left untouched. Other HTML
/// container/formatting tags (e.g. `<p>`, `<a>`, `<div>`) are stripped, and
/// HTML comments are removed.
String _expandHtmlImages(String source) {
  final text = source.replaceAll(_htmlComment, '');
  final lines = text.split('\n');
  final result = <String>[];
  var inFence = false;
  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = !inFence;
      result.add(line);
      continue;
    }
    result.add(inFence ? line : _processHtmlLine(line));
  }
  return result.join('\n');
}

final RegExp _htmlComment = RegExp(r'<!--[\s\S]*?-->');
final RegExp _htmlImgTag = RegExp(r'<img\b([^>]*)>', caseSensitive: false);
final RegExp _htmlAnyTag = RegExp(r'</?[a-zA-Z][a-zA-Z0-9]*(\s[^>]*)?/?>');
final RegExp _inlineCodeSpan = RegExp(r'`[^`]*`');

String _processHtmlLine(String line) {
  final held = <String>[];
  var work = line.replaceAllMapped(_inlineCodeSpan, (match) {
    held.add(match.group(0)!);
    return '\u0000${held.length - 1}\u0000';
  });
  work = work.replaceAllMapped(
    _htmlImgTag,
    (match) => _imgTagToMarkdown(match.group(1) ?? ''),
  );
  work = work.replaceAll(_htmlAnyTag, '');
  work = work.replaceAllMapped(
    RegExp(r'\u0000(\d+)\u0000'),
    (match) => held[int.parse(match.group(1)!)],
  );
  return work;
}

String _imgTagToMarkdown(String attributes) {
  final src = _htmlAttribute(attributes, 'src');
  if (src == null || src.isEmpty) return '';
  final alt = _htmlAttribute(attributes, 'alt') ?? '';
  final title = _htmlAttribute(attributes, 'title') ?? '';
  final destination = _imageDestination(
    src,
    _htmlAttribute(attributes, 'width'),
    _htmlAttribute(attributes, 'height'),
  );
  final escapedAlt = alt
      .replaceAll(r'\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');
  final buffer = StringBuffer('![$escapedAlt]($destination');
  if (title.isNotEmpty) {
    buffer.write(' "${title.replaceAll('"', r'\"')}"');
  }
  buffer.write(')');
  return buffer.toString();
}

String _imageDestination(String src, String? width, String? height) {
  var destination = src
      .replaceAll(' ', '%20')
      .replaceAll('(', '%28')
      .replaceAll(')', '%29');
  final w = _digitsOnly(width);
  final h = _digitsOnly(height);
  if (w.isNotEmpty || h.isNotEmpty) {
    destination += '#${w}x$h';
  }
  return destination;
}

String _digitsOnly(String? value) =>
    value == null ? '' : value.replaceAll(RegExp(r'[^0-9.]'), '');

String? _htmlAttribute(String attributes, String name) {
  final match = RegExp(
    '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s"\'>]+))',
    caseSensitive: false,
  ).firstMatch(attributes);
  if (match == null) return null;
  return match.group(1) ?? match.group(2) ?? match.group(3);
}

/// Builds an image widget for a Markdown `![alt](src)` reference.
///
/// Handles remote (`http`/`https`), inline (`data:`), bundled (`resource:`) and
/// local files. Relative local paths are resolved against [baseDir] (the
/// directory of the Markdown file being previewed), the way GitHub resolves
/// repository-relative image links.
Widget _buildImage(
  MarkdownImageConfig config,
  GitHubPalette palette,
  String? baseDir,
) {
  final uri = config.uri;
  final width = config.width;
  final height = config.height;

  Widget broken(BuildContext context, Object error, StackTrace? stackTrace) =>
      _BrokenImage(config: config, palette: palette);

  switch (uri.scheme) {
    case 'http':
    case 'https':
      return Image.network(
        uri.toString(),
        width: width,
        height: height,
        errorBuilder: broken,
      );
    case 'data':
      try {
        return Image.memory(
          uri.data!.contentAsBytes(),
          width: width,
          height: height,
          errorBuilder: broken,
        );
      } catch (_) {
        return _BrokenImage(config: config, palette: palette);
      }
    case 'resource':
      return Image.asset(
        uri.path,
        width: width,
        height: height,
        errorBuilder: broken,
      );
  }

  final source = uri.scheme == 'file'
      ? uri.toFilePath()
      : _decodeSource(uri.toString());
  return Image.file(
    _resolveImageFile(source, baseDir),
    width: width,
    height: height,
    filterQuality: FilterQuality.medium,
    errorBuilder: broken,
  );
}

String _decodeSource(String value) {
  try {
    return Uri.decodeFull(value);
  } catch (_) {
    return value;
  }
}

/// Resolves a local image path against the Markdown file's directory.
File _resolveImageFile(String source, String? baseDir) {
  final candidates = <String>[];
  if (source.startsWith('/')) {
    candidates.add(source);
    if (baseDir != null) {
      candidates.add(_joinPath(baseDir, source.substring(1)));
    }
  } else {
    candidates.add(baseDir == null ? source : _joinPath(baseDir, source));
  }
  for (final candidate in candidates) {
    final normalized = _normalizePath(candidate);
    if (File(normalized).existsSync()) return File(normalized);
  }
  return File(_normalizePath(candidates.first));
}

String _joinPath(String dir, String relative) =>
    dir.endsWith('/') ? '$dir$relative' : '$dir/$relative';

String _normalizePath(String path) {
  final isAbsolute = path.startsWith('/');
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isNotEmpty && segments.last != '..') {
        segments.removeLast();
      } else if (!isAbsolute) {
        segments.add('..');
      }
    } else {
      segments.add(segment);
    }
  }
  return '${isAbsolute ? '/' : ''}${segments.join('/')}';
}

/// Shown when an image cannot be loaded, mirroring GitHub's broken-image style.
class _BrokenImage extends StatelessWidget {
  const _BrokenImage({required this.config, required this.palette});

  final MarkdownImageConfig config;
  final GitHubPalette palette;

  @override
  Widget build(BuildContext context) {
    final label = (config.alt?.isNotEmpty ?? false)
        ? config.alt!
        : (config.title?.isNotEmpty ?? false)
        ? config.title!
        : 'Image';
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.canvasSubtle,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 16, color: palette.fgMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: palette.fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}
