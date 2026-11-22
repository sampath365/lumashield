# On-device verification

The build machine for this repository has no hardware virtualisation, so the
emulator cannot run here. Everything below is the exact sequence to prove the
filter and the service work on a real phone. Each step names the observable
result, so a failure is obvious.

## 1. Install and grant permissions

```bash
flutter install --release
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

1. Open LumaShield, finish onboarding.
2. On the permission screen grant **Display over other apps** and
   **Notifications**.
3. Open Settings > Apps > LumaShield > Battery > Unrestricted.
4. Optional: grant usage access for per-app profiles.

Expected: every granted row turns green with a check icon. Nothing is granted
automatically.

## 2. Prove the overlay covers other apps

1. On the dashboard tap the orb.
2. The orb shows a live percentage and the chip reads "Filter on".
3. Press Home and open the launcher, Settings, Chrome and the camera app.

Expected: the whole screen, including the status bar and other apps, carries a
warm tint. The tint is visibly stronger at 80% intensity and 2700 K.

Expected non-results: a banking app or a DRM video may stay untinted. That is
Android hiding overlays on secure windows, not a bug.

## 3. Prove the settings are live, not cosmetic

1. Drag "Blue light reduction" to 0%. The tint disappears immediately.
2. Set the temperature to 6500 K. The tint disappears (neutral daylight).
3. Set 2700 K and 80%. The screen is clearly amber.
4. Switch to Custom colour and pick deep red. The tint follows.
5. Use the "Screen dim" slider. The screen darkens without changing system
   brightness.

## 4. Prove the service survives leaving the app

1. Turn the filter on.
2. Open Recents and swipe LumaShield away.
3. Return to the home screen.

Expected: the tint stays, and the persistent notification is still in the shade.
The notification shows the live percentage, temperature and mode, and has a
Pause action that removes the tint.

## 5. Prove the quick settings tile and widget

1. Advanced > Quick settings tile > add it. Toggle it from the shade.
2. Advanced > Home screen widget > place it. Tap the shield on the widget.

Expected: both toggle the real overlay and both show the real state. Nothing is
simulated.

## 6. Prove reboot restore

1. Turn the filter on with a schedule disabled.
2. Reboot the phone without opening LumaShield.

Expected: after the boot animation the tint is already applied and the
notification is present. This uses `BOOT_COMPLETED` and the mirrored
`SharedPreferences`. If the overlay permission was revoked, the service stops
cleanly instead of showing a broken notification.

## 7. Prove the schedule

1. Set a custom schedule that starts two minutes from now with 80% / 2700 K.
2. Leave the phone idle on the home screen.

Expected: at the scheduled minute the tint appears and the notification updates.
Set the end time two minutes later; the tint disappears and, if the daytime
intensity is 0%, the filter turns off.

3. Switch to "Sunset to sunrise", grant approximate location, and check that the
   displayed sunset matches a weather app within a couple of minutes.

## 8. Prove per-app profiles

1. Grant usage access.
2. Create a profile for the camera app with "Apply filter" off.
3. Open the camera, then return to a browser.

Expected: the tint disappears over the camera and returns over the browser
within a few seconds.

## 9. Prove eye breaks and the status bar score

1. Eye care: turn the 20-20-20 rule on and pick the 20m chip.
2. Note the "Next break in N min" line on the dashboard and the silent
   "Eye comfort N%" notification in the shade. The number should match.
3. Swipe the app away from Recents so the process is gone.
4. Wait for the interval (set 5 minutes with the slider for a quick test).

Expected: a heads-up "Time for an eye break" notification arrives even though
the app is closed, with Start exercise, Snooze 5m and Done.

5. Tap **Start exercise**: the guided break opens with the owl, a countdown and
   three steps (look far away, blink slowly, roll and rest).
6. Let it finish, or tap Done.

Expected: the break closes and the status bar percentage jumps back up. Pull
down the shade to confirm the new score.

7. Tap **Snooze 5m** on a reminder instead: the next one arrives five minutes
   later and the dashboard countdown restarts.
8. Set quiet hours to cover the current time and repeat: no notification
   appears, but the alarm re-arms silently.

The score itself is covered by unit tests: one point per minute of screen time,
capped at 70, plus up to 10 for filter strength.

## 10. Prove graceful failure

1. Revoke "Display over other apps" while the filter is on.
2. Open LumaShield.

Expected: the dashboard shows the permission banner, the orb is off, and no
foreground service keeps running. Turning the orb on opens the system screen
instead of pretending to work.

## Automated coverage

* `flutter test` - 52 tests covering models, solar maths, schedule windows,
  statistics, repositories, the orb and the onboarding/dashboard flows.
* `cd android && ./gradlew testDebugUnitTest` - 23 JVM tests covering the tint
  colour and alpha maths, clamping, the schedule planner (overnight, weekday
  masks, sunset mode) and sunrise/sunset edge cases including polar night.
