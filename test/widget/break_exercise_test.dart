import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/core/services/notification_service.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/features/eye_care/break_exercise_screen.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/providers/app_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumashield.eyeCare':
          '{"twentyRuleEnabled":true,"twentyIntervalMin":20,"twentyBreakSec":20,'
          '"showEyeStatus":true}',
      'lumashield.app': '{"onboarded":true}',
    });
    prefs = await SharedPreferences.getInstance();
    dir = await Directory.systemTemp.createTemp('lumashield_break');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('break_history');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  void sizeToPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget screen) {
    final base = AppTheme.build(ThemeVariant.midnight, AccentChoice.amber);
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyBoxProvider.overrideWithValue(box),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
      child: MaterialApp(theme: base, home: screen),
    );
  }

  testWidgets('shows the owl and the first exercise step', (tester) async {
    sizeToPhone(tester);
    await tester.pumpWidget(app(const BreakExerciseScreen(autoStart: false)));

    expect(find.text('Eye break'), findsOneWidget);
    expect(find.text('Look far away'), findsOneWidget);
    // Half of a 20 second break is spent looking far away.
    expect(find.text('10 s'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('counts down and moves to the next step', (tester) async {
    sizeToPhone(tester);
    await tester.pumpWidget(app(const BreakExerciseScreen(autoStart: true)));

    expect(find.text('Look far away'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Blink slowly'), findsOneWidget);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('done closes the break screen', (tester) async {
    sizeToPhone(tester);
    await tester.pumpWidget(app(const Scaffold(body: Center(child: Text('home')))));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const BreakExerciseScreen(autoStart: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Eye break'), findsOneWidget);

    await tester.tap(find.text('Done'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Eye break'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
