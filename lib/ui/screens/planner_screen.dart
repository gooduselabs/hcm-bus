import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../domain/planner.dart';
import '../../services/location.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

class Place {
  const Place(this.label, this.pos, {this.isMe = false});
  final String label;
  final LatLon pos;
  final bool isMe;
}

class PlanInput {
  const PlanInput({this.from, this.to});
  final Place? from;
  final Place? to;
}

class PlanInputNotifier extends Notifier<PlanInput> {
  @override
  PlanInput build() => const PlanInput();
  void setFrom(Place p) => state = PlanInput(from: p, to: state.to);
  void setTo(Place p) => state = PlanInput(from: state.from, to: p);
  void swap() => state = PlanInput(from: state.to, to: state.from);
}

final planInputProvider = NotifierProvider<PlanInputNotifier, PlanInput>(PlanInputNotifier.new);

final planResultProvider = Provider<List<TripPlan>?>((ref) {
  final i = ref.watch(planInputProvider);
  if (i.from == null || i.to == null) return null;
  return ref.watch(plannerProvider).plan(i.from!.pos, i.to!.pos);
});

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  Future<Place?> _pick(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PlacePicker(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(planInputProvider);
    final results = ref.watch(planResultProvider);
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        const SliverAppBar.large(title: Text('Tìm đường')),
        SliverToBoxAdapter(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: Column(children: [
                    ListTile(
                      leading: Icon(Icons.trip_origin, color: t.colorScheme.primary),
                      title: Text(input.from?.label ?? 'Chọn điểm đi'),
                      onTap: () async {
                        final p = await _pick(context, ref);
                        if (p != null) ref.read(planInputProvider.notifier).setFrom(p);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.place, color: t.colorScheme.error),
                      title: Text(input.to?.label ?? 'Chọn điểm đến'),
                      onTap: () async {
                        final p = await _pick(context, ref);
                        if (p != null) ref.read(planInputProvider.notifier).setTo(p);
                      },
                    ),
                  ]),
                ),
                IconButton(tooltip: 'Đảo chiều', onPressed: () => ref.read(planInputProvider.notifier).swap(), icon: const Icon(Icons.swap_vert)),
              ]),
            ),
          ),
        ),
        if (results == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.alt_route, title: 'Bạn muốn đi đâu?', subtitle: 'Chọn điểm đi và điểm đến. Hỗ trợ đi thẳng hoặc chuyển 1 tuyến.'),
          )
        else if (results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.directions_walk, title: 'Chưa tìm được lộ trình', subtitle: 'Thử chọn điểm gần trạm hơn (trong ~700 m) hoặc cần chuyển nhiều hơn 1 tuyến.'),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Thời gian là ước tính (tốc độ trung bình + chờ theo lịch)', style: t.textTheme.labelMedium),
            ),
          ),
          SliverList.builder(
            itemCount: results.length,
            itemBuilder: (_, i) => FadeSlideIn(index: i, child: _PlanCard(plan: results[i], best: i == 0)),
          ),
        ],
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.best});
  final TripPlan plan;
  final bool best;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(formatMinutes(plan.totalMin), style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (best) Chip(label: const Text('Nhanh nhất'), visualDensity: VisualDensity.compact, backgroundColor: t.colorScheme.primaryContainer),
            const Spacer(),
            Text(plan.isDirect ? 'Đi thẳng' : 'Chuyển 1 lần', style: t.textTheme.labelLarge),
          ]),
          const SizedBox(height: 8),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 6, children: [
            const Icon(Icons.directions_walk, size: 20),
            for (final l in plan.legs) ...[
              const Icon(Icons.chevron_right, size: 18),
              RouteBadge(l.route.ref, size: 36),
            ],
            const Icon(Icons.chevron_right, size: 18),
            const Icon(Icons.directions_walk, size: 20),
          ]),
          const SizedBox(height: 12),
          _step(context, Icons.directions_walk, 'Đi bộ ${formatDistance(plan.walkStartM)} tới ${plan.legs.first.board.displayName}'),
          for (var i = 0; i < plan.legs.length; i++) ...[
            if (i > 0) _step(context, Icons.transfer_within_a_station, 'Chuyển tuyến${plan.transferWalkM > 5 ? ' (đi bộ ${formatDistance(plan.transferWalkM)})' : ''} – lên tại ${plan.legs[i].board.displayName}'),
            _step(context, Icons.directions_bus, 'Tuyến ${plan.legs[i].route.ref}: ${plan.legs[i].stopCount} trạm, ~${formatMinutes(plan.legs[i].rideMin)} – xuống ${plan.legs[i].alight.displayName}',
                onTap: () => context.push('/route/${plan.legs[i].route.id}')),
          ],
          _step(context, Icons.flag, 'Đi bộ ${formatDistance(plan.walkEndM)} tới đích'),
        ]),
      ),
    );
  }

  Widget _step(BuildContext context, IconData icon, String text, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ]),
        ),
      );
}

class _PlacePicker extends ConsumerStatefulWidget {
  const _PlacePicker();
  @override
  ConsumerState<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<_PlacePicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final d = ref.watch(busDataProvider).requireValue;
    final list = d.searchStops(_q, limit: 40);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tìm trạm / địa danh gần trạm', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.my_location),
          title: const Text('Vị trí của tôi'),
          onTap: () async {
            final nav = Navigator.of(context);
            final p = await LocationService.current();
            if (p != null) nav.pop(Place('Vị trí của tôi', p, isMe: true));
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.signpost_outlined),
              title: Text(list[i].displayName),
              onTap: () => Navigator.pop(context, Place(list[i].displayName, list[i].pos)),
            ),
          ),
        ),
      ]),
    );
  }
}
