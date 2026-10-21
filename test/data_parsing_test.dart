import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/core/geo.dart';
import 'package:hcm_bus/data/models.dart';

import 'helpers.dart';

void main() {
  test('parse JSON tối thiểu + bỏ tuyến < 2 trạm hợp lệ', () {
    final d = BusData.parse('''{"generated":"2026-10-21","attribution":"© OpenStreetMap contributors",
      "stops":[{"id":"1","name":"Bến Thành","lat":10.77,"lon":106.69},{"id":"2","name":"","lat":10.78,"lon":106.70}],
      "routes":[{"id":"r1","ref":"01","name":"","from":"A","to":"B","stops":["1","2"],"geom":[[10.77,106.69],[10.78,106.7]]},
                {"id":"r2","ref":"02","stops":["1","999"]}]}''');
    expect(d.routes.length, 1);
    expect(d.routes.first.title, 'A - B');
    expect(d.stopById['2']!.displayName, 'Trạm chưa đặt tên');
    expect(d.routesAtStop('1').single.ref, '01');
    expect(d.routes.first.geometry.length, 2);
  });

  test('tìm kiếm không dấu', () {
    expect(normalizeVi('Bến Thành Đông'), 'ben thanh dong');
    final d = toyData();
    expect(d.searchStops('tram x').single.id, 'x');
    expect(d.searchRoutes('B').map((r) => r.id), contains('B'));
  });

  test('trạm gần nhất sắp xếp theo khoảng cách', () {
    final n = toyData().nearbyStops(const LatLon(10.7701, 106.7001), radiusM: 1500);
    expect(n.first.$1.id, 'x');
    expect(n.first.$2, lessThan(30));
  });

  test('asset OSM thật đọc được và đủ lớn', () {
    final d = realData();
    expect(d.routes.length, greaterThan(100));
    expect(d.stops.length, greaterThan(1000));
    expect(d.attribution, contains('OpenStreetMap'));
    expect(d.nearbyStops(benThanh, radiusM: 1000), isNotEmpty);
  });
}
