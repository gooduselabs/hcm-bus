import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/core/geo.dart';
import 'package:hcm_bus/domain/planner.dart';

import 'helpers.dart';

void main() {
  final planner = TripPlanner(toyData());

  test('đi thẳng cùng tuyến đúng chiều', () {
    final p = planner.plan(const LatLon(10.7701, 106.6801), const LatLon(10.7701, 106.7101));
    expect(p, isNotEmpty);
    expect(p.first.isDirect, isTrue);
    expect(p.first.legs.single.route.id, 'A');
    expect(p.first.legs.single.stopCount, 3);
  });

  test('chiều ngược dùng tuyến chiều về', () {
    final p = planner.plan(const LatLon(10.7701, 106.7101), const LatLon(10.7701, 106.6801));
    expect(p.first.legs.single.route.id, 'Ar');
  });

  test('chuyển 1 tuyến tại trạm giao', () {
    final p = planner.plan(const LatLon(10.7700, 106.6800), const LatLon(10.7900, 106.7000));
    final t = p.firstWhere((e) => !e.isDirect);
    expect(t.legs.map((l) => l.route.ref), ['A', 'B']);
    expect(t.legs.first.alight.id, 'x');
    expect(t.legs.last.alight.id, 'b5');
    expect(t.totalMin, greaterThan(0));
  });

  test('không có trạm gần -> rỗng', () {
    expect(planner.plan(const LatLon(11.5, 107.5), const LatLon(10.77, 106.70)), isEmpty);
  });

  test('dữ liệu thật: Bến Thành -> Bến xe Miền Tây có lộ trình', () {
    final p = TripPlanner(realData()).plan(const LatLon(10.7726, 106.6993), const LatLon(10.7414, 106.6188));
    expect(p, isNotEmpty);
    expect(p.first.totalMin, lessThan(150));
  });
}
