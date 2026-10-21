/// Ước tính "xe sắp đến" CHỈ dựa trên thẻ OSM `interval` + `opening_hours`.
/// Đây KHÔNG phải dữ liệu GPS thời gian thực.
class ServiceWindow {
  const ServiceWindow(this.startMin, this.endMin);
  final int startMin; // phút kể từ 00:00
  final int endMin;
  bool contains(int m) => m >= startMin && m <= endMin;
  String get label => '${_hm(startMin)}–${_hm(endMin)}';
}

String _hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

int? _parseHm(String s) {
  final p = s.trim().split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// "00:08-00:20" -> (8,20); "00:15" -> (15,15); "15" -> (15,15); "PT10M" -> (10,10).
(int, int)? parseInterval(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final iso = RegExp(r'^PT(\d+)M$').firstMatch(s);
  if (iso != null) {
    final v = int.parse(iso.group(1)!);
    return (v, v);
  }
  int? one(String x) {
    x = x.trim();
    if (x.contains(':')) return _parseHm(x);
    return int.tryParse(x);
  }

  final parts = s.split(RegExp(r'\s*[-–]\s*'));
  final a = one(parts.first);
  final b = parts.length > 1 ? one(parts[1]) : a;
  if (a == null || b == null || a <= 0 || b <= 0) return null;
  return a <= b ? (a, b) : (b, a);
}

/// Hỗ trợ dạng phổ biến: "Mo-Su 05:00-22:00", "05:00-21:00", "24/7".
/// Dạng phức tạp hơn trả về null (hiển thị "không rõ").
ServiceWindow? parseOpeningHours(String raw) {
  final s = raw.trim();
  if (s == '24/7') return const ServiceWindow(0, 24 * 60 - 1);
  final m = RegExp(r'^(?:Mo-Su\s+)?(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$').firstMatch(s);
  if (m == null) return null;
  final a = _parseHm(m.group(1)!), b = _parseHm(m.group(2)!);
  if (a == null || b == null) return null;
  return ServiceWindow(a, b < a ? b + 24 * 60 : b);
}

enum EstimateKind { inService, beforeService, afterService, unknown }

class ArrivalEstimate {
  const ArrivalEstimate(this.kind, {this.nextInMin, this.headwayMin, this.headwayMax, this.window});
  final EstimateKind kind;
  final int? nextInMin;
  final int? headwayMin;
  final int? headwayMax;
  final ServiceWindow? window;

  String get label {
    switch (kind) {
      case EstimateKind.inService:
        return 'Khoảng $nextInMin phút nữa (ước tính theo lịch)';
      case EstimateKind.beforeService:
        return 'Chưa chạy – bắt đầu ${window!.label.split('–').first}';
      case EstimateKind.afterService:
        return 'Đã hết giờ chạy (${window!.label})';
      case EstimateKind.unknown:
        return headwayMin != null
            ? 'Khoảng $headwayMin–$headwayMax phút/chuyến (không rõ giờ chạy)'
            : 'Chưa có dữ liệu lịch';
    }
  }
}

/// [offsetMin]: thời gian xe đi từ đầu tuyến đến trạm (ước lượng theo quãng đường).
ArrivalEstimate estimateArrival({
  required String interval,
  required String openingHours,
  required DateTime now,
  double offsetMin = 0,
}) {
  final iv = parseInterval(interval);
  final win = parseOpeningHours(openingHours);
  if (iv == null) return const ArrivalEstimate(EstimateKind.unknown);
  if (win == null) {
    return ArrivalEstimate(EstimateKind.unknown, headwayMin: iv.$1, headwayMax: iv.$2);
  }
  final nowMin = now.hour * 60 + now.minute;
  final first = win.startMin + offsetMin;
  final last = win.endMin + offsetMin;
  if (nowMin < first) {
    return ArrivalEstimate(EstimateKind.beforeService, window: win, headwayMin: iv.$1, headwayMax: iv.$2);
  }
  if (nowMin > last) {
    return ArrivalEstimate(EstimateKind.afterService, window: win, headwayMin: iv.$1, headwayMax: iv.$2);
  }
  final avg = (iv.$1 + iv.$2) / 2;
  final since = nowMin - first;
  var next = (avg - (since % avg)).round();
  if (next == 0) next = avg.round();
  return ArrivalEstimate(EstimateKind.inService,
      nextInMin: next, headwayMin: iv.$1, headwayMax: iv.$2, window: win);
}
