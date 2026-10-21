import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../domain/schedule.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bus_map.dart';
import '../widgets/common.dart';
import '../widgets/wake_action.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});
  final String routeId;
  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  bool _schematic = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(busDataProvider).requireValue;
    final route = data.routeById[widget.routeId];
    if (route == null) return const Scaffold(body: EmptyState(icon: Icons.help_outline, title: 'Không tìm thấy tuyến'));
    final stops = data.stopsOf(route);
    final fav = ref.watch(favRoutesProvider).contains(route.id);
    final t = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final color = Brand.routeColor(route.ref);
    final win = parseOpeningHours(route.openingHours);
    final iv = parseInterval(route.interval);
    // Ước tính tại từng trạm theo quãng đường từ đầu tuyến.
    final cum = <double>[0];
    for (var i = 1; i < stops.length; i++) {
      cum.add(cum.last + distanceM(stops[i - 1].pos, stops[i].pos));
    }
    ArrivalEstimate estAt(int i) =>
        estimateArrival(interval: route.interval, openingHours: route.openingHours, now: now, offsetMin: cum[i] * 1.2 / 5 / 60);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 330,
          automaticallyImplyLeading: false,
          backgroundColor: t.colorScheme.surface,
          titleSpacing: 12,
          title: Row(children: [
            GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Quay lại', onPressed: () => context.pop()),
            const Spacer(),
            GlassIconButton(
              icon: _schematic ? Icons.map_rounded : Icons.layers_rounded,
              tooltip: _schematic ? 'Bản đồ' : 'Sơ đồ offline',
              onPressed: () => setState(() => _schematic = !_schematic),
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              tooltip: 'Yêu thích',
              color: fav ? const Color(0xFFE5484D) : null,
              onPressed: () => ref.read(favRoutesProvider.notifier).toggle(route.id),
            ),
          ]),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: BusMap(line: route.geometry, lineColor: color, stops: stops, schematic: _schematic),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: BoxDecoration(color: t.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Hero(tag: 'route-${route.id}', child: RouteBadge(route.ref, size: 58)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tuyến ${route.ref}', style: t.textTheme.labelLarge?.copyWith(color: color)),
                      Text(route.title, style: t.textTheme.titleLarge?.copyWith(height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Stat(Icons.schedule_rounded, 'Giờ chạy', win?.label ?? 'Chưa rõ'),
                  _Stat(Icons.repeat_rounded, 'Giãn cách', iv == null ? 'Chưa rõ' : '${iv.$1}–${iv.$2} phút'),
                  _Stat(Icons.place_rounded, 'Số trạm', '${stops.length}'),
                ]),
                if (route.operator.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.business_rounded, size: 16, color: t.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(route.operator, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader('Lộ trình', padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), trailing: const EstimateChip('Dự kiến theo lịch, không phải GPS')),
        ),
        SliverList.builder(
          itemCount: stops.length,
          itemBuilder: (_, i) => _TimelineRow(
            name: stops[i].displayName,
            first: i == 0,
            last: i == stops.length - 1,
            color: color,
            est: estAt(i),
            onTap: () => context.push('/stop/${stops[i].id}'),
            onAlarm: () => startWake(context, stops[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(color: t.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: t.colorScheme.primary),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          Text(value, style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.name, required this.first, required this.last, required this.color, required this.est, required this.onTap, required this.onAlarm});
  final String name;
  final bool first, last;
  final Color color;
  final ArrivalEstimate est;
  final VoidCallback onTap, onAlarm;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final end = first || last;
    return InkWell(
      onTap: () {
        tapHaptic();
        onTap();
      },
      child: IntrinsicHeight(
        child: Row(children: [
          const SizedBox(width: 24),
          SizedBox(
            width: 28,
            child: Column(children: [
              Expanded(child: Container(width: 6, decoration: BoxDecoration(color: first ? Colors.transparent : color, borderRadius: BorderRadius.circular(3)))),
              Container(
                width: end ? 22 : 14,
                height: end ? 22 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: end ? color : t.colorScheme.surface,
                  border: Border.all(color: end ? t.colorScheme.surface : color, width: end ? 4 : 3),
                  boxShadow: end ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : null,
                ),
              ),
              Expanded(child: Container(width: 6, decoration: BoxDecoration(color: last ? Colors.transparent : color, borderRadius: BorderRadius.circular(3)))),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(name, style: end ? t.textTheme.titleSmall : t.textTheme.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (end) Text(first ? 'Đầu tuyến' : 'Cuối tuyến', style: t.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          if (est.kind == EstimateKind.inService) EstimatePill(est, compact: true),
          IconButton(tooltip: 'Đánh thức trước trạm này', onPressed: onAlarm, icon: Icon(Icons.alarm_add_rounded, color: t.colorScheme.onSurfaceVariant, size: 22)),
          const SizedBox(width: 6),
        ]),
      ),
    );
  }
}
