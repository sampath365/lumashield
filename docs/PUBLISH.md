# Publishing LumaShield

The build container's GitHub token can read repositories but cannot create new
ones, so the repository has to be created once from your account. Everything
else is ready.

## 1. Create the repository

On GitHub: <https://github.com/new?name=lumashield> (owner `sampath365`,
visibility of your choice), or from a terminal:

```bash
gh repo create lumashield --public \
  --description "LumaShield - blue light filter and eye care for Android" \
  --source=. --remote=origin --push
```

If the repository already exists and is empty:

```bash
git remote add origin https://github.com/sampath365/lumashield.git
git branch -M main
git push -u origin main
```

The history is already committed locally (two commits on `master`). A portable
copy exists at `/tmp/lumashield-repo.bundle`:

```bash
git clone /tmp/lumashield-repo.bundle lumashield
```

## 2. Signed artefacts already built

| Artefact | Path | Size |
| --- | --- | --- |
| Play upload bundle | `deploy/playstore/binaries/LumaShield-1.0.0-release.aab` | 56 MB |
| Sideload / QA APK | `deploy/playstore/binaries/LumaShield-1.0.0-release.apk` | 57 MB |

Both are signed with the upload key configured in `android/key.properties`
(alias `egan`, certificate `CN=EGAN`). They are committed under `deploy/playstore/binaries/`
with SHA-256 checksums.

To rebuild:

```bash
flutter build appbundle --release
flutter build apk --release
```

## 3. Play Console

Follow `deploy/playstore/listing.md`:

1. Create the app, package name `com.lumashield.app`.
2. Upload the AAB to the internal testing track first.
3. Paste the listing text, icon (`deploy/playstore/graphics/app-icon-512.png`),
   feature graphic (`deploy/playstore/graphics/feature-graphic-1024x500.png`) and
   screenshots (`deploy/playstore/graphics/screenshots/{phone,tablet-7,tablet-10}`).
4. Complete the data safety form as "no data collected, no data shared".
5. Host `deploy/playstore/privacy-policy.md` at a public URL and link it.
6. Run the on-device checklist in `docs/VERIFICATION.md` on a real phone before
   promoting to production.

## 4. Before every future upload

```bash
# bump the build number, then rebuild
flutter pub version patch        # or edit version in pubspec.yaml
flutter build appbundle --release
```
