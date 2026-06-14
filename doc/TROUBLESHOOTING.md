# Troubleshooting

## Analyzer — false positives with local Flutter SDK

**Symptom:** Five `info`-level hints appear locally:

```
info • The named parameter 'initialValue' isn't defined (DropdownButtonFormField)
info • 'RadioGroup' isn't defined
```

**Cause:** The local Flutter SDK (3.32.x) is older than the CI channel (stable, 3.44+). These APIs exist on 3.44+ and the code is correct.

**Fix:** Do not suppress with `// ignore` comments. Run `flutter analyze --no-fatal-infos` locally (the CI gate uses `--fatal-infos` and passes because it uses the newer SDK).

---

## `build_runner` — "conflicting outputs" error

**Symptom:** `build_runner` exits with an error about conflicting `.g.dart` files.

**Fix:** Always pass `--delete-conflicting-outputs`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Nextcloud — connection test fails

Work through these steps in order:

1. **Check the URL format.** AWoMa requires the root server URL, e.g. `https://cloud.example.com` — no trailing slash, no `/remote.php/...` suffix.
2. **App password required.** AWoMa must use a Nextcloud **app password**, not your login password. Create one in Nextcloud → Settings → Security → Devices & Sessions → Create new app password.
3. **Self-signed certificate.** If the server uses a self-signed or private CA certificate, AWoMa will show a certificate-details dialog after the first connection attempt. Choose **Trust & pin** to accept it. The SHA-256 fingerprint is stored in Settings and used for all subsequent requests.
4. **Certificate expired.** If a pinned certificate expires, the connection will fail silently (no matching fingerprint). Go to Settings → Nextcloud, clear the connection, run Test connection again, and re-pin the new certificate.
5. **Firewall / VPN.** Test that your device can reach the Nextcloud server URL in a browser before blaming AWoMa.

### Extracting a certificate fingerprint manually (for verification)

```bash
openssl s_client -connect cloud.example.com:443 </dev/null 2>/dev/null \
  | openssl x509 -fingerprint -sha256 -noout
```

---

## Nextcloud — "Insufficient storage" error

The Nextcloud user account has reached its storage quota. Free up space on the server or ask the admin to increase the quota. AWoMa uploads a complete ZIP of all artworks and photos on each sync.

---

## Android — WorkManager / background sync not firing

Background sync is only scheduled on **Android API 33+**. Check the device API level via Settings → About phone → Android version.

On Android 12+ the system may restrict exact alarms. If auto-sync seems to drift or not fire:
- Open Settings → Apps → AWoMa → Alarms & reminders and ensure AWoMa is allowed.
- Some OEM ROMs (Xiaomi MIUI, Samsung One UI) have aggressive background-process killers. Add AWoMa to the battery optimisation whitelist.

---

## Android — install conflict (debug vs release APK)

**Symptom:** `adb install` fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

**Cause:** A debug APK (signed with the debug keystore) and a release APK (signed with the release keystore) cannot be installed side-by-side because Android treats them as different apps.

**Fix:** Uninstall the existing APK first, or use `adb install -r --allow-version-downgrade` if signatures match.

---

## Database — migration crash on first launch after upgrade

**Symptom:** App crashes immediately after an update with a Drift/SQLite exception.

**Cause:** A schema migration step was skipped or the `schemaVersion` was not bumped correctly.

**Fix for development:** Uninstall the app (this deletes the database) and re-install the updated build. For production, ensure every schema change follows the four-step migration rule in `CLAUDE.md`.

---

## Exchange rates — dashboard shows "–" instead of converted total

**Cause:** The Frankfurter API was unreachable and no cached rates exist for the selected base currency.

**Fix:** Connect to the internet and navigate away from and back to the dashboard to trigger a fresh fetch. The cache is per base currency and lives in the system temp directory (`rates_<BASE>.json`).

---

## PDF export — garbled or missing photos

**Cause:** The photo file is missing from the app documents directory (e.g., the artwork was restored from a backup that did not include all photos, or the file was deleted externally).

**Fix:** Re-add the photo via Edit artwork. AWoMa logs a warning (`BackupService: N file(s) missing during export`) when a photo cannot be found during backup — check **Settings → App logs**.

---

## Local backup export — file not saved on Android

**Cause:** AWoMa uses the system share sheet (`open_filex` / `XFile.saveTo`) to hand the ZIP to a file manager or Files app. The file is saved by the receiving app, not AWoMa.

**Fix:** Choose **Save to Files** (or your file manager of choice) in the share sheet. On Android 10+ the ZIP lands in `Downloads/` by default.

---

## App logs

AWoMa writes all service-layer events to a rolling log file trimmed to 2000 lines.

**Location:** `<app documents>/app_logs.txt`

**View/export:** Settings → App logs → share icon (top-right)

All errors include a stack trace. When reporting a bug, attach the exported log.
