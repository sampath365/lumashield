import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/core/services/notification_service.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/features/app_profiles/app_profiles_screen.dart';
import 'package:lumashield/features/reading_mode/reading_mode_screen.dart';
import 'package:lumashield/shared/models/app_profile.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/providers/app_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These screens used to cut off their bottom content: the profile list did not
/// scroll at all, and the reading controls sat under the system navigation bar.
void main() {
  late Directory dir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'lumashield.app': '{"onboarded":true}'});
    prefs = await SharedPreferences.getInstance();
    dir = await Directory.systemTemp.createTemp('lumashield_layout');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('layout_history');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Widget app(Widget screen, {List<Override> overrides = const []}) {
    final theme = AppTheme.build(ThemeVariant.midnight, AccentChoice.amber);
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyBoxProvider.overrideWithValue(box),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        ...overrides,
      ],
      child: MaterialApp(theme: theme, home: screen),
    );
  }

  void sizeToPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('app profiles scrolls to the last app', (tester) async {
    sizeToPhone(tester);
    final apps = List.generate(
      40,
      (i) => AppProfile(packageName: 'com.example.app$i', label: 'Example app $i'),
    );

    await tester.pumpWidget(
      app(
        const AppProfilesScreen(),
        overrides: [installedAppsProvider.overrideWith((ref) async => apps)],
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final last = find.text('Example app 39');
    await tester.scrollUntilVisible(last, 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(last, findsOneWidget);
  });

  testWidgets('reading mode shows its controls above the system bar', (tester) async {
    sizeToPhone(tester);
    await tester.pumpWidget(app(const ReadingModeScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Page warmth'), findsOneWidget);
    expect(find.text('Text size'), findsOneWidget);

    // Bottom of the controls must stay inside the safe area.
    final controls = tester.getBottomLeft(find.text('Text size'));
    expect(controls.dy, lessThan(720 - 8));
  });
}
