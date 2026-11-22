import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Appearance')),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          SectionHeader(
            title: 'Theme',
            subtitle: 'Deep navy by default, true black for OLED panels',
          ),
          for (final variant in ThemeVariant.values)
            _ThemeOption(
              variant: variant,
              selected: settings.themeVariant == variant,
              palette: palette,
              onTap: () => controller.update((s) => s.copyWith(themeVariant: variant)),
            ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Accent colour'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final accent in AccentChoice.values)
                GestureDetector(
                  onTap: () => controller.update((s) => s.copyWith(accent: accent)),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: settings.accent == accent
                                ? palette.textPrimary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: settings.accent == accent
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        accent.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(title: 'Preview'),
          GlassCard(
            gradient: palette.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: palette.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.shield_moon_rounded,
                        color: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LumaShield',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Accent, surfaces and type in context',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: true, onChanged: (_) {}),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.opacity_rounded, color: palette.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.62,
                            minHeight: 7,
                            backgroundColor: palette.surfaceHigh,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '62%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Feel'),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                subtitle: 'A light tap when toggling protection',
                trailing: Switch(
                  value: settings.hapticsEnabled,
                  onChanged: (value) =>
                      controller.update((s) => s.copyWith(hapticsEnabled: value)),
                ),
              ),
              SettingTile(
                icon: Icons.tips_and_updates_outlined,
                title: 'Show tips',
                subtitle: 'Contextual guidance on the dashboard',
                trailing: Switch(
                  value: settings.showTips,
                  onChanged: (value) => controller.update((s) => s.copyWith(showTips: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'LumaShield uses the system font so text stays crisp and respects your '
            'accessibility size setting.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.variant,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final ThemeVariant variant;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  AppPalette get _sample => switch (variant) {
    ThemeVariant.amoled => AppPalette.amoled,
    ThemeVariant.daylight => AppPalette.daylight,
    _ => AppPalette.midnight,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _sample.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sample.border),
              ),
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_sample.accent, _sample.warm],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    variant.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: palette.accent, size: 22),
          ],
        ),
      ),
    );
  }
}
