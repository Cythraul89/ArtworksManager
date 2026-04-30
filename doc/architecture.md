# Architecture

## Pattern

The app follows **MVVM (Model-View-ViewModel)** with a **single Activity** hosting all screens via the Android Navigation Component. Data is stored entirely on-device; the only network call is an optional live currency-rate fetch.

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
│  ExchangeRateService                            │
└─────────────────────────────────────────────────┘
```

---

## Technology Stack

| Component              | Library / API                        | Version       |
|------------------------|--------------------------------------|---------------|
| Language               | Kotlin                               | 2.0.21        |
| UI framework           | AndroidX Fragments + ViewBinding     | —             |
| Navigation             | Navigation Component + Safe Args     | 2.9.0         |
| Design system          | Material 3 (`DayNight.NoActionBar`)  | 1.12.0        |
| Database               | Room                                 | 2.7.1         |
| Annotation processor   | KSP                                  | 2.0.21-1.0.28 |
| Async                  | Kotlin Coroutines + Flow             | 1.10.2        |
| Image loading          | Glide                                | 4.16.0        |
| PDF generation         | `android.graphics.pdf.PdfDocument`   | built-in      |
| EXIF reading           | `android.media.ExifInterface`        | built-in      |
| JSON serialisation     | `org.json`                           | built-in      |
| Backup I/O             | Storage Access Framework (SAF)       | built-in      |
| Exchange rates         | Frankfurter API (`HttpURLConnection`)| built-in      |
| Min SDK / Target SDK   | 33 / 35                              | —             |
| Build tools            | AGP 8.13.2 / Gradle 8.13             | —             |

---

## Package Structure

```
com.example.artworksmanager/
│
├── ArtworksManagerApp.kt          Application — database & repository singletons,
│                                  preferences singleton, night-mode follow-system
│
├── data/
│   ├── Artwork.kt                 Room @Entity — primary artwork record
│   ├── ArtworkPhoto.kt            Room @Entity — additional photos (one-to-many);
│   │                              FK → Artwork with CASCADE delete
│   ├── ArtworkDao.kt              Room @Dao — all SQL + @Transaction operations,
│   │                              including photo CRUD and price-total queries
│   ├── ArtworkDatabase.kt         Room @Database v3 — singleton via double-checked lock;
│   │                              migrations 1→2 (type/currency columns) and 2→3 (photos table)
│   ├── ArtworkRepository.kt       Single source of truth; exposes Flow and suspend
│   │                              functions for both entities to ViewModels
│   ├── AppPreferences.kt          SharedPreferences wrapper; exposes reactive
│   │                              currencyFlow via callbackFlow
│   └── Currency.kt                Enum: EUR / USD / NOK / ZAR;
│                                  fromCode() companion; label computed property
│
├── ui/
│   ├── MainActivity.kt            Single @Activity host; owns NavController &
│   │                              bottom nav; applies edge-to-edge insets
│   ├── addedit/
│   │   ├── AddEditFragment.kt     Add / Edit form; camera + gallery launcher
│   │   │                          (routed by pickingAdditionalPhoto flag);
│   │   │                          photo-diff state (photoItems / photosToDelete);
│   │   │                          IME inset handling; discard-changes dialog
│   │   ├── AddEditViewModel.kt    Validates input; saves artwork + photo diff
│   │   │                          via repository; exposes savedId StateFlow
│   │   │                          and additionalPhotos StateFlow
│   │   └── AdditionalPhotoAdapter.kt  RecyclerView adapter for the horizontal
│   │                                  photo strip; optional onRemove callback
│   │                                  shows/hides × badge (edit vs detail mode)
│   ├── collection/
│   │   ├── ArtworkAdapter.kt      RecyclerView adapter; supports grid & list view modes
│   │   ├── CollectionFragment.kt  Search bar, filter chips, view-toggle FAB
│   │   ├── CollectionViewModel.kt Combines search query + filter/sort state
│   │   │                          into a single filtered Flow via combine()
│   │   └── FilterSortBottomSheet.kt  Bottom sheet for medium filter & sort order
│   ├── dashboard/
│   │   ├── DashboardFragment.kt   Stats cards + collection value card + recent strip
│   │   ├── DashboardViewModel.kt  Exposes count, medium counts, top artists,
│   │   │                          recent artworks, priceTotals, and valueState
│   │   │                          (Loading / Ready / Unavailable) as StateFlows;
│   │   │                          uses currencyFlow.flatMapLatest to re-fetch
│   │   │                          exchange rates on preference change
│   │   └── RecentArtworkAdapter.kt  Horizontal RecyclerView adapter for the
│   │                               recently-added thumbnail strip
│   ├── detail/
│   │   ├── ArtworkDetailFragment.kt  Read-only detail view; horizontal photo strip;
│   │   │                             edit / delete toolbar actions
│   │   └── ArtworkDetailViewModel.kt  Loads artwork by ID; exposes additionalPhotos
│   │                                  StateFlow; provides delete()
│   └── settings/
│       └── SettingsFragment.kt    PDF export, backup export/import, currency
│                                  preference, Nextcloud placeholder, about info;
│                                  co-located SettingsViewModel
│
└── util/
    ├── BackupExporter.kt          Serialises List<Artwork> + Map<Long,List<ArtworkPhoto>>
    │                              to JSON (with additionalPhotos arrays) + copies all
    │                              photo files → writes zip to a SAF Uri
    ├── BackupImporter.kt          Reads a SAF Uri zip → extracts photos →
    │                              parses artworks.json (including additionalPhotos) →
    │                              returns BackupData(artworks, photos)
    ├── ExchangeRateService.kt     Fetches live rates from api.frankfurter.app;
    │                              returns Map<String,Double> or null on failure;
    │                              called on Dispatchers.IO
    └── PdfExporter.kt             Renders one A4 page per artwork using
                                   PdfDocument; corrects photo orientation via EXIF
```

---

## Data Layer

### Entities

The database contains two Room entities:

**`Artwork`** — the primary record. All fields except `id` and `title` are optional. Key fields:
- `type` — artwork type (Painting, Drawing, Photography, Sculpture, Print, Book, Textile, Ceramics, Other)
- `currency` — per-artwork currency code; empty string means "use global preference"
- `photoPath` — absolute path of the cover photo within `filesDir/artworks/`; empty when no photo

**`ArtworkPhoto`** — additional photos for an artwork. Has a foreign key to `Artwork` with `CASCADE` delete, so all photos are automatically removed when their parent artwork is deleted. Fields: `id`, `artworkId`, `photoPath`, `sortOrder`.

### DAO

`ArtworkDao` exposes:

| Category | Operations |
|----------|------------|
| **Reactive queries** (`Flow`) | `getAllArtworks`, `getCount`, `getMediumCounts`, `getTopArtists`, `getRecentArtworks`, `getDistinctMediums`, `getPriceTotals`, `getPhotosForArtwork` |
| **Suspend mutations** | `insert`, `insertAll`, `update`, `delete`, `deleteAll`, `replaceAll`, `insertPhoto`, `insertPhotos`, `deletePhoto`, `deletePhotosForArtwork` |
| **One-shot suspend** | `getById`, `getAllPhotosOnce` |

`replaceAll` is `@Transaction`: atomically deletes all artworks (cascading to photos) and inserts the replacement set including new photo rows.

`getPriceTotals` returns `List<CurrencyTotal>` — one row per distinct currency with the sum of purchase prices. Used by the Dashboard collection value card.

### Repository

`ArtworkRepository` is a thin delegation layer that exposes both entity's operations. ViewModels never touch the DAO directly.

### Database version history

| Version | Change |
|---------|--------|
| 1 | Initial schema (`artworks` table) |
| 2 | Added `type TEXT NOT NULL DEFAULT ''` and `currency TEXT NOT NULL DEFAULT ''` columns to `artworks` |
| 3 | Added `artwork_photos` table with index on `artworkId` |

---

## UI Layer

### Single Activity

`MainActivity` owns the `NavHostFragment` and the bottom navigation bar. It applies `WindowInsetsCompat` to:
- add `top` padding to the nav host (clears the status bar on Android 15 edge-to-edge)
- add `bottom` padding to the bottom nav (clears the navigation bar)
- **return `insets` unconsumed** so IME (keyboard) insets propagate to individual fragments

### ViewModels

Each screen has a dedicated ViewModel created via a `ViewModelProvider.Factory` that receives the repository (and `AppPreferences` where needed) from `ArtworksManagerApp`. ViewModels:
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
  └─ Flow<List<Artwork>> / Flow<List<ArtworkPhoto>>
       └─ Repository (passes through)
            └─ ViewModel
                 ├─ stateIn(WhileSubscribed / Eagerly) → StateFlow
                 └─ Fragment.collect { updateUI() }
```

One-shot reads (e.g. for PDF/backup export) use `repository.getAllArtworks().first()` on `Dispatchers.IO` — this guarantees Room has emitted real data even on the very first call.

Mutations are `suspend` functions called from `viewModelScope` in ViewModels or `lifecycleScope + withContext(Dispatchers.IO)` in Fragments.

**Reactive preferences:** `AppPreferences.currencyFlow` wraps `SharedPreferences.OnSharedPreferenceChangeListener` in a `callbackFlow`, emitting a new `Currency` value whenever the preference changes. `DashboardViewModel` uses `currencyFlow.flatMapLatest { … }` to automatically re-fetch exchange rates whenever the user changes the currency preference.

---

## Collection Value & Exchange Rates

The Dashboard **Collection Value** card shows a per-currency breakdown of purchase prices and, when online, a grand total converted to the user's preferred currency.

```
DashboardViewModel
  ├─ priceTotals: StateFlow<List<CurrencyTotal>>
  │    └─ ArtworkDao.getPriceTotals()   GROUP BY currency, SUM(purchasePrice)
  └─ valueState: StateFlow<ValueState>
       └─ preferences.currencyFlow.flatMapLatest { targetCurrency ->
              rates = ExchangeRateService.fetchRates(targetCurrency.code)   // IO thread
              priceTotals.map { totals -> computeValueState(totals, targetCurrency, rates) }
          }
```

`ValueState` is a sealed class: `Loading`, `Ready(amount, currency, isLive)`, `Unavailable`.

`ExchangeRateService` calls `https://api.frankfurter.app/latest?from=<code>`, returning ECB rates. Conversion: `amount_in_X / rates["X"]`. Returns `null` on any network or parse failure — `DashboardFragment` shows "Offline – conversion unavailable" in that case.

---

## Backup System

### Export

```
SettingsFragment
  ├─ loadArtworksNow()           → suspend, Dispatchers.IO
  ├─ loadAllPhotosNow()          → suspend, Dispatchers.IO; Map<Long, List<ArtworkPhoto>>
  └─ BackupExporter.writeTo(uri, artworks, photosByArtwork)
       ├─ addJson()              serialises artworks to JSON; each artwork entry
       │                         includes an "additionalPhotos" array when present
       └─ addPhotoFiles()        streams every file from filesDir/artworks/ as a zip entry
```

### Import

```
SettingsFragment
  └─ BackupImporter.importFrom(uri)     Dispatchers.IO
       ├─ ZipInputStream pass           extracts photos → filesDir/artworks/
       │                                captures artworks.json bytes
       └─ parseData()                   reconstructs Artwork list and ArtworkPhoto list;
                                        resolves all photoPath fields to extracted local files
                                        returns BackupData(artworks, photos)
  └─ SettingsViewModel.replaceAll(data.artworks, data.photos)
       └─ ArtworkDao.replaceAll()       @Transaction: deleteAll + insertAll (artworks + photos)
```

---

## File Storage

| Location | Content | Access |
|----------|---------|--------|
| `filesDir/artworks/` | Artwork photos — cover and additional (`.jpg`) | Via `FileProvider` for camera / sharing |
| `cacheDir/` | Temporary PDF files | Via `FileProvider` for sharing |
| SAF Uri (user-chosen) | Backup zip | Via `ContentResolver` |

Photos are stored in `filesDir` (private internal storage), avoiding the `READ/WRITE_EXTERNAL_STORAGE` permission. `FileProvider` is used whenever a Uri must be passed to another app.

---

## User Preferences

App-level preferences are stored in `SharedPreferences` via `AppPreferences`.

| Preference | Key | Default | Type |
|------------|-----|---------|------|
| Currency   | `currency` | `EUR` | `Currency` enum code |

`Currency` is an enum with `code`, `symbol`, `displayName`, and a computed `label` property. Adding a new currency is a one-line change in the enum. The global currency preference is the default display currency; individual artworks can override it with their own `currency` field.

`AppPreferences` exposes both a synchronous `currency` property and a `currencyFlow: Flow<Currency>` for reactive observation.

## Dark Mode

The app uses `Theme.Material3.DayNight.NoActionBar` and calls `AppCompatDelegate.setDefaultNightMode(MODE_NIGHT_FOLLOW_SYSTEM)` at startup. Dark-mode colour overrides live in `res/values-night/colors.xml`. All colour references use `@color/` names so they resolve automatically at runtime.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Single Activity + Navigation Component | Simplifies back-stack management; Safe Args provides type-safe argument passing |
| Repository pattern | Decouples ViewModels from Room; makes the data source swappable for tests |
| `Flow` for reactive queries | Room emits updates automatically on every write; no manual refresh needed |
| `getAllArtworks().first()` for one-shot reads | `StateFlow.first()` returns the cached value (possibly empty); a plain Room `Flow.first()` suspends until the DB emits |
| `currencyFlow` + `flatMapLatest` | Re-fetches exchange rates whenever the user changes the currency preference; avoids stale totals without polling |
| `ArtworkPhoto` separate entity + CASCADE | Keeps the `Artwork` table lean; orphan photos are cleaned up automatically on artwork deletion |
| `BackupData` return type from importer | Keeps `BackupImporter` stateless and makes the photo list explicit at the call site |
| Internal storage + FileProvider | Avoids dangerous external storage permissions; works on all supported API levels |
| SAF for backup I/O | User controls the save location (local, SD card, cloud drive) without the app needing storage permissions |
| `org.json` + `android.media.ExifInterface` | Both are part of the Android SDK — no extra dependencies required |
| `@Transaction replaceAll` | Guarantees the collection is never in a partially-replaced state visible to other readers |
| Frankfurter API (no key) | ECB-sourced rates, free, no registration; `null` return on failure triggers graceful offline fallback |
