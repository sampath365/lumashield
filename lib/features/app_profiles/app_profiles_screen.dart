import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';
import '../../shared/models/app_profile.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/luma_slider.dart';
import '../../shared/widgets/permission_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';

class AppProfilesScreen extends ConsumerStatefulWidget {
  const AppProfilesScreen({super.key});

  @override
  ConsumerState<AppProfilesScreen> createState() => _AppProfilesScreenState();
}

class _AppProfilesScreenState extends ConsumerState<AppProfilesScreen> {
  String _query = '';
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final permissions = ref.watch(permissionsControllerProvider);
    final appsAsync = ref.watch(installedAppsProvider);
    final profiles = ref.watch(profilesControllerProvider);

    final configured = {for (final p in profiles) p.packageName: p};

    return GradientScaffold(
      appBar: AppBar(title: const Text('App profiles')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose which apps keep the filter, which get a stronger tint, and which '
            'should be left untouched (photo editors and video players are common choices).',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.textMuted, height: 1.45),
          ),
          const SizedBox(height: 16),
          if (!permissions.usageAccess)
            PermissionCard(
              icon: Icons.insights_outlined,
              title: 'Usage access',
              description:
                  'LumaShield needs to know which app is in front. Only the package name is '
                  'read, never screen content. Grant it in the system usage access screen.',
              granted: false,
              actionLabel: 'Open',
              onAction: () => ref
                  .read(permissionsControllerProvider.notifier)
                  .openUsageAccess(),
            ),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SettingTile(
              icon: Icons.tune_rounded,
              title: 'Enable per-app profiles',
              subtitle:
                  'Only the foreground app name is read, every few seconds',
              trailing: Switch(
                value: _enabled,
                onChanged: (value) async {
                  setState(() => _enabled = value);
                  await ref
                      .read(profilesControllerProvider.notifier)
                      .setEnabled(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search installed apps',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: palette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Configured apps',
            subtitle:
                '${profiles.length} profile${profiles.length == 1 ? '' : 's'}',
          ),
          if (profiles.isEmpty)
            GlassCard(
              child: Text(
                'No app profiles yet. Pick an app below to give it its own filter.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textMuted),
              ),
            )
          else
            for (final profile in profiles)
              _ProfileTile(
                profile: profile,
                onTap: () => _editProfile(profile),
                onRemove: () => ref
                    .read(profilesControllerProvider.notifier)
                    .remove(profile.packageName),
              ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Installed apps'),
          appsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not list apps',
              message: '$error',
            ),
            data: (apps) {
              final filtered = apps
                  .where((app) => app.label.toLowerCase().contains(_query))
                  .toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.apps_rounded,
                  title: 'No apps found',
                  message: _query.isEmpty
                      ? 'Installed apps will appear here once the app list is available.'
                      : 'Nothing matches "$_query".',
                );
              }
              return Column(
                children: [
                  for (final app in filtered.take(40))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () => _editProfile(
                            configured[app.packageName] ??
                                AppProfile(
                                  packageName: app.packageName,
                                  label: app.label,
                                ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: palette.surfaceHigh,
                            child: Text(
                              app.label.isEmpty
                                  ? '?'
                                  : app.label.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: palette.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(app.label),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          trailing: configured.containsKey(app.packageName)
                              ? Icon(
                                  configured[app.packageName]!.enabled
                                      ? Icons.check_circle_rounded
                                      : Icons.block_rounded,
                                  color: configured[app.packageName]!.enabled
                                      ? palette.success
                                      : palette.textMuted,
                                )
                              : const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(AppProfile profile) async {
    var enabled = profile.enabled;
    var intensity = profile.intensity == 0 ? 45 : profile.intensity;
    var kelvin = profile.kelvin;

    final saved = await showModalBottomSheet<AppProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                profile.packageName,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.palette.textMuted),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apply filter in this app'),
                subtitle: const Text('Turn off to lift the filter completely'),
                value: enabled,
                onChanged: (value) => setSheetState(() => enabled = value),
              ),
              if (enabled) ...[
                LumaSlider(
                  label: 'Intensity',
                  value: intensity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  valueLabel: '$intensity%',
                  onChanged: (value) =>
                      setSheetState(() => intensity = value.round()),
                ),
                LumaSlider(
                  label: 'Temperature',
                  value: kelvin.toDouble(),
                  min: 1900,
                  max: 6500,
                  divisions: 46,
                  valueLabel:
                      '$kelvin K · ${ColorTemperature.labelFor(kelvin)}',
                  activeColor: ColorTemperature.colorFor(kelvin),
                  onChanged: (value) =>
                      setSheetState(() => kelvin = value.round()),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  profile.copyWith(
                    enabled: enabled,
                    intensity: enabled ? intensity : 0,
                    kelvin: kelvin,
                  ),
                ),
                child: const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != null) {
      await ref.read(profilesControllerProvider.notifier).upsert(saved);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${saved.label} profile saved')));
      }
    }
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.onTap,
    required this.onRemove,
  });

  final AppProfile profile;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: CircleAvatar(
            backgroundColor: palette.surfaceHigh,
            child: Icon(
              profile.enabled ? Icons.filter_alt_outlined : Icons.block_rounded,
              color: profile.enabled ? palette.accent : palette.textMuted,
              size: 20,
            ),
          ),
          title: Text(profile.label),
          subtitle: Text(
            profile.enabled
                ? '${profile.intensity}% · ${profile.kelvin}K'
                : 'Filter lifted for this app',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          trailing: IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: palette.textMuted),
          ),
        ),
      ),
    );
  }
}
