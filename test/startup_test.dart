import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/app.dart';
import 'package:hcm_bus/boot.dart';
import 'package:hcm_bus/data/models.dart';
import 'package:hcm_bus/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  testWidgets('BootApp: chậm -> splash có tiến trình, rồi vào app', (t) async {
    SharedPreferences.setMockInitialValues({'onboarded': false});
    final c = Completer<SharedPreferences>();
    await t.pumpWidget(BootApp(loadPrefs: () => c.future));
    await t.pump();
    expect(find.text('Đang tải dữ liệu tuyến…'), findsOneWidget);
    c.complete(await SharedPreferences.getInstance());
    // Dữ liệu thật nạp qua compute -> chạy ngoài fake async.
    await t.runAsync(() async {
      for (var i = 0; i < 100 && find.text('Bỏ qua').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await t.pump();
      }
    });
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Bỏ qua'), findsOneWidget, reason: 'phải qua được splash tới onboarding');
  });

  testWidgets('BootApp: lỗi prefs -> màn hình lỗi + thử lại thành công', (t) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    var calls = 0;
    await t.pumpWidget(BootApp(loadPrefs: () async {
      calls++;
      if (calls == 1) throw StateError('prefs hỏng');
      return SharedPreferences.getInstance();
    }));
    await t.pump();
    await t.pump();
    expect(find.text('Không khởi động được'), findsOneWidget);
    await t.tap(find.text('Thử lại'));
    await t.pump();
    await t.pump();
    expect(find.text('Không khởi động được'), findsNothing);
    expect(calls, 2);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 60));
  });

  testWidgets('Lỗi nạp dữ liệu -> màn lỗi (không treo ở splash), thử lại được', (t) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    var n = 0;
    await t.pumpWidget(ProviderScope(overrides: [
      prefsProvider.overrideWithValue(prefs),
      busDataProvider.overrideWith((ref) async {
        n++;
        if (n == 1) throw Exception('asset thiếu');
        return toyData();
      }),
      useNativeMapProvider.overrideWithValue(false),
    ], child: const HcmBusApp()));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Không khởi động được'), findsOneWidget);
    expect(n, 1, reason: 'không được tự retry vô hạn');
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('Bạn muốn đi đâu?'), findsOneWidget);
  });

  test('parse trên isolate cho asset thật', () async {
    final d = await Future(() => BusData.parse(realDataText()));
    expect(d.routes, isNotEmpty);
  });
}
