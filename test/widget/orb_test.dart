import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/widgets/protection_orb.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(ThemeVariant.midnight, AccentChoice.amber),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows the blue light percentage and the eye score', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          strength: 55,
          eyeScore: 82,
          statusLabel: 'Protection active',
          onToggle: () {},
          onStrengthChanged: (_) {},
        ),
      ),
    );

    expect(find.text('55%'), findsOneWidget);
    expect(find.text('BLUE LIGHT'), findsOneWidget);
    expect(find.text('Eyes 82%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('the power button toggles the filter', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: false,
          strength: 30,
          eyeScore: 100,
          statusLabel: 'Protection paused',
          onToggle: () => toggles++,
          onStrengthChanged: (_) {},
        ),
      ),
    );

    expect(find.text('BLUE LIGHT OFF'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.power_settings_new_rounded));
    await tester.pump();
    expect(toggles, 1);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('dragging around the ring changes the percentage', (tester) async {
    final values = <int>[];
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          strength: 50,
          eyeScore: 90,
          statusLabel: 'Protection active',
          onToggle: () {},
          onStrengthChanged: values.add,
        ),
      ),
    );

    final centre = tester.getCenter(find.byType(ProtectionOrb));
    const size = 260.0;
    // Start at the top of the ring (0%), then drag to the right hand side (25%)
    // and down to the bottom (50%).
    final top = centre + const Offset(0, -size / 2 + 14);
    final right = centre + const Offset(size / 2 - 14, 0);

    final gesture = await tester.startGesture(top);
    for (var i = 1; i <= 10; i++) {
      final t = i / 10;
      await gesture.moveTo(Offset.lerp(top, right, t)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();

    expect(values, isNotEmpty);
    expect(values.last, closeTo(25, 6));

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('a touch in the middle does not change the percentage', (tester) async {
    final values = <int>[];
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          strength: 50,
          eyeScore: 90,
          statusLabel: 'Protection active',
          onToggle: () {},
          onStrengthChanged: values.add,
        ),
      ),
    );

    final centre = tester.getCenter(find.byType(ProtectionOrb));
    final gesture = await tester.startGesture(centre);
    await gesture.moveTo(centre + const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(values, isEmpty);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });
}

/// Keeps the maths import used, documents the ring convention for readers.
double angleForPercent(int percent) => (percent / 100) * 2 * math.pi;
