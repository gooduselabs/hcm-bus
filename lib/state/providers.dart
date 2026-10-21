import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo.dart';
import '../data/models.dart';
import '../domain/planner.dart';
import '../realtime/realtime_provider.dart';

/// Ghi đè trong main() sau khi SharedPreferences sẵn sàng.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final busDataProvider = FutureProvider<BusData>((ref) async {
  final txt = await rootBundle.loadString('assets/data/hcm_bus.json');
  return BusData.parse(txt);
});

/// Đổi sang provider của đối tác chính thức khi có (xem realtime_provider.dart).
final realtimeProvider = Provider<RealtimeProvider>((ref) {
  final data = ref.watch(busDataProvider).requireValue;
  return ScheduleEstimateProvider(data);
});

final plannerProvider = Provider<TripPlanner>((ref) => TripPlanner(ref.watch(busDataProvider).requireValue));

/// false trong test/golden: vẽ sơ đồ thay cho bản đồ MapLibre (platform view).
final useNativeMapProvider = Provider<bool>((ref) => true);

/// Đồng hồ (ghi đè trong test để ảnh chụp ổn định).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Vị trí hiện tại đã biết (null = chưa cấp quyền).
class LocationNotifier extends Notifier<LatLon?> {
  @override
  LatLon? build() => null;
  void set(LatLon? p) => state = p;
}

final locationProvider = NotifierProvider<LocationNotifier, LatLon?>(LocationNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.values[ref.read(prefsProvider).getInt('theme') ?? 0];
  void set(ThemeMode m) {
    state = m;
    ref.read(prefsProvider).setInt('theme', m.index);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).getBool('onboarded') ?? false;
  void done() {
    state = true;
    ref.read(prefsProvider).setBool('onboarded', true);
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(OnboardedNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  FavoritesNotifier(this.key);
  final String key;
  @override
  Set<String> build() => (ref.read(prefsProvider).getStringList(key) ?? const []).toSet();
  void toggle(String id) {
    final s = {...state};
    if (!s.remove(id)) s.add(id);
    state = s;
    ref.read(prefsProvider).setStringList(key, s.toList());
  }
}

final favRoutesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(() => FavoritesNotifier('fav_routes'));
final favStopsProvider = NotifierProvider<FavoritesNotifier, Set<String>>(() => FavoritesNotifier('fav_stops'));

enum ReportType { empty, normal, crowded, arrived }

extension ReportTypeVi on ReportType {
  String get label => const ['Vắng', 'Vừa', 'Đông', 'Xe vừa đến'][index];
  IconData get icon => const [Icons.event_seat, Icons.people_outline, Icons.groups, Icons.directions_bus][index];
}

class UserReport {
  UserReport(this.stopId, this.routeRef, this.type, this.time);
  final String stopId;
  final String routeRef;
  final ReportType type;
  final DateTime time;
  Map<String, dynamic> toJson() => {'s': stopId, 'r': routeRef, 't': type.index, 'at': time.millisecondsSinceEpoch};
  factory UserReport.fromJson(Map<String, dynamic> j) => UserReport(j['s'] as String, j['r'] as String,
      ReportType.values[j['t'] as int], DateTime.fromMillisecondsSinceEpoch(j['at'] as int));
}

/// Báo cáo cộng đồng – hiện lưu trên máy (sẽ đồng bộ backend sau).
class ReportsNotifier extends Notifier<List<UserReport>> {
  @override
  List<UserReport> build() {
    final raw = ref.read(prefsProvider).getString('reports');
    if (raw == null) return const [];
    return [for (final j in jsonDecode(raw) as List) UserReport.fromJson(j as Map<String, dynamic>)];
  }

  void add(UserReport r) {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    state = [r, ...state.where((e) => e.time.isAfter(cutoff))].take(200).toList();
    ref.read(prefsProvider).setString('reports', jsonEncode([for (final e in state) e.toJson()]));
  }

  List<UserReport> recentAt(String stopId, DateTime now) => state
      .where((e) => e.stopId == stopId && now.difference(e.time).inMinutes < 60)
      .toList();
}

final reportsProvider = NotifierProvider<ReportsNotifier, List<UserReport>>(ReportsNotifier.new);
