import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../services/location.dart';

Future<void> startWake(BuildContext context, BusStop stop) async {
  final radius = await showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.alarm_add),
          title: Text('Đánh thức trước trạm ${stop.displayName}'),
          subtitle: const Text('Ứng dụng theo dõi GPS (kể cả khi tắt màn hình) và rung + thông báo khi tới gần.'),
        ),
        for (final r in const [300.0, 500.0, 800.0])
          ListTile(
            leading: const Icon(Icons.radar),
            title: Text('Báo khi còn khoảng ${r.round()} m'),
            onTap: () => Navigator.pop(ctx, r),
          ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (radius == null || !context.mounted) return;
  final ok = await WakeService.instance.start(stop.pos, stop.displayName, radiusM: radius);
  if (!context.mounted) return;
  if (ok) {
    context.push('/wake');
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? 'Đã bật báo thức cho trạm ${stop.displayName}' : 'Cần quyền vị trí (Luôn cho phép) để báo thức'),
  ));
}
