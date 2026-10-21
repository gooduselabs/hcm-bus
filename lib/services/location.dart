import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../core/geo.dart';
import '../domain/geofence.dart';
import 'notifications.dart';

class LocationService {
  static Future<bool> ensurePermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (background && p == LocationPermission.whileInUse) {
      // iOS/Android sẽ hỏi "Luôn cho phép" nếu hệ điều hành hỗ trợ.
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  static Future<LatLon?> current() async {
    if (!await ensurePermission()) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      return LatLon(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// Theo dõi vị trí (kể cả khi tắt màn hình, Android dùng foreground service)
/// và báo thức khi sắp tới trạm.
class WakeService extends ChangeNotifier {
  WakeService._();
  static final instance = WakeService._();

  WakeAlarm? alarm;
  String? stopName;
  StreamSubscription<Position>? _sub;

  double? startDistance;

  bool get active => alarm?.state == WakeState.tracking;

  /// 0..1: đã đi được bao nhiêu quãng đường tới vùng báo thức.
  double get progress {
    final a = alarm, d = a?.lastDistance, s0 = startDistance;
    if (a == null || d == null || s0 == null || s0 <= a.radiusM) return 0;
    return ((s0 - d) / (s0 - a.radiusM)).clamp(0.0, 1.0);
  }

  /// Chỉ dùng cho ảnh chụp/demo.
  @visibleForTesting
  void debugDemo(LatLon target, String name, {required double start, required double now, double radiusM = 400}) {
    alarm = WakeAlarm(target: target, radiusM: radiusM)..lastDistance = now;
    stopName = name;
    startDistance = start;
    notifyListeners();
  }

  Future<bool> start(LatLon target, String name, {double radiusM = 400}) async {
    if (!await LocationService.ensurePermission(background: true)) return false;
    await Notifications.init();
    await stop();
    alarm = WakeAlarm(target: target, radiusM: radiusM);
    stopName = name;
    final LocationSettings settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'Đang theo dõi để báo xuống trạm',
            notificationText: 'Trạm: $name',
            enableWakeLock: true,
          ),
        ),
      TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 25,
          activityType: ActivityType.automotiveNavigation,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          pauseLocationUpdatesAutomatically: false,
        ),
      _ => const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25),
    };
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(_onPos);
    notifyListeners();
    return true;
  }

  Future<void> _onPos(Position p) async {
    final a = alarm;
    if (a == null) return;
    final fire = a.update(LatLon(p.latitude, p.longitude), speedMps: p.speed, accuracyM: p.accuracy);
    startDistance ??= a.lastDistance;
    notifyListeners();
    if (fire) {
      await Notifications.wakeUp(stopName ?? '');
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 1200]);
      }
      await _sub?.cancel();
      _sub = null;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    alarm?.cancel();
    alarm = null;
    startDistance = null;
    notifyListeners();
  }
}
