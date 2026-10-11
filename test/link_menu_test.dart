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
import 'package:flutter_test/flutter_test.dart';
import 'package:md_file_viewer/src/home_page.dart';

Future<void> _pumpWith(WidgetTester tester, String data) async {
  final tmp = File('${Directory.systemTemp.path}/md_viewer_link_test.md');
  tmp.writeAsStringSync(data);
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: HomePage(initialPath: tmp.path)));
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('right click on a link shows a link context menu', (
    tester,
  ) async {
    await _pumpWith(tester, '[Example](https://example.com)');

    await tester.tap(find.text('Example'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(find.text('Open link in browser'), findsOneWidget);
    expect(find.text('Copy link address'), findsOneWidget);
  });

  testWidgets('regular text can still be selected', (tester) async {
    await _pumpWith(tester, 'Hello selectable world');

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('Hello selectable world'), findsOneWidget);
  });
}
