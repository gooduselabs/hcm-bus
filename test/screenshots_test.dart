// Tạo ảnh chụp màn hình (golden) sáng + tối:
//   flutter test test/screenshots_test.dart --update-goldens
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/app.dart';
import 'package:hcm_bus/state/providers.dart';
import 'package:hcm_bus/ui/screens/planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

final now = DateTime(2026, 10, 21, 8, 12);

class _PresetPlan extends PlanInputNotifier {
  @override
  PlanInput build() {
    final d = realData();
    final a = d.stopById['3166133536']!, b = d.stopById['11757081910']!;
    return PlanInput(from: Place(a.displayName, a.pos), to: Place(b.displayName, b.pos));
  }
}

void main() {
  final d = realData();
  final route01 = d.routes.firstWhere((r) => r.ref == '01').id;
  const shots = <String, String?>{
    'onboarding': null,
    'routes': '/routes',
    'route_detail': '/route/ROUTE',
    'stop_detail': '/stop/3166133536',
    'stops_nearby': '/stops',
    'planner': '/plan',
    'saved': '/saved',
    'settings': '/settings',
  };

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final e in shots.entries) {
      final name = '${e.key}_${mode.name}';
      testWidgets(name, (t) async {
        t.view.physicalSize = const Size(1080, 2340);
        t.view.devicePixelRatio = 2.625;
        addTearDown(t.view.reset);
        SharedPreferences.setMockInitialValues({
          'onboarded': e.value != null,
          'theme': mode.index,
          'fav_routes': [route01],
          'fav_stops': ['3166133536'],
          'reports': jsonEncode([
            {'s': '3166133536', 'r': '01', 't': 2, 'at': now.subtract(const Duration(minutes: 4)).millisecondsSinceEpoch},
            {'s': '3166133536', 'r': '01', 't': 3, 'at': now.subtract(const Duration(minutes: 11)).millisecondsSinceEpoch},
          ]),
        });
        final prefs = await SharedPreferences.getInstance();
        await t.pumpWidget(ProviderScope(overrides: [
          prefsProvider.overrideWithValue(prefs),
          busDataProvider.overrideWith((ref) async => d),
          useNativeMapProvider.overrideWithValue(false),
          clockProvider.overrideWithValue(() => now),
          planInputProvider.overrideWith(_PresetPlan.new),
        ], child: HcmBusApp(initialLocation: e.value?.replaceAll('ROUTE', route01))));
        await t.pumpAndSettle();
        await t.pump(const Duration(seconds: 1));
        await expectLater(find.byType(HcmBusApp), matchesGoldenFile('goldens/$name.png'));
      });
    }
  }
}
