import '../core/geo.dart';

enum WakeState { idle, tracking, triggered }

/// Logic "Đánh thức trước trạm" thuần Dart (dễ test). Dịch vụ vị trí đẩy
/// từng điểm GPS vào [update]; trả true đúng MỘT lần khi cần báo thức.
class WakeAlarm {
  WakeAlarm({
    required this.target,
    this.radiusM = 400,
    this.leadSeconds = 90,
    this.maxAccuracyM = 200,
  });

  final LatLon target;
  final double radiusM;
  final int leadSeconds;
  final double maxAccuracyM;

  WakeState state = WakeState.tracking;
  double? lastDistance;
  int _hits = 0;

  /// [speedMps] tốc độ hiện tại (m/s), [accuracyM] sai số GPS.
  bool update(LatLon pos, {double speedMps = 0, double accuracyM = 10}) {
    if (state != WakeState.tracking) return false;
    if (accuracyM > maxAccuracyM) return false; // bỏ điểm GPS kém
    final d = distanceM(pos, target);
    lastDistance = d;
    final etaSec = speedMps > 1.5 ? d / speedMps : double.infinity;
    if (d <= radiusM || etaSec <= leadSeconds) {
      _hits++;
    } else {
      _hits = 0;
    }
    // Cần 2 lần liên tiếp để tránh báo nhầm do GPS nhảy, trừ khi đã rất gần.
    if (_hits >= 2 || d <= radiusM / 2) {
      state = WakeState.triggered;
      return true;
    }
    return false;
  }

  void cancel() => state = WakeState.idle;
}
