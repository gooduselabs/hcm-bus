import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../widgets/bus_map.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final d = ref.watch(busDataProvider).requireValue;
    final rt = ref.watch(realtimeProvider);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt & giới thiệu')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Giao diện', style: t.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Hệ thống')),
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Sáng')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Tối')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.info_outline, color: t.colorScheme.primary), const SizedBox(width: 8), Text('Về giờ xe đến', style: t.textTheme.titleSmall)]),
              const SizedBox(height: 8),
              Text('Nguồn hiện tại: ${rt.sourceLabel}.\n'
                  'Hiện chưa có API GPS xe buýt TP.HCM công khai, được phép dùng lại. '
                  'Ứng dụng KHÔNG dùng API riêng của ứng dụng khác. Khi có hợp tác chính thức với '
                  'Trung tâm Quản lý Giao thông công cộng, giờ xe thời gian thực sẽ được bổ sung.'),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dữ liệu & giấy phép', style: t.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text('Tuyến/trạm: © OpenStreetMap contributors, giấy phép ODbL 1.0 (cập nhật ${d.generated}; '
                  '${d.routes.length} lượt tuyến, ${d.stops.length} trạm). Dữ liệu do cộng đồng đóng góp, có thể thiếu hoặc cũ.\n'
                  'Bản đồ nền: $mapAttribution.\n'
                  'Mã nguồn: giấy phép MIT.'),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Giấy phép phần mềm mã nguồn mở'),
          onTap: () => showLicensePage(context: context, applicationName: 'Buýt Sài Gòn', applicationVersion: '0.1.0'),
        ),
      ]),
    );
  }
}
