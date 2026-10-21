import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.directions_bus_filled_rounded, 'Xe buýt TP.HCM trong túi bạn', 'Hơn 300 lượt tuyến, hàng nghìn trạm. Tra cứu và tìm đường không cần mạng.'),
    (Icons.alarm_rounded, 'Đánh thức trước trạm', 'Ngủ quên trên xe? Ứng dụng rung và báo khi bạn sắp tới trạm cần xuống.'),
    (Icons.alt_route_rounded, 'Tìm đường thông minh', 'Đi thẳng hoặc chuyển 1 tuyến, tính cả quãng đi bộ. Giờ xe hiển thị là dự kiến theo lịch.'),
  ];

  void _finish() {
    ref.read(onboardedProvider.notifier).done();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.colorScheme.primary.withValues(alpha: 0.14), t.colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 20),
              Text('Buýt Sài Gòn', style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: _finish, child: const Text('Bỏ qua')),
              const SizedBox(width: 8),
            ]),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  tapHaptic();
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      BusIllustration(icon: p.$1, size: 240),
                      const SizedBox(height: 40),
                      Text(p.$2, style: t.textTheme.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      Text(p.$3, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
                    ]),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == _page ? Brand.amber : t.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                  onPressed: last ? _finish : () => _pc.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
                  child: Text(last ? 'Bắt đầu' : 'Tiếp tục'),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
