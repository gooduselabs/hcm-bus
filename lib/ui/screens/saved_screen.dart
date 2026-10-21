import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/stop_card.dart';
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
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          backgroundColor: t.colorScheme.surface,
          actions: [IconButton(tooltip: 'Cài đặt', onPressed: () => context.push('/settings'), icon: const Icon(Icons.tune_rounded))],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
            title: Text('Của tôi', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        if (routes.isEmpty && stops.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.favorite_rounded, title: 'Chưa có mục yêu thích', subtitle: 'Nhấn biểu tượng trái tim ở tuyến hoặc trạm để lưu lại, truy cập nhanh mỗi ngày.'),
          ),
        if (stops.isNotEmpty) const SliverToBoxAdapter(child: SectionHeader('Trạm yêu thích')),
        SliverList.list(children: [for (final s in stops) StopCard(stop: s)]),
        if (routes.isNotEmpty) const SliverToBoxAdapter(child: SectionHeader('Tuyến yêu thích')),
        SliverList.list(children: [for (final r in routes) RouteTile(route: r, fav: true)]),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }
}
