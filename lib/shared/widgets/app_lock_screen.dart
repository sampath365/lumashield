import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

/// Optional biometric gate. It only guards the UI; the filter keeps running.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(appLockProvider);
    if (unlocked) return child;
    return const AppLockScreen();
  }
}

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _busy = false;
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || _prompted) return;
    _prompted = true;
    setState(() => _busy = true);
    final ok = await ref.read(appLockProvider.notifier).unlock();
    if (mounted) {
      setState(() => _busy = false);
      if (!ok) _prompted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.lock_outline_rounded, size: 40, color: palette.accent),
              ),
              const SizedBox(height: 24),
              Text('LumaShield is locked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Unlock to change your filter settings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : _unlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(_busy ? 'Waiting for biometrics…' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
