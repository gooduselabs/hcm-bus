import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../domain/planner.dart';
import '../../services/location.dart';
import '../../state/providers.dart';
import '../theme.dart';
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

  Future<Place?> _pick(BuildContext context) => showModalBottomSheet<Place>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _PlacePicker(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(planInputProvider);
    final results = ref.watch(planResultProvider);
    final now = ref.watch(clockProvider)();
    final t = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(16, top + 16, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Brand.greenDeep, Brand.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text('Tìm đường', style: t.textTheme.headlineSmall?.copyWith(color: Colors.white)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(children: [
                  const SizedBox(width: 16),
                  Column(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Brand.green, width: 3))),
                    for (var i = 0; i < 4; i++) Container(width: 2, height: 4, margin: const EdgeInsets.symmetric(vertical: 2), color: t.colorScheme.outlineVariant),
                    const Icon(Icons.location_on_rounded, color: Brand.coral, size: 16),
                  ]),
                  Expanded(
                    child: Column(children: [
                      _Field(label: 'Điểm đi', value: input.from?.label, onTap: () async {
                        final p = await _pick(context);
                        if (p != null) ref.read(planInputProvider.notifier).setFrom(p);
                      }),
                      Divider(height: 1, indent: 12, color: t.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      _Field(label: 'Điểm đến', value: input.to?.label, onTap: () async {
                        final p = await _pick(context);
                        if (p != null) ref.read(planInputProvider.notifier).setTo(p);
                      }),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Đảo chiều',
                    onPressed: () {
                      tapHaptic();
                      ref.read(planInputProvider.notifier).swap();
                    },
                    icon: const Icon(Icons.swap_vert_rounded),
                  ),
                  const SizedBox(width: 4),
                ]),
              ),
            ]),
          ),
        ),
        if (results == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.alt_route_rounded, title: 'Bạn muốn đi đâu?', subtitle: 'Chọn điểm đi và điểm đến.\nHỗ trợ đi thẳng hoặc chuyển 1 tuyến, có tính quãng đi bộ.'),
          )
        else if (results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.directions_walk_rounded, title: 'Chưa tìm được lộ trình', subtitle: 'Thử chọn điểm gần trạm hơn (trong ~700 m), hoặc chặng cần chuyển nhiều hơn 1 tuyến.'),
          )
        else ...[
          SliverToBoxAdapter(
            child: SectionHeader('${results.length} lộ trình', trailing: const EstimateChip('Thời gian dự kiến')),
          ),
          SliverList.builder(
            itemCount: results.length,
            itemBuilder: (_, i) => FadeSlideIn(index: i, child: _ItineraryCard(plan: results[i], best: i == 0, now: now)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, required this.onTap});
  final String label;
  final String? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          Text(value ?? 'Chọn trạm hoặc vị trí', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: t.textTheme.titleSmall?.copyWith(color: value == null ? t.colorScheme.onSurfaceVariant : null)),
        ]),
      ),
    );
  }
}

String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.plan, required this.best, required this.now});
  final TripPlan plan;
  final bool best;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    const walkMps = 1.25;
    final segs = <(double, Color?, String?)>[
      (plan.walkStartM / walkMps / 60, null, null),
      for (var i = 0; i < plan.legs.length; i++) ...[
        if (i > 0) (plan.transferWalkM / walkMps / 60 + 4, null, null),
        (plan.legs[i].waitMin + plan.legs[i].rideMin, Brand.routeColor(plan.legs[i].route.ref), plan.legs[i].route.ref),
      ],
      (plan.walkEndM / walkMps / 60, null, null),
    ];
    final total = segs.fold<double>(0, (a, s) => a + s.$1);
    final arrive = now.add(Duration(minutes: plan.totalMin.round()));
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      color: best ? null : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${plan.totalMin.round()}', style: t.textTheme.headlineMedium?.copyWith(height: 1)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('phút', style: t.textTheme.titleSmall)),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('${_hm(now)} – ${_hm(arrive)}', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          const Spacer(),
          if (best)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Brand.amber, borderRadius: BorderRadius.circular(10)),
              child: const Text('Nhanh nhất', style: TextStyle(color: Brand.ink, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 12),
        // Thanh thời lượng theo chặng.
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(children: [
              for (final s in segs)
                if (s.$1 > 0.2)
                  Expanded(
                    flex: (s.$1 / total * 1000).round().clamp(1, 1000),
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      color: s.$2 ?? t.colorScheme.outlineVariant,
                    ),
                  ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 6, children: [
          _Walk(m: plan.walkStartM),
          for (final l in plan.legs) ...[
            Icon(Icons.chevron_right_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
            RouteBadge(l.route.ref, size: 34),
          ],
          Icon(Icons.chevron_right_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
          _Walk(m: plan.walkEndM),
          const SizedBox(width: 4),
          Text(plan.isDirect ? '· Đi thẳng' : '· Chuyển 1 lần', style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 10),
        Divider(color: t.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        _Step(icon: Icons.directions_walk_rounded, text: 'Đi bộ ${formatDistance(plan.walkStartM)} tới ${plan.legs.first.board.displayName}'),
        for (var i = 0; i < plan.legs.length; i++) ...[
          if (i > 0) _Step(icon: Icons.transfer_within_a_station_rounded, text: 'Chuyển tuyến tại ${plan.legs[i].board.displayName}${plan.transferWalkM > 5 ? ' (đi bộ ${formatDistance(plan.transferWalkM)})' : ''}'),
          _Step(
            icon: Icons.directions_bus_rounded,
            color: Brand.routeColor(plan.legs[i].route.ref),
            text: 'Tuyến ${plan.legs[i].route.ref} · ${plan.legs[i].stopCount} trạm · ~${formatMinutes(plan.legs[i].rideMin)}\nXuống tại ${plan.legs[i].alight.displayName}',
            onTap: () => context.push('/route/${plan.legs[i].route.id}'),
          ),
        ],
        _Step(icon: Icons.flag_rounded, text: 'Đi bộ ${formatDistance(plan.walkEndM)} tới đích'),
      ]),
    );
  }
}

class _Walk extends StatelessWidget {
  const _Walk({required this.m});
  final double m;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.directions_walk_rounded, size: 18, color: cs.onSurfaceVariant),
        Text('${(m / 1.25 / 60).ceil()}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text, this.color, this.onTap});
  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 19, color: color ?? t.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: t.textTheme.bodyMedium?.copyWith(height: 1.35))),
          if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
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
            decoration: const InputDecoration(hintText: 'Tìm trạm / địa danh gần trạm', prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.my_location_rounded, color: Color(0xFF2F80ED)),
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
