# Play Console checklist — LumaShield 1.0.0

Work top to bottom. Every value below is already in this folder, so the console
is copy and paste.

## 0. Before you touch the console

- [ ] Play App Signing: keep `~/keys/egan-release.jks` and `android/key.properties`
      safe. Losing the upload key means you cannot ship updates. Back both up now.
- [ ] Note the certificate: `CN=EGAN`, SHA-256 `ce7faf14…c4aa`
      (`apksigner verify --print-certs deploy/playstore/binaries/*.apk`).
- [ ] Upload the **AAB**, not the APK:
      `deploy/playstore/binaries/LumaShield-1.0.0-release.aab`

## 1. Create the app

| Field | Value |
| --- | --- |
| App name | `LumaShield: Blue Light Filter` |
| Default language | English (United States) |
| App or game | App |
| Free or paid | Free |
| Declarations | Accept both checkboxes |

## 2. Dashboard → "Set up your app"

### App access
- [ ] **All functionality is available without special access**
  (no login, no account, nothing gated).

### Ads
- [ ] **No, my app does not contain ads.**

### Content rating
- [ ] Questionnaire: see `content-rating.md` (all "No", category Utility).
      Expected rating: Everyone / PEGI 3.

### Target audience and content
- [ ] Age groups: **18 and over**.
- [ ] "Is your app designed for children?" **No**.
- [ ] Appeals to children? **No**.

### News app
- [ ] **No.**

### COVID-19 contact tracing and status apps
- [ ] **No.**

### Data safety
- [ ] See `data-safety.md`. Summary: **no data collected, no data shared**,
      data encrypted in transit "not applicable", deletion available in app.

### Government apps
- [ ] **No.**

### Financial features
- [ ] **No.**

### Health apps
- [ ] Category is Health & Fitness, but the app **is not a medical device** and
      collects no health data. Say so if the form asks.
- [ ] If offered "Health Connect", decline: LumaShield does not use it.

## 3. Store listing

Copy from `listing.md`.

| Field | Value |
| --- | --- |
| App name | `LumaShield: Blue Light Filter` |
| Short description | `Warm your screen, cut blue light, and rest your eyes with smart reminders.` |
| Full description | `listing.md` → Full description |
| App icon | `graphics/app-icon-512.png` |
| Feature graphic | `graphics/feature-graphic-1024x500.png` |
| Phone screenshots | `graphics/screenshots/phone/` (8 files, in order) |
| 7" tablet screenshots | `graphics/screenshots/tablet-7/` (5 files) |
| 10" tablet screenshots | `graphics/screenshots/tablet-10/` (5 files) |
| Video | none |
| Contact email | `msg4sampath@gmail.com` |
| Website | optional, leave blank if you have none |
| Privacy policy | public URL of `privacy-policy.md` |

Screenshot order matters; upload them sorted by filename.

## 4. Store settings

| Field | Value |
| --- | --- |
| App category | Health & Fitness |
| Tags | blue light filter, eye strain, night mode, screen dimmer, eye care |
| Contact email | `msg4sampath@gmail.com` |
| External marketing | your choice (opt in only if you want Google to promote it) |

## 5. Countries and pricing

- [ ] Countries: all, or your list.
- [ ] Price: **Free** (no in-app purchases, no ads).

## 6. Release

1. **Testing → Internal testing → Create new release**
2. Upload `binaries/LumaShield-1.0.0-release.aab`.
3. Release name: `1.0.0 (1)`.
4. Release notes: `release-notes.txt`.
5. Add yourself as a tester, roll out, install from the opt-in link.
6. Run `docs/VERIFICATION.md` on the real device.
7. **Production → Create new release**, reuse the same bundle, roll out to a
   small percentage first.

## 7. Right after the first upload

- [ ] **App bundle explorer** → check for warnings (target SDK, 64-bit, etc.).
- [ ] **Pre-launch report** → watch for crashes on the test devices.
- [ ] Confirm the listing preview looks right on phone and tablet.

## 8. Every future update

```bash
# bump the version, rebuild, upload
sed -i 's/^version: 1.0.0+1/version: 1.0.1+2/' pubspec.yaml
flutter build appbundle --release
python3 tool/playstore/validate_assets.py
```

Never reuse a versionCode. Play rejects a bundle with a versionCode it has
already seen.

## Known review notes

These are the things a reviewer may ask about; the answers are already in
`data-safety.md`:

| Permission | One line answer |
| --- | --- |
| Display over other apps | The app is a blue light filter; the overlay is the product |
| Foreground service (special use) | Keeps the filter running while you use other apps |
| Usage access | Optional, only the foreground package name, for per-app profiles |
| Location (coarse) | Optional, once, to compute sunrise/sunset offline |
| Notifications | Break reminders and the protection status |
| Exact alarms | On-the-minute schedules; falls back to inexact |
| Biometrics | Optional app lock, the system does the check |
