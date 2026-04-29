# Architecture

## Pattern

The app follows **MVVM (Model-View-ViewModel)** with a **single Activity** hosting all screens via the Android Navigation Component. There is no network layer — all data is local.

```
┌─────────────────────────────────────────────────┐
│                    UI Layer                     │
│  Fragment → ViewModel → Repository → DAO/Room  │
└─────────────────────────────────────────────────┘
           ↑ StateFlow / collect
┌─────────────────────────────────────────────────┐
│                   Data Layer                    │
│  Room Database ← DAO ← Repository              │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│                   Util Layer                    │
│  PdfExporter  BackupExporter  BackupImporter    │
└─────────────────────────────────────────────────┘
```

---

## Technology Stack

| Component              | Library / API                        | Version  |
|------------------------|--------------------------------------|----------|
| Language               | Kotlin                               | 2.0.21   |
| UI framework           | AndroidX Fragments + ViewBinding     | —        |
| Navigation             | Navigation Component + Safe Args     | 2.9.0    |
| Design system          | Material 3 (`DayNight.NoActionBar`)  | 1.12.0   |
| Database               | Room                                 | 2.7.1    |
| Annotation processor   | KSP                                  | 2.0.21-1.0.28 |
| Async                  | Kotlin Coroutines + Flow             | 1.10.2   |
| Image loading          | Glide                                | 4.16.0   |
| PDF generation         | `android.graphics.pdf.PdfDocument`   | built-in |
| EXIF reading           | `android.media.ExifInterface`        | built-in |
| JSON serialisation     | `org.json`                           | built-in |
| Backup I/O             | Storage Access Framework (SAF)       | built-in |
| Min SDK / Target SDK   | 33 / 35                              | —        |
| Build tools            | AGP 8.13.2 / Gradle 8.13             | —        |

---

## Package Structure

```
com.example.artworksmanager/
│
├── ArtworksManagerApp.kt          Application — database & repository singletons,
│                                  sets night-mode to follow system
│
├── data/
│   ├── Artwork.kt                 Room @Entity — the single data model
│   ├── ArtworkDao.kt              Room @Dao — all SQL + @Transaction operations
│   ├── ArtworkDatabase.kt         Room @Database — singleton via double-checked lock
│   ├── ArtworkRepository.kt       Single source of truth; exposes Flow to ViewModels
│   ├── AppPreferences.kt          SharedPreferences wrapper for user settings
│   └── Currency.kt                Enum of supported display currencies (EUR/USD/NOK/ZAR)
│
├── ui/
│   ├── MainActivity.kt            Single @Activity host; owns NavController &
│   │                              bottom nav; applies edge-to-edge insets
│   ├── addedit/
│   │   ├── AddEditFragment.kt     Add / Edit form; camera + gallery picker;
│   │   │                          IME inset handling; discard-changes dialog
│   │   └── AddEditViewModel.kt    Validates input; saves via repository;
│   │                              exposes savedId StateFlow for post-save navigation
│   ├── collection/
│   │   ├── ArtworkAdapter.kt      RecyclerView adapter; supports grid & list view modes
│   │   ├── CollectionFragment.kt  Search bar, filter chips, view-toggle FAB
│   │   ├── CollectionViewModel.kt Combines search query + filter/sort state
│   │   │                          into a single filtered Flow via combine()
│   │   └── FilterSortBottomSheet.kt  Bottom sheet for medium filter & sort order
│   ├── dashboard/
│   │   ├── DashboardFragment.kt   Stats cards + recent artwork strip
│   │   ├── DashboardViewModel.kt  Exposes count, medium counts, top artists,
│   │   │                          and recent artworks as StateFlows
│   │   └── RecentArtworkAdapter.kt  Horizontal RecyclerView adapter for the
│   │                               recently-added thumbnail strip
│   ├── detail/
│   │   ├── ArtworkDetailFragment.kt  Read-only detail view; edit / delete actions
│   │   └── ArtworkDetailViewModel.kt  Loads artwork by ID; exposes delete()
│   └── settings/
│       └── SettingsFragment.kt    PDF export, backup export, backup import,
│                                  Nextcloud placeholder, about info;
│                                  contains co-located SettingsViewModel
│
└── util/
    ├── BackupExporter.kt          Serialises List<Artwork> to JSON + copies photos
    │                              → writes zip directly to a SAF Uri
    ├── BackupImporter.kt          Reads a SAF Uri zip → extracts photos →
    │                              parses artworks.json → returns List<Artwork>
    └── PdfExporter.kt             Renders one A4 page per artwork using
                                   PdfDocument; corrects photo orientation via EXIF
```

---

## Data Layer

### Artwork entity

`Artwork` is the only Room entity. All fields except `id` and `title` are optional, supporting partial records. `photoPath` stores the absolute path within `filesDir/artworks/`; it is empty when no photo has been attached.

### DAO

`ArtworkDao` exposes two categories of operations:

| Category | Operations |
|----------|------------|
| **Reactive queries** (return `Flow`) | `getAllArtworks`, `getCount`, `getMediumCounts`, `getTopArtists`, `getRecentArtworks`, `getDistinctMediums` |
| **Suspend mutations** | `insert`, `insertAll`, `update`, `delete`, `deleteAll`, `replaceAll` |

`replaceAll` is annotated `@Transaction` so the delete-all + insert-all pair is atomic — no other writer can interleave.

### Repository

`ArtworkRepository` is a thin delegation layer. ViewModels never touch the DAO directly; this keeps the DAO swappable (e.g. for tests) and centralises data access.

### Database

`ArtworkDatabase` is a Room singleton initialised lazily in `ArtworksManagerApp`. The database file is named `artworks_db`.

---

## UI Layer

### Single Activity

`MainActivity` owns the `NavHostFragment` and the bottom navigation bar. It applies `WindowInsetsCompat` to:
- add `top` padding to the nav host (clears the status bar on Android 15 edge-to-edge)
- add `bottom` padding to the bottom nav (clears the navigation bar)
- **return `insets` unconsumed** so IME (keyboard) insets propagate to individual fragments

### ViewModels

Each screen has a dedicated ViewModel created via a `ViewModelProvider.Factory` that receives the repository from `ArtworksManagerApp`. ViewModels:
- hold `StateFlow` properties observed by their Fragment
- perform all suspend calls on `viewModelScope`
- never hold references to `Context` or `View`

### Navigation

Navigation Component with Safe Args is used throughout. The nav graph defines:
- Three top-level destinations (Dashboard, Collection, Settings) tied to the bottom nav
- `AddEditFragment` accepting an `artworkId: Int` argument (0 = new artwork)
- `ArtworkDetailFragment` accepting `artworkId: Int`

The bottom nav is hidden on non-top-level destinations via `addOnDestinationChangedListener`.

---

## Async / Reactive Data Flow

```
Room (IO thread)
  └─ Flow<List<Artwork>>
       └─ Repository (passes through)
            └─ ViewModel
                 ├─ stateIn(WhileSubscribed / Eagerly) → StateFlow
                 └─ Fragment.collect { updateUI() }
```

One-shot reads (e.g. for PDF/backup export) use `repository.getAllArtworks().first()` on `Dispatchers.IO` rather than reading the cached `StateFlow` value — this guarantees Room has emitted real data even on the very first call.

Mutations (`insert`, `update`, `delete`, `replaceAll`) are `suspend` functions called from `viewLifecycleOwner.lifecycleScope.launch { withContext(Dispatchers.IO) { … } }` in Fragments, or directly in `viewModelScope` in ViewModels.

---

## Backup System

### Export

```
SettingsFragment
  ├─ loadArtworksNow()           → suspend, Dispatchers.IO
  └─ BackupExporter.writeTo(uri, artworks)
       ├─ addJson()              serialises List<Artwork> to pretty-printed JSON
       │                         dates as yyyy-MM-dd / ISO-8601, photo field = filename only
       └─ addPhotoFiles()        streams each file from filesDir/artworks/ as a zip entry
```

The zip is written directly to the SAF `Uri` returned by `ActivityResultContracts.CreateDocument` — no temp file is needed.

### Import

```
SettingsFragment
  └─ BackupImporter.importFrom(uri)     Dispatchers.IO
       ├─ ZipInputStream pass           extracts photos → filesDir/artworks/
       │                                captures artworks.json bytes
       └─ parseArtworks()               reconstructs List<Artwork>
                                        resolves photoPath → extracted local file
  └─ SettingsViewModel.replaceAll(artworks)
       └─ ArtworkDao.replaceAll()       @Transaction: deleteAll + insertAll
```

---

## File Storage

| Location | Content | Access |
|----------|---------|--------|
| `filesDir/artworks/` | Artwork photos (`.jpg`) | Via `FileProvider` for sharing / camera |
| `cacheDir/` | Temporary PDF files | Via `FileProvider` for sharing |
| SAF Uri (user-chosen) | Backup zip | Via `ContentResolver` |

Photos are stored in `filesDir` (private internal storage) rather than external storage, avoiding the `READ/WRITE_EXTERNAL_STORAGE` permission. `FileProvider` is used whenever a Uri must be passed to another app (camera, share sheet).

---

## User Preferences

App-level preferences are stored in `SharedPreferences` via `AppPreferences`, which is initialised lazily in `ArtworksManagerApp` and accessible as `app.preferences` from any Fragment or utility class.

| Preference | Key | Default | Type |
|------------|-----|---------|------|
| Currency   | `currency` | `EUR` | `Currency` enum code |

`Currency` is an enum with `code`, `symbol`, `displayName`, and a computed `label` property. Adding a new currency is a one-line change in the enum — nothing else needs updating. The currency symbol is read at view-creation time in `AddEditFragment` (price prefix), `ArtworkDetailFragment` (price display), and `PdfExporter` (PDF price field).

## Dark Mode

The app uses `Theme.Material3.DayNight.NoActionBar` and calls `AppCompatDelegate.setDefaultNightMode(MODE_NIGHT_FOLLOW_SYSTEM)` at startup. Dark-mode colour overrides live in `res/values-night/colors.xml`. All colour references in layouts use `@color/` names so they resolve automatically to the correct palette at runtime.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Single Activity + Navigation Component | Simplifies back-stack management; Safe Args provides type-safe argument passing |
| Repository pattern | Decouples ViewModels from Room; makes the data source swappable for tests |
| `Flow` for reactive queries | Room emits updates automatically on every write; no manual refresh needed |
| `getAllArtworks().first()` for one-shot reads | `StateFlow.first()` returns the cached value immediately (possibly empty); a plain Room `Flow.first()` suspends until the DB emits |
| Internal storage + FileProvider | Avoids dangerous external storage permissions; works on all supported API levels |
| SAF for backup I/O | User controls the save location (local, SD card, cloud drive) without the app needing storage permissions |
| `org.json` + `android.media.ExifInterface` | Both are part of the Android SDK — no extra dependencies required |
| `@Transaction replaceAll` | Guarantees the collection is never in a partially-replaced state visible to other readers |
