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
  testWidgets('inactive orb shows the eye score and reacts to taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: false,
          score: 82,
          filterStrength: 0,
          statusLabel: 'Protection paused',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('82%'), findsOneWidget);
    expect(find.text('EYE COMFORT'), findsOneWidget);
    expect(find.text('Filter off'), findsOneWidget);

    await tester.tap(find.byType(ProtectionOrb));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('active orb shows both percentages', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          score: 62,
          filterStrength: 55,
          statusLabel: 'Protection active',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('62%'), findsOneWidget);
    expect(find.text('Filter 55%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });

  testWidgets('the ring animates when the score drops', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          score: 90,
          filterStrength: 40,
          statusLabel: 'Protection active',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('90%'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          score: 40,
          filterStrength: 40,
          statusLabel: 'Protection active',
          onTap: () {},
        ),
      ),
    );
    // Mid animation the value is between the two scores.
    await tester.pump(const Duration(milliseconds: 300));
    final midValue = tester.widget<Text>(
      find.descendant(of: find.byType(ProtectionOrb), matching: find.textContaining('%')).first,
    );
    expect(midValue.data, isNot('90%'));

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('40%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox(width: 0, height: 0));
    await tester.pumpAndSettle();
  });
}
