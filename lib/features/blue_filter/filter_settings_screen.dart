import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/models/filter_preset.dart';
import '../../shared/models/filter_settings.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/filter_preview.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/luma_slider.dart';
import '../../shared/widgets/mode_selector.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/segmented_control.dart';
import '../app_profiles/app_profiles_screen.dart';
import '../reading_mode/reading_mode_screen.dart';

class FilterSettingsScreen extends ConsumerStatefulWidget {
  const FilterSettingsScreen({super.key});

  @override
  ConsumerState<FilterSettingsScreen> createState() => _FilterSettingsScreenState();
}

class _FilterSettingsScreenState extends ConsumerState<FilterSettingsScreen> {
  bool _customColour = false;

  static const _warmSwatches = [
    Color(0xFFFFB067),
    Color(0xFFF0A44A),
    Color(0xFFE8823C),
    Color(0xFFD96A2B),
    Color(0xFFC7522A),
    Color(0xFFE8B84B),
    Color(0xFFF2C14E),
    Color(0xFFB83B2E),
    Color(0xFFE07A5F),
    Color(0xFFCE8D6A),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(filterControllerProvider);
    final controller = ref.read(filterControllerProvider.notifier);
    final presets = ref.watch(presetsControllerProvider);
    final customColourActive = filter.customColor != null;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Filter settings'),
        actions: [
          IconButton(
            tooltip: 'Reading mode',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReadingModeScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          FilterPreview(
            kelvin: filter.kelvin,
            intensity: filter.intensity,
            customColor: filter.customColor,
            dim: filter.dim,
            height: 208,
            compare: true,
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Colour source',
            subtitle: 'Temperature follows the black body curve. Custom colour paints an exact tint.',
          ),
          LumaSegmented<bool>(
            value: _customColour || customColourActive,
            options: const [
              SegmentOption(value: false, label: 'Temperature', icon: Icons.thermostat),
              SegmentOption(value: true, label: 'Custom colour', icon: Icons.palette_outlined),
            ],
            onChanged: (value) {
              setState(() => _customColour = value);
              if (!value) controller.setCustomColor(null);
            },
          ),
          const SizedBox(height: 16),
          if (!(_customColour || customColourActive)) ...[
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                children: [
                  LumaSlider(
                    label: 'Colour temperature',
                    icon: Icons.thermostat_rounded,
                    value: filter.kelvin.toDouble(),
                    min: 1900,
                    max: 6500,
                    divisions: 46,
                    valueLabel: '${filter.kelvin}K · ${ColorTemperature.labelFor(filter.kelvin)}',
                    activeColor: ColorTemperature.colorFor(filter.kelvin),
                    onChanged: (value) => controller.setKelvin(value.round()),
                    captions: const ['1900K candle', '4000K warm', '6500K neutral'],
                  ),
                  LumaSlider(
                    label: 'Blue light reduction',
                    icon: Icons.opacity_rounded,
                    value: filter.intensity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    valueLabel: '${filter.intensity}%',
                    onChanged: (value) => controller.setIntensity(value.round()),
                  ),
                ],
              ),
            ),
          ] else ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warm palettes',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final colour in _warmSwatches)
                        _Swatch(
                          colour: colour,
                          selected: filter.customColor == colour.toARGB32(),
                          onTap: () => controller.setCustomColor(colour.toARGB32()),
                        ),
                      _Swatch(
                        colour: palette.surfaceHigh,
                        selected: false,
                        icon: Icons.colorize_rounded,
                        onTap: () async {
                          final picked = await showDialog<int>(
                            context: context,
                            builder: (_) => _ColourPickerDialog(
                              initial: Color(filter.customColor ?? 0xFFF0A44A.toInt()),
                            ),
                          );
                          if (picked != null) controller.setCustomColor(picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LumaSlider(
                    label: 'Blue light reduction',
                    icon: Icons.opacity_rounded,
                    value: filter.intensity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    valueLabel: '${filter.intensity}%',
                    onChanged: (value) => controller.setIntensity(value.round()),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Quick modes',
            subtitle: 'Presets tuned for different times of day',
          ),
          ModeSelector(
            selected: filter.mode,
            scrollable: false,
            onSelected: (mode) {
              controller.setMode(mode);
              if (mode != FilterMode.custom) {
                setState(() => _customColour = false);
              }
            },
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Screen comfort',
            subtitle: PlatformCapabilities.isAndroid
                ? 'Dimming is drawn by the overlay, so it never changes your system brightness.'
                : 'Brightness follows the system control on iOS.',
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              children: [
                LumaSlider(
                  label: 'Screen dim',
                  icon: Icons.brightness_6_rounded,
                  value: filter.dim.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 60,
                  valueLabel: '${filter.dim}%',
                  enabled: PlatformCapabilities.systemOverlay,
                  onChanged: (value) => controller.setDim(value.round()),
                ),
                if (!PlatformCapabilities.systemOverlay)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'System wide dimming needs an overlay, which iOS does not allow.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Saved presets',
            subtitle: 'Keep your favourite looks one tap away',
            action: TextButton.icon(
              onPressed: () => _savePreset(context, filter),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save'),
            ),
          ),
          if (presets.isEmpty)
            GlassCard(
              child: Text(
                'No presets yet. Dial in a filter you like, then tap Save.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  height: 1.4,
                ),
              ),
            )
          else
            for (final preset in presets)
              _PresetTile(
                preset: preset,
                onApply: () => controller.applyPreset(preset),
                onDelete: () => ref.read(presetsControllerProvider.notifier).remove(preset.id),
                onFavourite: () =>
                    ref.read(presetsControllerProvider.notifier).toggleFavourite(preset.id),
              ),
          const SizedBox(height: 20),
          SectionHeader(title: 'More control'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.apps_rounded),
                  title: const Text('Per-app profiles'),
                  subtitle: Text(
                    PlatformCapabilities.perAppProfiles
                        ? 'Adjust or lift the filter for individual apps'
                        : 'Android only',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: PlatformCapabilities.perAppProfiles
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AppProfilesScreen()),
                        )
                      : null,
                ),
                Divider(color: palette.border.withValues(alpha: 0.5), height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Reading mode'),
                  subtitle: const Text('Full screen paper tone with a break timer'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ReadingModeScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreset(BuildContext context, FilterSettings filter) async {
    final nameController = TextEditingController(
      text: '${ColorTemperature.labelFor(filter.kelvin)} ${filter.intensity}%',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save preset'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Preset name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(presetsControllerProvider.notifier).add(
      FilterPreset(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        intensity: filter.intensity,
        kelvin: filter.kelvin,
        customColor: filter.customColor,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final Color colour;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colour,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? palette.textPrimary : palette.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: icon == null
            ? (selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null)
            : Icon(icon, size: 20, color: palette.textSecondary),
      ),
    );
  }
}

class _ColourPickerDialog extends StatefulWidget {
  const _ColourPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_ColourPickerDialog> createState() => _ColourPickerDialogState();
}

class _ColourPickerDialogState extends State<_ColourPickerDialog> {
  late double _r = widget.initial.r * 255;
  late double _g = widget.initial.g * 255;
  late double _b = widget.initial.b * 255;

  Color get _colour => Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      title: const Text('Custom filter colour'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _colour,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: Text(
                '#${_colour.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: _colour.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _channel('Red', _r, (v) => setState(() => _r = v)),
          _channel('Green', _g, (v) => setState(() => _g = v)),
          _channel('Blue', _b, (v) => setState(() => _b = v)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, _colour.toARGB32()),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _channel(String label, double value, ValueChanged<double> onChanged) => Row(
    children: [
      SizedBox(
        width: 48,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
      Expanded(
        child: Slider(value: value, min: 0, max: 255, onChanged: onChanged),
      ),
      SizedBox(
        width: 32,
        child: Text(value.round().toString(), textAlign: TextAlign.end),
      ),
    ],
  );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.onApply,
    required this.onDelete,
    required this.onFavourite,
  });

  final FilterPreset preset;
  final VoidCallback onApply;
  final VoidCallback onDelete;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colour = preset.customColor != null
        ? Color(preset.customColor!)
        : ColorTemperature.colorFor(preset.kelvin);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        onTap: onApply,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${preset.intensity}% · ${preset.kelvin}K',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onFavourite,
              icon: Icon(
                preset.favourite ? Icons.star_rounded : Icons.star_border_rounded,
                color: preset.favourite ? palette.accent : palette.textMuted,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: palette.textMuted),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
