import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';

/// Opens a link and tells the user when nothing can handle it, which is common
/// for `mailto:` on a device without a mail account.
Future<void> _openLink(
  BuildContext context,
  Uri uri, {
  required String fallback,
}) async {
  var launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fallback)));
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GradientScaffold(
      appBar: AppBar(title: const Text('About')),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield_moon_rounded,
                    size: 44,
                    color: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => Text(
                    snapshot.data == null
                        ? AppConstants.tagline
                        : 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Text(
              'LumaShield warms your screen to reduce blue light, reminds you to rest your '
              'eyes and shows you what actually happened. The filter runs entirely on your '
              'device: no account, no cloud, no screen capture, no advertising identifiers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Support'),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.policy_outlined,
                title: 'Privacy policy',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              SettingTile(
                icon: Icons.article_outlined,
                title: 'Open source licences',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: '1.0.0',
                ),
              ),
              SettingTile(
                icon: Icons.mail_outline_rounded,
                title: 'Contact support',
                subtitle: AppConstants.supportEmail,
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _openLink(
                  context,
                  Uri.parse(
                    'mailto:${AppConstants.supportEmail}?subject=LumaShield%20support',
                  ),
                  fallback:
                      'No email app is set up on this device. Write to '
                      '${AppConstants.supportEmail}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'How the filter works',
            subtitle: 'Honest technical detail',
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in const [
                  (
                    'Android overlay',
                    'A full screen window is drawn above other apps with the '
                        'Display over other apps permission. It composites a warm translucent '
                        'layer, which is how non-root filters reduce blue light.',
                  ),
                  (
                    'What it cannot do',
                    'Secure screens (banking, DRM video), some system dialogs and apps that '
                        'explicitly hide overlays stay unfiltered. No app can bypass that.',
                  ),
                  (
                    'iOS',
                    'Third party apps cannot tint the system. LumaShield warms its own screens, '
                        'schedules reminders and points you to Night Shift for system wide warmth.',
                  ),
                  (
                    'Battery',
                    'The overlay costs almost nothing while the screen is on. The service sleeps '
                        'when protection is off, and reminders are batched with inexact alarms.',
                  ),
                ]) ...[
                  Text(
                    entry.$1,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Made for tired eyes.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'What LumaShield stores',
      'Filter settings, schedule, eye care preferences, saved presets and the times when '
          'protection was active. All of it is stored in the app private storage on this device.',
    ),
    (
      'What LumaShield never collects',
      'Screen content, screenshots, keystrokes, contacts, precise location history, '
          'advertising identifiers or account information. There is no account.',
    ),
    (
      'Location',
      'If you choose sunset scheduling, LumaShield reads an approximate position once and '
          'keeps it on the device to calculate sunrise and sunset offline. It is never uploaded.',
    ),
    (
      'Usage access',
      'Per-app profiles need the name of the app currently in the foreground. Only the '
          'package name is read, and only while the feature is enabled.',
    ),
    (
      'Diagnostics',
      'Anonymous diagnostics are off by default. If you enable them, only crash type and '
          'app version are sent. No screen data is included.',
    ),
    (
      'Your control',
      'Clear protection history at any time from Advanced settings. Uninstalling the app '
          'removes every stored value.',
    ),
    (
      'Children',
      'LumaShield is a general wellbeing tool and is not directed at children under 13.',
    ),
    (
      'Contact',
      'Questions about privacy: ${AppConstants.supportEmail}',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Last updated 1 November 2026',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in _sections) ...[
            Text(
              section.$1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.$2,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
          ],
          GlassCard(
            child: Text(
              'LumaShield is not a medical device and does not diagnose or treat any '
              'condition. If you have persistent eye pain, headaches or trouble sleeping, '
              'speak to a qualified professional.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
