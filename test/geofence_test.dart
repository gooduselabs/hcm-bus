import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/core/geo.dart';
import 'package:hcm_bus/domain/geofence.dart';

void main() {
  const target = LatLon(10.7700, 106.7000);
  // ~111 m mỗi 0.001 độ vĩ.
  LatLon south(double m) => LatLon(target.lat - m / 111195, target.lon);

  test('không báo khi còn xa', () {
    final a = WakeAlarm(target: target, radiusM: 400);
    expect(a.update(south(2000)), isFalse);
    expect(a.update(south(1500)), isFalse);
    expect(a.state, WakeState.tracking);
  });

  test('báo sau 2 điểm liên tiếp trong bán kính, chỉ 1 lần', () {
    final a = WakeAlarm(target: target, radiusM: 400);
    expect(a.update(south(350)), isFalse);
    expect(a.update(south(300)), isTrue);
    expect(a.state, WakeState.triggered);
    expect(a.update(south(100)), isFalse);
  });

  test('GPS nhảy 1 điểm không gây báo nhầm', () {
    final a = WakeAlarm(target: target, radiusM: 400);
    expect(a.update(south(350)), isFalse);
    expect(a.update(south(1200)), isFalse);
    expect(a.update(south(380)), isFalse);
  });

  test('rất gần thì báo ngay', () {
    expect(WakeAlarm(target: target, radiusM: 400).update(south(150)), isTrue);
  });

  test('bỏ qua điểm có sai số lớn', () {
    final a = WakeAlarm(target: target);
    expect(a.update(south(50), accuracyM: 500), isFalse);
    expect(a.lastDistance, isNull);
  });

  test('báo sớm theo tốc độ (ETA < leadSeconds)', () {
    final a = WakeAlarm(target: target, radiusM: 200, leadSeconds: 90);
    expect(a.update(south(900), speedMps: 12), isFalse); // 75s -> hit 1
    expect(a.update(south(800), speedMps: 12), isTrue);
  });

  test('hủy thì không báo', () {
    final a = WakeAlarm(target: target)..cancel();
    expect(a.update(south(10)), isFalse);
  });
}
