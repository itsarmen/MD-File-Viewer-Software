/*
 * MD File Viewer
 * Author:     Amiran Kimadze (itsarmen)
 * GitHub:     https://github.com/itsarmen
 * Email:      amoswaper@gmail.com
 * Web:        https://xrow.asia
 */

import 'package:flutter/material.dart';

import 'src/app.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  final fileArgs = args.where((a) => !a.startsWith('-')).toList();
  runApp(
    MdFileViewerApp(initialPath: fileArgs.isEmpty ? null : fileArgs.first),
  );
}
