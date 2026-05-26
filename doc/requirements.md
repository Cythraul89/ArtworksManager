# App Requirements

> **Implementation status**
> The original Kotlin/Android app (`app/`) fulfils the v1 requirements below.
> The Flutter cross-platform rewrite (`flutter_app/`) is the active development target and adds the extensions described in the [Flutter Rewrite Extensions](#flutter-rewrite-extensions) section.

## Overview

A personal artwork catalogue app (display name **AWoMa**) for a private collector. The app gives the owner a clear overview of their collection and lets them record, browse, and manage up to 1000 artworks. All data is stored locally; an internet connection is never required.

## Target Users

A single private individual who owns a personal art collection of up to 1000 artworks and wants a simple, organised way to catalogue and review it.

## Core Features

- **Add artwork** — record a new artwork with the following details:
  - Title
  - Artist name
  - Year of creation
  - Type (Painting, Drawing, Print, Photography, Sculpture, Ceramics, Textile, Digital, Book, Other)
  - Medium / technique (18 options: oil on canvas, acrylic, watercolor, etc.)
  - Condition (Excellent, Good, Fair, Poor)
  - Provenance / ownership history (free text)
  - Dimensions (height × width × depth where applicable)
  - Cover photo + additional photos (taken with camera, selected from gallery, or picked from any cloud storage provider installed on the device via the Android Storage Access Framework)
  - Description / notes
  - Location (where the artwork is stored or displayed)
  - Acquisition date and purchase price
  - Per-artwork currency (overrides the global preference for that artwork)
- **Edit artwork** — update any detail of an existing artwork
- **Delete artwork** — remove an artwork and all its photos from the catalogue
- **Browse collection** — scrollable list/grid of all artworks with thumbnail, title, and artist
- **Artwork detail view** — full-screen view of all recorded details, the cover photo, and the additional photo strip
- **Search** — find artworks by title or artist name
- **Filter & sort** — filter by medium or condition; sort by title, artist, acquisition date, or year
- **Dashboard / overview** — summary statistics:
  - Total number of artworks
  - Breakdown by medium
  - Breakdown by artist
  - Recently added strip
  - **Collection Value card** — per-currency purchase price subtotals; when an internet connection is available, a grand total converted to the preferred currency using live ECB exchange rates (Frankfurter API); graceful offline fallback shows subtotals only
- **Export to PDF** — generate a printable PDF of the full catalogue; each artwork gets its own page with photo (orientation-corrected), title, artist, year, and all recorded fields
- **Local backup** — create a ZIP archive containing `artworks.json` (all artwork records as human-readable JSON, including additional photo references) and all artwork photos; the archive can be saved to any location via the native file-save dialog; the collection can be restored from any previously saved ZIP file
- **Nextcloud backup** — connect to a Nextcloud server using an app-specific password; supports self-signed / untrusted certificates via an opt-in SHA-256 certificate fingerprint field; the full collection (artworks + photos) is automatically uploaded on a configurable schedule via WebDAV to a configurable remote directory (default `AWoMa`) on the server when a network connection is available; a "Back up now" button triggers an immediate upload; the last backup timestamp is shown on the Settings screen; the app remains fully functional without a Nextcloud connection
- **Multiple photos per artwork** — a cover photo plus any number of additional photos stored in a separate table; displayed as a horizontal strip in both the detail view and the add/edit form
- **Certificate of authenticity** — optionally attach a PDF certificate to any artwork; the file is copied to on-device internal storage; the detail view provides a "View certificate" button that opens the PDF in any installed PDF viewer; certificates are included in ZIP backups and restored on import

## Nice to Have

- Tags / custom categories
- Export collection as CSV
- Estimated current value field separate from purchase price
- ~~Provenance / ownership history notes~~ — implemented in Flutter rewrite
- ~~Condition field (excellent, good, fair, poor)~~ — implemented in Flutter rewrite

## Out of Scope

- Multi-user access or sharing with others
- Mandatory cloud dependency (app must be fully functional without any internet connection)
- Public marketplace or valuation services
- Collections larger than 1000 artworks

## Screens / User Flows

1. **Dashboard** — entry point; shows total artwork count, quick stats by medium and artist, collection value card, recently-added strip, and a shortcut to add a new artwork
2. **Collection list** — grid or list of all artworks; supports search, filter, and sort; tapping an item opens the detail view
3. **Artwork detail** — displays the cover photo, additional photo strip, all recorded fields, and a "View certificate" button (shown only when a certificate is attached); action buttons to edit or delete
4. **Add / Edit artwork** — form with all fields, cover photo picker/camera, additional photo strip with add/remove, a certificate PDF picker (attach / remove), and a save button
5. **Settings** — currency preference, export PDF, local backup tile, Nextcloud tile (shows URL or "Not configured"), last backup timestamp, sync error tile, diagnostics (app logs), about (version, license)
6. **Local backup** — sub-screen with "Save backup" (export ZIP via native save dialog) and "Restore from file" (pick ZIP to restore from); accessible from Settings → Local backup
7. **Nextcloud** — sub-screen for entering server URL, username, app password, remote path, SHA-256 certificate fingerprint; "Test connection", "Backup now", "Restore from cloud"; auto-sync toggle (Android 13+ only) with configurable interval and keep-N-backups setting
8. **App logs** — view last 300 log lines colour-coded by severity; export log file; clear with confirmation

## Settings / Preferences

- **Global currency** — the default currency used to display purchase prices throughout the app (form prefix, detail view, PDF export, collection value total); supported values: EUR, USD, GBP, JPY, CHF, CAD, AUD, BRL, CZK, DKK, HKD, HUF, INR, KRW, MXN, NOK, NZD, PLN, SEK, SGD, ZAR; selection is persisted across app restarts
- **Per-artwork currency** — each artwork can store its own currency code; when set it overrides the global preference for that artwork's price display

## Non-Functional Requirements

- **Min Android version:** Android 6.0 (API 23); background auto-sync requires Android 13 (API 33) and is silently skipped on lower versions
- **Target platforms:** Android, iOS, macOS, Linux, Windows
- **Offline support:** Full offline operation is a hard requirement — all data stored locally; the app must work completely without an internet connection (live exchange rates are a best-effort enhancement only)
- **Storage:** Photos, DB, and log file in `getApplicationDocumentsDirectory()`; exchange-rate cache in `getTemporaryDirectory()`
- **Performance:** Collection list should load and scroll smoothly for up to 1000 artworks
- **Languages / localisation:** English (single language for initial version)
- **Accessibility:** Adequate contrast and content descriptions on images
- **Dark mode:** The app must follow the device system dark/light mode setting; all screens must be legible and visually consistent in both modes
- **Internet:** `INTERNET` permission declared; used for the optional live exchange rate fetch and, when configured, the Nextcloud backup upload

---

## Flutter Rewrite Extensions

The Flutter rewrite (`flutter_app/`) adds and changes the following relative to the Kotlin v1 requirements above.

### New Features

- **Cross-platform** — single codebase targets Android, iOS, macOS, Linux, and Windows
- **Adaptive shell** — `BottomNavigationBar` on mobile (< 600 dp), `NavigationRail` on tablet/desktop (≥ 600 dp), extended rail with labels at ≥ 1200 dp
- **Local backup screen** (Settings → Local backup) — dedicated screen to export a ZIP backup via the native save dialog and restore from a local ZIP file; not dependent on Nextcloud
- **Diagnostic logs screen** (Settings → App logs) — view last 300 log lines color-coded by severity (INFO / WARN / ERROR); export log file; clear with confirmation
- **Configurable auto-sync interval** — daily (24 h), every 2 days (48 h), or weekly (168 h); previously fixed at daily
- **Keep last N backups** — configurable number of Nextcloud backups to retain (1–∞, default 5); older files are pruned automatically after each successful upload
- **Restore from Nextcloud** — browse and download specific backup files directly from the Nextcloud screen without leaving the app
- **Stale exchange-rates indicator** — Dashboard shows "Rates from Xh ago" when the cached rates are more than 1 hour old, so the user knows the portfolio value may be imprecise
- **Sync error tile** — Settings screen shows the last sync failure message as a distinct tile; cleared automatically on the next successful backup
- **Certificate fingerprint pinning** (replaces trust-all checkbox) — SHA-256 fingerprint field; empty = no pinning; avoids blanket MITM risk of the Kotlin trust-all approach
- **Configurable Nextcloud remote path** — user-configurable remote directory (default `AWoMa`); previously hard-coded
- **Sort by year** — collection can now be sorted by artwork year in addition to title, artist, and date added
- **Ceramics and Book artwork types** — added alongside Painting, Drawing, Print, Photography, Sculpture, Textile, Digital, Other

### Changed Behaviours

| Area | Kotlin v1 | Flutter rewrite |
|------|-----------|-----------------|
| App name | ArtworksManager | AWoMa |
| Nextcloud credential storage | `SharedPreferences` (plain text) | Password in platform Keystore/Keychain via `flutter_secure_storage` |
| Cert trust | Trust-all checkbox | SHA-256 fingerprint |
| Auto-sync scheduling | Fixed 1-day `PeriodicWorkRequest` | Configurable interval; Android 13+ only |
| Backup filename | `artworks_backup.zip` (single, overwritten) | Timestamped `artworks_yyyyMMdd_HHmmss.zip` with N-file retention |
| Exchange rate fallback | Return `null`; show "Offline" | Return 24h stale cache; show "Rates from Xh ago" |
| Settings screen structure | Single flat list | Grouped by section with `_SectionLabel` headers |
| Local backup | Android SAF only | Native save/open dialog on all platforms |

### Non-Functional Requirements (Flutter)

- **Min Android API:** 23 (app runs on Android 6+); auto-sync requires API 33
- **Target platforms:** Android, iOS, macOS, Linux, Windows
- **Release pipeline:** Tag `v{major}.{minor}.{patch}` on `main` → GitHub Actions builds all platforms and publishes a GitHub Release with APK, Linux tar.gz, Windows zip, and macOS zip artifacts
- **License:** GNU General Public License v3.0; copyright Cythraul89
- **Storage:** Photos, DB, and log file in `getApplicationDocumentsDirectory()`; exchange-rate cache in `getTemporaryDirectory()`
- **Background sync:** WorkManager (`workmanager` package); no-op on non-Android platforms
- **Dark mode:** Flutter Material 3 `ColorScheme` with system brightness; all screens adapt automatically
