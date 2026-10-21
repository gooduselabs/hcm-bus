import 'dart:math' as math;

/// Toạ độ đơn giản, không phụ thuộc thư viện bản đồ (để test thuần Dart).
class LatLon {
  const LatLon(this.lat, this.lon);
  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      other is LatLon && other.lat == lat && other.lon == lon;
  @override
  int get hashCode => Object.hash(lat, lon);
  @override
  String toString() => 'LatLon($lat, $lon)';
}

/// Trung tâm mặc định: chợ Bến Thành.
const benThanh = LatLon(10.7725, 106.6980);

/// Khoảng cách Haversine (mét).
double distanceM(LatLon a, LatLon b) {
  const r = 6371000.0;
  final dLat = _rad(b.lat - a.lat);
  final dLon = _rad(b.lon - a.lon);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h.toDouble()));
}

double _rad(double d) => d * math.pi / 180;

String formatDistance(double m) =>
    m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

String formatMinutes(num min) {
  final m = min.round();
  if (m < 60) return '$m phút';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '$h giờ' : '$h giờ $r phút';
}

const _vn = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _plain = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Bỏ dấu tiếng Việt + chữ thường để tìm kiếm ("Bến Thành" ~ "ben thanh").
String normalizeVi(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = _vn.indexOf(ch);
    b.write(i >= 0 ? _plain[i] : ch);
  }
  return b.toString().trim();
}
