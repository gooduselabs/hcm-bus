import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/geo.dart';
import '../../services/location.dart';
import '../theme.dart';

/// Thanh trạng thái khi đang bật "Đánh thức trước trạm".
class WakeBanner extends StatelessWidget {
  const WakeBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WakeService.instance,
      builder: (context, _) {
        final w = WakeService.instance;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: !w.active
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Material(
                    color: Brand.amber,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push('/wake'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                        child: Row(children: [
                          const Icon(Icons.alarm_on, color: Brand.ink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Báo thức: ${w.stopName} · ${w.alarm?.lastDistance == null ? 'chờ GPS…' : 'còn ${formatDistance(w.alarm!.lastDistance!)}'}',
                              style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(onPressed: w.stop, child: const Text('Tắt', style: TextStyle(color: Brand.ink, fontWeight: FontWeight.w800))),
                        ]),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
