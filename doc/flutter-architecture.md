# Flutter App — Architecture

> This document covers `flutter_app/` — the active cross-platform rewrite.
> For the original Kotlin/Android app see `doc/architecture.md`.

---

## Pattern

The app follows a **reactive-stream architecture** using Riverpod 2 as the state container. Data lives in a Drift (SQLite) database; all UI rebuilds are triggered by database streams rather than manual `setState` calls.

```
┌────────────────────────────────────────────────────────┐
│                       UI Layer                         │
│  ConsumerWidget / ConsumerStatefulWidget               │
│    └─ ref.watch(someProvider)                          │
└───────────────────────┬────────────────────────────────┘
                        │ rebuild on new value
┌───────────────────────▼────────────────────────────────┐
│                   Provider Layer (Riverpod)             │
│  StreamProvider / FutureProvider / Provider            │
│    └─ watches DAO stream or composes other providers   │
└───────────────────────┬────────────────────────────────┘
                        │ SQL query / suspend call
┌───────────────────────▼────────────────────────────────┐
│                    Data Layer (Drift)                   │
│  DAO.watch*()  →  Stream<T>  (auto-emits on write)     │
│  DAO.get*()    →  Future<T>  (one-shot read)           │
│  DAO.insert/update/delete → mutation                   │
└────────────────────────────────────────────────────────┘
```

One-shot reads (PDF export, backup, WorkManager task) call `DAO.get*()` or `DAO.getAll()` directly as `Future`s. Mutations are called via `ref.read(databaseProvider).someDao.method()` directly from the widget or via a service class.

---

## Technology Stack

| Concern | Library | Version |
|---------|---------|---------|
| Language | Dart | 3.3+ |
| UI framework | Flutter | 3.32+ (local), 3.44+ (CI) |
| State management | Riverpod 2 (`flutter_riverpod`) | 2.5.1 |
| Navigation | `go_router` | 14.2.7 |
| Database ORM | Drift (SQLite) | 2.18.0 |
| HTTP | Dio | 5.4.3 |
| Background sync | WorkManager (`workmanager`) | 0.6.0 — Android only, no-op elsewhere |
| Secure storage | `flutter_secure_storage` | 9.2.2 |
| Permissions | `permission_handler` | 11.3.1 |
| PDF generation | `pdf` + `printing` | 3.11.1 / 5.13.2 |
| File picking | `file_picker`, `image_picker` | 8.1.0 / 1.1.2 |
| File opening | `open_filex` | 4.4.1 |
| ZIP I/O | `archive` | 3.6.1 |
| Exchange rates | Frankfurter API (ECB, free, no key) | — |
| Logging | `AppLogger` (custom) | — |
| Fonts (PDF) | `PdfGoogleFonts.notoSans*` | embedded by `printing` |

---

## Module Structure

```
flutter_app/lib/
├── main.dart                      Entry point: Flutter engine init, WorkManager
│                                  callbackDispatcher registration, runApp()
├── app.dart                       GoRouter config + ArtworksManagerApp (MaterialApp.router)
│
├── core/
│   ├── database/
│   │   ├── app_database.dart      @DriftDatabase: Artworks, ArtworkPhotos, Settings tables
│   │   │                          MigrationStrategy (v1→v2→v3), openForIsolate() for WorkManager
│   │   ├── app_database.g.dart    Generated — do not edit
│   │   ├── database_provider.dart databaseProvider (Riverpod Provider<AppDatabase>; app-lifetime singleton)
│   │   └── daos/
│   │       ├── artworks_dao.dart  watch*, getAll(), get(), insert, update, delete, replaceAll
│   │       ├── photos_dao.dart    watchForArtwork(), getForArtwork(), insert*, deleteById/ForArtwork
│   │       └── settings_dao.dart  watch(), get() [creates row on first call], save(SettingsCompanion)
│   │
│   ├── models/
│   │   ├── artwork_constants.dart artworkTypes (8), artworkMediums (18), SortBy enum, kDefaultRemotePath
│   │   └── currency.dart          Currency enum: EUR/USD/NOK/ZAR; fromCode() factory
│   │
│   ├── services/
│   │   ├── app_logger.dart        File logger (app_logs.txt, 2000-line trim)
│   │   │                          AppLogger.info/warn/error() — all fire-and-forget
│   │   │                          readRecent(lines), getFile(), clear()
│   │   ├── backup_service.dart    ZIP export: artworks.json + photos/
│   │   │                          ZIP import: parse JSON, extract files, ZIP-slip protection
│   │   │                          BackupData return type; generateFilename()
│   │   ├── exchange_rate_service.dart  Frankfurter API, 24h disk cache, stale fallback
│   │   │                          fetchRates(base) → Map<String,double>?
│   │   │                          cacheModifiedTime(base) → DateTime?
│   │   ├── nextcloud_service.dart WebDAV client (Dio-based)
│   │   │                          NcResult<T> sealed class: NcSuccess / NcFailure / NcTransient
│   │   │                          verifyCredentials, uploadBackup, downloadFile, listFiles, deleteFile
│   │   │                          SHA-256 cert fingerprint validation (optional)
│   │   ├── pdf_exporter.dart      A4 PDF; one page per artwork; EXIF-corrected photos via
│   │   │                          flutterImageProvider(FileImage()); Noto Sans fonts
│   │   ├── secure_credentials_service.dart  Nextcloud password via flutter_secure_storage
│   │   │                          readPassword, writePassword, clearPassword
│   │   └── sync_worker.dart       WorkManager entry point (Android only, API 33+)
│   │                              AppDatabase.openForIsolate() (direct NativeDatabase — task
│   │                              already runs in its own isolate, no nested isolate needed)
│   │                              Saves lastSyncAt (success) or lastSyncError (failure) to DB
│   │
│   └── widgets/
│       ├── error_view.dart        Shared error display widget
│       └── photo_strip.dart       Horizontal scrolling photo strip (add + delete callbacks)
│
├── features/
│   ├── dashboard/
│   │   ├── dashboard_providers.dart  artworkCountProvider, recentArtworksProvider,
│   │   │                            mediumCountsProvider, topArtistsProvider,
│   │   │                            priceTotalsProvider, exchangeRatesProvider(base),
│   │   │                            ratesCacheTimeProvider(base), portfolioValueProvider
│   │   └── dashboard_screen.dart  Stats, medium chart, top artists, recent strip,
│   │                              portfolio value with stale-rates hint
│   ├── collection/
│   │   ├── collection_providers.dart  collectionFilterProvider (StateProvider<CollectionFilter>)
│   │   │                             filteredArtworksProvider, distinctMediumsProvider
│   │   ├── collection_screen.dart    Grid/list toggle, search, filter, sort
│   │   └── widgets/artwork_card.dart  Grid and list card renderer
│   ├── addedit/
│   │   └── addedit_screen.dart    Add + edit combined form; camera/gallery/file picker;
│   │                              certificate picker; additional photos strip; unsaved-changes guard
│   ├── detail/
│   │   ├── detail_providers.dart  artworkByIdProvider(id), photosByArtworkProvider(id)
│   │   └── detail_screen.dart     Read-only view; certificate opener via open_filex
│   ├── settings/
│   │   ├── settings_providers.dart  settingsProvider (StreamProvider<Setting>)
│   │   ├── settings_screen.dart     Currency picker, PDF export, Nextcloud status tiles,
│   │   │                           sync error / overdue warning tiles, logs link
│   │   └── logs_screen.dart         Last 300 log lines; color-coded; export; clear
│   └── nextcloud/
│       └── nextcloud_screen.dart  Credentials form (URL, username, password, remote path,
│                                  cert fingerprint); keep-last-N; auto-sync config;
│                                  test connection, backup now, restore from cloud/file
│
└── shell/
    └── adaptive_shell.dart        BottomNavigationBar (< 600 dp) / NavigationRail (≥ 600 dp)
                                   Extended rail at ≥ 1200 dp
```

---

## Database Schema (Drift / SQLite)

**Schema version: 3**

### Artworks

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | INTEGER PK autoincrement | — | — |
| `title` | TEXT | — | — |
| `artist` | TEXT | — | `''` |
| `year` | INTEGER | ✓ | — |
| `type` | TEXT | — | `''` |
| `medium` | TEXT | — | `''` |
| `heightCm` | REAL | ✓ | — |
| `widthCm` | REAL | ✓ | — |
| `depthCm` | REAL | ✓ | — |
| `location` | TEXT | — | `''` |
| `acquisitionDate` | INTEGER | ✓ | — | Unix ms |
| `currency` | TEXT | — | `''` | empty = use global |
| `purchasePrice` | REAL | ✓ | — |
| `description` | TEXT | — | `''` |
| `photoPath` | TEXT | — | `''` |
| `certificatePath` | TEXT | — | `''` |
| `createdAt` | INTEGER | — | `now()` client-side |

### ArtworkPhotos

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER PK autoincrement | — |
| `artworkId` | INTEGER FK → Artworks.id | CASCADE delete |
| `photoPath` | TEXT | — |
| `sortOrder` | INTEGER | default 0 |

### Settings (single row, id = 1)

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `id` | INTEGER PK | 1 | Always id=1 |
| `currency` | TEXT | `'EUR'` | Global display currency |
| `nextcloudUrl` | TEXT | `''` | |
| `nextcloudUsername` | TEXT | `''` | |
| `nextcloudPassword` | TEXT | `''` | **Vestigial** — password stored in `flutter_secure_storage` |
| `nextcloudPath` | TEXT | `'ArtworksManager'` | Remote directory |
| `nextcloudCertFingerprint` | TEXT | `''` | SHA-256 hex; empty = no pinning |
| `nextcloudKeepExports` | INTEGER | 5 | Max files to keep on server |
| `lastSyncAt` | INTEGER? | — | Unix ms of last successful sync |
| `lastSyncError` | TEXT? | — | Last sync failure message (v3) |
| `autoSyncEnabled` | BOOLEAN | `false` | (v2) |
| `autoSyncIntervalHours` | INTEGER | 24 | 24 / 48 / 168 (v2) |

### Migration history

| Version | Change |
|---------|--------|
| 1 | Initial schema (Artworks, ArtworkPhotos, Settings) |
| 2 | Added `autoSyncEnabled`, `autoSyncIntervalHours` to Settings |
| 3 | Added `lastSyncError` to Settings |

---

## Navigation (GoRouter)

Three shell branches sharing `AdaptiveShell` (bottom nav / rail):

```
/dashboard
/collection
  /collection/add
  /collection/edit/:id
  /collection/artwork/:id
/settings
  /settings/nextcloud
  /settings/logs
```

---

## Reactive Data Flow

```
Drift SQLite (background isolate via NativeDatabase.createInBackground)
  └─ DAO.watch*() → Stream<T>   (emits on every relevant write)
       └─ StreamProvider / FutureProvider (Riverpod)
            └─ ref.watch(provider) in ConsumerWidget.build()
                 └─ widget tree rebuilds automatically
```

Mutations reach the DB via `ref.read(databaseProvider).someDao.someMethod()`.

---

## Collection Value & Exchange Rates

```
portfolioValueProvider (Provider)
  ├─ priceTotalsProvider → ArtworksDao.watchPriceTotals()   GROUP BY currency
  ├─ settingsProvider    → SettingsDao.watch()              base currency
  └─ exchangeRatesProvider(base) → ExchangeRateService.fetchRates(base)
       ├─ live: https://api.frankfurter.app/latest?base=<code>
       └─ fallback: 24h disk cache in Documents dir
```

`ratesCacheTimeProvider(base)` reads the cache file mtime; Dashboard shows "Rates from Xh ago" when cache age > 1 hour.

---

## Backup System

### Manual (in-app share sheet)

```
NextcloudScreen / SettingsScreen
  └─ BackupService.exportToZip(artworks, photosByArtwork)
       ├─ artworks.json   all metadata; ISO 8601 dates; additionalPhotos array
       └─ photos/         cover photos, additional photos, certificate PDFs
  └─ Printing.sharePdf / FilePicker.saveFile    native share / save dialog
```

### Import

```
NextcloudScreen (file picker or cloud download)
  └─ BackupService.importFromBytes(bytes)
       ├─ ZipDecoder: extract photos/ → Documents/artworks/
       │   (ZIP-slip protection: canonicalPath.startsWith(base))
       └─ parse artworks.json → List<ArtworksCompanion> + List<ArtworkPhotosCompanion>
  └─ ArtworksDao.replaceAll(artworks, photos)   @Transaction: deleteAll + insertAll
```

### Nextcloud Auto-Sync (Android 13+ only)

```
main.dart: WorkManager.initialize(callbackDispatcher)
  └─ callbackDispatcher → SyncWorker.run()
       ├─ AppDatabase.openForIsolate()   direct NativeDatabase (task already in own isolate)
       ├─ ArtworksDao.getAll() + PhotosDao.getAll()
       ├─ BackupService.exportToZip(...)
       ├─ NextcloudService.uploadBackup(...)
       ├─ NextcloudService.listFiles() + deleteFile()   prune old backups
       └─ SettingsDao.save(lastSyncAt / lastSyncError)
```

Scheduling is managed by `NextcloudScreen` via `Workmanager.registerPeriodicTask` (daily / 48h / weekly). Only registered on Android API ≥ 33 (checked via `device_info_plus`).

---

## PDF Export

```
PdfExporter(defaultCurrencyCode: code)
  └─ generate(artworks) → Uint8List
       ├─ pw.Document with Noto Sans (PdfGoogleFonts)
       └─ for each artwork:
            ├─ flutterImageProvider(FileImage(file))   EXIF-corrected via Flutter pipeline
            └─ pw.Page (A4, 40pt margins)
                 ├─ Photo (ConstrainedBox maxH=220, BoxFit.contain)
                 ├─ Title (20pt bold, primary colour 0xFF5C6BC0)
                 ├─ Artist · Year (13pt, subtitle colour 0xFF6E6E73)
                 ├─ Divider (0xFFE0DED9)
                 └─ Fields: Type, Medium, Dimensions, Location,
                            Acquired, Price (symbol + formatted), Description
```

---

## Nextcloud / Security

| Concern | Approach |
|---------|----------|
| Password at rest | `flutter_secure_storage` → Android Keystore / iOS Keychain / macOS Keychain |
| Self-signed certs | SHA-256 fingerprint field; `BadCertificateHandler` in `NextcloudService._buildDio()` |
| Trust-all option | Not supported in Flutter app — fingerprint is the explicit trust mechanism |
| WebDAV upload | PUT with Basic Auth; MKCOL for parent dir; configurable remote path |
| Backup pruning | Keep last N (`nextcloudKeepExports`); oldest files deleted after each successful upload |

---

## Logging

`AppLogger` appends to `Documents/app_logs.txt`. Auto-trims to 2000 lines on each write. Levels: `INFO`, `WARN`, `ERROR`. Format: `[yyyy-MM-dd HH:mm:ss.SSS] [LEVEL] message`. Errors include the exception toString and full stack trace. All calls are fire-and-forget (`unawaited` internally). The log file is viewable and exportable at **Settings → App logs**.

---

## Adaptive Shell

`AdaptiveShell` switches layout at runtime:

| Viewport width | Navigation widget |
|---------------|-------------------|
| < 600 dp | `BottomNavigationBar` (3 destinations) |
| 600–1199 dp | `NavigationRail` (compact, icon only) |
| ≥ 1200 dp | `NavigationRail` (extended, icon + label) |

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Drift Streams → StreamProvider | Room-equivalent automatic UI refresh on every DB write; no manual refresh |
| Riverpod `Provider` for portfolio value | Synchronous composition of three async providers; avoids waterfall loading states |
| `FutureProvider.family` for exchange rates | Keyed by base currency; Riverpod caches per key for the widget lifetime |
| `NativeDatabase.createInBackground` for app | Offloads SQLite I/O to a background isolate automatically |
| `NativeDatabase` direct for SyncWorker | WorkManager task already runs in its own isolate; wrapping in `createInBackground` would spawn a third isolate unnecessarily |
| `flutterImageProvider` for PDF photos | Routes through Flutter's image pipeline; EXIF orientation applied on Android/iOS without manual EXIF parsing |
| `PdfGoogleFonts.notoSans*` | Single cross-platform font that embeds automatically; no platform font dependency |
| `flutter_secure_storage` for password | Uses platform Keystore / Keychain; password never written to SQLite |
| SHA-256 fingerprint over trust-all | Explicit trust model; avoids MITM risk of a blanket trust-all certificate handler |
| `NcResult<T>` sealed class | Distinguishes permanent failure (NcFailure) from transient network error (NcTransient) to drive retry UI |
| `BackupService` throws on missing files | Strict: a backup containing broken file references is not created at all |
| Single-row Settings table (id=1) | Simplest persistent key-value store for typed settings without JSON serialisation |
| `SettingsDao.get()` creates row on first access | Ensures the row exists before any save(); callers never need to check for null |
| `CollectionFilter` StateProvider | Ephemeral filter/sort state lives in Riverpod (no DB round-trip); resets on provider disposal |
