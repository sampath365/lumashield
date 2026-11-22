import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/color_temperature.dart';
import 'core/utils/platform_capabilities.dart';
import 'features/dashboard/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/providers/app_providers.dart';
import 'shared/widgets/app_lock_screen.dart';

class LumaShieldApp extends ConsumerStatefulWidget {
  const LumaShieldApp({super.key});

  @override
  ConsumerState<LumaShieldApp> createState() => _LumaShieldAppState();
}

class _LumaShieldAppState extends ConsumerState<LumaShieldApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      final settings = ref.read(appSettingsControllerProvider);
      if (settings.appLockEnabled) {
        ref.read(appLockProvider.notifier).lock();
      }
    }
    if (state == AppLifecycleState.resumed) {
      // Permissions may have changed in system settings while we were away.
      ref.read(permissionsControllerProvider.notifier).refresh();
      ref.invalidate(statusProvider);
      final status = ref.read(protectionStatusProvider);
      if (status.supported) {
        ref.read(filterControllerProvider.notifier).syncFromPlatform(status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeBundleProvider);
    return MaterialApp(
      title: 'LumaShield',
      debugShowCheckedModeBanner: false,
      theme: theme.theme,
      darkTheme: theme.darkTheme,
      themeMode: theme.mode,
      scrollBehavior: const _AppScrollBehavior(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            const _IosTintOverlay(),
          ],
        );
      },
      home: const _RootGate(),
    );
  }
}

/// Decides between onboarding and the dashboard exactly once, after the splash
/// animation. Later navigation is explicit so onboarding can push the
/// permission flow on top without fighting the gate.
class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    final settings = ref.watch(appSettingsControllerProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: settings.onboarded
          ? const AppLockGate(child: HomeShell())
          : const OnboardingScreen(),
    );
  }
}

/// iOS cannot tint other apps. Instead the app tints its own interface so the
/// preview and the reading experience stay consistent, and says so in the UI.
class _IosTintOverlay extends ConsumerWidget {
  const _IosTintOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformCapabilities.isIOS) return const SizedBox.shrink();
    final filter = ref.watch(filterControllerProvider);
    if (!filter.enabled) return const SizedBox.shrink();
    final tint = filter.customColor != null
        ? Color(filter.customColor!)
        : ColorTemperature.colorFor(filter.kelvin);
    final alpha = filter.customColor != null
        ? (filter.intensity / 100) * 0.72
        : ColorTemperature.overlayAlpha(kelvin: filter.kelvin, intensity: filter.intensity);
    if (alpha <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(child: Container(color: tint.withValues(alpha: alpha)));
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
