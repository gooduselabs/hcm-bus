import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../services/location.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bus_map.dart';
import '../widgets/common.dart';
import '../widgets/stop_card.dart';

/// Trang chủ: bản đồ toàn màn hình + bottom sheet kéo được.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    final p = await LocationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không lấy được vị trí. Hãy bật GPS và cấp quyền.')));
    }
    ref.read(locationProvider.notifier).set(p);
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(busDataProvider).requireValue;
    final loc = ref.watch(locationProvider);
    final center = loc ?? benThanh;
    final nearby = d.nearbyStops(center, radiusM: 900, limit: 20);
    final favRoutes = [for (final id in ref.watch(favRoutesProvider)) ?d.routeById[id]];
    final t = Theme.of(context);
    final h = MediaQuery.sizeOf(context).height;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: BusMap(markers: [for (final e in nearby.take(12)) e.$1], me: loc, bottomInset: h * 0.42, showAttribution: false),
        ),
        // Thanh tìm kiếm kính mờ.
        Positioned(
          top: top + 12,
          left: 16,
          right: 16,
          child: Row(children: [
            Expanded(
              child: Pressable(
                onTap: () => context.go('/plan'),
                child: Glass(
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: t.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Bạn muốn đi đâu?', style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.onSurfaceVariant))),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GlassIconButton(icon: Icons.tune_rounded, tooltip: 'Cài đặt', onPressed: () => context.push('/settings')),
          ]),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.46,
          minChildSize: 0.18,
          maxChildSize: 0.93,
          snap: true,
          snapSizes: const [0.18, 0.46, 0.93],
          builder: (context, sc) => Stack(clipBehavior: Clip.none, children: [
            Positioned(
              right: 16,
              top: -64,
              child: GlassIconButton(
                icon: _locating ? Icons.more_horiz : Icons.my_location_rounded,
                tooltip: 'Vị trí của tôi',
                color: const Color(0xFF2F80ED),
                onPressed: _locate,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
              ),
              child: ListView(controller: sc, padding: EdgeInsets.zero, children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: t.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(children: [
                    _QuickAction(icon: Icons.alt_route_rounded, label: 'Tìm đường', color: Brand.green, onTap: () => context.go('/plan')),
                    _QuickAction(icon: Icons.directions_bus_rounded, label: 'Tuyến', color: const Color(0xFF1E88E5), onTap: () => context.go('/routes')),
                    _QuickAction(icon: Icons.signpost_rounded, label: 'Tìm trạm', color: const Color(0xFF8E24AA), onTap: () => context.push('/stops')),
                    _QuickAction(icon: Icons.alarm_rounded, label: 'Báo thức', color: Brand.amber, onTap: () => context.push('/wake')),
                  ]),
                ),
                if (favRoutes.isNotEmpty) ...[
                  const SectionHeader('Tuyến yêu thích', padding: EdgeInsets.fromLTRB(20, 14, 20, 8)),
                  SizedBox(
                    height: 46,
                    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                      for (final r in favRoutes)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Pressable(
                            onTap: () => context.push('/route/${r.id}'),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                              decoration: BoxDecoration(color: t.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                              child: Row(children: [
                                RouteBadge(r.ref, size: 34),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 150),
                                  child: Text(r.to.isNotEmpty ? r.to : r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.labelLarge),
                                ),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ],
                SectionHeader(
                  loc == null ? 'Trạm quanh Bến Thành' : 'Trạm gần bạn',
                  trailing: const EstimateChip('Giờ xe: dự kiến theo lịch'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                ),
                if (nearby.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Không có trạm nào trong 900 m.')),
                for (var i = 0; i < nearby.length; i++) FadeSlideIn(index: i, child: StopCard(stop: nearby[i].$1, distance: nearby[i].$2)),
                const SizedBox(height: 24),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Pressable(
          onTap: onTap,
          child: Column(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
