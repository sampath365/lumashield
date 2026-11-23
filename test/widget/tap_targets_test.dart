import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/core/services/notification_service.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/features/dashboard/home_shell.dart';
import 'package:lumashield/features/settings/about_screen.dart';
import 'package:lumashield/features/settings/settings_screen.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/providers/app_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for taps that used to land on the floating navigation bar
/// instead of the row underneath it.
void main() {
  late Directory dir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumashield.app': '{"onboarded":true}',
    });
    prefs = await SharedPreferences.getInstance();
    dir = await Directory.systemTemp.createTemp('lumashield_taps');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('tap_history');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('content is never hidden behind the floating navigation bar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final theme = AppTheme.build(ThemeVariant.midnight, AccentChoice.amber);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyBoxProvider.overrideWithValue(box),
          notificationServiceProvider.overrideWithValue(NotificationService()),
        ],
        child: MaterialApp(theme: theme, home: const HomeShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    // Jump straight to the end of the list so the result does not depend on
    // fling physics.
    final scrollable = find
        .descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 200));

    // The floating bar covers the last 80dp of the screen (12 padding plus a
    // 68dp bar). Anything below that line can never receive a tap.
    const screenHeight = 720.0;
    const barTop = screenHeight - 12 - 68;
    final lastContent = find.textContaining('protected').last;
    expect(
      tester.getBottomLeft(lastContent).dy,
      lessThanOrEqualTo(barTop),
      reason: 'content sits under the floating navigation bar, so taps are swallowed',
    );

    // And the last real row still works.
    await tester.tap(find.text('About and privacy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
