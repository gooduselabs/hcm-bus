import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../theme.dart';

const openFreeMapLight = 'https://tiles.openfreemap.org/styles/liberty';
const openFreeMapDark = 'https://tiles.openfreemap.org/styles/dark';
const mapAttribution = '© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors';

/// Bản đồ: MapLibre + OpenFreeMap khi có mạng; bản đồ tĩnh vẽ từ dữ liệu OSM
/// đóng gói khi offline (và trong ảnh chụp test).
class BusMap extends ConsumerStatefulWidget {
  const BusMap({
    super.key,
    this.line = const [],
    this.lineColor,
    this.stops = const [],
    this.markers = const [],
    this.highlight,
    this.me,
    this.focus,
    this.schematic = false,
    this.bottomInset = 0,
    this.radius = 0,
    this.showAttribution = true,
  });
  final List<LatLon> line;
  final Color? lineColor;
  final List<BusStop> stops;
  final List<BusStop> markers;
  final LatLon? highlight;
  final LatLon? me;
  final LatLon? focus;
  final bool schematic;
  final double bottomInset;
  final double radius;
  final bool showAttribution;

  @override
  ConsumerState<BusMap> createState() => _BusMapState();
}

class _BusMapState extends ConsumerState<BusMap> {
  MapLibreMapController? _c;

  List<LatLon> get _pts => widget.focus != null
      ? [widget.focus!]
      : [...widget.line, ...widget.stops.map((s) => s.pos), ...widget.markers.map((s) => s.pos), ?widget.highlight, ?widget.me];

  String _hex(Color col) => '#${(col.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Future<void> _draw() async {
    final c = _c;
    if (c == null) return;
    final color = widget.lineColor ?? Brand.green;
    if (widget.line.length > 1) {
      await c.addLine(LineOptions(geometry: [for (final p in widget.line) LatLng(p.lat, p.lon)], lineColor: '#ffffff', lineWidth: 9));
      await c.addLine(LineOptions(geometry: [for (final p in widget.line) LatLng(p.lat, p.lon)], lineColor: _hex(color), lineWidth: 5.5));
    }
    for (final s in widget.stops) {
      await c.addCircle(CircleOptions(geometry: LatLng(s.pos.lat, s.pos.lon), circleRadius: 4.5, circleColor: '#ffffff', circleStrokeColor: _hex(color), circleStrokeWidth: 2.5));
    }
    for (final s in widget.markers) {
      await c.addCircle(CircleOptions(geometry: LatLng(s.pos.lat, s.pos.lon), circleRadius: 7, circleColor: _hex(Brand.greenDeep), circleStrokeColor: '#ffffff', circleStrokeWidth: 2.5));
    }
    for (final p in [?widget.highlight]) {
      await c.addCircle(CircleOptions(geometry: LatLng(p.lat, p.lon), circleRadius: 10, circleColor: _hex(Brand.amber), circleStrokeColor: '#ffffff', circleStrokeWidth: 3));
    }
    for (final p in [?widget.me]) {
      await c.addCircle(CircleOptions(geometry: LatLng(p.lat, p.lon), circleRadius: 18, circleColor: '#2F80ED', circleOpacity: 0.18));
      await c.addCircle(CircleOptions(geometry: LatLng(p.lat, p.lon), circleRadius: 7, circleColor: '#2F80ED', circleStrokeColor: '#ffffff', circleStrokeWidth: 3));
    }
    final pts = _pts;
    if (pts.length > 1) {
      final b = _bounds(pts);
      await c.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(b.$1, b.$2), northeast: LatLng(b.$3, b.$4)),
          left: 48, right: 48, top: 110, bottom: 48 + widget.bottomInset));
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = ref.watch(useNativeMapProvider) && !widget.schematic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final center = _pts.isEmpty ? benThanh : _pts.first;
    final roads = ref.watch(busDataProvider).value?.routes ?? const <BusRoute>[];
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(children: [
        Positioned.fill(
          child: native
              ? MapLibreMap(
                  styleString: dark ? openFreeMapDark : openFreeMapLight,
                  initialCameraPosition: CameraPosition(target: LatLng(center.lat, center.lon), zoom: 15),
                  onMapCreated: (c) => _c = c,
                  onStyleLoadedCallback: _draw,
                  compassEnabled: false,
                  attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                )
              : CustomPaint(
                  painter: StaticMapPainter(
                    focus: _pts,
                    roads: roads,
                    line: widget.line,
                    lineColor: widget.lineColor ?? Brand.green,
                    stops: widget.stops,
                    markers: widget.markers,
                    highlight: widget.highlight,
                    me: widget.me,
                    dark: dark,
                    bottomInset: widget.bottomInset,
                  ),
                ),
        ),
        if (widget.showAttribution)
          Positioned(
            right: 8,
            bottom: 6 + widget.bottomInset,
            child: Text(native ? mapAttribution : '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.55))),
          ),
      ]),
    );
  }
}

(double, double, double, double) _bounds(List<LatLon> pts) {
  var s = 90.0, w = 180.0, n = -90.0, e = -180.0;
  for (final p in pts) {
    s = math.min(s, p.lat);
    n = math.max(n, p.lat);
    w = math.min(w, p.lon);
    e = math.max(e, p.lon);
  }
  return (s, w, n, e);
}

// Sông Sài Gòn và kênh Bến Nghé (gần đúng) để bản đồ tĩnh trông thật hơn.
const _river = [
  LatLon(10.840, 106.735), LatLon(10.815, 106.722), LatLon(10.800, 106.722), LatLon(10.790, 106.713),
  LatLon(10.781, 106.708), LatLon(10.773, 106.707), LatLon(10.767, 106.711), LatLon(10.763, 106.722),
  LatLon(10.758, 106.733), LatLon(10.748, 106.742), LatLon(10.730, 106.748), LatLon(10.700, 106.755),
];
const _canal = [
  LatLon(10.767, 106.707), LatLon(10.762, 106.699), LatLon(10.756, 106.689), LatLon(10.751, 106.676),
  LatLon(10.748, 106.662), LatLon(10.746, 106.648), LatLon(10.743, 106.632),
];
const _parks = [
  (LatLon(10.7790, 106.6925), 260.0), (LatLon(10.7745, 106.6905), 180.0), (LatLon(10.7875, 106.7050), 230.0),
  (LatLon(10.7700, 106.6820), 150.0), (LatLon(10.8000, 106.6640), 420.0), (LatLon(10.7590, 106.6760), 160.0),
];

/// Vẽ một "bản đồ" tĩnh: nền, công viên, sông, mạng đường (từ hình học tuyến OSM),
/// tuyến được chọn, trạm, vị trí tôi.
class StaticMapPainter extends CustomPainter {
  StaticMapPainter({
    required this.focus,
    required this.roads,
    required this.line,
    required this.lineColor,
    required this.stops,
    required this.markers,
    required this.highlight,
    required this.me,
    required this.dark,
    this.bottomInset = 0,
  });
  final List<LatLon> focus;
  final List<BusRoute> roads;
  final List<LatLon> line;
  final Color lineColor;
  final List<BusStop> stops;
  final List<BusStop> markers;
  final LatLon? highlight;
  final LatLon? me;
  final bool dark;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final land = dark ? const Color(0xFF141C19) : const Color(0xFFF1EFE9);
    final water = dark ? const Color(0xFF0E2A33) : const Color(0xFFAAD3DF);
    final park = dark ? const Color(0xFF16291F) : const Color(0xFFCDEBC4);
    final roadFill = dark ? const Color(0xFF2A3833) : Colors.white;
    final roadCase = dark ? const Color(0xFF1C2622) : const Color(0xFFDCD7CC);
    canvas.drawRect(Offset.zero & size, Paint()..color = land);

    final pts = focus.isEmpty ? [benThanh] : focus;
    final b = _bounds(pts);
    final lat0 = (b.$1 + b.$3) / 2;
    final k = math.cos(lat0 * math.pi / 180);
    final viewH = size.height - bottomInset;
    const pad = 56.0;
    var spanX = (b.$4 - b.$2) * k, spanY = b.$3 - b.$1;
    spanX = math.max(spanX, 0.010);
    spanY = math.max(spanY, 0.010);
    final sc = math.min((size.width - 2 * pad) / spanX, (viewH - 2 * pad - 60) / spanY);
    final cx = (b.$2 + b.$4) / 2 * k, cy = (b.$1 + b.$3) / 2;
    Offset f(LatLon p) => Offset(size.width / 2 + (p.lon * k - cx) * sc, 60 + (viewH - 60) / 2 - (p.lat - cy) * sc);
    final mPerPx = 111320 / sc; // mét / pixel
    double px(double meters) => meters / mPerPx;
    final view = (Offset.zero & size).inflate(40);

    Path pathOf(List<LatLon> l) {
      final p = Path()..moveTo(f(l.first).dx, f(l.first).dy);
      for (final q in l.skip(1)) {
        final o = f(q);
        p.lineTo(o.dx, o.dy);
      }
      return p;
    }

    for (final (c, r) in _parks) {
      final o = f(c);
      if (view.contains(o)) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: px(r * 2.2), height: px(r * 1.6)), Radius.circular(px(r) * 0.5)), Paint()..color = park);
      }
    }
    final waterPaint = Paint()
      ..color = water
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathOf(_river), waterPaint..strokeWidth = math.max(px(260), 6));
    canvas.drawPath(pathOf(_canal), waterPaint..strokeWidth = math.max(px(70), 3));

    // Mạng đường từ hình học các tuyến buýt OSM.
    final visible = <Path>[];
    for (final r in roads) {
      if (r.geometry.length < 2) continue;
      if (!r.geometry.any((p) => view.contains(f(p)))) continue;
      visible.add(pathOf(r.geometry));
    }
    final wMain = (px(26)).clamp(3.0, 14.0);
    final casing = Paint()
      ..color = roadCase
      ..style = PaintingStyle.stroke
      ..strokeWidth = wMain + 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = roadFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = wMain
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final p in visible) {
      canvas.drawPath(p, casing);
    }
    for (final p in visible) {
      canvas.drawPath(p, fill);
    }

    if (line.length > 1) {
      final p = pathOf(line);
      canvas.drawPath(p, Paint()
        ..color = lineColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(p, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(p, Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
    for (final s in stops) {
      final o = f(s.pos);
      canvas.drawCircle(o, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(o, 5.5, Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
    for (final s in markers) {
      _pin(canvas, f(s.pos), Brand.greenDeep);
    }
    final h = highlight;
    if (h != null) _pin(canvas, f(h), Brand.coral, big: true);
    final m = me;
    if (m != null) {
      final o = f(m);
      canvas.drawCircle(o, 34, Paint()..color = const Color(0xFF2F80ED).withValues(alpha: 0.12));
      canvas.drawCircle(o, 11, Paint()..color = Colors.white);
      canvas.drawCircle(o, 8, Paint()..color = const Color(0xFF2F80ED));
    }
  }

  void _pin(Canvas c, Offset o, Color color, {bool big = false}) {
    final r = big ? 15.0 : 11.0;
    final tip = o;
    final head = o - Offset(0, r * 1.7);
    c.drawCircle(tip + const Offset(0, 1), 4, Paint()..color = Colors.black.withValues(alpha: 0.18));
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(head.dx - r * 0.75, head.dy + r * 0.6)
      ..arcToPoint(Offset(head.dx + r * 0.75, head.dy + r * 0.6), radius: Radius.circular(r), largeArc: true)
      ..close();
    c.drawShadow(path, Colors.black, 3, false);
    c.drawPath(path, Paint()..color = color);
    c.drawCircle(head, r * 0.62, Paint()..color = Colors.white);
    final tp = TextPainter(
      text: TextSpan(text: String.fromCharCode(Icons.directions_bus.codePoint), style: TextStyle(fontFamily: Icons.directions_bus.fontFamily, fontSize: r * 0.95, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, head - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant StaticMapPainter old) => true;
}
