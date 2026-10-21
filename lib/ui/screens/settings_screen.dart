import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bus_map.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final d = ref.watch(busDataProvider).requireValue;
    final rt = ref.watch(realtimeProvider);
    final t = Theme.of(context);
    Widget card(IconData icon, Color color, String title, String body) => SoftCard(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, height: 1.45)),
              ]),
            ),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt & giới thiệu')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        const SectionHeader('Giao diện', padding: EdgeInsets.fromLTRB(20, 8, 20, 10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Hệ thống')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Sáng')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Tối')),
            ],
            selected: {mode},
            onSelectionChanged: (s) {
              tapHaptic();
              ref.read(themeModeProvider.notifier).set(s.first);
            },
          ),
        ),
        const SectionHeader('Thông tin'),
        card(Icons.schedule_rounded, Brand.amber, 'Về giờ xe "Dự kiến"',
            'Nguồn hiện tại: ${rt.sourceLabel}. Hiện chưa có API GPS xe buýt TP.HCM công khai và được phép dùng lại. Ứng dụng không dùng API riêng của ứng dụng khác. Khi có hợp tác chính thức với Trung tâm Quản lý Giao thông công cộng, giờ xe thời gian thực sẽ được bổ sung.'),
        card(Icons.map_rounded, Brand.green, 'Dữ liệu tuyến & trạm',
            '© OpenStreetMap contributors, giấy phép ODbL 1.0. Cập nhật ${d.generated}: ${d.routes.length} lượt tuyến, ${d.stops.length} trạm. Dữ liệu cộng đồng, có thể thiếu hoặc cũ.'),
        card(Icons.layers_rounded, const Color(0xFF1E88E5), 'Bản đồ nền', mapAttribution),
        card(Icons.text_fields_rounded, const Color(0xFF8E24AA), 'Phông chữ & mã nguồn', 'Be Vietnam Pro (SIL Open Font License 1.1). Mã nguồn ứng dụng: giấy phép MIT.'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Giấy phép phần mềm mã nguồn mở'),
            onPressed: () => showLicensePage(context: context, applicationName: 'Buýt Sài Gòn', applicationVersion: '0.2.1'),
          ),
        ),
      ]),
    );
  }
}
