# LumaShield deployment pack

Everything the Google Play Console asks for, in upload order.

```
deploy/
└── playstore/
    ├── listing.md            app name, short + full description, category
    ├── release-notes.txt     "What's new" for version 1.0.0
    ├── data-safety.md        Data safety form answers + permission justifications
    ├── content-rating.md     IARC questionnaire answers
    ├── privacy-policy.md     host this at a public URL, then link it
    ├── graphics/
    │   ├── app-icon-512.png            512x512  (store listing icon)
    │   ├── app-icon-1024.png           1024x1024 (press / adaptive source)
    │   ├── app-icon-round-512.png      512x512 round variant
    │   ├── feature-graphic-1024x500.png 1024x500 (store listing header)
    │   ├── logo-lockup-1200x400.png    transparent lockup for press/site
    │   ├── adaptive-icon/              Android 13 layers (foreground/background/monochrome)
    │   └── screenshots/
    │       ├── phone/       1080x1920  (10 screens)
    │       ├── tablet-7/    1200x1920  (5 screens)
    │       └── tablet-10/   1600x2560  (5 screens)
    └── binaries/
        ├── LumaShield-1.0.0-release.aab   upload this to Play
        ├── LumaShield-1.0.0-release.apk   sideload / QA
        ├── SHA256SUMS.txt
        └── BUILD_INFO.txt
```

## Upload order

1. **App bundle** — `binaries/LumaShield-1.0.0-release.aab` on the internal
   testing track first.
2. **Store listing** — copy from `listing.md`.
3. **Graphics** — icon, feature graphic, then the phone screenshots. Tablet
   screenshots are required if you mark the app as tablet supported.
4. **Data safety** — answers in `data-safety.md`.
5. **Content rating** — answers in `content-rating.md`.
6. **Privacy policy** — host `privacy-policy.md` publicly and paste the URL.
7. **Release notes** — `release-notes.txt`.

## Regenerating the images

```bash
pip install pillow
python3 tool/brand/generate_assets.py          # icons, feature graphic, lockup
flutter test tool/screenshots/screens_test.dart --update-goldens  # screenshots
```

Both scripts are deterministic, so the images can be rebuilt from source at any
time. The screenshots are rendered from the real widget tree at the exact sizes
Play expects.

## Signing

The binaries are signed with the upload key configured in
`android/key.properties` (alias `egan`). Keep that keystore: Play needs the same
key for every future update. Check any artefact with:

```bash
apksigner verify --print-certs playstore/binaries/LumaShield-1.0.0-release.apk
jarsigner -verify playstore/binaries/LumaShield-1.0.0-release.aab
```
