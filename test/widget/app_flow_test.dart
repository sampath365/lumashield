import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/app.dart';
import 'package:lumashield/core/services/notification_service.dart';
import 'package:lumashield/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late Box<dynamic> box;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('lumashield_widget');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('widget_history');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyBoxProvider.overrideWithValue(box),
          notificationServiceProvider.overrideWithValue(NotificationService()),
        ],
        child: const LumaShieldApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows the splash then onboarding', (tester) async {
    await pumpApp(tester);
    expect(find.text('Blue light after dark\nis not your friend'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('onboarding advances to the live preview and permissions', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Try the filter'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Set up LumaShield'), findsOneWidget);

    await tester.tap(find.text('Set up LumaShield'));
    await tester.pumpAndSettle();
    expect(find.text('Permissions'), findsOneWidget);
  });

  testWidgets('returning users land on the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lumashield.app': '{"onboarded":true,"themeVariant":"midnight","accent":"amber"}',
    });
    await pumpApp(tester);
    expect(find.text('LumaShield'), findsWidgets);
    expect(find.text('EYE COMFORT'), findsWidgets);
    expect(find.text('Quick modes'), findsOneWidget);
    expect(find.text('Live filter'), findsOneWidget);

    // Dispose the dashboard so its refresh timer is cancelled.
    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });
}
