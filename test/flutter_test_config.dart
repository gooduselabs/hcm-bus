import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Nạp font thật để ảnh golden hiển thị đúng tiếng Việt và icon.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File(f.contains('/') ? f : 'test/fonts/$f').readAsBytesSync())));
    }
    await l.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('BeVietnamPro', [for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/BeVietnamPro-$w.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  await testMain();
}
