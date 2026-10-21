import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../../services/location.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/stop_card.dart';

class StopsScreen extends ConsumerStatefulWidget {
  const StopsScreen({super.key});
  @override
  ConsumerState<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends ConsumerState<StopsScreen> {
  String _q = '';
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
    final t = Theme.of(context);
    final List<(BusStop, double?)> items = _q.isEmpty
        ? [for (final e in d.nearbyStops(center, radiusM: 1000, limit: 40)) (e.$1, e.$2)]
        : [for (final s in d.searchStops(_q)) (s, loc == null ? null : distanceM(loc, s.pos))];
    return Scaffold(
      body: CustomScrollView(slivers: [
        const SliverAppBar(pinned: true, title: Text('Tìm trạm')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Tìm tên trạm (có dấu hoặc không dấu)', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ),
        if (_q.isEmpty)
          SliverToBoxAdapter(
            child: SoftCard(
              padding: EdgeInsets.zero,
              color: t.colorScheme.primaryContainer,
              child: ListTile(
                leading: _locating
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.my_location, color: t.colorScheme.onPrimaryContainer),
                title: Text(loc == null ? 'Trạm gần chợ Bến Thành' : 'Trạm gần bạn'),
                subtitle: Text(loc == null ? 'Nhấn để dùng vị trí GPS của bạn' : 'Trong bán kính 1 km'),
                onTap: _locating ? null : _locate,
              ),
            ),
          ),
        if (items.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.location_off, title: 'Không có trạm phù hợp'))
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final (s, dist) = items[i];
              return FadeSlideIn(index: i, child: StopCard(stop: s, distance: dist, maxRoutes: 2));
            },
          ),
      ]),
    );
  }
}
