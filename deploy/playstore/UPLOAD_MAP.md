# Where each file goes

Exact Play Console location for every file in this folder. Copy the path, click
the menu, paste the text.

## 1. The app bundle and release notes

**Play Console → Testing → Internal testing → Releases → Create new release**

| Field on that screen | What to upload | File | Limit |
| --- | --- | --- | --- |
| *App bundles* → Upload | The app | `deploy/playstore/binaries/LumaShield-1.0.0-release.aab` (53.6 MB) | 150 MB |
| *Release name* | `1.0.0 (1)` | — | — |
| *Release notes* → English (United States) | What's new | `deploy/playstore/release-notes.txt` (467 chars) | 500 chars |

Do not upload the APK here. The APK is only for sideloading and testing.

## 2. Images and text

**Play Console → Grow → Store presence → Main store listing**

| Section | Field | File | Limit |
| --- | --- | --- | --- |
| Product details | App name | text from `listing.md` → App name (`LumaShield: Blue Light Filter`, 29 chars) | 30 chars |
| Product details | Short description | `listing.md` → Short description | 80 chars |
| Product details | Full description | `listing.md` → Full description | 4000 chars |
| Graphics | App icon | `graphics/app-icon-512.png` (512×512, 17 KB) | exact size |
| Graphics | Feature graphic | `graphics/feature-graphic-1024x500.png` (1024×500, 65 KB) | exact size |
| Graphics | Phone screenshots | `graphics/screenshots/phone/` 01-08 | 2-8 images |
| Graphics | 7-inch tablet screenshots | `graphics/screenshots/tablet-7/` 01-05 | 2-8 images |
| Graphics | 10-inch tablet screenshots | `graphics/screenshots/tablet-10/` 01-05 | 2-8 images |
| Contact details | Email | `msg4sampath@gmail.com` | required |
| Contact details | Website / phone | optional, leave blank | — |

Screenshot captions to paste under each image are at the bottom of `listing.md`.
Upload the phone shots in filename order: dashboard, filter, schedule, eye care,
eye break, insights, appearance, onboarding.

## 3. The forms under "App content"

**Play Console → Policy → App content**

| Page | What to do | Source |
| --- | --- | --- |
| Privacy policy | Paste your public URL | host `docs/privacy.html` (see below) |
| App access | Choose "All functionality is available without special access" | `CONSOLE_CHECKLIST.md` §2 |
| Ads | "No, my app does not contain ads" | `CONSOLE_CHECKLIST.md` §2 |
| Content rating | Answer the questionnaire | `content-rating.md` |
| Target audience | 18 and over, not designed for children | `CONSOLE_CHECKLIST.md` §2 |
| Data safety | No data collected, no data shared | `data-safety.md` |
| News app / COVID / Government / Financial / Health | All "No" (not a medical device) | `CONSOLE_CHECKLIST.md` §2 |

## 4. Privacy policy URL

`docs/privacy.html` is ready to host. Enable GitHub Pages for the repository
(Settings → Pages → Source: *Deploy from a branch* → branch `main`, folder
`/docs`). The URL becomes:

```
https://sampath365.github.io/lumashield/privacy.html
```

## 5. Store settings

**Play Console → Grow → Store presence → Store settings**

| Field | Value |
| --- | --- |
| App category | Health & Fitness |
| Tags | blue light filter, eye strain, night mode, screen dimmer, eye care |
| Contact email | msg4sampath@gmail.com |

## 6. Production

After internal testing passes on your phone:

**Play Console → Production → Releases → Create new release** → upload the same
`LumaShield-1.0.0-release.aab`, reuse the release notes, roll out.

## Quick reference: every uploadable file

| File | Size |
| --- | --- |
| `deploy/playstore/graphics/adaptive-icon/background-432.png` | 1 KB |
| `deploy/playstore/graphics/adaptive-icon/foreground-432.png` | 12 KB |
| `deploy/playstore/graphics/adaptive-icon/monochrome-432.png` | 7 KB |
| `deploy/playstore/graphics/app-icon-1024.png` | 35 KB |
| `deploy/playstore/graphics/app-icon-512.png` | 17 KB |
| `deploy/playstore/graphics/app-icon-round-512.png` | 21 KB |
| `deploy/playstore/graphics/feature-graphic-1024x500.png` | 65 KB |
| `deploy/playstore/graphics/logo-lockup-1200x400.png` | 40 KB |
| `deploy/playstore/graphics/screenshots/extras/filter_presets.png` | 455 KB |
| `deploy/playstore/graphics/screenshots/extras/permissions.png` | 539 KB |
| `deploy/playstore/graphics/screenshots/extras/reading_mode.png` | 189 KB |
| `deploy/playstore/graphics/screenshots/phone/01_dashboard.png` | 746 KB |
| `deploy/playstore/graphics/screenshots/phone/02_filter_settings.png` | 430 KB |
| `deploy/playstore/graphics/screenshots/phone/03_schedule.png` | 416 KB |
| `deploy/playstore/graphics/screenshots/phone/04_eye_care.png` | 406 KB |
| `deploy/playstore/graphics/screenshots/phone/05_eye_break.png` | 609 KB |
| `deploy/playstore/graphics/screenshots/phone/06_insights.png` | 320 KB |
| `deploy/playstore/graphics/screenshots/phone/07_appearance.png` | 425 KB |
| `deploy/playstore/graphics/screenshots/phone/08_onboarding.png` | 638 KB |
| `deploy/playstore/graphics/screenshots/tablet-10/01_dashboard.png` | 962 KB |
| `deploy/playstore/graphics/screenshots/tablet-10/02_filter_settings.png` | 752 KB |
| `deploy/playstore/graphics/screenshots/tablet-10/03_schedule.png` | 646 KB |
| `deploy/playstore/graphics/screenshots/tablet-10/04_eye_care.png` | 563 KB |
| `deploy/playstore/graphics/screenshots/tablet-10/05_insights.png` | 559 KB |
| `deploy/playstore/graphics/screenshots/tablet-7/01_dashboard.png` | 734 KB |
| `deploy/playstore/graphics/screenshots/tablet-7/02_filter_settings.png` | 486 KB |
| `deploy/playstore/graphics/screenshots/tablet-7/03_schedule.png` | 428 KB |
| `deploy/playstore/graphics/screenshots/tablet-7/04_eye_care.png` | 375 KB |
| `deploy/playstore/graphics/screenshots/tablet-7/05_insights.png` | 363 KB |

Text files (no upload, copy and paste): `listing.md`, `release-notes.txt`,
`data-safety.md`, `content-rating.md`, `CONSOLE_CHECKLIST.md`.
