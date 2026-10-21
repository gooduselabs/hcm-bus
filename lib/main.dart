import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'boot.dart';

/// Khởi động an toàn: runApp NGAY LẬP TỨC (để native splash được gỡ ở frame
/// đầu), mọi việc khởi tạo chạy bên trong app với timeout + màn hình lỗi.
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (d) {
      FlutterError.presentError(d);
      bootLog('FlutterError: ${d.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (e, st) {
      bootLog('Uncaught: $e\n$st');
      return true;
    };
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['Be Vietnam Pro'], await rootBundle.loadString('assets/fonts/OFL.txt'));
    });
    runApp(const BootApp());
  }, (e, st) => bootLog('Zone error: $e\n$st'));
}
