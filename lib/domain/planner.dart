import '../core/geo.dart';
import '../data/models.dart';
import 'schedule.dart';

/// Tham số tốc độ (ước lượng, có thể tinh chỉnh).
class PlannerConfig {
  const PlannerConfig({
    this.walkMps = 1.25,
    this.busMps = 5.0, // ~18 km/h nội đô
    this.maxWalkM = 700,
    this.maxTransferWalkM = 250,
    this.transferPenaltyMin = 4,
    this.detourFactor = 1.2,
    this.defaultWaitMin = 10,
    this.maxResults = 5,
  });
  final double walkMps, busMps, maxWalkM, maxTransferWalkM, transferPenaltyMin, detourFactor;
  final double defaultWaitMin;
  final int maxResults;
}

class TripLeg {
  const TripLeg({required this.route, required this.board, required this.alight, required this.stopCount, required this.rideMin, required this.waitMin});
  final BusRoute route;
  final BusStop board;
  final BusStop alight;
  final int stopCount;
  final double rideMin;
  final double waitMin;
}

class TripPlan {
  const TripPlan({required this.legs, required this.walkStartM, required this.walkEndM, required this.transferWalkM, required this.totalMin});
  final List<TripLeg> legs;
  final double walkStartM, walkEndM, transferWalkM, totalMin;
  bool get isDirect => legs.length == 1;
  double get walkTotalM => walkStartM + walkEndM + transferWalkM;
}

class _Reach {
  _Reach(this.cost, this.leg, this.walkStart);
  final double cost; // phút từ điểm đi tới lúc xuống ở trạm
  final TripLeg leg;
  final double walkStart;
}

/// Tìm đường: đi thẳng + tối đa 1 lần chuyển tuyến (có đi bộ ngắn giữa 2 trạm).
class TripPlanner {
  TripPlanner(this.data, [this.cfg = const PlannerConfig()]);
  final BusData data;
  final PlannerConfig cfg;

  double _wait(BusRoute r) {
    final iv = parseInterval(r.interval);
    return iv == null ? cfg.defaultWaitMin : (iv.$1 + iv.$2) / 4; // nửa khoảng cách chuyến
  }

  double _walkMin(double m) => m / cfg.walkMps / 60;

  List<double> _cum(BusRoute r) {
    final stops = r.stopIds.map((id) => data.stopById[id]).toList();
    final cum = <double>[0];
    for (var i = 1; i < stops.length; i++) {
      final a = stops[i - 1], b = stops[i];
      cum.add(cum.last + (a == null || b == null ? 0 : distanceM(a.pos, b.pos)));
    }
    return cum;
  }

  List<TripPlan> plan(LatLon from, LatLon to) {
    final origin = {for (final e in data.nearbyStops(from, radiusM: cfg.maxWalkM, limit: 60)) e.$1.id: e.$2};
    final dest = {for (final e in data.nearbyStops(to, radiusM: cfg.maxWalkM, limit: 60)) e.$1.id: e.$2};
    if (origin.isEmpty || dest.isEmpty) return const [];

    final cums = {for (final r in data.routes) r.id: _cum(r)};
    double rideMin(BusRoute r, int i, int j) =>
        (cums[r.id]![j] - cums[r.id]![i]) * cfg.detourFactor / cfg.busMps / 60;

    final results = <TripPlan>[];
    // Bước 1: mọi trạm có thể tới bằng 1 chuyến (giữ chi phí tốt nhất).
    final reach = <String, _Reach>{};
    for (final r in data.routes) {
      final wait = _wait(r);
      double? bestBoardCost;
      int? bestIdx;
      double bestWalk = 0;
      for (var j = 0; j < r.stopIds.length; j++) {
        final sid = r.stopIds[j];
        final s = data.stopById[sid];
        if (s == null) continue;
        if (bestIdx != null && j > bestIdx) {
          final cost = bestBoardCost! + rideMin(r, bestIdx, j);
          final leg = TripLeg(route: r, board: data.stopById[r.stopIds[bestIdx]]!, alight: s, stopCount: j - bestIdx, rideMin: rideMin(r, bestIdx, j), waitMin: wait);
          final prev = reach[sid];
          if (prev == null || cost < prev.cost) reach[sid] = _Reach(cost, leg, bestWalk);
          final dw = dest[sid];
          if (dw != null) {
            results.add(TripPlan(legs: [leg], walkStartM: bestWalk, walkEndM: dw, transferWalkM: 0, totalMin: cost + _walkMin(dw)));
          }
        }
        final ow = origin[sid];
        if (ow != null) {
          // Bỏ qua cost cộng dồn: chỉ so sánh (đi bộ + chờ - vị trí trên tuyến).
          final c = _walkMin(ow) + wait;
          final adjusted = c - rideMin(r, 0, j);
          final curAdj = bestIdx == null ? double.infinity : bestBoardCost! - rideMin(r, 0, bestIdx);
          if (adjusted < curAdj) {
            bestBoardCost = c;
            bestIdx = j;
            bestWalk = ow;
          }
        }
      }
    }

    // Bước 2: chuyển tuyến tại trạm đã tới (hoặc trạm gần trong bán kính đi bộ).
    final transferAt = <String, (double, _Reach, double)>{}; // trạm lên tuyến 2 -> (chi phí, reach, đi bộ)
    for (final e in reach.entries) {
      final s = data.stopById[e.key]!;
      for (final n in data.nearbyStops(s.pos, radiusM: cfg.maxTransferWalkM, limit: 12)) {
        final c = e.value.cost + _walkMin(n.$2) + cfg.transferPenaltyMin;
        final prev = transferAt[n.$1.id];
        if (prev == null || c < prev.$1) transferAt[n.$1.id] = (c, e.value, n.$2);
      }
    }
    for (final r in data.routes) {
      final wait = _wait(r);
      int? bi;
      (double, _Reach, double)? best;
      for (var j = 0; j < r.stopIds.length; j++) {
        final sid = r.stopIds[j];
        if (bi != null && best != null && dest.containsKey(sid) && best.$2.leg.route.id != r.id) {
          final ride = rideMin(r, bi, j);
          final leg2 = TripLeg(route: r, board: data.stopById[r.stopIds[bi]]!, alight: data.stopById[sid]!, stopCount: j - bi, rideMin: ride, waitMin: wait);
          results.add(TripPlan(
            legs: [best.$2.leg, leg2],
            walkStartM: best.$2.walkStart,
            walkEndM: dest[sid]!,
            transferWalkM: best.$3,
            totalMin: best.$1 + wait + ride + _walkMin(dest[sid]!),
          ));
        }
        final t = transferAt[sid];
        if (t != null && t.$2.leg.route.ref != r.ref) {
          final adj = t.$1 - rideMin(r, 0, j);
          final cur = best == null ? double.infinity : best.$1 - rideMin(r, 0, bi!);
          if (adj < cur) {
            best = t;
            bi = j;
          }
        }
      }
    }

    // Đi bộ thẳng nếu rất gần.
    results.sort((a, b) => a.totalMin.compareTo(b.totalMin));
    final seen = <String>{};
    final out = <TripPlan>[];
    for (final p in results) {
      final key = p.legs.map((l) => l.route.ref).join('>');
      if (seen.add(key)) out.add(p);
      if (out.length >= cfg.maxResults) break;
    }
    return out;
  }
}
