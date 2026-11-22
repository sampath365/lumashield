# Data safety form answers

## Section 1: Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable — no data leaves the device |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in app: Settings > Advanced > Clear protection history. Uninstalling removes everything |
| Has your app been independently validated against a global security standard? | No |

Because nothing is collected or shared, the Data safety summary shows
"No data collected" and "No data shared".

## Section 2: Sensitive permissions and why they are needed

Play reviews these declarations. The answers match the manifest exactly.

### Display over other apps (SYSTEM_ALERT_WINDOW)

> LumaShield draws a warm translucent overlay above other apps to reduce blue
> light. This is the core function of a blue light filter and there is no
> alternative API on Android. The overlay is not touchable, does not read screen
> content, and can be turned off at any time from the persistent notification.

### Foreground service (FOREGROUND_SERVICE_SPECIAL_USE)

> The overlay must stay active while the user works in other apps. The service
> posts a low-importance notification with a Pause action and stops immediately
> when protection is turned off.

### Usage access (PACKAGE_USAGE_STATS)

> Optional. Used only to read the package name of the app currently in the
> foreground so per-app profiles can lift or adjust the filter (for example to
> leave the camera unfiltered). Screen content is not accessible with this
> permission and is never read. The feature is off by default.

### Approximate location (ACCESS_COARSE_LOCATION)

> Optional. Read once, only when the user enables "Sunset to sunrise" scheduling.
> The coordinates are used to calculate sunrise and sunset offline and are stored
> on the device only.

### Notifications (POST_NOTIFICATIONS)

> Required by Android for the foreground protection service, and used for eye
> care reminders the user schedules.

### Exact alarms (SCHEDULE_EXACT_ALARM)

> Optional. Lets a schedule start on the minute. Without it LumaShield falls back
> to inexact alarms, which may run a few minutes late.

### Biometrics (USE_BIOMETRIC)

> Optional app lock. The system prompt performs the check; LumaShield only
> receives pass or fail.

### Eye comfort percentage

The percentage shown in the status bar is calculated on the device from the time
since your last break, the filter strength and screen-off periods. It is not
collected, not transmitted and not a medical measurement.

## Section 3: Advertising and tracking

| Question | Answer |
| --- | --- |
| Does the app contain ads? | No |
| Does the app use advertising ID? | No |
| Does the app use analytics or crash reporting SDKs? | No. An optional anonymous diagnostics toggle exists but sends nothing by default and contains no identifiers |

## Section 4: Data handled by third parties

None. The app declares **no INTERNET permission**, so it cannot transmit data.
This can be verified in the uploaded bundle:

```bash
apkanalyzer manifest permissions playstore/binaries/LumaShield-1.0.0-release.apk
```
