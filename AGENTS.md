# AGENTS.md

Repository notes for future agents working on LumaShield.

## What this is

Flutter app (Android first) that applies a system wide blue light filter through
an Android overlay window, plus scheduling, eye care reminders and local reports.
Package id `com.lumashield.app`. iOS intentionally ships only in-app features.

## Toolchain that built it

* Flutter 3.50.1 stable / Dart 3.14 (`/opt/flutter`)
* JDK 21, Android SDK 37 (`compileSdk = 37`, `minSdk = 26`, `targetSdk = 36`)
* AGP 9.3.1, Gradle 9.5, Kotlin 2.4.20

## Commands

```bash
flutter pub get
flutter analyze                 # must stay at zero issues
flutter test                    # 52 Dart tests
cd android && ./gradlew testDebugUnitTest   # 23 JVM tests
flutter build apk --release
flutter build appbundle --release

# Store screenshots -> deploy/playstore/graphics/screenshots/{phone,tablet-7,tablet-10}
flutter test tool/screenshots/screens_test.dart --update-goldens

# Validate every Play asset and regenerate ASSET_CHECK.md + MANIFEST.md
python3 tool/playstore/validate_assets.py

# Rebuild the demo video (needs ffmpeg)
python3 tool/video/build_fgs_demo.py
```

## Critical gotcha: material_ui

Flutter 3.50 deprecated `package:flutter/material.dart`. This project imports
**`package:material_ui/material_ui.dart`** everywhere, including tests.

Mixing the two libraries creates *two different* `ThemeData`, `SizedBox`, etc.
types and produces confusing "argument type can't be assigned" errors. Never add
a `package:flutter/material.dart` import.

## Architecture rules

* State: Riverpod 3 `Notifier` controllers in `lib/shared/providers/app_providers.dart`.
  No `StateProvider` (removed in Riverpod 3), no `valueOrNull` (use `.value`).
* Settings: immutable models with `copyWith` + `toJson`/`fromJson`, persisted in
  `SettingsRepository` (SharedPreferences JSON blobs).
* History: `HistoryRepository` over Hive CE (`protection_history` box).
* Native bridge: `FilterService` wraps the method channel defensively; every call
  returns a safe value when the plugin is missing (iOS, tests).
* Platform checks: `PlatformCapabilities` uses `defaultTargetPlatform`, never
  `dart:io Platform`, so widget tests can emulate Android.

## Android overlay invariants

* Only `OverlayFilterService` adds or removes the overlay view. Start, stop,
  schedule, per-app and reboot paths all funnel through it.
* `FilterPrefs` mirrors every setting natively so the service survives Flutter
  process death and reboots.
* Tint alpha is `intensity x warmth x 0.72`; 6500 K is neutral and adds nothing.
  This is verified by `android/app/src/test/.../FilterConfigTest.kt`.
* Schedule boundaries are computed by `SchedulePlanner` + `SolarCalc` and armed
  with `AlarmManager`; exact alarms degrade to inexact when not permitted.
* `ProtectionOrb` is a circular slider: drag handlers convert the touch angle
  into a 0-100 value and call `onStrengthChanged`. The power button inside the
  circle is a separate tap target, so dragging never toggles the filter.
* Eye breaks are owned by `EyeBreakScheduler` + `EyeBreakReceiver` (native, so
  they fire with the app closed). The percentage in the status bar comes from
  `EyeScore` and `EyeStatusNotifier`; the Dart side only displays it.
* The app must never claim a capability it lacks. `ProtectionStatus` comes from
  the native side; the orb reflects it.

## Signing

`android/key.properties` (git ignored) points at the upload keystore. Never commit
`key.properties`, `*.jks` or `*.keystore`. Without the file the release build
falls back to the debug key.

## Verification

`docs/VERIFICATION.md` holds the on-device checklist. There is no emulator in the
build container (no `/dev/kvm`), so overlay behaviour must be confirmed on a
physical device with that checklist.
