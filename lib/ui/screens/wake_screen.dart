import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../services/location.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Màn hình "Đánh thức trước trạm" với vòng tiến độ lớn.
class WakeScreen extends StatelessWidget {
  const WakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WakeService.instance,
      builder: (context, _) {
        final w = WakeService.instance;
        final t = Theme.of(context);
        if (!w.active) {
          return Scaffold(
            appBar: AppBar(title: const Text('Báo thức xuống trạm')),
            body: EmptyState(
              icon: Icons.alarm_rounded,
              title: 'Chưa bật báo thức',
              subtitle: 'Mở một tuyến hoặc trạm và nhấn nút báo thức để được rung + thông báo khi sắp tới trạm cần xuống, kể cả khi khóa màn hình.',
              action: FilledButton.icon(onPressed: () => context.go('/routes'), icon: const Icon(Icons.directions_bus_rounded), label: const Text('Chọn tuyến')),
            ),
          );
        }
        final dist = w.alarm?.lastDistance;
        final dark = t.brightness == Brightness.dark;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark ? const [Color(0xFF06352A), Brand.night] : const [Brand.greenDeep, Brand.teal],
              ),
            ),
            child: SafeArea(
              child: Column(children: [
                Row(children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Đang theo dõi GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 12),
                const Text('Sẽ đánh thức bạn trước trạm', style: TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(w.stopName ?? '', textAlign: TextAlign.center, style: t.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: w.progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => SizedBox(
                    width: 270,
                    height: 270,
                    child: CustomPaint(
                      painter: _RingPainter(v),
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 34),
                          const SizedBox(height: 6),
                          Text(dist == null ? '—' : formatDistance(dist),
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                          Text(dist == null ? 'đang chờ GPS…' : 'còn lại', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    _Info(icon: Icons.radar_rounded, label: 'Báo khi còn', value: formatDistance(w.alarm?.radiusM ?? 400)),
                    const SizedBox(width: 12),
                    _Info(icon: Icons.vibration_rounded, label: 'Cảnh báo', value: 'Rung + thông báo'),
                  ]),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.greenDeep, minimumSize: const Size.fromHeight(58)),
                      onPressed: () {
                        tapHaptic();
                        w.stop();
                      },
                      icon: const Icon(Icons.alarm_off_rounded),
                      label: const Text('Tắt báo thức'),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Icon(icon, color: Brand.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2 - 14;
    c.drawCircle(ctr, r + 14, Paint()..color = Colors.white.withValues(alpha: 0.06));
    c.drawCircle(ctr, r, Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18);
    final rect = Rect.fromCircle(center: ctr, radius: r);
    c.drawArc(rect, -math.pi / 2, 2 * math.pi * v, false, Paint()
      ..shader = const SweepGradient(colors: [Color(0xFFFFD180), Brand.amber, Color(0xFFFFD180)], transform: GradientRotation(-math.pi / 2)).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18);
    final a = -math.pi / 2 + 2 * math.pi * v;
    final dot = ctr + Offset(math.cos(a), math.sin(a)) * r;
    c.drawCircle(dot, 13, Paint()..color = Colors.white);
    c.drawCircle(dot, 7, Paint()..color = Brand.amber);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v;
}
