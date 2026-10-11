/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import 'home_page.dart';

class MdFileViewerApp extends StatelessWidget {
  const MdFileViewerApp({super.key, this.initialPath});

  final String? initialPath;

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'MD File Viewer',
          debugShowCheckedModeBanner: false,
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          themeMode: ThemeMode.system,
          home: HomePage(initialPath: initialPath),
        );
      },
    );
  }
}
