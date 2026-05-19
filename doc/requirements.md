# App Requirements

> **Implementation status**
> The original Kotlin/Android app (`app/`) fulfils the v1 requirements below.
> The Flutter cross-platform rewrite (`flutter_app/`) is the active development target and adds the extensions described in the [Flutter Rewrite Extensions](#flutter-rewrite-extensions) section.

## Overview

A personal artwork catalogue app for a private collector. The app gives the owner a clear overview of their collection and lets them record, browse, and manage up to 1000 artworks from their Android device.

## Target Users

A single private individual who owns a personal art collection of up to 1000 artworks and wants a simple, organised way to catalogue and review it.

## Core Features

- **Add artwork** — record a new artwork with the following details:
  - Title
  - Artist name
  - Year of creation
  - Type (Painting, Drawing, Photography, Sculpture, Print, Book, Textile, Ceramics, Other)
  - Medium / technique (e.g. oil on canvas, watercolour, sculpture)
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
- **Filter & sort** — filter by medium; sort by title, artist, or acquisition date
- **Dashboard / overview** — summary statistics:
  - Total number of artworks
  - Breakdown by medium
  - Breakdown by artist
  - Recently added strip
  - **Collection Value card** — per-currency purchase price subtotals; when an internet connection is available, a grand total converted to the preferred currency using live ECB exchange rates (Frankfurter API); graceful offline fallback shows subtotals only
- **Export to PDF** — generate a printable PDF of the full catalogue; each artwork gets its own page with photo (orientation-corrected), title, artist, year, and all recorded fields
- **Export backup** — create a zip archive containing `artworks.json` (all artwork records as human-readable JSON, including additional photo references) and all artwork photos; the archive can be saved to any location supported by the Android Storage Access Framework
- **Import backup** — restore the collection (artworks + additional photos) from a previously exported backup zip; replaces the entire current collection after user confirmation
- **Multiple photos per artwork** — a cover photo plus any number of additional photos stored in a separate table; displayed as a horizontal strip in both the detail view and the add/edit form
- **Certificate of authenticity** — optionally attach a PDF certificate to any artwork via the Android Storage Access Framework; the file is copied to on-device internal storage; the detail view provides a "View certificate" button that opens the PDF in any installed PDF viewer; certificates are included in zip backups and restored on import
- **Nextcloud backup** — connect to a Nextcloud server using an app-specific password; supports self-signed / untrusted certificates via an opt-in "Trust self-signed certificates" checkbox; the full collection (artworks + photos) is automatically uploaded once a day via WebDAV to `ArtworksManager/artworks_backup.zip` on the server when a network connection is available; a "Back up now" button triggers an immediate upload with a success or failure toast; the last backup timestamp is shown on the Nextcloud settings screen; the app remains fully functional without a Nextcloud connection

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
4. **Add / Edit artwork** — form with all fields, cover photo picker/camera, additional photo strip with add/remove (photos can also be picked from cloud storage), a certificate PDF picker (attach / remove), and a save button
5. **Settings** — currency preference, export PDF, export/import zip backup, Nextcloud backup row (shows connected/not-connected status; navigates to sub-screen), about info (version, license)
6. **Nextcloud settings** — sub-screen for entering server URL, username, app password, and a "Trust self-signed certificates" checkbox; connect/disconnect; "Back up now" button (shows success or failure toast) and last backup timestamp (shown when connected)

## Settings / Preferences

- **Global currency** — the default currency used to display purchase prices throughout the app (form prefix, detail view, PDF export, collection value total); supported values: EUR (€), USD ($), NOK (kr), ZAR (R); selection is persisted across app restarts; easy to extend (one-line enum change)
- **Per-artwork currency** — each artwork can store its own currency code; when set it overrides the global preference for that artwork's price display

## Non-Functional Requirements

- **Min Android version:** Android 13 (API 33)
- **Target devices:** Android smartphones (portrait-first, tablet-friendly)
- **Offline support:** Full offline operation is a hard requirement — all data stored locally; the app must work completely without an internet connection (live exchange rates are a best-effort enhancement only)
- **Storage:** Photos stored on-device in internal storage (`filesDir`); collection data in a local SQLite/Room database
- **Performance:** Collection list should load and scroll smoothly for up to 1000 artworks
- **Languages / localisation:** English (single language for initial version)
- **Accessibility:** Adequate contrast and content descriptions on images
- **Dark mode:** The app must follow the device system dark/light mode setting; all screens must be legible and visually consistent in both modes
- **Internet:** `INTERNET` and `ACCESS_NETWORK_STATE` permissions are declared; used for the optional live exchange rate fetch and, when configured, the Nextcloud backup upload

---

## Flutter Rewrite Extensions

The Flutter rewrite (`flutter_app/`) adds and changes the following relative to the Kotlin v1 requirements above.

### New Features

- **Cross-platform** — single codebase targets Android, macOS, and Linux (iOS supported by Flutter but no build config in repo; Windows out of scope)
- **Adaptive shell** — `BottomNavigationBar` on mobile (< 600 dp), `NavigationRail` on tablet/desktop (≥ 600 dp), extended rail with labels at ≥ 1200 dp
- **Diagnostic logs screen** (Settings → App logs) — view last 300 log lines color-coded by severity (INFO / WARN / ERROR); export log file; clear with confirmation
- **Configurable auto-sync interval** — daily (24 h), every 2 days (48 h), or weekly (168 h); previously fixed at daily
- **Keep last N backups** — configurable number of Nextcloud backups to retain (1–∞, default 5); older files are pruned automatically after each successful upload
- **Restore from Nextcloud** — browse and download specific backup files directly from the Nextcloud screen without leaving the app
- **Stale exchange-rates indicator** — Dashboard shows "Rates from Xh ago" when the cached rates are more than 1 hour old, so the user knows the portfolio value may be imprecise
- **Sync error tile** — Settings screen shows the last sync failure message as a distinct tile; cleared automatically on the next successful backup
- **Certificate fingerprint pinning** (replaces trust-all checkbox) — SHA-256 fingerprint field; empty = no pinning; avoids blanket MITM risk of the Kotlin trust-all approach
- **Nextcloud remote path** — configurable remote directory (default `ArtworksManager`); previously hard-coded
- **Sort by year** — collection can now be sorted by artwork year in addition to title, artist, and date added

### Changed Behaviours

| Area | Kotlin v1 | Flutter rewrite |
|------|-----------|-----------------|
| Nextcloud credential storage | `SharedPreferences` (plain text) | Password in platform Keystore/Keychain via `flutter_secure_storage` |
| Cert trust | Trust-all checkbox | SHA-256 fingerprint |
| Auto-sync scheduling | Fixed 1-day `PeriodicWorkRequest` | Configurable interval; Android 13+ only |
| Backup filename | `artworks_backup.zip` (single, overwritten) | Timestamped `artworks_yyyyMMdd_HHmmss.zip` with N-file retention |
| Exchange rate fallback | Return `null`; show "Offline" | Return 24h stale cache; show "Rates from Xh ago" |
| Settings screen structure | Single flat list | Grouped by section with `_SectionLabel` headers |

### Non-Functional Requirements (Flutter)

- **Min Android API:** 33 (background auto-sync); app runs on lower APIs but auto-sync is silently skipped
- **Target platforms:** Android, macOS, Linux (primary); iOS (Flutter-capable, no build config yet)
- **Storage:** Photos and DB in `getApplicationDocumentsDirectory()`; log file and rate cache in same dir (⚠ cache should move to temp dir — known issue)
- **Background sync:** WorkManager (`workmanager` package); no-op on non-Android platforms
- **Dark mode:** Flutter Material 3 `ColorScheme` with system brightness; all screens adapt automatically
