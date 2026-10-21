import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/providers.dart';
import 'ui/theme.dart';
import 'ui/widgets/splash_view.dart';

void bootLog(String msg) => debugPrint('[hcm_bus] $msg');

/// Khởi tạo các phụ thuộc trước khi dựng app chính (có timeout).
class BootApp extends StatefulWidget {
  const BootApp({super.key, this.loadPrefs});

  /// Ghi đè trong test để mô phỏng chậm/lỗi.
  final Future<SharedPreferences> Function()? loadPrefs;

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  late Future<SharedPreferences> _prefs = _load();

  Future<SharedPreferences> _load() async {
    try {
      final p = await (widget.loadPrefs ?? SharedPreferences.getInstance)().timeout(const Duration(seconds: 8));
      bootLog('prefs ready');
      return p;
    } catch (e, st) {
      bootLog('prefs failed: $e\n$st');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefs,
      builder: (context, s) {
        if (s.hasData) {
          return ProviderScope(overrides: [prefsProvider.overrideWithValue(s.data!)], child: const HcmBusApp());
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: s.hasError
              ? BootErrorView(error: s.error!, onRetry: () => setState(() {
                  _prefs = _load();
                }))
              : const SplashView(),
        );
      },
    );
  }
}

/// Màn hình lỗi có nút thử lại (thay vì treo).
class BootErrorView extends StatelessWidget {
  const BootErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline_rounded, size: 72, color: t.colorScheme.error),
            const SizedBox(height: 16),
            Text('Không khởi động được', style: t.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('$error', style: t.textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 6, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
          ]),
        ),
      ),
    );
  }
}

