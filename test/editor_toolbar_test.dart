/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_file_viewer/src/home_page.dart';

void main() {
  testWidgets('editor toolbar formats the selection', (tester) async {
    final tmp = File('${Directory.systemTemp.path}/md_viewer_toolbar_test.md');
    tmp.writeAsStringSync('hello world');

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(initialPath: tmp.path)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final editorField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Write Markdown here…',
    );
    expect(editorField, findsOneWidget);

    final controller = tester.widget<TextField>(editorField).controller!;
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 11,
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
    await tester.pump();
    expect(controller.text, '**hello world**');

    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();
    await tester.tap(find.byTooltip('Bulleted list'));
    await tester.pump();
    expect(controller.text, '- **hello world**');

    await tester.tap(find.byTooltip('Bulleted list'));
    await tester.pump();
    expect(controller.text, '**hello world**');
  });
}