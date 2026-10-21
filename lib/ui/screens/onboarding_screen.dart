import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.directions_bus_filled, 'Xe buýt TP.HCM trong túi bạn', 'Tra hơn 300 lượt tuyến và hàng nghìn trạm – chạy hoàn toàn offline.'),
    (Icons.alarm, 'Đánh thức trước trạm', 'Ngủ quên trên xe? Ứng dụng rung và báo khi bạn sắp tới trạm cần xuống.'),
    (Icons.alt_route, 'Tìm đường thông minh', 'Đi thẳng hoặc chuyển 1 tuyến, có tính quãng đi bộ. Giờ xe là ước tính theo lịch, chưa phải GPS.'),
  ];

  void _finish() {
    ref.read(onboardedProvider.notifier).done();
    context.go('/routes');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.topRight, child: TextButton(onPressed: _finish, child: const Text('Bỏ qua'))),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [cs.primaryContainer, cs.tertiaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Icon(p.$1, size: 88, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 40),
                    Text(p.$2, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(p.$3, style: t.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(color: i == _page ? cs.primary : cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: last ? _finish : () => _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                child: Text(last ? 'Bắt đầu' : 'Tiếp tục'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
