import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/theme/app_theme.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/widgets/protection_orb.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.build(ThemeVariant.midnight, AccentChoice.amber),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('inactive orb shows Off and reacts to taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: false,
          strength: 0,
          statusLabel: 'Protection paused',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('PROTECTION PAUSED'), findsOneWidget);

    await tester.tap(find.byType(ProtectionOrb));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('active orb shows the live percentage', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProtectionOrb(
          active: true,
          strength: 62,
          statusLabel: 'Protection active',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('PROTECTION ACTIVE'), findsOneWidget);

    // Stop the breathing animation before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
