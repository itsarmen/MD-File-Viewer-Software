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
import 'package:flutter_test/flutter_test.dart';
import 'package:md_file_viewer/src/github_markdown.dart';
import 'package:md_file_viewer/src/home_page.dart';

Future<ScrollPosition> _pumpLongFile(WidgetTester tester) async {
  final tmp = File('${Directory.systemTemp.path}/md_viewer_scroll_test.md');
  tmp.writeAsStringSync(
    List.generate(200, (i) => 'Paragraph $i with some long text.').join('\n\n'),
  );

  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: HomePage(initialPath: tmp.path)));
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await tester.pumpAndSettle();

  final preview = find
      .ancestor(
        of: find.byType(GitHubMarkdown),
        matching: find.byType(Scrollable),
      )
      .first;
  return tester.state<ScrollableState>(preview).position;
}

void main() {
  testWidgets('preview scrolls with the mouse wheel', (tester) async {
    final position = await _pumpLongFile(tester);
    final preview = find
        .ancestor(
          of: find.byType(GitHubMarkdown),
          matching: find.byType(Scrollable),
        )
        .first;

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(tester.getCenter(preview));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 400)));
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
  });

  testWidgets('preview scrolls with the keyboard', (tester) async {
    final position = await _pumpLongFile(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
  });
}
