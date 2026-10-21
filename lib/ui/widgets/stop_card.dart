import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../../realtime/realtime_provider.dart';
import '../../state/providers.dart';
import 'common.dart';

/// Thẻ trạm: tên, khoảng cách, các tuyến kèm viên "Dự kiến".
class StopCard extends ConsumerWidget {
  const StopCard({super.key, required this.stop, this.distance, this.maxRoutes = 3});
  final BusStop stop;
  final double? distance;
  final int maxRoutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(busDataProvider).requireValue;
    final now = ref.watch(clockProvider)();
    final t = Theme.of(context);
    final seen = <String>{};
    final routes = d.routesAtStop(stop.id).where((r) => seen.add(r.ref)).toList();
    return SoftCard(
      onTap: () => context.push('/stop/${stop.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: t.colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.signpost_rounded, color: t.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stop.displayName, style: t.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                [if (distance != null) '${formatDistance(distance!)} · ${(distance! / 80).ceil()} phút đi bộ', '${routes.length} tuyến'].join(' · '),
                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
        ]),
        if (routes.isNotEmpty) const SizedBox(height: 12),
        for (final r in routes.take(maxRoutes))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              RouteBadge(r.ref, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Đi ${r.to.isNotEmpty ? r.to : r.title}', style: t.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              EstimatePill(scheduleEstimate(d, r, stop, now), compact: true),
            ]),
          ),
        if (routes.length > maxRoutes)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+${routes.length - maxRoutes} tuyến khác', style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.primary)),
          ),
      ]),
    );
  }
}
