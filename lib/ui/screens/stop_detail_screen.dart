import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/schedule.dart';
import '../../state/providers.dart';
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
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(stop.displayName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Yêu thích',
            onPressed: () => ref.read(favStopsProvider.notifier).toggle(stopId),
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? t.colorScheme.error : null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startWake(context, stop),
        icon: const Icon(Icons.alarm_add),
        label: const Text('Báo khi tới trạm'),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(height: 180, child: BusMap(highlight: stop.pos)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            Expanded(child: Text('Xe sắp đến', style: t.textTheme.titleSmall)),
            Flexible(child: EstimateChip(rt.isRealtime ? rt.sourceLabel : 'Ước tính theo lịch', realtime: rt.isRealtime)),
          ]),
        ),
        if (routes.isEmpty) const ListTile(title: Text('Chưa có tuyến nào trong dữ liệu')),
        for (final r in routes)
          Card(
            child: ListTile(
              onTap: () => context.push('/route/${r.id}'),
              leading: RouteBadge(r.ref, size: 44),
              title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: FutureBuilder<ArrivalEstimate>(
                future: rt.arrival(r, stop, now),
                builder: (_, s) => Text(s.data?.label ?? '…'),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text('Báo cáo của bạn (lưu trên máy)', style: t.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final type in ReportType.values)
              ActionChip(
                avatar: Icon(type.icon, size: 18),
                label: Text(type.label),
                onPressed: () {
                  ref.read(reportsProvider.notifier).add(UserReport(stopId, routes.isEmpty ? '' : routes.first.ref, type, ref.read(clockProvider)()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã ghi nhận: ${type.label}. Cảm ơn bạn!')));
                },
              ),
          ]),
        ),
        for (final r in reports)
          ListTile(
            dense: true,
            leading: Icon(r.type.icon),
            title: Text(r.type.label),
            trailing: Text('${now.difference(r.time).inMinutes} phút trước'),
          ),
      ]),
    );
  }
}
