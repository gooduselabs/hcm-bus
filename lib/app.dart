import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'boot.dart';
import 'state/providers.dart';
import 'ui/screens/explore_screen.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/planner_screen.dart';
import 'ui/screens/route_detail_screen.dart';
import 'ui/screens/routes_screen.dart';
import 'ui/screens/saved_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/stop_detail_screen.dart';
import 'ui/screens/stops_screen.dart';
import 'ui/screens/wake_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/splash_view.dart';

GoRouter buildRouter({required bool onboarded, String? initial}) => GoRouter(
      initialLocation: initial ?? (onboarded ? '/home' : '/welcome'),
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const ExploreScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/routes', builder: (_, _) => const RoutesScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/plan', builder: (_, _) => const PlannerScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/saved', builder: (_, _) => const SavedScreen())]),
          ],
        ),
        GoRoute(path: '/route/:id', builder: (_, s) => RouteDetailScreen(routeId: s.pathParameters['id']!)),
        GoRoute(path: '/stop/:id', builder: (_, s) => StopDetailScreen(stopId: s.pathParameters['id']!)),
        GoRoute(path: '/stops', builder: (_, _) => const StopsScreen()),
        GoRoute(path: '/wake', builder: (_, _) => const WakeScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    );

class HcmBusApp extends ConsumerStatefulWidget {
  const HcmBusApp({super.key, this.initialLocation});
  final String? initialLocation;
  @override
  ConsumerState<HcmBusApp> createState() => _HcmBusAppState();
}

class _HcmBusAppState extends ConsumerState<HcmBusApp> {
  late final GoRouter _router =
      buildRouter(onboarded: ref.read(onboardedProvider), initial: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Buýt Sài Gòn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      builder: (context, child) => Consumer(
        builder: (context, ref, _) => ref.watch(busDataProvider).when(
              data: (_) => child!,
              error: (e, _) => BootErrorView(error: e, onRetry: () => ref.invalidate(busDataProvider)),
              loading: () => const SplashView(),
            ),
      ),
    );
  }
}
