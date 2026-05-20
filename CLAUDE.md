# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Overview

This repository contains **two separate apps**:

| Directory | App | Status |
|-----------|-----|--------|
| `app/` + root `build.gradle` | Original Android (Kotlin/MVVM/Room) | Legacy — see `doc/` for its architecture |
| `flutter_app/` | Flutter cross-platform rewrite | **Active development target** |

All day-to-day work happens in `flutter_app/`. The Kotlin app is the reference for feature parity but is not modified.

---

## Flutter App — Commands

All commands run from `flutter_app/`:

```bash
# Install dependencies
flutter pub get

# REQUIRED after any change to app_database.dart, any DAO, or any @DriftDatabase class:
dart run build_runner build --delete-conflicting-outputs

# Analyze (CI uses --fatal-infos; use --no-fatal-infos locally to ignore info hints)
flutter analyze --no-fatal-infos

# Run all tests
flutter test

# Run a single test file
flutter test test/backup_service_test.dart

# Run a single named test
flutter test --name "round-trip preserves artwork fields"

# Build debug APK
flutter build apk --debug

# Build Linux release
flutter build linux --release

# Build macOS release
flutter build macos --release
```

> **Important:** The local Flutter SDK (3.32.x) is older than CI (stable channel, 3.44+). A handful of analyzer errors for `RadioGroup` and `DropdownButtonFormField.initialValue` appear locally but are valid on CI — do not "fix" these.

---

## Flutter App — Architecture

### Tech Stack

| Concern | Library |
|---------|---------|
| State management | Riverpod 2 (`flutter_riverpod`) — manual providers, no code generation |
| Navigation | `go_router` |
| Database | Drift (SQLite ORM) — all generated code in `*.g.dart` |
| HTTP | Dio |
| Background sync | WorkManager (`workmanager`) — Android only, no-op on macOS/Linux/iOS/Windows |
| Secure storage | `flutter_secure_storage` (Keychain / Keystore) |
| Permissions | `permission_handler` |
| PDF export | `pdf` + `printing` (`PdfGoogleFonts.notoSans*` for cross-platform fonts) |
| App version | `package_info_plus` (About tile in Settings) |
| Logging | `AppLogger` (custom, see `lib/core/services/app_logger.dart`) |

### Module Structure

```
flutter_app/lib/
├── main.dart                      Entry point; WorkManager init + callbackDispatcher
├── app.dart                       GoRouter config + ArtworksManagerApp (MaterialApp.router)
├── core/
│   ├── database/
│   │   ├── app_database.dart      Drift @DriftDatabase, table definitions, schema migrations
│   │   ├── app_database.g.dart    Generated — do not edit
│   │   ├── database_provider.dart databaseProvider (Riverpod Provider<AppDatabase>)
│   │   └── daos/                  ArtworksDao, PhotosDao, SettingsDao + their *.g.dart
│   ├── models/
│   │   ├── artwork_constants.dart SortBy enum + kDefaultRemotePath constant
│   │   └── currency.dart          Currency enum (EUR/USD/NOK/ZAR)
│   ├── services/
│   │   ├── app_logger.dart        File logger: AppLogger.info/warn/error(); fire-and-forget
│   │   ├── backup_service.dart    ZIP export/import; BackupService.generateFilename()
│   │   ├── exchange_rate_service.dart  Frankfurter API + 24h disk cache + AppLogger
│   │   ├── nextcloud_service.dart WebDAV client; sealed NcResult<T> (NcSuccess/NcFailure/NcTransient)
│   │   ├── pdf_exporter.dart      A4 PDF: one page per artwork, EXIF-corrected photo, Noto Sans
│   │   ├── secure_credentials_service.dart  Nextcloud password via flutter_secure_storage
│   │   └── sync_worker.dart       WorkManager background task; uses AppDatabase.openForIsolate()
│   └── widgets/
│       ├── error_view.dart        Shared error display widget
│       └── photo_strip.dart       Horizontal scrolling photo strip
├── features/
│   ├── dashboard/                 DashboardScreen, dashboard_providers.dart
│   ├── collection/                CollectionScreen, collection_providers.dart
│   ├── addedit/                   AddEditScreen (add + edit combined)
│   ├── detail/                    DetailScreen, detail_providers.dart
│   ├── settings/                  SettingsScreen, LogsScreen, settings_providers.dart
│   └── nextcloud/                 NextcloudScreen (credentials + auto-sync config)
└── shell/
    └── adaptive_shell.dart        Bottom nav / NavigationRail adaptive wrapper
```

### Data Flow

```
Drift (SQLite)
  └─ Stream<T> from DAO watch*() methods
       └─ StreamProvider (Riverpod)
            └─ ConsumerWidget.ref.watch(provider)
                 └─ build() rebuilds automatically on new data
```

One-shot reads use `getAll()` / `get()` on DAOs (Future, not Stream).

Mutations: widgets call `ref.read(databaseProvider).someDao.method()` directly, or go through a service class.

### Database

`AppDatabase` (Drift) has three tables: **Artworks**, **ArtworkPhotos**, **Settings**.

- **Schema version 5** — migrations defined in `app_database.dart`
- Always run `build_runner` after any schema change
- `AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()))` for in-memory tests
- `AppDatabase.openForIsolate()` for WorkManager background tasks (direct `NativeDatabase`, not `createInBackground`, because the task is already in its own isolate)
- `Settings` is a single-row table (id=1); `SettingsDao.get()` creates the row on first call; `SettingsDao.save(SettingsCompanion(...))` does a partial UPDATE — call `get()` first if the row may not yet exist

### Provider Conventions

- `databaseProvider` — app-lifetime singleton, not autoDispose
- `settingsProvider` — `StreamProvider<Setting>` in `settings_providers.dart`
- `packageInfoProvider` — `FutureProvider<PackageInfo>` in `settings_providers.dart`; used by About tile
- `filteredArtworksProvider` — `StreamProvider` combining DB stream + `CollectionFilter` state
- `collectionFilterProvider` — `StateProvider<CollectionFilter>` with fields: `search`, `medium`, `condition`, `sortBy`, `isGrid`
- `portfolioValueProvider` — synchronous `Provider` that composes `priceTotalsProvider` + `exchangeRatesProvider`
- `exchangeRatesProvider` — `FutureProvider.family<Map<String,double>?, String>` keyed by base currency; calls `ExchangeRateService().fetchRates(base)` (instance class with injectable `Dio`/`apiBase`)
- `ratesCacheTimeProvider` — `FutureProvider.family<DateTime?, String>` for stale-rates hint

### Navigation (GoRouter)

Three shell branches (bottom nav): `/dashboard`, `/collection`, `/settings`.

Sub-routes: `/collection/artwork/:id`, `/collection/add`, `/collection/edit/:id`, `/settings/nextcloud`, `/settings/logs`.

### Background Sync (Android only)

`callbackDispatcher` (marked `@pragma('vm:entry-point')`) is the WorkManager entry point registered in `main()`. `SyncWorker.taskName = 'nc_auto_backup'` is the task identifier. Auto-sync is only scheduled on Android API ≥ 33 (checked at runtime via `device_info_plus`).

`Workmanager().initialize()` is guarded by `Platform.isAndroid` in `main.dart` — calling it on Windows/Linux/macOS throws `MissingPluginException` because the package has no implementation for those platforms.

The core logic lives in the top-level `runSyncTask({db, backupService, nextcloudService, settings, password})` function in `sync_worker.dart`; `SyncWorker.run()` is a thin wrapper that opens the DB and reads credentials before delegating. This makes the sync logic unit-testable without WorkManager.

### Nextcloud / Security

- Password stored in `flutter_secure_storage` via `SecureCredentialsService` — never in the DB
- Certificate pinning via SHA-256 fingerprint in `NextcloudService._buildDio()`
- `NcResult<T>` sealed class: `NcSuccess(value)`, `NcFailure(message)`, `NcTransient()` (retry)
- `_mapDioError` handles 401 and 507 explicitly; all other errors → `NcFailure(e.message)`

### Logging

`AppLogger` writes to `app_logs.txt` in the app documents directory, trimmed to 2000 lines. All service-layer catches must log via `AppLogger.error(message, err, stackTrace)`. The log file is viewable and exportable at **Settings → App logs**.

---

## Tests

Test files live in `flutter_app/test/`:

| File | Coverage |
|------|----------|
| `backup_service_test.dart` | ZIP export/import, generateFilename, condition/provenance round-trip |
| `collection_filter_test.dart` | CollectionFilter (search, medium, condition, sortBy, isGrid), SortBy enum |
| `database_migration_test.dart` | Schema defaults, settings save/clear, artworks CRUD |
| `app_logger_test.dart` | info/warn/error writes; readRecent order + limit; getFile null/non-null; clear |
| `exchange_rate_service_test.dart` | cacheModifiedTime (null/DateTime/per-base); fetchRates success, cache write, network fallback, null-when-no-cache, non-200 fallback — via real loopback HttpServer + fake path_provider |
| `nextcloud_service_test.dart` | NcResult types; verifyCredentials (200/401/500/refused); listFiles PROPFIND parsing; uploadBackup (201/204/507) — all via real loopback HttpServer |
| `pdf_exporter_test.dart` | Currency.fromCode, fallback, symbols, codes; PdfExporter.fmtDim (integer/fractional/rounding) |
| `sync_worker_test.dart` | runSyncTask: skip conditions; success records lastSyncAt; failures record lastSyncError; pruning logic; error cleared on success — using fake services + in-memory DB |
| `widget_test.dart` | Empty placeholder (widget/integration tests require a device) |

When writing DB tests: import `drift/drift.dart` with `hide isNull, isNotNull` to avoid matcher conflicts with `package:matcher`.

---

## Schema Migration Rules

When adding a column to any table:
1. Declare it in `app_database.dart`
2. Bump `schemaVersion`
3. Add `m.addColumn(table, table.column)` in the appropriate `if (from < N)` block
4. Update the fallback `Setting(...)` literal in `SettingsDao.watch()`
5. Run `build_runner`

---

## CI Pipeline

`.github/workflows/flutter_ci.yml` runs on pushes to `main`, `develop`, and `feature/**`:

1. **analyze** — `flutter analyze --fatal-infos` + `flutter test`
2. **build-android** (needs analyze) — debug APK
3. **build-linux** (needs analyze) — requires `libsecret-1-dev libjsoncpp-dev` apt packages
4. **build-macos** (needs analyze) — macOS runner, sandbox disabled for CI

Working directory for all steps is `flutter_app/`. Code generation runs before analyze and build.
