# App Requirements

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
  - Cover photo + additional photos (taken with camera or selected from gallery)
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

## Nice to Have

- Tags / custom categories
- Export collection as CSV
- Nextcloud backup — optional sync of the local database and photos to a user-configured Nextcloud instance
- Estimated current value field separate from purchase price
- Provenance / ownership history notes
- Condition field (excellent, good, fair, poor)

## Out of Scope

- Multi-user access or sharing with others
- Mandatory cloud dependency (app must be fully functional without any internet connection)
- Public marketplace or valuation services
- Collections larger than 1000 artworks

## Screens / User Flows

1. **Dashboard** — entry point; shows total artwork count, quick stats by medium and artist, collection value card, recently-added strip, and a shortcut to add a new artwork
2. **Collection list** — grid or list of all artworks; supports search, filter, and sort; tapping an item opens the detail view
3. **Artwork detail** — displays the cover photo, additional photo strip, and all recorded fields; action buttons to edit or delete
4. **Add / Edit artwork** — form with all fields, cover photo picker/camera, additional photo strip with add/remove, and a save button
5. **Settings** — currency preference, export PDF, export/import zip backup, about info (version, license)

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
- **Internet:** `INTERNET` and `ACCESS_NETWORK_STATE` permissions are declared; used only for the optional live exchange rate fetch
