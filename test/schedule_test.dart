import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_bus/domain/schedule.dart';

void main() {
  test('parseInterval nhiều định dạng', () {
    expect(parseInterval('00:08-00:20'), (8, 20));
    expect(parseInterval('00:15'), (15, 15));
    expect(parseInterval('12'), (12, 12));
    expect(parseInterval('PT10M'), (10, 10));
    expect(parseInterval(''), isNull);
    expect(parseInterval('abc'), isNull);
  });

  test('parseOpeningHours', () {
    expect(parseOpeningHours('Mo-Su 05:00-22:00')!.label, '05:00–22:00');
    expect(parseOpeningHours('24/7')!.startMin, 0);
    expect(parseOpeningHours('Mo-Fr 05:00-19:00; Sa off'), isNull);
  });

  test('ước tính trong / ngoài giờ chạy', () {
    final e = estimateArrival(interval: '00:10', openingHours: 'Mo-Su 05:00-22:00', now: DateTime(2026, 10, 21, 8, 3));
    expect(e.kind, EstimateKind.inService);
    expect(e.nextInMin, 7);
    expect(e.label, contains('ước tính'));
    expect(estimateArrival(interval: '10', openingHours: 'Mo-Su 05:00-22:00', now: DateTime(2026, 1, 1, 4)).kind, EstimateKind.beforeService);
    expect(estimateArrival(interval: '10', openingHours: 'Mo-Su 05:00-22:00', now: DateTime(2026, 1, 1, 23)).kind, EstimateKind.afterService);
    expect(estimateArrival(interval: '10', openingHours: '', now: DateTime(2026)).kind, EstimateKind.unknown);
    expect(estimateArrival(interval: '', openingHours: '', now: DateTime(2026)).label, 'Chưa có dữ liệu lịch');
  });
}
