import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

const openFreeMapLight = 'https://tiles.openfreemap.org/styles/liberty';
const openFreeMapDark = 'https://tiles.openfreemap.org/styles/dark';
const mapAttribution = '© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors';

/// Bản đồ tuyến/trạm. Dùng MapLibre + OpenFreeMap khi có mạng; chế độ
/// "Sơ đồ" vẽ offline từ dữ liệu đóng gói (cũng dùng cho ảnh chụp test).
class BusMap extends ConsumerStatefulWidget {
  const BusMap({super.key, this.line = const [], this.stops = const [], this.highlight, this.schematic = false});
  final List<LatLon> line;
  final List<BusStop> stops;
  final LatLon? highlight;
  final bool schematic;

  @override
  ConsumerState<BusMap> createState() => _BusMapState();
}

class _BusMapState extends ConsumerState<BusMap> {
  MapLibreMapController? _c;

  List<LatLon> get _pts => [...widget.line, ...widget.stops.map((s) => s.pos), ?widget.highlight];

  Future<void> _draw() async {
    final c = _c;
    if (c == null) return;
    final cs = Theme.of(context).colorScheme;
    String hex(Color col) => '#${(col.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    if (widget.line.length > 1) {
      await c.addLine(LineOptions(
        geometry: [for (final p in widget.line) LatLng(p.lat, p.lon)],
        lineColor: hex(cs.primary),
        lineWidth: 5,
        lineOpacity: 0.9,
      ));
    }
    for (final s in widget.stops) {
      await c.addCircle(CircleOptions(
        geometry: LatLng(s.pos.lat, s.pos.lon),
        circleRadius: 5,
        circleColor: '#ffffff',
        circleStrokeColor: hex(cs.primary),
        circleStrokeWidth: 2,
      ));
    }
    final h = widget.highlight;
    if (h != null) {
      await c.addCircle(CircleOptions(geometry: LatLng(h.lat, h.lon), circleRadius: 9, circleColor: hex(cs.tertiary), circleStrokeColor: '#ffffff', circleStrokeWidth: 3));
    }
    final pts = _pts;
    if (pts.length > 1) {
      final b = _bounds(pts);
      await c.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(b.$1, b.$2), northeast: LatLng(b.$3, b.$4)),
          left: 40, right: 40, top: 40, bottom: 40));
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = ref.watch(useNativeMapProvider) && !widget.schematic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final center = _pts.isEmpty ? benThanh : _pts.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(children: [
        Positioned.fill(
          child: native
              ? MapLibreMap(
                  styleString: dark ? openFreeMapDark : openFreeMapLight,
                  initialCameraPosition: CameraPosition(target: LatLng(center.lat, center.lon), zoom: 14),
                  myLocationEnabled: false,
                  onMapCreated: (c) => _c = c,
                  onStyleLoadedCallback: _draw,
                  attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                )
              : CustomPaint(painter: _SchematicPainter(widget.line, widget.stops, widget.highlight, Theme.of(context).colorScheme)),
        ),
        Positioned(
          right: 8,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6)),
            child: Text(native ? mapAttribution : 'Sơ đồ offline · © OpenStreetMap contributors', style: const TextStyle(fontSize: 9)),
          ),
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

class _SchematicPainter extends CustomPainter {
  _SchematicPainter(this.line, this.stops, this.highlight, this.cs);
  final List<LatLon> line;
  final List<BusStop> stops;
  final LatLon? highlight;
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = cs.surfaceContainerHighest);
    final grid = Paint()
      ..color = cs.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final all = [...line, ...stops.map((s) => s.pos), ?highlight];
    if (all.isEmpty) return;
    final b = _bounds(all);
    final latSpan = math.max(b.$3 - b.$1, 0.002), lonSpan = math.max(b.$4 - b.$2, 0.002);
    const pad = 28.0;
    final sc = math.min((size.width - 2 * pad) / lonSpan, (size.height - 2 * pad) / latSpan);
    final ox = (size.width - lonSpan * sc) / 2, oy = (size.height - latSpan * sc) / 2;
    Offset f(LatLon p) => Offset(ox + (p.lon - b.$2) * sc, oy + (b.$3 - p.lat) * sc);
    if (line.length > 1) {
      final path = Path()..moveTo(f(line.first).dx, f(line.first).dy);
      for (final p in line.skip(1)) {
        path.lineTo(f(p).dx, f(p).dy);
      }
      canvas.drawPath(path, Paint()
        ..color = cs.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
    for (final s in stops) {
      canvas.drawCircle(f(s.pos), 5, Paint()..color = Colors.white);
      canvas.drawCircle(f(s.pos), 5, Paint()
        ..color = cs.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    final h = highlight;
    if (h != null) {
      canvas.drawCircle(f(h), 10, Paint()..color = cs.tertiary);
      canvas.drawCircle(f(h), 10, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _SchematicPainter old) => true;
}
