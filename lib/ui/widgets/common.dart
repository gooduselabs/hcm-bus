import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/schedule.dart';
import '../theme.dart';

void tapHaptic() => HapticFeedback.selectionClick();

/// Huy hiệu số tuyến có màu riêng.
class RouteBadge extends StatelessWidget {
  const RouteBadge(this.refText, {super.key, this.size = 44});
  final String refText;
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = Brand.routeColor(refText);
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size * 0.72),
      padding: EdgeInsets.symmetric(horizontal: size * 0.16),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(refText.isEmpty ? '?' : refText,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34, letterSpacing: -0.3)),
      ),
    );
  }
}

/// Thẻ bo tròn có bóng mềm.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6), this.color});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: dark
              ? null
              : [BoxShadow(color: const Color(0xFF0F3D2E).withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6))],
          border: dark ? Border.all(color: t.colorScheme.outlineVariant.withValues(alpha: 0.35)) : null,
        ),
        child: Material(
          color: color ?? t.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null ? null : () {
              tapHaptic();
              onTap!();
            },
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Viên "Dự kiến X phút": rõ ràng nhưng trung thực (không phải GPS).
class EstimatePill extends StatelessWidget {
  const EstimatePill(this.est, {super.key, this.compact = false});
  final ArrivalEstimate est;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, String main, String? sub) = switch (est.kind) {
      EstimateKind.inService => (
          est.nextInMin! <= 5 ? Brand.amber : (dark ? const Color(0xFF1F4A3A) : const Color(0xFFDDF5EA)),
          est.nextInMin! <= 5 ? Brand.ink : cs.primary,
          '${est.nextInMin} phút',
          'Dự kiến'
        ),
      EstimateKind.beforeService => (cs.surfaceContainerHighest, cs.onSurfaceVariant, 'Chưa chạy', est.window?.label.split('–').first),
      EstimateKind.afterService => (cs.surfaceContainerHighest, cs.onSurfaceVariant, 'Hết giờ', null),
      EstimateKind.unknown => (
          cs.surfaceContainerHighest,
          cs.onSurfaceVariant,
          est.headwayMin != null ? '${est.headwayMin}–${est.headwayMax}p' : '—',
          est.headwayMin != null ? 'mỗi chuyến' : null
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(compact ? 10 : 14)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (sub != null && !compact)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.schedule, size: 11, color: fg.withValues(alpha: 0.8)),
            const SizedBox(width: 3),
            Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.8))),
          ]),
        Text(compact && sub == 'Dự kiến' ? '~$main' : main,
            style: TextStyle(fontSize: compact ? 12 : 16, fontWeight: FontWeight.w800, color: fg, letterSpacing: -0.2)),
      ]),
    );
  }
}

/// Nhãn nguồn dữ liệu.
class EstimateChip extends StatelessWidget {
  const EstimateChip(this.text, {super.key, this.realtime = false});
  final String text;
  final bool realtime;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(realtime ? Icons.gps_fixed : Icons.schedule, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
      ]),
    );
  }
}

/// Thanh trên kính mờ, dùng trên bản đồ.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = 20, this.padding = EdgeInsets.zero});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.color});
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 16,
        child: IconButton(tooltip: tooltip, onPressed: () {
          tapHaptic();
          onPressed();
        }, icon: Icon(icon, color: color)),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 6)});
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ?trailing,
        ]),
      );
}

/// Minh họa cho trạng thái rỗng: xe buýt trên đường, vẽ bằng code.
class BusIllustration extends StatelessWidget {
  const BusIllustration({super.key, this.icon = Icons.directions_bus_filled, this.size = 150});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size), painter: _BlobPainter(cs.primary, Brand.amber)),
        Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(size * 0.16),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Icon(icon, color: cs.onPrimary, size: size * 0.28),
        ),
      ]),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.a, this.b);
  final Color a, b;
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    c.drawCircle(ctr, s.width * 0.46, Paint()..color = a.withValues(alpha: 0.10));
    c.drawCircle(ctr, s.width * 0.34, Paint()..color = a.withValues(alpha: 0.12));
    for (var i = 0; i < 6; i++) {
      final ang = i * math.pi / 3 + 0.4;
      c.drawCircle(ctr + Offset(math.cos(ang), math.sin(ang)) * s.width * 0.43, i.isEven ? 5 : 3,
          Paint()..color = (i.isEven ? b : a).withValues(alpha: 0.8));
    }
    final road = Paint()
      ..color = a.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = s.width * 0.18; x < s.width * 0.82; x += 16) {
      c.drawLine(Offset(x, s.height * 0.86), Offset(x + 8, s.height * 0.86), road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
          BusIllustration(icon: icon),
          const SizedBox(height: 20),
          Text(title, style: t.textTheme.titleLarge, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, height: 1.45), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ]),
      ),
    );
  }
}

/// Hiện danh sách xuất hiện dần.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index.clamp(0, 10) * 45)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c)),
      child: child,
    );
  }
}

/// Nút nhấn co lại nhẹ (micro-animation).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          tapHaptic();
          widget.onTap();
        },
        child: AnimatedScale(scale: _down ? 0.96 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
      );
}
