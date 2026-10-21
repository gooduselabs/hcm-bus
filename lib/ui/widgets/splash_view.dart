import 'package:flutter/material.dart';

/// Màn hình chờ trong lúc nạp dữ liệu offline (sau native splash).
class SplashView extends StatelessWidget {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (_, v, c) => Transform.scale(scale: v, child: c),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.directions_bus_filled, size: 96, color: cs.onPrimary),
            const SizedBox(height: 16),
            Text('Buýt Sài Gòn', style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 28),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: cs.onPrimary)),
            const SizedBox(height: 12),
            Text('Đang tải dữ liệu tuyến…', style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85))),
          ]),
        ),
      ),
    );
  }
}
