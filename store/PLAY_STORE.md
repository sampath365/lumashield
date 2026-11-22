# Google Play release pack

Everything needed to publish LumaShield 1.0.0.

## Build artefacts

```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab   <- upload this
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk      <- sideload / QA
```

The release build is signed from `android/key.properties`. Keep that keystore and
its passwords safe: Play needs the same key for every future update, or you must
use the "reset upload key" flow.

## Store listing

**App name** (30 chars max)

```
LumaShield: Blue Light Filter
```

**Short description** (80 chars max)

```
Warm your screen, cut blue light, and rest your eyes with smart reminders.
```

**Full description**

```
LumaShield warms your screen to reduce blue light and helps you look after your
eyes, without an account, without ads and without sending anything off your
phone.

BLUE LIGHT FILTER
• Turn protection on with one tap from the dashboard orb
• Adjust blue light reduction from 0% to 100%
• Fine tune colour temperature from 1900K candle light to 6500K neutral
• Warm, amber, orange, yellow and warm red palettes, plus a custom colour picker
• Live preview that matches the real overlay exactly
• Screen dim slider that never changes your system brightness

AUTOMATIC PROTECTION
• Sunset to sunrise scheduling calculated offline from your approximate location
• Custom start and end times, weekday and weekend rules
• Separate night and daytime intensities so protection follows your day
• Restores your settings after a reboot, and restarts itself if interrupted
• Persistent status notification with a pause action
• Quick settings tile and home screen widget for one tap control

EYE CARE
• 20-20-20 rule reminders with a full screen break timer
• Eye strain and continuous use reminders
• Sleep wind down cue and daily eye comfort report
• Reading mode with a warm paper surface and larger type
• Daily and weekly statistics: protected time, streaks and session history

MADE TO RESPECT YOU
• No account, no sign in, no advertising, no internet permission at all
• History stays on your device and is pruned after 120 days
• Optional biometric app lock
• Deep navy, AMOLED black and daylight themes

HONEST ABOUT LIMITS
Android allows LumaShield to tint other apps through the "Display over other
apps" permission. Some secure screens, such as banking apps and DRM video, hide
overlays by design and stay unfiltered. Aggressive manufacturer battery savers can
stop any background service; LumaShield asks for the battery exemption and
explains why.

On iPhone, Apple does not allow third party apps to tint the system. LumaShield
warms its own screens, schedules reminders and points you to Night Shift for
system wide warmth.

LumaShield is not a medical device.
```

**Category:** Health & Fitness (alternative: Tools)
**Tags:** blue light filter, eye strain, night mode, screen dimmer, eye care

## Graphics

* App icon 512x512: `store/play_icon_512.png`
* Feature graphic 1024x500: `store/feature_graphic_1024x500.png`
* Phone screenshots: capture at 1080x1920 or larger from a real device using the
  flows in `docs/VERIFICATION.md`:
  1. Dashboard with protection active
  2. Filter settings with the live preview
  3. Schedule screen with sunset mode
  4. Eye care with the 20-20-20 card
  5. Insights with a week of data
  6. Appearance / AMOLED theme

## Data safety form

| Question | Answer |
| --- | --- |
| Does your app collect or share any required user data types? | No |
| Is all user data encrypted in transit? | Not applicable, no data leaves the device |
| Do you provide a way for users to request data deletion? | Yes, in-app (Advanced > Clear history) and by uninstalling |
| Data collected | None |
| Data shared | None |

## Content rating questionnaire

* No violence, no sexual content, no profanity, no gambling.
* No user generated content, no social features, no purchases.
* Contains no ads. Answer "No" to the advertising ID question.
* Expected rating: Everyone / PEGI 3.

## App access

No login is required, so answer "All functionality is available without special
access". The permission setup screen explains each permission inside the app.

## Target audience

18+ general wellbeing tool. Not designed for children.

## Release notes (1.0.0)

```
First release. System wide blue light filter with live preview, sunset to
sunrise scheduling, per-app profiles, eye care reminders and local reports.
```

## Pre-upload checklist

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes (52 tests)
- [ ] `./gradlew testDebugUnitTest` passes (23 tests)
- [ ] `flutter build appbundle --release` succeeds
- [ ] Overlay verified on a physical device using `docs/VERIFICATION.md`
- [ ] Screenshots captured on a device
- [ ] Privacy policy hosted at a public URL and linked in the listing
- [ ] Data safety form submitted
- [ ] `versionCode` incremented in `pubspec.yaml` for future uploads
