// ignore_for_file: invalid_use_of_visible_for_testing_member
// Generates the store screenshots from the real widget tree.
//
// Run with:
//   flutter test tool/screenshots/screens_test.dart --update-goldens
//
// Output lands in deploy/playstore/graphics/screenshots/ for phone (1080x1920),
// 7 inch (1200x1920) and 10 inch (1600x2560) tablets. This is not part of `flutter test` (it lives outside test/) so the
// regular suite stays fast and font independent.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/core/services/filter_service.dart';
import 'package:lumashield/core/services/notification_service.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/features/blue_filter/filter_settings_screen.dart';
import 'package:lumashield/features/dashboard/dashboard_screen.dart';
import 'package:lumashield/features/eye_care/break_exercise_screen.dart';
import 'package:lumashield/features/eye_care/eye_care_screen.dart';
import 'package:lumashield/features/onboarding/onboarding_screen.dart';
import 'package:lumashield/features/onboarding/permission_setup_screen.dart';
import 'package:lumashield/features/reading_mode/reading_mode_screen.dart';
import 'package:lumashield/features/scheduling/schedule_screen.dart';
import 'package:lumashield/features/settings/theme_settings_screen.dart';
import 'package:lumashield/features/statistics/statistics_screen.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/models/protection_session.dart';
import 'package:lumashield/shared/models/protection_status.dart';
import 'package:lumashield/shared/providers/app_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PreviewFilterService extends FilterService {
  const _PreviewFilterService();

  static final ProtectionStatus status = ProtectionStatus(
    supported: true,
    running: true,
    enabled: true,
    intensity: 55,
    kelvin: 3400,
    modeLabel: 'Night Mode',
    strength: 42,
    overlayGranted: true,
    batteryOptimized: false,
    usageAccessGranted: true,
    exactAlarmsAllowed: true,
    scheduleEnabled: true,
    nextActivation: DateTime.now().add(const Duration(hours: 3)),
    showNotification: true,
    eyeScore: 86,
    nextBreakIn: 12,
    breaksEnabled: true,
    breakIntervalMin: 20,
  );

  @override
  Future<ProtectionStatus> getStatus() async => status;

  @override
  Stream<ProtectionStatus> statusStream() => const Stream.empty();

  @override
  Future<bool> isOverlayGranted() async => true;

  @override
  Future<bool> isUsageAccessGranted() async => true;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

/// Play Store screenshot classes. Physical sizes are what gets uploaded.
enum _Device {
  phone('phone', Size(1080, 1920), 3),
  extras('extras', Size(1080, 1920), 3),
  tablet7('tablet-7', Size(1200, 1920), 2),
  tablet10('tablet-10', Size(1600, 2560), 2);

  const _Device(this.folder, this.physicalSize, this.pixelRatio);

  final String folder;
  final Size physicalSize;
  final double pixelRatio;
}

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUpAll(() async {
    const roboto = [
      '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
      '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
    ];
    await _loadFont('Roboto', roboto);
    // Text styles that do not name a family fall back to the test font, which
    // draws solid boxes. Aliasing Roboto as Ahem keeps every label readable.
    await _loadFont('Ahem', roboto);
    await _loadFont('MaterialIcons', [
      '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumashield.app':
          '{"onboarded":true,"themeVariant":"midnight","accent":"amber"}',
      'lumashield.filter':
          '{"enabled":true,"mode":"night","intensity":55,"kelvin":3400,"dim":6}',
      'lumashield.schedule':
          '{"enabled":true,"mode":"custom","startMinute":1230,"endMinute":420,'
          '"weekdays":[1,2,3,4,5,6,7],"nightIntensity":65,"nightKelvin":3200,'
          '"dayIntensity":15,"dayKelvin":5400}',
    });
    prefs = await SharedPreferences.getInstance();
    dir = await Directory.systemTemp.createTemp('lumashield_shots');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('shots');
    await _seedSessions(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Widget app(Widget screen) {
    final base = AppTheme.build(ThemeVariant.midnight, AccentChoice.amber);
    // Button styles declare their own TextStyle, so they need the family too.
    const buttonText = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: const WidgetStatePropertyAll(buttonText),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (base.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyBoxProvider.overrideWithValue(box),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        filterServiceProvider.overrideWithValue(const _PreviewFilterService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: screen,
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    Widget screen,
    String name, {
    _Device device = _Device.phone,
    bool scrollDown = false,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = device.physicalSize;
    tester.view.devicePixelRatio = device.pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(screen));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    if (scrollDown) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 400));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../deploy/playstore/graphics/screenshots/'
          '${device.folder}/$name.png'),
    );

    // Dispose so timers and animations stop before the next capture.
    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pump(const Duration(milliseconds: 100));
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('01 dashboard', (tester) async {
    await capture(tester, const Scaffold(body: DashboardScreen()), '01_dashboard');
  });

  testWidgets('02 filter settings', (tester) async {
    await capture(tester, const FilterSettingsScreen(), '02_filter_settings');
  });

  testWidgets('03 schedule', (tester) async {
    await capture(tester, const Scaffold(body: ScheduleScreen()), '03_schedule');
  });

  testWidgets('04 eye care', (tester) async {
    await capture(tester, const Scaffold(body: EyeCareScreen()), '04_eye_care');
  });

  testWidgets('05 eye break', (tester) async {
    await capture(
      tester,
      const BreakExerciseScreen(autoStart: false),
      '05_eye_break',
    );
  });

  testWidgets('06 insights', (tester) async {
    await capture(tester, const Scaffold(body: StatisticsScreen()), '06_insights');
  });

  testWidgets('07 appearance', (tester) async {
    await capture(tester, const ThemeSettingsScreen(), '07_appearance');
  });

  testWidgets('08 onboarding', (tester) async {
    await capture(tester, const OnboardingScreen(), '08_onboarding');
  });

  // Extras: useful for the website and press, not uploaded (Play caps the
  // phone set at eight).
  testWidgets('extras permissions', (tester) async {
    await capture(
      tester,
      const PermissionSetupScreen(),
      'permissions',
      device: _Device.extras,
    );
  });

  testWidgets('extras reading mode', (tester) async {
    await capture(
      tester,
      const ReadingModeScreen(),
      'reading_mode',
      device: _Device.extras,
    );
  });

  testWidgets('extras presets', (tester) async {
    await capture(
      tester,
      const FilterSettingsScreen(),
      'filter_presets',
      device: _Device.extras,
      scrollDown: true,
    );
  });

  testWidgets('tablet 7 dashboard', (tester) async {
    await capture(
      tester,
      const Scaffold(body: DashboardScreen()),
      '01_dashboard',
      device: _Device.tablet7,
    );
  });

  testWidgets('tablet 7 filter', (tester) async {
    await capture(
      tester,
      const FilterSettingsScreen(),
      '02_filter_settings',
      device: _Device.tablet7,
    );
  });

  testWidgets('tablet 7 schedule', (tester) async {
    await capture(
      tester,
      const Scaffold(body: ScheduleScreen()),
      '03_schedule',
      device: _Device.tablet7,
    );
  });

  testWidgets('tablet 7 eye care', (tester) async {
    await capture(
      tester,
      const Scaffold(body: EyeCareScreen()),
      '04_eye_care',
      device: _Device.tablet7,
    );
  });

  testWidgets('tablet 7 insights', (tester) async {
    await capture(
      tester,
      const Scaffold(body: StatisticsScreen()),
      '05_insights',
      device: _Device.tablet7,
    );
  });

  testWidgets('tablet 10 dashboard', (tester) async {
    await capture(
      tester,
      const Scaffold(body: DashboardScreen()),
      '01_dashboard',
      device: _Device.tablet10,
    );
  });

  testWidgets('tablet 10 filter', (tester) async {
    await capture(
      tester,
      const FilterSettingsScreen(),
      '02_filter_settings',
      device: _Device.tablet10,
    );
  });

  testWidgets('tablet 10 schedule', (tester) async {
    await capture(
      tester,
      const Scaffold(body: ScheduleScreen()),
      '03_schedule',
      device: _Device.tablet10,
    );
  });

  testWidgets('tablet 10 eye care', (tester) async {
    await capture(
      tester,
      const Scaffold(body: EyeCareScreen()),
      '04_eye_care',
      device: _Device.tablet10,
    );
  });

  testWidgets('tablet 10 insights', (tester) async {
    await capture(
      tester,
      const Scaffold(body: StatisticsScreen()),
      '05_insights',
      device: _Device.tablet10,
    );
  });
}

Future<void> _seedSessions(Box<dynamic> box) async {
  final now = DateTime.now();
  final pattern = [186, 142, 205, 96, 168, 120, 64];
  for (var day = 6; day >= 0; day--) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: day));
    final minutes = pattern[6 - day];
    var cursor = date.add(const Duration(hours: 9));
    var remaining = minutes;
    var index = 0;
    while (remaining > 0) {
      final chunk = remaining > 70 ? 70 : remaining;
      await box.add(
        ProtectionSession(
          start: cursor,
          end: cursor.add(Duration(minutes: chunk)),
          mode: index.isEven ? 'Night Mode' : 'Reading Mode',
          intensity: 55,
          kelvin: 3400,
        ).toJson(),
      );
      cursor = cursor.add(Duration(minutes: chunk + 12));
      remaining -= chunk;
      index++;
    }
  }
}
