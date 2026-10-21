import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/schedule.dart';
import '../../state/providers.dart';
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
    final first = stops.isEmpty ? null : stops.first;
    final est = estimateArrival(interval: route.interval, openingHours: route.openingHours, now: now);
    final win = parseOpeningHours(route.openingHours);
    final iv = parseInterval(route.interval);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Hero(tag: 'route-${route.id}', child: RouteBadge(route.ref, size: 40)),
          const SizedBox(width: 12),
          Expanded(child: Text('Tuyến ${route.ref}', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Yêu thích',
            onPressed: () => ref.read(favRoutesProvider.notifier).toggle(route.id),
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? t.colorScheme.error : null),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(height: 260, child: BusMap(line: route.geometry, stops: stops, schematic: _schematic)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.map_outlined), label: Text('Bản đồ')),
              ButtonSegment(value: true, icon: Icon(Icons.offline_bolt_outlined), label: Text('Sơ đồ offline')),
            ],
            selected: {_schematic},
            onSelectionChanged: (s) => setState(() => _schematic = s.first),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(route.title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Info(Icons.schedule, win?.label ?? (route.openingHours.isEmpty ? 'Chưa rõ giờ' : route.openingHours)),
                _Info(Icons.repeat, iv == null ? 'Chưa rõ giãn cách' : '${iv.$1}–${iv.$2} phút/chuyến'),
                _Info(Icons.pin_drop_outlined, '${stops.length} trạm'),
                if (route.operator.isNotEmpty) _Info(Icons.business, route.operator),
                if (route.fee.isNotEmpty) _Info(Icons.payments_outlined, route.fee),
              ]),
              const SizedBox(height: 12),
              if (first != null) Text('Tại đầu tuyến (${first.displayName}):', style: t.textTheme.labelLarge),
              const SizedBox(height: 4),
              EstimateChip(est.label),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text('Các trạm dừng', style: t.textTheme.titleSmall),
        ),
        for (var i = 0; i < stops.length; i++)
          _StopRow(
            index: i,
            last: i == stops.length - 1,
            name: stops[i].displayName,
            onTap: () => context.push('/stop/${stops[i].id}'),
            onAlarm: () => startWake(context, stops[i]),
          ),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(text), visualDensity: VisualDensity.compact);
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.index, required this.last, required this.name, required this.onTap, required this.onAlarm});
  final int index;
  final bool last;
  final String name;
  final VoidCallback onTap;
  final VoidCallback onAlarm;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final end = index == 0 || last;
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(children: [
          const SizedBox(width: 28),
          SizedBox(
            width: 24,
            child: Column(children: [
              Expanded(child: Container(width: 4, color: index == 0 ? Colors.transparent : cs.primary)),
              Container(
                width: end ? 18 : 12,
                height: end ? 18 : 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: end ? cs.primary : cs.surface, border: Border.all(color: cs.primary, width: 3)),
              ),
              Expanded(child: Container(width: 4, color: last ? Colors.transparent : cs.primary)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(name, style: TextStyle(fontWeight: end ? FontWeight.w700 : FontWeight.w400)),
            ),
          ),
          IconButton(tooltip: 'Đánh thức trước trạm này', onPressed: onAlarm, icon: const Icon(Icons.alarm_add_outlined)),
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}
