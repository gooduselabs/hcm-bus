import 'package:flutter/material.dart';

/// Huy hiệu số tuyến.
class RouteBadge extends StatelessWidget {
  const RouteBadge(this.refText, {super.key, this.size = 48});
  final String refText;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(refText.isEmpty ? '?' : refText,
            style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: size * 0.33)),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 40, backgroundColor: t.colorScheme.primaryContainer, child: Icon(icon, size: 40, color: t.colorScheme.onPrimaryContainer)),
          const SizedBox(height: 16),
          Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

/// Nhãn nguồn dữ liệu: luôn nói rõ đây là ước tính.
class EstimateChip extends StatelessWidget {
  const EstimateChip(this.text, {super.key, this.realtime = false});
  final String text;
  final bool realtime;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: realtime ? cs.primaryContainer : cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(realtime ? Icons.gps_fixed : Icons.schedule, size: 14, color: cs.onSecondaryContainer),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer))),
      ]),
    );
  }
}

/// Hiện danh sách xuất hiện dần (hiệu ứng mượt).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index.clamp(0, 10) * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c)),
      child: child,
    );
  }
}
