import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/stats_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/protection_session.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_shell.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/segmented_control.dart';
import '../../shared/widgets/stat_tile.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _window = 7;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sessions = ref.watch(sessionsProvider);
    final filter = ref.watch(filterControllerProvider);
    final controller = ref.watch(filterControllerProvider.notifier);
    final ongoing = filter.enabled ? controller.sessionDuration : Duration.zero;
    final summary = StatsCalculator.summarize(
      sessions,
      ongoing: ongoing,
      days: _window,
    );
    final maxMinutes = summary.days.fold<int>(1, (max, day) => day.minutes > max ? day.minutes : max);

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(
            title: 'Insights',
            subtitle: 'Local only. Nothing leaves this device.',
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'clear') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear history?'),
                      content: const Text(
                        'This deletes every locally stored protection session. It cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(historyRepositoryProvider).clear();
                    ref.read(statsRefreshProvider.notifier).bump();
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'clear', child: Text('Clear history')),
              ],
            ),
          ),
          LumaSegmented<int>(
            value: _window,
            options: const [
              SegmentOption(value: 7, label: '7 days'),
              SegmentOption(value: 30, label: '30 days'),
            ],
            onChanged: (value) => setState(() => _window = value),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.duration(Duration(minutes: summary.weekMinutes)),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'protected in the last $_window days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'avg ${Formatters.minutesAsDuration(StatsCalculator.averageDailyMinutes(summary))}/day',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 150,
                  child: _BarChart(
                    values: [for (final day in summary.days) day.minutes.toDouble()],
                    labels: [for (final day in summary.days) Formatters.dayLabel(day.day)],
                    maxValue: maxMinutes.toDouble(),
                    accent: palette.accent,
                    warm: palette.warm,
                    track: palette.surfaceHigh,
                    labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: palette.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (summary.days.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.shortDate(summary.days.first.day),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        Formatters.shortDate(summary.days.last.day),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'TODAY',
                  value: Formatters.duration(Duration(minutes: summary.todayMinutes)),
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'AVG FILTER',
                  value: '${summary.avgIntensity}%',
                  icon: Icons.opacity_rounded,
                  accent: palette.warm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'STREAK',
                  value: '${summary.currentStreakDays} days',
                  icon: Icons.local_fire_department_rounded,
                  accent: palette.warm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'SESSIONS',
                  value: '${summary.totalSessions}',
                  icon: Icons.timeline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Weekly report',
            subtitle: 'How your eye comfort is trending',
          ),
          _WeeklyReport(summary: summary),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Activation history',
            subtitle: 'Most recent sessions',
          ),
          if (sessions.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No sessions yet',
              message: 'Turn the filter on and it will appear here with its duration.',
            )
          else
            for (final session in sessions.take(15)) _SessionTile(session: session),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'History is stored on this device only and pruned after 120 days.',
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

class _WeeklyReport extends StatelessWidget {
  const _WeeklyReport({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final best = summary.days.isEmpty
        ? null
        : summary.days.reduce((a, b) => a.minutes >= b.minutes ? a : b);
    final activeDays = summary.days.where((day) => day.minutes > 0).length;
    final consistency = summary.days.isEmpty
        ? 0
        : ((activeDays / summary.days.length) * 100).round();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.weekMinutes == 0
                ? 'No protection logged yet. Turn the filter on and the report fills itself.'
                : 'You protected your eyes for ${Formatters.duration(Duration(minutes: summary.weekMinutes))} '
                      'across $activeDays of the last ${summary.days.length} days.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Consistency',
                  value: '$consistency%',
                  icon: Icons.insights_rounded,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Best day',
                  value: best == null || best.minutes == 0
                      ? '—'
                      : Formatters.duration(Duration(minutes: best.minutes)),
                  icon: Icons.emoji_events_outlined,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Avg filter',
                  value: '${summary.avgIntensity}%',
                  icon: Icons.opacity_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  consistency >= 70
                      ? 'Great consistency. Keep the schedule on and the streak will follow.'
                      : 'Try enabling the automatic schedule so protection starts without thinking about it.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: palette.textMuted),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final ProtectionSession session;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sameDay = session.start.day == session.end.day &&
        session.start.month == session.end.month;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_outlined, size: 18, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.mode,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${Formatters.shortDate(session.start)} · '
                  '${Formatters.timeOfDay(session.start)}'
                  '${sameDay ? '' : ' → ${Formatters.shortDate(session.end)}'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.duration(session.duration),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${session.intensity}% · ${session.kelvin}K',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.accent,
    required this.warm,
    required this.track,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final Color accent;
  final Color warm;
  final Color track;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: CustomPaint(
      painter: _BarChartPainter(
        values: values,
        labels: labels,
        maxValue: maxValue,
        accent: accent,
        warm: warm,
        track: track,
        labelStyle: labelStyle,
      ),
    ),
  );
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.accent,
    required this.warm,
    required this.track,
    required this.labelStyle,
  });

  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final Color accent;
  final Color warm;
  final Color track;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    final slot = size.width / values.length;
    final barWidth = (slot * 0.48).clamp(6.0, 30.0);
    final maxV = maxValue <= 0 ? 1.0 : maxValue;

    for (var i = 0; i < values.length; i++) {
      final centerX = slot * i + slot / 2;
      final barHeight = (values[i] / maxV) * (chartHeight - 10);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          chartHeight - barHeight,
          barWidth,
          barHeight.clamp(3.0, chartHeight),
        ),
        const Radius.circular(7),
      );
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth / 2, 0, barWidth, chartHeight),
        const Radius.circular(7),
      );
      canvas.drawRRect(trackRect, Paint()..color = track.withValues(alpha: 0.55));
      if (values[i] > 0) {
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [warm.withValues(alpha: 0.9), accent],
            ).createShader(rect.outerRect),
        );
      }

      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(centerX - painter.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}
