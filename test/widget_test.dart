import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/app.dart';
import 'package:hcm_bus/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<Widget> app({bool onboarded = true, String? initial}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(overrides: [
    prefsProvider.overrideWithValue(prefs),
    busDataProvider.overrideWith((ref) async => toyData()),
    useNativeMapProvider.overrideWithValue(false),
    clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 8, 0)),
  ], child: HcmBusApp(initialLocation: initial));
}

void main() {
  testWidgets('onboarding -> danh sách tuyến', (t) async {
    await t.pumpWidget(await app(onboarded: false));
    await t.pumpAndSettle();
    expect(find.text('Xe buýt TP.HCM trong túi bạn'), findsOneWidget);
    await t.tap(find.text('Bỏ qua'));
    await t.pumpAndSettle();
    expect(find.text('Bạn muốn đi đâu?'), findsOneWidget);
    expect(find.text('Trạm x'), findsWidgets);
  });

  testWidgets('tìm tuyến và mở chi tiết, bật yêu thích', (t) async {
    await t.pumpWidget(await app(initial: '/routes'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'B1');
    await t.pumpAndSettle();
    expect(find.text('B5'), findsOneWidget);
    expect(find.text('A4'), findsNothing);
    await t.tap(find.text('B5'));
    await t.pumpAndSettle();
    expect(find.text('Tuyến B'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Trạm b2'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Trạm b2'), findsOneWidget);
    await t.tap(find.byTooltip('Yêu thích'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('trạm: ghi báo cáo cộng đồng', (t) async {
    t.view.physicalSize = const Size(1200, 3600);
    addTearDown(t.view.reset);
    await t.pumpWidget(await app(initial: '/stop/x'));
    await t.pumpAndSettle();
    expect(find.text('Dự kiến theo lịch'), findsOneWidget);
    expect(find.text('Dự kiến'), findsWidgets);
    await t.tap(find.text('Đông'));
    await t.pumpAndSettle();
    expect(find.text('0 phút trước'), findsOneWidget);
  });
}
