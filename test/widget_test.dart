/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_file_viewer/src/github_markdown.dart';

void main() {
  testWidgets('renders GitHub-flavoured markdown', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GitHubMarkdown(
            data: '# Title\n\n- [x] done\n\n| a | b |\n| - | - |\n| 1 | 2 |',
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('done'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
