import '../core/geo.dart';
import '../data/models.dart';
import '../domain/schedule.dart';

/// Nguồn giờ xe đến. Hiện chỉ có ước tính theo lịch OSM.
///
/// Khi có hợp tác CHÍNH THỨC với Trung tâm Quản lý Giao thông công cộng
/// TP.HCM (dữ liệu GPS/ETA có giấy phép), hãy thêm một lớp mới triển khai
/// [RealtimeProvider] (vd. `OfficialPartnerProvider`) và đổi provider trong
/// `state/providers.dart`. KHÔNG dùng API riêng của MultiGo/BusMap/apicms.
abstract class RealtimeProvider {
  String get sourceLabel;
  bool get isRealtime;
  Future<ArrivalEstimate> arrival(BusRoute route, BusStop stop, DateTime now);
}

/// Ước tính theo `interval` + `opening_hours` và quãng đường từ đầu tuyến.
class ScheduleEstimateProvider implements RealtimeProvider {
  ScheduleEstimateProvider(this.data);
  final BusData data;

  @override
  String get sourceLabel => 'Ước tính theo lịch (OSM) – không phải GPS';
  @override
  bool get isRealtime => false;

  @override
  Future<ArrivalEstimate> arrival(BusRoute route, BusStop stop, DateTime now) async {
    final stops = data.stopsOf(route);
    var dist = 0.0;
    for (var i = 1; i < stops.length; i++) {
      dist += distanceM(stops[i - 1].pos, stops[i].pos);
      if (stops[i].id == stop.id) break;
    }
    return estimateArrival(
      interval: route.interval,
      openingHours: route.openingHours,
      now: now,
      offsetMin: dist * 1.2 / 5.0 / 60,
    );
  }
}

/// Dữ liệu giả cho demo/test. KHÔNG bật trong bản phát hành.
class MockRealtimeProvider implements RealtimeProvider {
  @override
  String get sourceLabel => 'Dữ liệu giả lập (demo)';
  @override
  bool get isRealtime => true;
  @override
  Future<ArrivalEstimate> arrival(BusRoute route, BusStop stop, DateTime now) async =>
      ArrivalEstimate(EstimateKind.inService, nextInMin: (route.id.hashCode + stop.id.hashCode).abs() % 15 + 1);
}
