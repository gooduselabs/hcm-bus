import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../domain/schedule.dart';
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
    final d = ref.watch(busDataProvider).requireValue;
    final favs = ref.watch(favRoutesProvider);
    final list = d.searchRoutes(_q);
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 150,
          backgroundColor: t.colorScheme.surface,
          actions: [IconButton(tooltip: 'Cài đặt', onPressed: () => context.push('/settings'), icon: const Icon(Icons.tune_rounded))],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
            title: Text('Xe buýt Sài Gòn', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            background: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 0),
                child: Text('${d.routes.length} lượt tuyến · offline', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Số tuyến hoặc tên bến…', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ),
        if (list.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off_rounded, title: 'Không tìm thấy tuyến', subtitle: 'Thử số tuyến (vd. 19) hoặc tên bến không dấu.'))
        else
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => FadeSlideIn(index: i, child: RouteTile(route: list[i], fav: favs.contains(list[i].id))),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
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
    final iv = parseInterval(route.interval);
    final win = parseOpeningHours(route.openingHours);
    final parts = route.title.split(RegExp(r'\s+-\s+'));
    final from = route.from.isNotEmpty ? route.from : parts.first;
    final to = route.to.isNotEmpty ? route.to : (parts.length > 1 ? parts.last : '');
    return SoftCard(
      onTap: () => context.push('/route/${route.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(children: [
        Hero(tag: 'route-${route.id}', child: RouteBadge(route.ref, size: 50)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _End(text: from, color: t.colorScheme.onSurfaceVariant, hollow: true),
            if (to.isNotEmpty) _End(text: to, color: t.colorScheme.primary),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (win != null) _Tag(Icons.schedule_rounded, win.label),
              if (iv != null) _Tag(Icons.repeat_rounded, '${iv.$1}–${iv.$2} phút'),
              _Tag(Icons.place_outlined, '${route.stopIds.length} trạm'),
            ]),
          ]),
        ),
        IconButton(
          tooltip: fav ? 'Bỏ yêu thích' : 'Yêu thích',
          onPressed: () {
            tapHaptic();
            ref.read(favRoutesProvider.notifier).toggle(route.id);
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
            child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(fav), color: fav ? const Color(0xFFE5484D) : t.colorScheme.onSurfaceVariant),
          ),
        ),
      ]),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.text, required this.color, this.hollow = false});
  final String text;
  final Color color;
  final bool hollow;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: hollow ? null : color, border: Border.all(color: color, width: 2)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: hollow ? FontWeight.w500 : FontWeight.w700))),
        ]),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}
