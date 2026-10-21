import 'dart:io';

import 'package:hcm_bus/core/geo.dart';
import 'package:hcm_bus/data/models.dart';

BusData? _real;
BusData realData() => _real ??= BusData.parse(File('assets/data/hcm_bus.json').readAsStringSync());

/// Mạng giả: tuyến A (đông-tây) và B (bắc-nam) giao nhau ở trạm X.
BusData toyData() {
  BusStop s(String id, double lat, double lon) => BusStop(id: id, name: 'Trạm $id', pos: LatLon(lat, lon));
  final stops = [
    s('a1', 10.770, 106.680), s('a2', 10.770, 106.690), s('x', 10.770, 106.700), s('a4', 10.770, 106.710),
    s('b1', 10.750, 106.700), s('b2', 10.760, 106.700), s('b4', 10.780, 106.700), s('b5', 10.790, 106.700),
  ];
  return BusData(stops: stops, routes: [
    BusRoute(id: 'A', ref: 'A', name: 'A1 - A4', stopIds: const ['a1', 'a2', 'x', 'a4'], interval: '00:10-00:10', openingHours: 'Mo-Su 05:00-21:00'),
    BusRoute(id: 'Ar', ref: 'A', name: 'A4 - A1', stopIds: const ['a4', 'x', 'a2', 'a1'], interval: '10'),
    BusRoute(id: 'B', ref: 'B', name: 'B1 - B5', stopIds: const ['b1', 'b2', 'x', 'b4', 'b5'], interval: '00:15'),
  ]);
}
