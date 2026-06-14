# Release Process

## Version numbers

AWoMa follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`).

The `pubspec.yaml` version field uses `version: MAJOR.MINOR.PATCH+BUILD` where `+BUILD` is the CI run number (set automatically by the workflow via `--build-number=${{ github.run_number }}`).

**For a new release, only update the `MAJOR.MINOR.PATCH` part:**

```yaml
# flutter_app/pubspec.yaml
version: 1.2.0+1     # the +1 is a local placeholder; CI overrides it
```

---

## Pre-release checklist

- [ ] All feature branches merged into `develop`
- [ ] `develop` merged into `main` via a pull request
- [ ] `pubspec.yaml` `version` field updated on `main`
- [ ] `flutter analyze --fatal-infos` passes on CI (check the `analyze` job)
- [ ] All tests pass on CI (`flutter test` in the `analyze` job)
- [ ] Manually test the happy path on Android (install the debug APK from CI artifacts)
- [ ] Check that Nextcloud backup/restore still works end-to-end (no schema migration side-effects)

---

## Publishing a release

```bash
git checkout main
git pull origin main
git tag v1.2.0
git push origin v1.2.0
```

The `flutter_release.yml` workflow triggers automatically on any `v*.*.*` tag and:

1. Runs `flutter analyze --fatal-infos` + `flutter test`
2. Builds Android APK (release-signed), Linux `.deb`, Windows `.zip`, macOS `.zip`
3. Generates a CycloneDX SBOM
4. Creates a GitHub Release with auto-generated notes and all artifacts attached

Monitor the Actions tab — the release appears only after all build jobs succeed.

---

## Android release signing

The release workflow signs the APK with the keystore stored in GitHub secrets. The same keystore can be used to sign local release builds for testing.

### GitHub secrets required

| Secret | Description |
|--------|-------------|
| `ANDROID_RELEASE_KEYSTORE_B64` | Base-64 encoded `.jks` keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Password for the keystore |
| `ANDROID_KEY_ALIAS` | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | Password for the key |

### Generating a new keystore (first-time setup)

```bash
keytool -genkey -v \
  -keystore release-keystore.jks \
  -alias awoma \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

### Encoding for GitHub secrets

```bash
base64 -i release-keystore.jks | pbcopy   # macOS — paste into ANDROID_RELEASE_KEYSTORE_B64
base64 release-keystore.jks               # Linux — copy the output
```

### Local release build

```bash
# 1. Place your keystore at flutter_app/android/app/release-keystore.jks
# 2. Create flutter_app/android/key.properties:
echo "storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=awoma
storeFile=release-keystore.jks" > android/key.properties

# 3. Build
flutter build apk --release
```

The `android/key.properties` file is git-ignored. Never commit the keystore or `key.properties`.

---

## Post-release verification

1. Open the GitHub Release page — confirm all 5 artifacts are attached:
   - `app-release.apk`
   - `awoma-linux-amd64.deb`
   - `awoma-windows-x64.zip`
   - `awoma-macos.zip`
   - `awoma-sbom.cdx.json`
2. Download the Android APK and install it on a physical device via `adb install`
3. Verify the version shown in **Settings → AWoMa** matches the release tag

---

## Rollback

GitHub releases can be deleted from the Releases page if an artifact was published by mistake. The tag must also be deleted:

```bash
git tag -d v1.2.0              # delete local tag
git push origin :refs/tags/v1.2.0   # delete remote tag
```

Re-push a corrected tag after fixing the issue.
