# Class Diagram

```mermaid
classDiagram
    direction TB

    %% ─────────────────────────────────────────
    %% APPLICATION
    %% ─────────────────────────────────────────

    class ArtworksManagerApp {
        <<Application>>
        +database : ArtworkDatabase
        +repository : ArtworkRepository
        +preferences : AppPreferences
    }

    %% ─────────────────────────────────────────
    %% DATA LAYER
    %% ─────────────────────────────────────────

    class Artwork {
        <<Entity>>
        +id : Long
        +title : String
        +artist : String
        +year : Int
        +medium : String
        +heightCm : Float
        +widthCm : Float
        +depthCm : Float
        +location : String
        +acquisitionDate : Long
        +purchasePrice : Double
        +description : String
        +photoPath : String
        +createdAt : Long
    }

    class AppPreferences {
        -prefs : SharedPreferences
        +currency : Currency
    }

    class Currency {
        <<enumeration>>
        EUR
        USD
        NOK
        ZAR
        +code : String
        +symbol : String
        +displayName : String
        +label : String
        +fromCode(code) Currency$
    }

    class MediumCount {
        +medium : String
        +count : Int
    }

    class ArtistCount {
        +artist : String
        +count : Int
    }

    class ArtworkDao {
        <<interface>>
        +getAllArtworks() Flow~List~Artwork~~
        +getById(id : Long) Artwork
        +getCount() Flow~Int~
        +getMediumCounts() Flow~List~MediumCount~~
        +getTopArtists() Flow~List~ArtistCount~~
        +getRecentArtworks() Flow~List~Artwork~~
        +getDistinctMediums() Flow~List~String~~
        +insert(artwork : Artwork) Long
        +insertAll(artworks : List~Artwork~)
        +update(artwork : Artwork)
        +delete(artwork : Artwork)
        +deleteAll()
        +replaceAll(artworks : List~Artwork~)
    }

    class ArtworkDatabase {
        <<abstract>>
        +artworkDao() ArtworkDao
        +getDatabase(context) ArtworkDatabase$
    }

    class ArtworkRepository {
        -dao : ArtworkDao
        +getAllArtworks() Flow~List~Artwork~~
        +getCount() Flow~Int~
        +getMediumCounts() Flow~List~MediumCount~~
        +getTopArtists() Flow~List~ArtistCount~~
        +getRecentArtworks() Flow~List~Artwork~~
        +getDistinctMediums() Flow~List~String~~
        +getById(id : Long) Artwork
        +insert(artwork : Artwork) Long
        +update(artwork : Artwork)
        +delete(artwork : Artwork)
        +replaceAll(artworks : List~Artwork~)
    }

    %% ─────────────────────────────────────────
    %% UI — MAIN
    %% ─────────────────────────────────────────

    class MainActivity {
        <<Activity>>
        -binding : ActivityMainBinding
    }

    %% ─────────────────────────────────────────
    %% UI — ADD / EDIT
    %% ─────────────────────────────────────────

    class AddEditViewModel {
        -repository : ArtworkRepository
        +artwork : StateFlow~Artwork~
        +savedId : StateFlow~Long~
        +load(id : Long)
        +save(id, title, artist, ...)
    }

    class AddEditFragment {
        <<Fragment>>
        -viewModel : AddEditViewModel
        -currentPhotoPath : String
        -selectedDateMs : Long
    }

    %% ─────────────────────────────────────────
    %% UI — COLLECTION
    %% ─────────────────────────────────────────

    class CollectionViewModel {
        -repository : ArtworkRepository
        +artworks : StateFlow~List~Artwork~~
        +distinctMediums : StateFlow~List~String~~
        +searchQuery : StateFlow~String~
        +filterMedium : StateFlow~String~
        +sortBy : StateFlow~String~
        +setSearch(query : String)
        +applyFilter(medium, sortBy)
        +resetFilters()
    }

    class CollectionFragment {
        <<Fragment>>
        -viewModel : CollectionViewModel
        -adapter : ArtworkAdapter
    }

    class ArtworkAdapter {
        <<ListAdapter>>
        +submitList(artworks : List~Artwork~)
    }

    class FilterSortBottomSheet {
        <<BottomSheetDialogFragment>>
        +onApply : (medium, sortBy) -> Unit
    }

    %% ─────────────────────────────────────────
    %% UI — DASHBOARD
    %% ─────────────────────────────────────────

    class DashboardViewModel {
        -repository : ArtworkRepository
        +totalCount : StateFlow~Int~
        +mediumCounts : StateFlow~List~MediumCount~~
        +topArtists : StateFlow~List~ArtistCount~~
        +recentArtworks : StateFlow~List~Artwork~~
    }

    class DashboardFragment {
        <<Fragment>>
        -viewModel : DashboardViewModel
        -recentAdapter : RecentArtworkAdapter
    }

    class RecentArtworkAdapter {
        <<ListAdapter>>
        +submitList(artworks : List~Artwork~)
    }

    %% ─────────────────────────────────────────
    %% UI — DETAIL
    %% ─────────────────────────────────────────

    class ArtworkDetailViewModel {
        -repository : ArtworkRepository
        +artwork : StateFlow~Artwork~
        +load(id : Long)
        +delete(artwork, onDone)
    }

    class ArtworkDetailFragment {
        <<Fragment>>
        -viewModel : ArtworkDetailViewModel
    }

    %% ─────────────────────────────────────────
    %% UI — SETTINGS
    %% ─────────────────────────────────────────

    class SettingsViewModel {
        -repository : ArtworkRepository
        +loadArtworksNow() List~Artwork~
        +replaceAll(artworks : List~Artwork~)
    }

    class SettingsFragment {
        <<Fragment>>
        -viewModel : SettingsViewModel
    }

    %% ─────────────────────────────────────────
    %% UTIL
    %% ─────────────────────────────────────────

    class PdfExporter {
        -context : Context
        +generateUri(artworks : List~Artwork~) Uri
        +share(uri : Uri)
        -loadOrientedBitmap(path) Bitmap
    }

    class BackupExporter {
        -context : Context
        +writeTo(uri : Uri, artworks : List~Artwork~)
    }

    class BackupImporter {
        -context : Context
        +importFrom(uri : Uri) List~Artwork~
    }

    %% ─────────────────────────────────────────
    %% RELATIONSHIPS
    %% ─────────────────────────────────────────

    %% Application bootstraps the data layer
    ArtworksManagerApp *-- ArtworkDatabase : creates
    ArtworksManagerApp *-- ArtworkRepository : creates
    ArtworksManagerApp *-- AppPreferences : creates
    AppPreferences --> Currency : reads/writes

    %% Data layer wiring
    ArtworkDatabase ..> ArtworkDao : exposes
    ArtworkRepository --> ArtworkDao : delegates to
    ArtworkDao ..> Artwork : operates on
    ArtworkDao ..> MediumCount : projects
    ArtworkDao ..> ArtistCount : projects

    %% ViewModels depend on repository
    AddEditViewModel --> ArtworkRepository : uses
    CollectionViewModel --> ArtworkRepository : uses
    DashboardViewModel --> ArtworkRepository : uses
    ArtworkDetailViewModel --> ArtworkRepository : uses
    SettingsViewModel --> ArtworkRepository : uses

    %% Fragments own their ViewModels and adapters
    AddEditFragment --> AddEditViewModel : observes
    CollectionFragment --> CollectionViewModel : observes
    CollectionFragment *-- ArtworkAdapter : owns
    CollectionFragment ..> FilterSortBottomSheet : shows
    DashboardFragment --> DashboardViewModel : observes
    DashboardFragment *-- RecentArtworkAdapter : owns
    ArtworkDetailFragment --> ArtworkDetailViewModel : observes
    SettingsFragment --> SettingsViewModel : uses

    %% Settings uses util classes
    SettingsFragment ..> PdfExporter : uses
    SettingsFragment ..> BackupExporter : uses
    SettingsFragment ..> BackupImporter : uses

    %% Util classes operate on Artwork
    PdfExporter ..> Artwork : renders
    BackupExporter ..> Artwork : serialises
    BackupImporter ..> Artwork : deserialises

    %% Dashboard projections
    DashboardViewModel ..> MediumCount : observes
    DashboardViewModel ..> ArtistCount : observes
```

## Legend

| Symbol | Meaning |
|--------|---------|
| `*--`  | Composition — the owner creates and owns the target |
| `-->`  | Association — holds a reference to the target |
| `..>`  | Dependency — uses the target (parameter, return type, or short-lived) |
| `$`    | Companion object / static member |
| `<<interface>>` | Kotlin interface |
| `<<abstract>>` | Abstract class |
| `<<Entity>>` | Room database entity |
| `<<Application>>` | Android Application subclass |
| `<<Activity>>` | Android Activity |
| `<<Fragment>>` | AndroidX Fragment |
| `<<ListAdapter>>` | RecyclerView ListAdapter |
| `<<BottomSheetDialogFragment>>` | Material bottom sheet |
