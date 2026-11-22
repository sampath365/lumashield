import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/repositories/history_repository.dart';
import 'core/services/notification_service.dart';
import 'shared/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  final historyBox = await Hive.openBox<dynamic>(HistoryRepository.boxName);
  final history = HistoryRepository(historyBox);
  await history.prune();

  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyBoxProvider.overrideWithValue(historyBox),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const LumaShieldApp(),
    ),
  );
}
