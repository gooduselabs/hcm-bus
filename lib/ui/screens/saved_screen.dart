import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../widgets/common.dart';
import 'routes_screen.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(busDataProvider).requireValue;
    final routes = [for (final id in ref.watch(favRoutesProvider)) ?d.routeById[id]];
    final stops = [for (final id in ref.watch(favStopsProvider)) ?d.stopById[id]];
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar.large(
          title: const Text('Của tôi'),
          actions: [IconButton(tooltip: 'Cài đặt', onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined))],
        ),
        if (routes.isEmpty && stops.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.favorite_border, title: 'Chưa có mục yêu thích', subtitle: 'Nhấn ♡ ở tuyến hoặc trạm để lưu lại truy cập nhanh.'),
          ),
        if (routes.isNotEmpty)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 4), child: Text('Tuyến yêu thích', style: t.textTheme.titleSmall))),
        SliverList.list(children: [for (final r in routes) RouteTile(route: r, fav: true)]),
        if (stops.isNotEmpty)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4), child: Text('Trạm yêu thích', style: t.textTheme.titleSmall))),
        SliverList.list(children: [
          for (final s in stops)
            Card(
              child: ListTile(
                leading: const Icon(Icons.signpost),
                title: Text(s.displayName),
                subtitle: Text('Tuyến ${d.routesAtStop(s.id).map((r) => r.ref).toSet().join(' · ')}'),
                onTap: () => context.push('/stop/${s.id}'),
              ),
            ),
        ]),
      ]),
    );
  }
}
