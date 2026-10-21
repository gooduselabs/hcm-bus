import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});
  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(busDataProvider);
    final favs = ref.watch(favRoutesProvider);
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Không đọc được dữ liệu', subtitle: '$e'),
        data: (d) {
          final list = d.searchRoutes(_q);
          return CustomScrollView(slivers: [
            SliverAppBar.large(
              title: const Text('Xe buýt Sài Gòn'),
              actions: [IconButton(tooltip: 'Cài đặt', onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined))],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Tìm số tuyến, tên bến…', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text('${list.length} lượt tuyến · dữ liệu offline', style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
            if (list.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, title: 'Không tìm thấy tuyến'))
            else
              SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => FadeSlideIn(index: i, child: RouteTile(route: list[i], fav: favs.contains(list[i].id))),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ]);
        },
      ),
    );
  }
}

class RouteTile extends ConsumerWidget {
  const RouteTile({super.key, required this.route, this.fav = false});
  final BusRoute route;
  final bool fav;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/route/${route.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Hero(tag: 'route-${route.id}', child: RouteBadge(route.ref)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(route.title, style: t.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  [
                    if (route.openingHours.isNotEmpty) route.openingHours.replaceFirst('Mo-Su ', ''),
                    if (route.interval.isNotEmpty) '${route.interval.replaceAll('00:', '')} phút/chuyến',
                    '${route.stopIds.length} trạm',
                  ].join(' · '),
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
              ]),
            ),
            IconButton(
              tooltip: fav ? 'Bỏ yêu thích' : 'Yêu thích',
              onPressed: () => ref.read(favRoutesProvider.notifier).toggle(route.id),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(fav ? Icons.favorite : Icons.favorite_border, key: ValueKey(fav), color: fav ? t.colorScheme.error : null),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
