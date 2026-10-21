import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/schedule.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bus_map.dart';
import '../widgets/common.dart';
import '../widgets/wake_action.dart';

class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({super.key, required this.stopId});
  final String stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(busDataProvider).requireValue;
    final stop = data.stopById[stopId];
    if (stop == null) return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Không tìm thấy trạm'));
    final routes = data.routesAtStop(stopId);
    final rt = ref.watch(realtimeProvider);
    final now = ref.watch(clockProvider)();
    ref.watch(reportsProvider);
    final reports = ref.read(reportsProvider.notifier).recentAt(stopId, now);
    final fav = ref.watch(favStopsProvider).contains(stopId);
    final nearby = [for (final e in data.nearbyStops(stop.pos, radiusM: 400, limit: 8)) if (e.$1.id != stopId) e.$1];
    final t = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Brand.amber,
        foregroundColor: Brand.ink,
        onPressed: () => startWake(context, stop),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Báo khi tới trạm', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          automaticallyImplyLeading: false,
          backgroundColor: t.colorScheme.surface,
          titleSpacing: 12,
          title: Row(children: [
            GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Quay lại', onPressed: () => context.pop()),
            const Spacer(),
            GlassIconButton(
              icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              tooltip: 'Yêu thích',
              color: fav ? const Color(0xFFE5484D) : null,
              onPressed: () => ref.read(favStopsProvider.notifier).toggle(stopId),
            ),
          ]),
          flexibleSpace: FlexibleSpaceBar(background: BusMap(highlight: stop.pos, markers: nearby)),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: BoxDecoration(color: t.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Brand.coral.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.signpost_rounded, color: Brand.coral),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(stop.displayName, style: t.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('${routes.map((r) => r.ref).toSet().length} tuyến dừng tại đây', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader('Xe sắp đến',
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              trailing: EstimateChip(rt.isRealtime ? rt.sourceLabel : 'Dự kiến theo lịch', realtime: rt.isRealtime)),
        ),
        if (routes.isEmpty) const SliverToBoxAdapter(child: ListTile(title: Text('Chưa có tuyến nào trong dữ liệu'))),
        SliverList.builder(
          itemCount: routes.length,
          itemBuilder: (_, i) {
            final r = routes[i];
            return FadeSlideIn(
              index: i,
              child: SoftCard(
                onTap: () => context.push('/route/${r.id}'),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(children: [
                  RouteBadge(r.ref, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Đi ${r.to.isNotEmpty ? r.to : r.title}', style: t.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(r.interval.isEmpty ? 'Không rõ giãn cách' : 'Mỗi ${parseInterval(r.interval)?.$1 ?? '?'}–${parseInterval(r.interval)?.$2 ?? '?'} phút',
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  FutureBuilder<ArrivalEstimate>(
                    future: rt.arrival(r, stop, now),
                    builder: (_, s) => s.data == null ? const SizedBox(width: 40) : EstimatePill(s.data!),
                  ),
                ]),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: SectionHeader('Trên trạm thế nào?', trailing: Text('lưu trên máy', style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant))),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final type in ReportType.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Pressable(
                      onTap: () {
                        ref.read(reportsProvider.notifier).add(UserReport(stopId, routes.isEmpty ? '' : routes.first.ref, type, ref.read(clockProvider)()));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã ghi nhận: ${type.label}. Cảm ơn bạn!')));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: t.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          Icon(type.icon, color: const [Brand.green, Color(0xFF1E88E5), Brand.coral, Brand.amber][type.index]),
                          const SizedBox(height: 4),
                          Text(type.label, style: t.textTheme.labelMedium, textAlign: TextAlign.center),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        SliverList.list(children: [
          for (final r in reports)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(r.type.icon, size: 20),
              title: Text(r.type.label, style: t.textTheme.bodyMedium),
              trailing: Text('${now.difference(r.time).inMinutes} phút trước', style: t.textTheme.labelMedium),
            ),
        ]),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ]),
    );
  }
}
