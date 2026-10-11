/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_file_viewer/src/github_markdown.dart';

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9'
    'awAAAABJRU5ErkJggg==';

void main() {
  testWidgets('local images resolve against the markdown directory', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('mdv_image_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final image = File('${dir.path}/pic.png')
      ..writeAsBytesSync(base64Decode(_onePixelPng));
    File('${dir.path}/nested.png').writeAsBytesSync(base64Decode(_onePixelPng));
    final sub = Directory('${dir.path}/assets')..createSync();
    File('${sub.path}/nested.png').writeAsBytesSync(base64Decode(_onePixelPng));

    final markdown =
        '# Title\n\n'
        '![sibling](pic.png)\n\n'
        '![nested](assets/nested.png)\n\n'
        '<p align="center">\n'
        '<img src="pic.png" alt="Banner" width="820">\n'
        '</p>\n';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GitHubMarkdown(data: markdown, imageDirectory: dir.path),
        ),
      ),
    );
    await tester.pump();

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final paths = images
        .map((w) => w.image)
        .whereType<FileImage>()
        .map((f) => f.file.path)
        .toList();

    expect(paths, contains(image.path));
    expect(paths, contains('${sub.path}/nested.png'));
  });
}
