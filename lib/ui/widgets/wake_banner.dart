import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../services/location.dart';

/// Thanh trạng thái khi đang bật "Đánh thức trước trạm".
class WakeBanner extends StatelessWidget {
  const WakeBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WakeService.instance,
      builder: (context, _) {
        final w = WakeService.instance;
        final cs = Theme.of(context).colorScheme;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: !w.active
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: cs.tertiaryContainer,
                  child: ListTile(
                    leading: Icon(Icons.alarm_on, color: cs.onTertiaryContainer),
                    title: Text('Báo thức xuống trạm: ${w.stopName}'),
                    subtitle: Text(w.alarm?.lastDistance == null
                        ? 'Đang chờ tín hiệu GPS…'
                        : 'Còn ${formatDistance(w.alarm!.lastDistance!)}'),
                    trailing: TextButton(onPressed: w.stop, child: const Text('Tắt')),
                  ),
                ),
        );
      },
    );
  }
}
