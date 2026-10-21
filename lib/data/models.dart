import 'dart:convert';

import '../core/geo.dart';

class BusStop {
  const BusStop({required this.id, required this.name, required this.pos});
  final String id;
  final String name;
  final LatLon pos;

  String get displayName => name.isEmpty ? 'Trạm chưa đặt tên' : name;

  factory BusStop.fromJson(Map<String, dynamic> j) => BusStop(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        pos: LatLon((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()),
      );
}

class BusRoute {
  const BusRoute({
    required this.id,
    required this.ref,
    required this.name,
    required this.stopIds,
    this.from = '',
    this.to = '',
    this.operator = '',
    this.interval = '',
    this.openingHours = '',
    this.fee = '',
    this.geometry = const [],
  });

  final String id;
  final String ref;
  final String name;
  final String from;
  final String to;
  final String operator;
  final String interval;
  final String openingHours;
  final String fee;
  final List<String> stopIds;
  final List<LatLon> geometry;

  String get title => name.isNotEmpty
      ? name
      : (from.isNotEmpty && to.isNotEmpty ? '$from - $to' : 'Tuyến $ref');

  factory BusRoute.fromJson(Map<String, dynamic> j) => BusRoute(
        id: j['id'] as String,
        ref: (j['ref'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        from: (j['from'] as String?) ?? '',
        to: (j['to'] as String?) ?? '',
        operator: (j['operator'] as String?) ?? '',
        interval: (j['interval'] as String?) ?? '',
        openingHours: (j['opening_hours'] as String?) ?? '',
        fee: (j['fee'] as String?) ?? '',
        stopIds: [for (final s in (j['stops'] as List? ?? const [])) s as String],
        geometry: [
          for (final p in (j['geom'] as List? ?? const []))
            LatLon(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())
        ],
      );
}

/// Toàn bộ dữ liệu tĩnh (offline) + chỉ mục tra cứu.
class BusData {
  BusData({required this.stops, required this.routes, this.generated = '', this.attribution = ''})
      : stopById = {for (final s in stops) s.id: s},
        routeById = {for (final r in routes) r.id: r} {
    for (final r in routes) {
      for (final s in r.stopIds) {
        (_routesAtStop[s] ??= <String>{}).add(r.id);
      }
    }
    for (final s in stops) {
      (_grid[_cell(s.pos)] ??= []).add(s);
    }
  }

  final List<BusStop> stops;
  final List<BusRoute> routes;
  final String generated;
  final String attribution;
  final Map<String, BusStop> stopById;
  final Map<String, BusRoute> routeById;
  final Map<String, Set<String>> _routesAtStop = {};
  final Map<(int, int), List<BusStop>> _grid = {};

  static const _cellDeg = 0.01; // ~1.1 km

  static (int, int) _cell(LatLon p) => ((p.lat / _cellDeg).floor(), (p.lon / _cellDeg).floor());

  factory BusData.parse(String jsonText) {
    final j = jsonDecode(jsonText) as Map<String, dynamic>;
    final stops = [for (final s in j['stops'] as List) BusStop.fromJson(s as Map<String, dynamic>)];
    final ids = {for (final s in stops) s.id};
    final routes = [
      for (final r in j['routes'] as List) BusRoute.fromJson(r as Map<String, dynamic>)
    ].where((r) => r.stopIds.where(ids.contains).length >= 2).toList();
    return BusData(
      stops: stops,
      routes: routes,
      generated: (j['generated'] as String?) ?? '',
      attribution: (j['attribution'] as String?) ?? '',
    );
  }

  List<BusRoute> routesAtStop(String stopId) =>
      [for (final id in _routesAtStop[stopId] ?? const <String>{}) routeById[id]!]
        ..sort((a, b) => a.ref.compareTo(b.ref));

  List<BusStop> stopsOf(BusRoute r) =>
      [for (final id in r.stopIds) if (stopById[id] != null) stopById[id]!];

  /// Trạm trong bán kính [radiusM], gần nhất trước.
  List<(BusStop, double)> nearbyStops(LatLon p, {double radiusM = 800, int limit = 50}) {
    final c = _cell(p);
    final span = (radiusM / 1000).ceil();
    final out = <(BusStop, double)>[];
    for (var dx = -span; dx <= span; dx++) {
      for (var dy = -span; dy <= span; dy++) {
        for (final s in _grid[(c.$1 + dx, c.$2 + dy)] ?? const <BusStop>[]) {
          final d = distanceM(p, s.pos);
          if (d <= radiusM) out.add((s, d));
        }
      }
    }
    out.sort((a, b) => a.$2.compareTo(b.$2));
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  List<BusRoute> searchRoutes(String q) {
    final n = normalizeVi(q);
    if (n.isEmpty) return routes;
    return routes
        .where((r) =>
            normalizeVi(r.ref) == n ||
            normalizeVi(r.ref).startsWith(n) ||
            normalizeVi('${r.title} ${r.from} ${r.to}').contains(n))
        .toList();
  }

  List<BusStop> searchStops(String q, {int limit = 80}) {
    final n = normalizeVi(q);
    if (n.isEmpty) return const [];
    return stops.where((s) => normalizeVi(s.name).contains(n)).take(limit).toList();
  }
}
